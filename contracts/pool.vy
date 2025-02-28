#pragma version >=0.3.0

from currency import SCALE
from current import getPrice
from snekmate import IERC20

MAX_POSITIONS: constant(uint8) = 10
BORROW_RATIO: constant(uint256) = 80 # N / 100
LIQUIDATE_RATIO: constant(uint256) = 5 # N / 100

cdpAsset: immutable(address)
liquidateAccount: immutable(address)
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
    liquidate_account: address, # where protocol-benefitting liquidated assets are stored.
    assets: DynArray[address, MAX_POSITIONS], # list of asset addresses for this pool
):
    assert cdp_asset._is_contract
    assert len(assets) > 0

    self.assets = assets
    self.cdpAsset = cdp_asset
    self.liquidateAccount = liquidate_account

struct PriceInfo:
    poolCollateral: uint256
    userCollateral: uint256
    cdpBorrowed: uint256
    cdpSupply: uint256

@view
@internal
def getPriceInfo():
    info: PriceInfo = empty(PriceInfo)

    for asset: address in self.assets:
        price: uint256 = getPrice(asset)
        info.poolCollateral += price * self.poolCollateral[asset]
        info.userCollateral += price * self.userCollateral[(msg.sender, asset)]

    info.cdpBorrowed = self.cdpBorrowed[msg.sender]
    info.cdpSupply = extcall IERC20(self.cdpAsset).totalSupply()
    return info

'''
Moves ${amount} from the user's ${asset} account to vault's ${asset} account (creating collateral).
Also mints new CDP to the vault's proportional to the asset amount value.
'''
@external
def deposit(asset: address, amount: uint256):
    assert asset._is_contract
    assert amount > 0

    self.poolCollateral[asset] += amount
    self.userCollateral[(msg.sender, asset)] += amount
    extcall IERC20(asset).transfer(self, amount) # caller(user) -> vault (asset)

    # TODO


'''
Moves ${cdpAmount} from the vault to the user, increasing their debt.
They must never borrow more than BORROW_RATIO of their deposited collateral.
'''
@external
def borrow(cdpAmount: uint256):
    return 0 # TODO

'''
Moves ${cdpAmount} from the user to the vault, decreasing their debt.
'''
@external
def repay(cdpAmount: uint256):
    return 0 # TODO

'''
Moves ${amount} from the vaults's ${asset} account to user's ${asset} account (removing collateral).
Fails either if:
- user never deposit ${amount} of ${asset}.
- it would bring their deposited value bellow the borrowed CDP value.
On success, burns an equivalent amount of CDP from the vault.
'''
@external
def withdraw(user_address: address, asset: address, amount: uint256) -> uint256:
    assert asset.is_contract, "Asset address must be a contract"
    assert asset != empty(address), "Asset address cannot be zero"
    assert amount > 0, "Amount must be greater than 0"
    
    user_cdp: uint256 = self.cdpBorrowed[user_address]
    assert user_cdp == 0, "User has no cdp"
    
    user_collateral: uint256 = self.userCollateral[(user_address, asset)]
    assert user_collateral >= amount, "Insufficient collateral"
    

    # I don't get how is when theres two tokens in the game
    asset_price: uint256 = getPrice(asset)
    cdp_to_burn: uint256 = amount * asset_price 
    
    
    self.poolCollateral[asset] -= amount
    self.userCollateral[(user_address, asset)] -= amount
    
    # Transfer asset back to user
    assert IERC20(asset).transfer(user_address, amount)
    #Burning
    assert IERC20(self.cdpAsset).burn(cdp_to_burn), "CDP burn failed"
    
    return amount

'''
Attempts to liquidate the passed in user's deposited collateral.
Returns [] user's borrowed CDP value is under the BORROW_RATIO of their collateral.

Otherwise it moves ${user's borrowed CDP} worth of caller's CDP to the vault.
Then:
- Move ${user's borrowed CDP} worth of their collateral from vault to caller (burning caller's CDP).
- Move LIQUIDATE_RATIO of user's collateral from vault to caller.
- Move remaining of user's collateral from vault to liquidate_account.
'''

@external
def liquidate(user: address) -> DynArray[(address, uint256), MAX_POSITIONS]:
    return 0 # TODO
