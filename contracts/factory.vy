#pragma version >=0.3.0

from pool import MAX_POSITIONS

token_blueprint: immutable(address)
pool_blueprint: immutable(address)
oracle: immutable(address)

@deploy
def __init__(pool_contract: address, token_contract: address, oracle: address):
    self.pool_blueprint = pool_contract 
    self.token_blueprint = token_contract
    self.oracle = oracle
    
# this also needs to deploy the CDP contract per vault  
@external
def new_pool(collateral_assets: DynArray[address, MAX_POSITIONS], name: String[25], symbol: String[5]) -> (address, address):
    domain_712: String[50] = "Dream Finance"
    version_712: String[25] = "1"
    decimals: uint8 = 18
    cdp_addr: address = create_from_blueprint(self.token_blueprint, name, symbol, decimals, domain_712, version_712)
    pool_addr: address = create_from_blueprint(self.pool_blueprint, collateral_assets, cdp_addr, revert_on_failure=True, value=0)
    return (pool_addr, cdp_addr)
