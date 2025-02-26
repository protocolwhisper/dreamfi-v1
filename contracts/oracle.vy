# @version ^0.3.3
# Chainlink wrapper

# https://github.com/smartcontractkit/apeworx-starter-kit/blob/main/ape-config.yaml
AGGREGATOR_ADDRESS: constant(address) = 0x694AA1769357215DE4FAC081bf1f309aDC325306

# https://github.com/smartcontractkit/apeworx-starter-kit/blob/main/contracts/interfaces/AggregatorV3Interface.vy#L34-L40
interface AggregatorV3Interface:
    def decimals() -> uint8: view
    def description() -> String[256]: view
    def getRoundData(roundId: uint80) -> (uint80, int256, uint256, uint256, uint80): view
    def latestRoundData() -> (uint80, int256, uint256, uint256, uint80): view
    def version() -> uint256: view

# https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1
@external
@view
def getPrice(contract: address) -> int256:
    feed: AggregatorV3Interface = AggregatorV3Interface(contract)

    roundId: uint80 = 0
    answer: int256 = 0
    startedAt: uint256 = 0
    updatedAt: uint256 = 0
    answeredInRound_Deprecated: uint80 = 0
    (roundId, answer, startedAt, updatedAt, answeredInRound_Deprecated) = extcall feed.latestRoundData()
    
    # TODO: use feed.decimals() to convert answer to fixed unit.
    return answer