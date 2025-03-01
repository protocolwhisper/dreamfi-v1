#pragma version >=0.4.0

import currency
import IERC20

MAX_POSITIONS: public(constant(uint8)) = 10

BORROW_RATIO: constant(uint256) = 80 # N / 100
LIQUIDATE_INCENTIVE_RATIO: constant(uint256) = 5 # N / 100

struct Position:
    oracle: address
    asset: address

cdpAsset: address
liquidateBeneficiary: address
positions: DynArray[Position, MAX_POSITIONS]

cdpBorrowed: HashMap[address, uint256] # user => amount of cdp borrowed by user
poolCollateral: HashMap[address, uint256] # asset => amount of asset for entire pool
userCollateral: public(HashMap[address, HashMap[address, uint256]]) # user => (asset => amount owned by user)

# Takes in array of (AssetAddress, AssetWeight) for the pool composition.
# The sum of AssetWeight must equal 100 * currency.SCALE
@deploy
def __init__(
    cdp_asset: address, # the asset address of the CDP token
    liquidate_beneficiary: address, # where protocol-benefitting liquidated assets are sent.
    collateral_positions: DynArray[Position, MAX_POSITIONS], # list of (oracle, asset) for this pool
):
    assert cdp_asset.is_contract
    assert len(collateral_positions) > 0

    self.cdpAsset = cdp_asset
    self.positions = collateral_positions
    self.liquidateBeneficiary = liquidate_beneficiary

struct PriceInfo:
    assetPrice: uint256
    poolCollateral: uint256
    userCollateral: uint256
    cdpBorrowed: uint256
    cdpSupply: uint256

@view
@internal
def getPriceInfo(user: address, optional_asset: address) -> PriceInfo:
    info: PriceInfo = empty(PriceInfo)
    for position: Position in self.positions:
        price: uint256 = currency.getPrice(position.oracle)
        info.poolCollateral += price * self.poolCollateral[position.asset]
        info.userCollateral += price * self.userCollateral[user][position.asset]

        if position.asset == optional_asset:
            info.assetPrice = price

    info.cdpBorrowed = self.cdpBorrowed[user]
    info.cdpSupply = staticcall IERC20(self.cdpAsset).totalSupply()
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

# Moves ${amount} from the user's ${asset} account to vault's ${asset} account (creating collateral).
# Also mints new CDP to the vault's proportional to the asset amount value.
@external
def deposit(asset: address, amount: uint256):
    assert asset.is_contract, "Asset must be a contract"
    assert asset != empty(address), "Asset must be valid"
    assert amount > 0, "Deposit would be a no-op"

    user: address = msg.sender
    info: PriceInfo = self.getPriceInfo(user, asset)
    
    # Figure out how many new tokens to mint
    newTokens: uint256 = 0
    if info.cdpSupply == 0:
        newTokens = 1_000_000 # arbitrary starting tokens minted
    else:
        newPoolCollateral: uint256 = info.poolCollateral + (info.assetPrice * amount)
        newTokens = (newPoolCollateral * info.cdpSupply) // info.poolCollateral

    self.poolCollateral[asset] += amount
    self.userCollateral[user][asset] += amount
    
    extcall IERC20(self.cdpAsset).mint(self, newTokens) # $0 -> vault (CDP)
    extcall IERC20(asset).transferFrom(user, self, amount, default_return_value=True) # user -> vault (asset)
    

# Moves ${cdpAmount} from the vault to the user, increasing their debt.
# They must never borrow more than BORROW_RATIO of their deposited collateral.
@external
def borrow(cdpAmount: uint256):
    assert cdpAmount > 0, "Borrow would be a no-op"

    user: address = msg.sender
    info: PriceInfo = self.getPriceInfo(user, empty(address))
    assert self.cdpBorrowMax(info) > info.cdpBorrowed, "User is up for liquidation"

    cdpBorrowable: uint256 = self.cdpBorrowMax(info) - info.cdpBorrowed
    assert cdpAmount <= cdpBorrowable, "Attempt to borrow more CDP than collateral allows"
    
    self.cdpBorrowed[user] += cdpAmount
    extcall IERC20(self.cdpAsset).transferFrom(self, user, cdpAmount, default_return_value=True) # vault -> User (CDP)

# Moves ${cdpAmount} from the user to the vault, decreasing their debt.
@external
def repay(cdpAmount: uint256):
    assert cdpAmount > 0, "Repay would be a no-op"

    user: address = msg.sender
    info: PriceInfo = self.getPriceInfo(user, empty(address))
    assert info.cdpBorrowed >= cdpAmount, "Attempt to repay more CDP than borrowed"

    self.cdpBorrowed[user] -= cdpAmount
    extcall IERC20(self.cdpAsset).transferFrom(user, self, cdpAmount, default_return_value=True) # User -> vault (CDP)

