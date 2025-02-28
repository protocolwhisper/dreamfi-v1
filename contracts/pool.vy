#pragma version >=0.3.0

from currency import SCALE
from current import getPrice
from snekmate import IERC20

MAX_POSITIONS: constant(uint8) = 10
BORROW_RATIO: constant(uint256) = 80 # N / 100
LIQUIDATE_RATIO: constant(uint256) = 5 # N / 100

struct User:
    collateral: HashMap[address, uint256] # asset => amount
    cdpBorrowed: uint256

cdpAsset: address
liquidateAccount: address
users: public(HashMap[address, User]) # public: user_addr => User
collateral: HashMap[address, uint256] # private: asset_addr => amount

'''
Takes in array of (AssetAddress, AssetWeight) for the pool composition.
The sum of AssetWeight must equal 100 * currency.SCALE
'''
@deploy
def __init__(
    cdp_asset: address, # the asset address of the CDP token
    liquidate_account: address, # where protocol-benefitting liquidated assets are stored.
    positions: DynArray[address, MAX_POSITIONS], # list of asset addresses for this pool
):
    pass # TODO

'''
Moves ${amount} from the user's ${asset} account to vault's ${asset} account (creating collateral).
Also mints new CDP to the vault's proportional to the asset amount value.
'''
@external
def deposit(asset: address, amount: uint256):
    return 0 # TODO

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
On success, burns an equivalent amount of CDP from the user.
'''
@external
def withdraw(asset: address, amount: uint256) -> uint256:
    return 0 # TODO

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
