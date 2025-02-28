# Vyper version 0.4.0

import rayMath

# Constants
RAY: constant(uint256) = 10**27

# 0.02 * 10**27 = 2e25
BASE_RATE: constant(uint256) = 20000000000000000000000000  # 2% base rate

# 0.04 * 10**27 = 4e25
SLOPE1: constant(uint256) = 40000000000000000000000000     # 4% slope1

# 0.6 * 10**27 = 6e26
SLOPE2: constant(uint256) = 600000000000000000000000000    # 60% slope2

# 0.8 * 10**27 = 8e26
OPTIMAL_UTILIZATION: constant(uint256) = 800000000000000000000000000  # 80% optimal utilization

# 0.1 * 10**27 = 1e26
RESERVE_FACTOR: constant(uint256) = 100000000000000000000000000   # 10% reserve factor

# Cada 15 segundos una actualizacion del interes o menos como gustes 

@internal
@view

def utilizationRate(total_borrowed:uint256 , total_liquidity:uint256) -> uint256:
    """
    Calculate the utilization Rate of the reserve

    """
    return rayMath.rayDiv(total_borrowed, total_liquidity)


@external
@view

def calculateBorrowInterest(total_borrowed: uint256, total_liquidity: uint256) -> uint256:
    """
    Calculate the borrow interest rate based on utilization.
    """
    if total_liquidity == 0:
        return 0

    utilization_rate: uint256 = self.utilizationRate(total_borrowed, total_liquidity)
    print(utilization_rate)

    if utilization_rate <= OPTIMAL_UTILIZATION:
        utilization_mistmatch: uint256 = rayMath.rayDiv(utilization_rate, OPTIMAL_UTILIZATION)
        borrow_rate: uint256 = BASE_RATE + rayMath.rayMul(utilization_mistmatch, SLOPE1)
        return borrow_rate
    else:
        over_utilization: uint256 = utilization_rate - OPTIMAL_UTILIZATION
        error_factor: uint256 = rayMath.rayDiv(over_utilization, RAY - OPTIMAL_UTILIZATION)
        borrow_rate: uint256 = BASE_RATE + SLOPE1 + rayMath.rayMul(rayMath.rayDiv(over_utilization, RAY - OPTIMAL_UTILIZATION), SLOPE2)
        return borrow_rate

@external
@view
def calculateSupplyInterest(borrowInterest: uint256, total_borrowed:uint256 , total_liquidity:uint256)-> uint256:
        utilization_rate: uint256 = self.utilizationRate(total_borrowed , total_liquidity)
        supplyInterest: uint256 = rayMath.rayMul(rayMath.rayMul(borrowInterest , utilization_rate), (RAY - RESERVE_FACTOR))
        return supplyInterest
    

