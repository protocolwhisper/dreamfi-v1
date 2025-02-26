# Chainlink interface
from ethereum.ercs import IERC20

struct CollateralType: 
    contract: IERC20
    weight: uint256
    percent_of_vault: uint8
    decimals: uint8

struct PositionInfo: 
    deposits: DynArray[(CollateralType, uint256), 10]
    borrowed_cdp_units: uint256  

positions: public(HashMap[address, PositionInfo])
pool_collateral_info: public(DynArray[CollateralType, 10])

interface AggregatorV3Interface:
    def decimals() -> uint8: view
    def description() -> String[256]: view
    def getRoundData() -> (uint80, int256, uint256, uint256, uint80): view
    def latestRoundData() -> (uint80, int256, uint256, uint256, uint80): view
    def version() -> uint256: view

# deposit 
# withdraw 
# borrow 
# repay 
# liquidate

    

