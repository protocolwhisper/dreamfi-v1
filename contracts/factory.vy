# every pool has collateral types, collateral weights 
blueprint: public(address)
oracle: public(address)

struct CollateralType: 
    contract: address
    weight: uint256

interface Pool: 
    def initialize(collateral_info: DynArray[CollateralType, 10]): nonpayable

@deploy
def __init__(implementation_contract: address, oracle: address):
    self.blueprint = implementation_contract 
    self.oracle = oracle
    
# this also needs to deploy the CDP contract per vault  

@external
def new_pool(collateral_info: DynArray[CollateralType, 10]) -> address:
    addr: address = create_minimal_proxy_to(self.blueprint, revert_on_failure=True, value=0)
    # pools can get the oracle contract address by calling the factory
    extcall Pool(addr).initialize(collateral_info)
    return addr
