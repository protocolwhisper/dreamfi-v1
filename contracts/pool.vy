#pragma version >=0.3.0

from currency import SCALE
from current import getPrice
from snekmate import IERC20

MAX_POSITIONS: constant(uint8) = 10
BORROW_RATIO: constant(uint256) = 80 # N / 100
LIQUIDATE_INCENTIVE_RATIO: constant(uint256) = 5 # N / 100

cdpAsset: immutable(address)
liquidateBeneficiary: immutable(address)
assets: immutable(DynArray[address, MAX_POSITIONS])

cdpBorrowed: HashMap[address, uint256] # user => amount of cdp borrowed by user
poolCollateral: HashMap[address, uint256] # asset => amount of asset for entire pool
userCollateral: public(HashMap[(address, address), uint256]) # (user, asset) => amount of asset for user

'''
Takes in array of (AssetAddress, AssetWeight) for the pool composition.
The sum of AssetWeight must equal 100 * currency.SCALE
'''
@deploy
def __init__(
    cdp_asset: address, # the asset address of the CDP token
    liquidate_beneficiary: address, # where protocol-benefitting liquidated assets are sent.
    assets: DynArray[address, MAX_POSITIONS], # list of asset addresses for this pool
):
    assert cdp_asset._is_contract
    assert len(assets) > 0

    self.assets = assets
    self.cdpAsset = cdp_asset
    self.liquidateBeneficiary = liquidate_beneficiary

struct PriceInfo:
    poolCollateral: uint256
    userCollateral: uint256
    cdpBorrowed: uint256
    cdpSupply: uint256

@view
@internal
def getPriceInfo(user: address) -> PriceInfo:
    info: PriceInfo = empty(PriceInfo)
    for asset: address in self.assets:
        price: uint256 = getPrice(asset)
        info.poolCollateral += price * self.poolCollateral[asset]
        info.userCollateral += price * self.userCollateral[(user, asset)]

    info.cdpBorrowed = self.cdpBorrowed[user]
    info.cdpSupply = extcall IERC20(self.cdpAsset).totalSupply()
    return info

@pure
@internal
def cdpPrice(info: PriceInfo) -> uint256:
    return info.poolCollateral // info.cdpSupply

@pure
@internal
def cdpBorrowMax(info: PriceInfo) -> uint256:
    collateralBorrowMax: uint256 = (info.userCollateral * BORROW_RATIO) // 100
    return (collateralBorrowMax * info.cdpSupply) // info.poolCollateral

'''
Moves ${amount} from the user's ${asset} account to vault's ${asset} account (creating collateral).
Also mints new CDP to the vault's proportional to the asset amount value.
'''
@external
def deposit(asset: address, amount: uint256):
    assert asset._is_contract, "Asset must be a contract"
    assert asset != empty(address), "Asset must be valid"
    assert amount > 0, "Deposit would be a no-op"

    user: address = msg.sender
    info: PriceInfo = getPriceInfo(user)
    
    # Figure out how many new tokens to mint
    newTokens: uint256 = 0
    if info.cdpSupply == 0:
        newTokens = 1_000_000 # arbitrary starting tokens minted
    else:
        newPoolCollateral: uint256 = info.poolCollateral + (getPrice(asset) * amount)
        newTokens = (newPoolCollateral * info.cdpSupply) // info.poolCollateral

    self.poolCollateral[asset] += amount
    self.userCollateral[(userr, asset)] += amount
    extcall IERC20(asset).transfer(self, amount) # user -> vault (asset)
    # TODO: IERC20(self.cdpAsset).mint(self, newTokens)

'''
Moves ${cdpAmount} from the vault to the user, increasing their debt.
They must never borrow more than BORROW_RATIO of their deposited collateral.
'''
@external
def borrow(cdpAmount: uint256):
    assert cdpAmount > 0, "Borrow would be a no-op"

    user: address = msg.sender
    info: PriceInfo = getPriceInfo(user)
    assert cdpBorrowMax(info) > info.cdpBorrowed, "User is up for liquidation"

    cdpBorrowable: uint256 = cdpBorrowMax(info) - info.cdpBorrowed
    assert cdpAmount <= cdpBorrowable, "Attempt to borrow more CDP than collateral allows"
    
    self.cdpBorrowed[user] += cdpAmount
    extcall IERC20(self.cdpAsset).transferFrom(self, user, cdpAmount) # vault -> User (CDP)

