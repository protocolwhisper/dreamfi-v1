# @version ^0.3.3

import oracle
from snekmate import IERC20
from currency import SCALE, Fund, getPrice

MAX_POSITIONS: constant(uint8) = 10
BORROW_RATIO: constant(uint256) = 80 # N / 100

struct CollateralPosition:
    contract: address
    weight: uint256 # ratio of collateral to maintain the vault.

struct Collateral:
    amount: uint256
    weight: uint256 # ratio of collateral to maintain in the pool

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

'''
Deposits amounts of each token contract from the user into the pool's CDP.
Returns number of tokens minted for the user.
'''
@payable
@external
def deposit(contract: address, amount: uint256) -> uint256:
    assert contract._is_contract
    assert amount > 0

    # Update the holder's collateral amount.
    holder = self.holders[msg.sender]
    holder.collateral[contract] += fund.amount
    self.holders[msg.sender] = holder
    
    oldTotal: uint256 = 0
    addedValue: uint256 = 0
    holderValue: uint256 = 0

    # Iterate all assets and compute their price in SCALE units.
    # Accumulating the total price of all assets as well as the total price of the holder's assets.
    for addr: address in self.contracts:
        collateralPrice = getPrice(addr)
        oldTotal += collateralPrice * self.collateral[addr].amount
        holderValue += collateralPrice * holder.collateral[addr]

        if addr == amount:
            addedValue = collateralPrice * amount
            self.collateral[addr].amount += amount

    # Compute how many new tokens to mint (give to self:address) given the deposit.
    cdp: IERC20 = IERC20(self.cdp_contract)
    cdpSupply: uint256 = cdp.totalSupply()
    newTotal: uint256 = oldTotal + addedValue
    newTokens: uint256 = (newTotal * cdpSupply) / oldTotal

    # TODO cdp.mint(newTokens)
    cdpSupply += newTokens
    cdpPrice = newTotal / cdpSupply

    # Return the new amount of cdp tokens that the caller can now borrow.
    maxBorrowValue: uint256 = (holderValue * BORROW_RATIO) / 100
    curBorrowValue: uint256 = holder.cdpBorrowed * cdpPrice
    cdpBorrowMax: uint256 = ((maxBorrowValue - curBorrowValue) * newTotal) / cdpSupply
    return cdpBorrowMax

@external
def withdraw(fund: Fund) -> uint256:
    # TODO
    return 0

'''
Creates a debt against the total collateral deposited by the caller, 
giving them cdp currency in exchange.
'''
def borrow(units_borrowed: uint256):
    collateralValue: uint256 = 0
    holderValue: uint256 = 0 
    for c in self.contracts:  
        collateralPrice = getPrice(c)
        collateralValue += collateralPrice * self.collateral[c].amount
        holderValue += collateralPrice * holders.collateral[addr].amount

     price: uint256 = collateralValue / IERC20(cdp_contract).totalSupply()

     total_value_borrow_attempt: uint256 = units_borrowed * price 
     maximum: uint256 = holderValue * BORROW_RATIO/100
     assert total_value_borrow_attempt <= maximum, "Rekt"
     # update user borrow information
     self.holders[msg.sender].cdpBorrowed += units_borrowed
     # transfer cdp from vault to user 
     IERC20(self.cdp_contract).transfer(msg.sender, units_borrowed)

@external
def repay():
    # reduce the borrowed amount by total repayed CDP units
    # transfer CDP to vault
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
