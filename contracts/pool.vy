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

    holder: Holder = self.holders[msg.sender]
    holder.collateral[contract] += amount
    
    # Gather the market value of the holder and pool's collateral.
    addedValue: uint256 = 0
    holderValue: uint256 = 0
    collateralValue: uint256 = 0
    for c: address in self.contracts:
        collateralPrice: uint256 = getPrice(c)
        collateralValue += collateralPrice * self.collateral[c].amount
        holderValue += collateralPrice * holder.collateral[c]
        if c == contract:
            addedValue = collateralPrice * amount

    # Update the collateral balances in the pool for total-collateral & holder-collateral.
    # TODO: transfer collat from user -> pool (yield farm)
    self.collateral[contract].amount += amount
    self.holders[msg.sender] = holder

    # Compute how many new tokens to mint (give to self:address) from the deposit.
    cdpSupply: uint256 = IERC20(self.cdp_contract).totalSupply()
    newTokens: uint256 = 0
    if cdpSupply == 0:
        newTokens = 1_000_000 # first deposit into pool mints an arbitrarily large amount of tokens
    else:
        newTokens = ((collateralValue + addedValue) * cdpSupply) // collateralValue

    # TODO cdp.mint(newTokens)
    cdpSupply += newTokens
    collateralValue += addedValue

    # Return how much more CDP the holder can now borrow (at the current collateral market price).
    maxBorrowValue: uint256 = (holderValue * BORROW_RATIO) // 100
    curBorrowValue: uint256 = holder.cdpBorrowed * (collateralValue // cdpSupply)
    if maxBorrowValue < curBorrowValue:
        return 0
    else:
        return ((maxBorrowValue - curBorrowValue) * collateralValue) // cdpSupply

@external
def withdraw(contract: address, amount: uint256) -> uint256:
    assert contract._is_contract
    assert amount > 0

    # Check holder has enough of this specific collateral to withdraw.
    holder: Holder = self.holders[msg.sender]
    assert amount <= holder.collateral[contract], "Withdrawing more collateral than deposited"

    # Gather the market value of the holder and pool collateral.
    removedValue: uint256 = 0
    holderValue: uint256 = 0
    collateralValue: uint256 = 0
    for c: address in self.contracts:
        collateralPrice: uint256 = getPrice(c)
        holderValue += collateralPrice * holder.collateral[c]
        collateralValue += collateralPrice * self.collateral[c].amount
        if c == contract:
            removedValue = collateralPrice * amount

    # "obvious" assumptions
    assert collateralValue >= holderValue
    assert holderValue >= removedValue

    # Check that withdraw wouldnt eat into borrowed-against collateral.
    cdpSupply: uint256 = IERC20(self.cdp_contract).totalSupply()
    borrowedValue: uint256 = holder.cdpBorrowed * (collateralValue // cdpSupply)
    assert (holderValue - removedValue) >= borrowdValue, "Withdrawing borrowed collateral at current price"

    # TODO: check if user's borrowedValue == maxBorrowValue (trigger liquidation)
    # TODO: move collat from pool (yield farm) to user
    self.collateral[contract].amount -= amount
    holder.collateral[contract] -= amount
    self.holders[msg.sender] = holder

    # TODO: burn appropriate tokens

'''
Creates a debt against the total collateral deposited by the caller, 
giving them cdp currency in exchange.
'''
@external
def borrow(cdp_to_borrow: uint256):
    collateralValue: uint256 = 0
    holderValue: uint256 = 0 
    for c in self.contracts:  
        collateralPrice = getPrice(c)
        collateralValue += collateralPrice * self.collateral[c].amount
        holderValue += collateralPrice * holders.collateral[c].amount

    cdp_supply: uint256 = extcall IERC20(self.cdp_contract).totalSupply()
    cdp_price: uint256 = collateralValue // cdp_supply
    total_value_borrow_attempt: uint256 = cdp_to_borrow * cdp_price 
    maximum: uint256 = (holderValue * BORROW_RATIO) // 100
    assert total_value_borrow_attempt <= maximum, "Rekt"

    # update user borrow information
    self.holders[msg.sender].cdpBorrowed += cdp_to_borrow
    # transfer cdp from vault to user 
    IERC20(self.cdp_contract).transfer(msg.sender, cdp_to_borrow)

@external
def repay():
    # reduce the borrowed amount by total repayed CDP units
    # transfer CDP to vault
    pass

'''
Externally triggered events
'''

@payable
@external
def check_users():
    # TODO: check holder liquidation limits & liquidate if so
    # TODO: trigger this in a timely matter (on price updates?)
    pass