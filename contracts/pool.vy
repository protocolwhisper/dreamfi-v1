# @version ^0.3.3

import oracle
from ethereum.ercs import IERC20

MAX_POSITIONS: constant(uint8) = 10

struct CollateralPosition: 
    contract: address
    weight: uint256 # ratio of collateral to maintain the pool.
    amount: uint256 # seeded on init (usually 0), updated via pool funcs.

struct HolderPosition:
    collateral: HashMap[address, uint256]
    total_value: uint256
    total_cdp_borrowed: uint256

holders: HashMap[address, HolderPosition]
collateral: DynArray[CollateralPosition, MAX_POSITIONS]

@deploy
def __init__(
    collateral_borrow_max: uint256, # ratio of borrowable deposits
    collateral_composition: DynArray[CollateralPosition, MAX_POSITIONS],
):
    pass

'''
Helper Functions
'''

@internal
@view
def totalCollateral() -> uint256:
    col_sum: uint256 = 0
    for col_pos: CollateralPosition in self.collateral:
        col_price: uint256 = oracle.getPrice(col_pos.contract)
        col_sum += col_price * col_pos.amount
    return col_sum


@internal
@view
def cdpPrice() -> uint256:
    supply: uint256 = extcall IERC20(self).totalSupply()
    return self.totalCollateral() / supply



# Deposits amounts of each token contract from the user into the pool's CDP.
# Returns number of tokens minted for the user
@payable
@external
def deposit(positions: DynArray[(address, uint256), MAX_POSITIONS]) -> uint256:
    pass

@external
def withdraw(positions: DynArray[(address, uint256), MAX_POSITIONS]):
    pass

@external
def borrow():
    pass

@external
def repay():
    pass

'''
Externally triggered events
'''

@external
def liquidate():
    pass

@external
def accumulate_interest_on_accounts():
    pass
