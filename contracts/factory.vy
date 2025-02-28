#pragma version >=0.4.0

import pool as Pool
from pool import MAX_POSITIONS
from currency import DECIMALS

token_blueprint: immutable(address)
pool_blueprint: immutable(address)
admin: address

@deploy
def __init__(admin: address, pool_blueprint: address, token_blueprint: address):
    assert admin != empty(address)

    self.admin = admin
    self.pool_blueprint = pool_blueprint
    self.token_blueprint = token_blueprint

event NewPool:
    pool_contract: uint256
    cdp_contract: uint256
    
# this also needs to deploy the CDP contract per vault  
@external
def new_pool(collateral_assets: DynArray[address, MAX_POSITIONS], name: String[25], symbol: String[5]) -> (address, address):
    assert self.admin == msg.sender, "Only the admin of the factor can create pools"
    
    domain_712: String[50] = "Dream Finance"
    version_712: String[25] = "1"
    decimals: uint8 = DECIMALS
    liquidate_beneficiary: address = self.admin

    cdp_addr: address = create_from_blueprint(self.token_blueprint, name, symbol, decimals, domain_712, version_712)
    pool_addr: address = create_from_blueprint(self.pool_blueprint, cdp_addr, liquidate_beneficiary, collateral_assets, revert_on_failure=True, value=0)
    
    log NewPool(pool_addr, cdp_addr)
    return (pool_addr, cdp_addr)