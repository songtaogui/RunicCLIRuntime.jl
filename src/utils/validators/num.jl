"""
    V_num_min(minv)

Return a ValidatorSpec that checks `x >= minv`.
"""
V_num_min(minv) = ValidatorSpec("V_num_min", "Should be >= " * repr(minv), x -> x >= minv)

"""
    V_num_max(maxv)

Return a ValidatorSpec that checks `x <= maxv`.
"""
V_num_max(maxv) = ValidatorSpec("V_num_max", "Should be <= " * repr(maxv), x -> x <= maxv)

"""
    V_num_range(lo, hi; closed=true)

Return a ValidatorSpec for numeric range checks.

- `closed=true`: `lo <= x <= hi`
- `closed=false`: `lo < x < hi`
"""
V_num_range(lo, hi; closed::Bool=true) = closed ?
    ValidatorSpec("V_num_range", "Should be in range [" * repr(lo) * ", " * repr(hi) * "]", x -> lo <= x <= hi) :
    ValidatorSpec("V_num_range", "Should be in range (" * repr(lo) * ", " * repr(hi) * ")", x -> lo < x < hi)

"""
    V_num_positive()

Return a ValidatorSpec that checks `x > 0`.
"""
V_num_positive() = ValidatorSpec("V_num_positive", "Should be positive", x -> x > 0)

"""
    V_num_nonnegative()

Return a ValidatorSpec that checks `x >= 0`.
"""
V_num_nonnegative() = ValidatorSpec("V_num_nonnegative", "Should be non-negative", x -> x >= 0)

"""
    V_num_negative()

Return a ValidatorSpec that checks `x < 0`.
"""
V_num_negative() = ValidatorSpec("V_num_negative", "Should be negative", x -> x < 0)

"""
    V_num_nonpositive()

Return a ValidatorSpec that checks `x <= 0`.
"""
V_num_nonpositive() = ValidatorSpec("V_num_nonpositive", "Should be non-positive", x -> x <= 0)

"""
    V_num_nonzero()

Return a ValidatorSpec that checks `x != 0`.
"""
V_num_nonzero() = ValidatorSpec("V_num_nonzero", "Should be non-zero", x -> x != 0)

"""
    V_num_finite()

Return a ValidatorSpec that checks whether `x` is finite.

For non-number values, returns `false`.
"""
V_num_finite() = ValidatorSpec("V_num_finite", "Should be finite", x -> x isa Number && isfinite(x))

"""
    V_num_notnan()

Return a ValidatorSpec that checks whether `x` is not NaN.

For non-number values, returns `false`.
"""
V_num_notnan() = ValidatorSpec("V_num_notnan", "Should not be NaN", x -> x isa Number && !isnan(x))

"""
    V_num_real()

Return a ValidatorSpec that checks whether `x` is a real number.

Complex values return `false`.
"""
V_num_real() = ValidatorSpec("V_num_real", "Should be a real number", x -> x isa Real)

"""
    V_num_int()

Return a ValidatorSpec that checks whether `x` is an integer value.

Works for integer types and numeric values like `3.0`.
"""
V_num_int() = ValidatorSpec("V_num_int", "Should be an integer", x -> x isa Integer || (x isa Number && isinteger(x)))

"""
    V_num_integer()

Return a ValidatorSpec that checks whether `x` is an integer value.

Works for integer types and numeric values like `3.0`.

Compatibility alias of [`V_num_int`](@ref).
"""
function V_num_integer()
    v = V_num_int()
    return ValidatorSpec("V_num_integer", validator_message(v), validator_fn(v))
end

"""
    V_num_float()

Return a ValidatorSpec that checks whether `x` is an `AbstractFloat`.
"""
V_num_float() = ValidatorSpec("V_num_float", "Should be a floating-point number", x -> x isa AbstractFloat)

"""
    V_num_percentage()

Alias of `V_num_range(0, 100; closed=true)`.
"""
V_num_percentage() = ValidatorSpec("V_num_percentage", "Should be in range [0, 100]", x -> 0 <= x <= 100)

"""
    V_num_gt(v)

Alias of strict greater-than check `x > v`.
"""
V_num_gt(v) = ValidatorSpec("V_num_gt", "Should be > " * repr(v), x -> x > v)

"""
    V_num_ge(v)

Alias of greater-or-equal check `x >= v`.
"""
V_num_ge(v) = ValidatorSpec("V_num_ge", "Should be >= " * repr(v), x -> x >= v)

"""
    V_num_lt(v)

Alias of strict less-than check `x < v`.
"""
V_num_lt(v) = ValidatorSpec("V_num_lt", "Should be < " * repr(v), x -> x < v)

"""
    V_num_le(v)

Alias of less-or-equal check `x <= v`.
"""
V_num_le(v) = ValidatorSpec("V_num_le", "Should be <= " * repr(v), x -> x <= v)
