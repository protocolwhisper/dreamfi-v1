#pragma version >=0.4.0

import currency
import pool
import IERC20

TOKEN_BLUEPRINT: immutable(address)
POOL_BLUEPRINT: immutable(address)
admin: public(address)

@deploy
def __init__(liquidate_beneficiary: address, pool_blueprint: address, token_blueprint: address):
    assert liquidate_beneficiary != empty(address)
    self.liquidate_beneficiary = liquidate_beneficiary
    TOKEN_BLUEPRINT = token_blueprint
    POOL_BLUEPRINT = pool_blueprint

event NewPool:
    pool_contract: address
    cdp_contract: address
    
# this also needs to deploy the CDP contract per vault  
@external
def new_pool(collateral_assets: DynArray[address, pool.MAX_POSITIONS], name: String[25], symbol: String[5]) -> (address, address):
    domain_712: String[50] = "Dream Finance"
    version_712: String[25] = "1"

    cdp_addr: address = create_from_blueprint(TOKEN_BLUEPRINT, name, symbol, currency.DECIMALS, domain_712, version_712)
    pool_addr: address = create_from_blueprint(POOL_BLUEPRINT, cdp_addr, self.liquidate_beneficiary, collateral_assets)
    extcall IERC20(cdp_addr).set_minter(pool_addr, True)

    log NewPool(pool_addr, cdp_addr)
    return (pool_addr, cdp_addr)
