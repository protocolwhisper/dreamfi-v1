#pragma version >=0.4.0

startedAt: uint256
name: String[256]
numDecimals: uint8
curPrice: int256

@deploy
def __init__(name: String[256], numDecimals: uint8, curPrice: int256):
    self.startedAt = block.timestamp
    self.name = name
    self.numDecimals = numDecimals
    self.curPrice = curPrice

@external
def setPrice(new_price: int256, new_decimals: uint8):
    self.numDecimals = new_decimals
    self.curPrice = new_price

@view
@external
def decimals() -> uint8:
    return self.numDecimals

@view
@external
def description() -> String[256]:
    return self.name

@view
@external
def getRoundData(roundId: uint80) -> (uint80, int256, uint256, uint256, uint80):
    return (0, self.curPrice, self.startedAt, self.startedAt, 0)

@view
@external
def latestRoundData() -> (uint80, int256, uint256, uint256, uint80):
    return (0, self.curPrice, self.startedAt, self.startedAt, 0)

@view
@external
def version() -> uint256:
    return 0