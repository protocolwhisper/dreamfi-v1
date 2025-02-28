
# Vyper version 0.4.0

#Params setted by governance
base_rate: public(uint256)
slope1: public(uint256)
slope2: public(uint256)
optimal_utilization: public(uint256)
reserve_factor: public(uint256)

#Owner of the pool 
owner: public(address)
@deploy
def __init__(
    _base_rate: uint256,
    _slope1: uint256,
    _slope2: uint256,
    _optimal_utilization: uint256,
    _reserve_factor: uint256
):
    self.base_rate = _base_rate
    self.slope1 = _slope1
    self.slope2 = _slope2
    self.reserve_factor = _reserve_factor
    self.optimal_utilization = _optimal_utilization
    self.owner = msg.sender


@external
def update_base_rate(_base_rate: uint256):
    assert msg.sender == self.owner, "Only owner can update parameters"
    self.base_rate = _base_rate

@external
def update_slope1(_slope1: uint256):
    assert msg.sender == self.owner, "Only owner can update parameters"
    self.slope1 = _slope1

@external
def update_slope2(_slope2: uint256):
    assert msg.sender == self.owner, "Only owner can update parameters"
    self.slope2 = _slope2

@external
def update_optimal_utilization(_optimal_utilization: uint256):
    assert msg.sender == self.owner, "Only owner can update parameters"
    self.optimal_utilization = _optimal_utilization

@external
def update_reserve_factor(_reserve_factor: uint256):
    assert msg.sender == self.owner, "Only owner can update parameters"
    self.reserve_factor = _reserve_factor

@external
def transfer_ownership(new_owner: address):
    assert msg.sender == self.owner, "Only owner can transfer ownership"
    assert new_owner != empty(address), "New owner cannot be zero address"
    self.owner = new_owner


