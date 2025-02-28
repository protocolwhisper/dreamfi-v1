#pragma version >=0.4.0



MAX_POSITIONS: public(constant(uint8)) = 10
DECIMALS: public(constant(uint8)) = 18

TOKEN_BLUEPRINT: immutable(address)
POOL_BLUEPRINT: immutable(address)
admin: address

@deploy
def __init__(admin: address, pool_blueprint: address, token_blueprint: address):
    assert admin != empty(address)

    self.admin = admin
    POOL_BLUEPRINT = pool_blueprint
    TOKEN_BLUEPRINT = token_blueprint

event NewPool:
    pool_contract: address
    cdp_contract: address
    
# this also needs to deploy the CDP contract per vault  
@external
def new_pool(collateral_assets: DynArray[address, MAX_POSITIONS], name: String[25], symbol: String[5]) -> (address, address):
    assert self.admin == msg.sender, "Only the admin of the factor can create pools"
    domain_712: String[50] = "Dream Finance"
    version_712: String[25] = "1"
    liquidate_beneficiary: address = self.admin
    cdp_addr: address = create_from_blueprint(TOKEN_BLUEPRINT, name, symbol, DECIMALS, domain_712, version_712)
    pool_addr: address = create_from_blueprint(POOL_BLUEPRINT, cdp_addr, liquidate_beneficiary, collateral_assets, revert_on_failure=True, value=0)
    log NewPool(pool_addr, cdp_addr)
    return (pool_addr, cdp_addr)
