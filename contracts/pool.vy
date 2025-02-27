# @version ^0.3.3

import oracle
from snekmate import IERC20
from currency import SCALE, Fund, getPrice

MAX_POSITIONS: constant(uint8) = 10
BORROW_RATIO: constant(uint256) = 80 # N / 100

struct CollateralPosition:
    contract: address
    weight: uint256 # ratio of collateral to maintain the pool.

struct Collateral:
    amount: uint256
    weight: uint256 # ratio of collateral to maintain in the pool.

struct Holder:
    collateral: HashMap[address, uint256]
    cdpBorrowed: uint256

cdp_contract: address # the CDP token addr
holders: HashMap[address, Holder] # maps user -> UserPosition
collateral: HashMap[address, Collateral] # maps contract -> Balance + Weight
contracts: DynArray[address, MAX_POSITIONS] # list of contracts

@deploy
def __init__(cdp_contract: address, positions: DynArray[CollateralPosition, MAX_POSITIONS]):
    assert cdp_contract._is_contract

    # Accumulate the weight to check + populate the contracts/collateral state
    weightSum: uint256 = 0
    for pos: CollateralPosition in positions:
        assert pos.contract._is_contract
        weightSum += pos.weight
        self.contracts.append(pos.contract)
        self.collateral[pos.contract] = Collateral(amount=0, weight=pos.weight)

    assert weightSum == 100 ** SCALE, "Pool position weights do not sum to 100 units"
    self.cdp_contract = cdp_contract

# Deposits amounts of each token contract from the user into the pool's CDP.
# Returns number of tokens minted for the user
@payable
@external
def deposit(fund: Fund) -> uint256:
    assert fund.contract._is_contract
    assert fund.amount > 0

    holder = self.holders[msg.sender]
    holder.collateral[fund.address] += fund.amount
    self.holders[msg.sender] = holder
    
    oldTotal: uint256 = 0
    addedValue: uint256 = 0
    holderValue: uint256 = 0

    for addr: address in self.contracts:
        collateral: Collateral = self.collateral[addr]
        collateralPrice = getPrice(addr)

        oldTotal += collateralPrice * collateral.amount
        holderValue += collateralPrice * holder.collateral[addr]

        if addr == fund.address:
            addedValue = collateralPrice * fund.amount
            self.collateral[addr] = collateral.amount + fund.amount

    cdp: IERC20 = IERC20(self.cdp_contract)
    cdpSupply: uint256 = cdp.totalSupply()
    newTotal: uint256 = oldTotal + addedValue
    newTokens: uint256 = (newTotal * cdpSupply) / oldTotal

    # TODO cdp.mint(newTokens)
    cdpSupply += newTokens

    # Return the amount of newly minted tokens that the holder can now borrow
    maxBorrowValue: uint256 = (holderValue * BORROW_RATIO) / 100
    maxBorrowCdp: uint256 = (maxBorrowValue * cdpSupply) / newTotal
    assert maxBorrowCdp >= holder.cdpBorrowed
    return maxBorrowCdp - holder.cdpBorrowed

@external
def withdraw(fund: Fund):
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

'''
Helper Functions
'''

@internal
@view
def totalCollateral() -> uint256:
    total: uint256 = 0
    for pos: CollateralPosition in self.collateral:
        price: uint256 = oracle.getPrice(pos.contract)
        total += prime * pos.amount
    return total

@internal
@view
def cdpPrice() -> uint256:
    supply: uint256 = extcall IERC20(self).totalSupply()
    return self.totalCollateral() / supply