#pragma version >=0.3.0

# https://github.com/smartcontractkit/apeworx-starter-kit/blob/main/ape-config.yaml
AGGREGATOR_ADDRESS: constant(address) = 0x694AA1769357215DE4FAC081bf1f309aDC325306

# https://github.com/smartcontractkit/apeworx-starter-kit/blob/main/contracts/interfaces/AggregatorV3Interface.vy#L34-L40
interface AggregatorV3Interface:
    def decimals() -> uint8: view
    def description() -> String[256]: view
    def getRoundData(roundId: uint80) -> (uint80, int256, uint256, uint256, uint80): view
    def latestRoundData() -> (uint80, int256, uint256, uint256, uint80): view
    def version() -> uint256: view

DECIMALS: constant(uint256) = 18
SCALE: constant(uint256) = 10 ** DECIMALS

# https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1
@external
@view
def getPrice(contract: address) -> uint256:
    feed: AggregatorV3Interface = AggregatorV3Interface(contract)
    
    # Get the price from ChainLink
    roundId: uint80 = 0
    price: int256 = 0
    startedAt: uint256 = 0
    updatedAt: uint256 = 0
    answeredInRound_Deprecated: uint80 = 0
    (roundId, price, startedAt, updatedAt, answeredInRound_Deprecated) = staticcall(feed.latestRoundData())
    # Convert price to unit by adjusting decimal
    priceDecimals: uint256 = convert(staticcall(feed.decimals()), uint256)
    if priceDecimals > DECIMALS:
        return convert(price, uint256) // 10 ** (priceDecimals - DECIMALS)
    else:
        return convert(price, uint256) * 10 ** (DECIMALS - priceDecimals)