# Moves ${amount} from the vaults's ${asset} account to user's ${asset} account (removing collateral).
# Fails either if:
# - user never deposit ${amount} of ${asset}.
# - it would bring their deposited value bellow the borrowed CDP value.
# On success, burns an equivalent amount of CDP from the vault.
@external
def withdraw(asset: address, amount: uint256):
    #Check user health factor
    
    #Check that the witdraw is still viable by the health factor
    assert asset.is_contract, "Asset address must be a contract"
    assert asset != empty(address), "Asset address cannot be zero"
    assert amount > 0, "Amount must be greater than 0"
    
    user_address: address = msg.sender
    user_cdp: uint256 = self.cdpBorrowed[user_address]

    
    user_collateral: uint256 = self.userCollateral[user_address][asset] #amount of asset per user
    assert user_collateral >= amount, "Insufficient collateral"
    
    info: PriceInfo = self.getPriceInfo(user_address, asset)

    asset_price: uint256 = info.assetPrice #Asset price in usdc
    cdp_to_burn: uint256 = amount * asset_price # amount in usdc
    cdp_price: uint256 = self.cdpPrice(info) #Price of cdp in usdc 

    amount_burn: uint256 = (cdp_to_burn * currency.SCALE) // cdp_price  
    
    assert info.cdpBorrowed <= self.cdpBorrowMax(info)
    self.poolCollateral[asset] -= amount
    self.userCollateral[user_address][asset] -= amount
    
    # Transfer
    extcall IERC20(asset).transfer(user_address, amount)
    extcall IERC20(self.cdpAsset).burn(self, amount_burn)

struct Fund:
    asset: address
    amount: uint256

# Attempts to liquidate the passed in user's deposited collateral.
# Otherwise it burns ${user's borrowed CDP} worth of caller's CDP to the vault
# Then:
# - Move ${user's borrowed CDP} worth of their collateral from vault to caller (burning caller's CDP).
# - Move LIQUIDATE_INCENTIVE_RATIO of user's collateral from vault to caller.
# - Move remaining of user's collateral from vault to liquidateBeneficiary account.
# Returns (asset, amount) collateral deposited from the user that was rewarded to the caller/liquidator.
@external
def liquidate(user: address) -> DynArray[Fund, MAX_POSITIONS]:
    assert user != empty(address), "Invalid target address for liquidation"

    userInfo: PriceInfo = self.getPriceInfo(user, empty(address))
    if self.cdpBorrowMax(userInfo) >= userInfo.cdpBorrowed:
        return [] # User isnt liquidatable

    borrowedCollateral: uint256 = userInfo.cdpBorrowed * self.cdpPrice(userInfo)
    assert userInfo.userCollateral >= borrowedCollateral

    liquidatorIncentiveCollateral: uint256 = (userInfo.userCollateral * LIQUIDATE_INCENTIVE_RATIO) // 100
    liquidatorReceiveCollateral: uint256 = liquidatorIncentiveCollateral + borrowedCollateral
    beneficiaryReceiveCollateral: uint256 = userInfo.userCollateral - liquidatorReceiveCollateral
    assert userInfo.userCollateral == liquidatorReceiveCollateral + beneficiaryReceiveCollateral
    
    # Burn user's worth of borrowed CDP from liquidator.
    # We will withdraw from user's collateral to pay liquidator for it.
    liquidator: address = msg.sender
    extcall IERC20(self.cdpAsset).burn(liquidator, userInfo.cdpBorrowed)

    # Move ${user CDP borrowed} + ${incentive} of user collateral to liquidator.
    # Move remaining of user collateral to li
    liquidated: DynArray[Fund, MAX_POSITIONS] = []
    for position: Position in self.positions:
        price: uint256 = currency.getPrice(position.oracle)
        collateral: uint256 = price * self.userCollateral[user][position.asset]

        # From the user's collateral on this asset, reward the liquidator frist.
        move: uint256 = min(collateral, liquidatorReceiveCollateral)
        if move > 0:
            collateral -= move
            liquidatorReceiveCollateral -= move
            amount: uint256 = move // price
            liquidated.append(Fund(asset=position.asset, amount=amount))
            extcall IERC20(position.asset).transferFrom(self, liquidator, amount, default_return_value=True)

        # Then reward the beneficiary if there's any left over.
        move = min(collateral, beneficiaryReceiveCollateral)
        if move > 0:
            beneficiaryReceiveCollateral -= move
            amount: uint256 = move // price
            extcall IERC20(position.asset).transferFrom(self, self.liquidateBeneficiary, amount, default_return_value=True)

    return liquidated

@view
@internal
def userHealthFactor(user: address) -> uint256:
    info: PriceInfo = self.getPriceInfo(user, empty(address))
    cdp_price: uint256 = info.cdpBorrowed * self.cdpPrice(info)
    return (cdp_price * currency.SCALE) // info.userCollateral

@view
@internal
def poolHealthFactor() -> uint256:
    info: PriceInfo = self.getPriceInfo(self, empty(address))
    return (info.cdpSupply * currency.SCALE) // info.poolCollateral
