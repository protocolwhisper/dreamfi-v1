from ethereum.ercs import IERC20

pool_blueprint: public(address)
token_blueprint: public(address)

struct CollateralType: 
    contract: IERC20
    weight: uint256
    percent_of_vault: uint8
    decimals: uint8

@deploy
def __init__(implementation_contract: address, token_contract: address, oracle: address):
    self.pool_blueprint = implementation_contract 
    self.token_blueprint = token_contract
    self.oracle = oracle
    
# this also needs to deploy the CDP contract per vault  
@external
def new_pool(collateral_info: DynArray[CollateralType, 10], name: String[25], symbol: String[5]) -> (address, address):
    domain_712: String[50] = "Dream Finance"
    version_712: String[25] = "1"
    decimals: uint8 = 18
    cdp_addr: address = create_from_blueprint(self.token_blueprint, name, symbol, decimals, domain_712, version_712)
    pool_addr: address = create_from_blueprint(self.pool_blueprint, collateral_info, cdp_addr, revert_on_failure=True, value=0)
    return (pool_addr, cdp_addr)
