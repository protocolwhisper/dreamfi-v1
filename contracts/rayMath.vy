# Vyper version 0.4.0

RAY: constant(uint256) = 10**27

@internal
@pure
def rayMul(a: uint256, b: uint256) -> uint256:
    """
    Multiplies two ray values, rounding half up to the nearest ray.
    :param a: First ray value
    :param b: Second ray value
    :return: Result of a * b in ray
    """
    result: uint256 = a * b + RAY // 2
    return result // RAY

@internal
@pure
def rayDiv(a: uint256, b: uint256) -> uint256:
    """
    Divides two ray values, rounding half up to the nearest ray.
    :param a: Numerator ray value
    :param b: Denominator ray value
    :return: Result of a / b in ray
    """
    assert b != 0, "Division by zero"
    result: uint256 = a * RAY + b // 2
    return result // b

@internal
@pure
def toRay(x: uint256) -> uint256:
    return x * RAY