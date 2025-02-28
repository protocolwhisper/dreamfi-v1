# @version ^0.4.0

import utils as utils  # Correct relative import statement

# Structs
struct CalculateInterestRatesParams:
    unbacked: uint256
    liquidityAdded: uint256
    liquidityTaken: uint256
    totalDebt: uint256
    reserveFactor: uint256
    reserve: address
    usingVirtualBalance: bool
    virtualUnderlyingBalance: uint256

struct InterestRateDataRay:
    baseVariableBorrowRate: uint256
    optimalUsageRatio: uint256
    variableRateSlope1: uint256
    variableRateSlope2: uint256

# Mapping for reserve interest rate data.
_interestRateData: public(HashMap[address, InterestRateDataRay])

@external
@view
def calculateInterestRates(params: CalculateInterestRatesParams) -> (uint256, uint256):
    """
    Calculates the current liquidity rate and variable borrow rate.
    """
    # Retrieve the rate data for this reserve.
    rateData: InterestRateDataRay = self._interestRateData[params.reserve]

    # If the reserve does not use a virtual balance, return a liquidity rate of 0
    # and the base variable borrow rate.
    if not params.usingVirtualBalance:
        return (0, rateData.baseVariableBorrowRate)

    currentLiquidityRate: uint256 = 0
    currentVariableBorrowRate: uint256 = rateData.baseVariableBorrowRate

    # If there's no outstanding debt, exit early.
    if params.totalDebt == 0:
        return (0, currentVariableBorrowRate)

    # Compute available liquidity as the virtual underlying balance plus liquidity added minus liquidity taken.
    availableLiquidity: uint256 = params.virtualUnderlyingBalance + params.liquidityAdded - params.liquidityTaken
    availableLiquidityPlusDebt: uint256 = availableLiquidity + params.totalDebt

    # Calculate the borrow and supply usage ratios in ray units.
    borrowUsageRatio: uint256 = utils.rayDiv(params.totalDebt, availableLiquidityPlusDebt)  # Use utils.rayDiv
    supplyUsageRatio: uint256 = utils.rayDiv(params.totalDebt, availableLiquidityPlusDebt + params.unbacked)

    # Adjust the variable borrow rate according to a two-slope model.
    if borrowUsageRatio > rateData.optimalUsageRatio:
        excessBorrowUsageRatio: uint256 = utils.rayDiv(
            borrowUsageRatio - rateData.optimalUsageRatio,
            utils.RAY - rateData.optimalUsageRatio
        )
        currentVariableBorrowRate += rateData.variableRateSlope1 + utils.rayMul(rateData.variableRateSlope2, excessBorrowUsageRatio)
    else:
        currentVariableBorrowRate += utils.rayDiv(
            utils.rayMul(rateData.variableRateSlope1, borrowUsageRatio),
            rateData.optimalUsageRatio
        )

    # The liquidity rate is derived from the variable borrow rate,
    # scaled by the supply usage ratio and reduced by the reserve factor.
    currentLiquidityRate = utils.percentMul(
        utils.rayMul(currentVariableBorrowRate, supplyUsageRatio),
        utils.PERCENTAGE_FACTOR - params.reserveFactor
    )

    return (currentLiquidityRate, currentVariableBorrowRate)

@external
@view
def utilizationRate(cash: uint256, borrow:uint256, reserve: uint256) -> uint256:
    uRate: uint256 = utils.rayDiv(Borrowed, totalDeposits)  # Use utils.rayDiv
    return uRate


@external
def getSupplyRate(cash: uint256, borrows:uint256 , reserves:uint256 , reserveFactor: uint256) -> uint256:

    

    