'''
Moves ${cdpAmount} from the user to the vault, decreasing their debt.
'''
@external
def repay(cdpAmount: uint256):
    assert cdpAmount > 0, "Repay would be a no-op"

    user: address = msg.sender
    info: PriceInfo = getPriceInfo(user)
    assert info.cdpBorrowed >= cdpAmount, "Attempt to repay more CDP than borrowed"

    self.cdpBorrowed[user] -= cdpAmount
    extcall IERC20(self.cdpAsset).transferFrom(user, self, cdpAmount) # User/caller -> vault (CDP)

'''
Moves ${amount} from the vaults's ${asset} account to user's ${asset} account (removing collateral).
Fails either if:
- user never deposit ${amount} of ${asset}.
- it would bring their deposited value bellow the borrowed CDP value.
On success, burns an equivalent amount of CDP from the vault.
'''
@external
def withdraw(asset: address, amount: uint256) -> uint256:
    #Check that the witdraw is still viable by the health factor
    assert asset.is_contract, "Asset address must be a contract"
    assert asset != empty(address), "Asset address cannot be zero"
    assert amount > 0, "Amount must be greater than 0"
    
    user_address: address = msg.sender
    user_cdp: uint256 = self.cdpBorrowed[user_address]

    
    user_collateral: uint256 = self.userCollateral[(user_address, asset)]
    assert user_collateral >= amount, "Insufficient collateral"
    

    # I don't get how is when theres two tokens in the game
    asset_price: uint256 = getPrice(asset)
    cdp_to_burn: uint256 = amount * asset_price #This is in usdc
    cdp_price: uint256 = self.cdpPrice(self.getPriceInfo()) #Price of cdp in usdc

    amount_burn: uint256 = cdp_to_burn / cdp_price

    # Update state and perform transfers
    self.poolCollateral[asset] -= amount
    self.userCollateral[(user_address, asset)] -= amount
    
    # Transfer
    assert IERC20(asset).transfer(user_address, amount)
    #Burning
    assert IERC20(self.cdpAsset).burn(amount_burn), "CDP burn failed"
    
    return amount

'''
Attempts to liquidate the passed in user's deposited collateral.
Otherwise it burns ${user's borrowed CDP} worth of caller's CDP to the vault
Then:
- Move ${user's borrowed CDP} worth of their collateral from vault to caller (burning caller's CDP).
- Move LIQUIDATE_INCENTIVE_RATIO of user's collateral from vault to caller.
- Move remaining of user's collateral from vault to liquidate_account.
Returns (asset, amount) collateral from the target user that was rewarded to the caller.
'''
@external
def liquidate(user: address) -> DynArray[(address, uint256), MAX_POSITIONS]:
    assert user != empty(address), "Invalid target address for liquidation"

    userInfo: PriceInfo = getPriceInfo(user)
    if cdpBorrowMax(userInfo) >= userInfo.cdpBorrowed:
        return [] # User isnt liquidatable

    borrowedCollateral: uint256 = userInfo.cdpBorrowed * cdpPrice(userInfo)
    assert userInfo.userCollateral >= borrowedCollateral

    liquidIncentiveCollateral: uint256 = (userInfo.userCollateral * LIQUIDATE_INCENTIVE_RATIO) // 100
    liquidBenefitCollateral: uint256 = user.userCollateral - liquidIncentiveCollateral - borrowedCollateral
    assert userInfo.userCollateral == (liquidBenefitCollateral + liquidIncentiveCollateral + borrowedCollateral)
    
    # Burn user's worth of borrowed CDP from liquidator.
    # We'll withdraw from user's collateral to pay liquidator for it.
    liquidator: address = msg.sender
    extcall IERC20(self.cdpAsset).burn(liquidator, userInfo.cdpBorrowed)
    
    # Move ${user CDP borrowed} + ${incentive} of user collateral to liquidator.
    # Move remaining of user collateral to li
    liquidated: DynArray[(address, uint256), MAX_POSITIONS] = []
    for asset: address in self.assets:
        collateral: uint256 = getPrice(asset) * self.userCollateral[(user, asset)]
        # TODO: count down from {borrow/liqIncent/liqBen}Collat and send the collats

    extcall IERC20(self.cdpAsset).transfer(user_address, amount)
