"""
    V_num_min(minv)

Return a validator that checks `x >= minv`.
"""
V_num_min(minv) = x -> x >= minv

"""
    V_num_max(maxv)

Return a validator that checks `x <= maxv`.
"""
V_num_max(maxv) = x -> x <= maxv

"""
    V_num_range(lo, hi; closed=true)

Return a validator for numeric range checks.

- `closed=true`: `lo <= x <= hi`
- `closed=false`: `lo < x < hi`
"""
V_num_range(lo, hi; closed::Bool=true) = closed ? (x -> lo <= x <= hi) : (x -> lo < x < hi)

"""
    V_num_positive()

Return a validator that checks `x > 0`.
"""
V_num_positive() = x -> x > 0

"""
    V_num_nonnegative()

Return a validator that checks `x >= 0`.
"""
V_num_nonnegative() = x -> x >= 0

"""
    V_num_negative()

Return a validator that checks `x < 0`.
"""
V_num_negative() = x -> x < 0

"""
    V_num_nonpositive()

Return a validator that checks `x <= 0`.
"""
V_num_nonpositive() = x -> x <= 0

"""
    V_num_nonzero()

Return a validator that checks `x != 0`.
"""
V_num_nonzero() = x -> x != 0

"""
    V_num_finite()

Return a validator that checks whether `x` is finite.

For non-number values, returns `false`.
"""
V_num_finite() = x -> x isa Number && isfinite(x)

"""
    V_num_notnan()

Return a validator that checks whether `x` is not NaN.

For non-number values, returns `false`.
"""
V_num_notnan() = x -> x isa Number && !isnan(x)

"""
    V_num_real()

Return a validator that checks whether `x` is a real number.

Complex values return `false`.
"""
V_num_real() = x -> x isa Real

"""
    V_num_int()

Return a validator that checks whether `x` is an integer value.

Works for integer types and numeric values like `3.0`.
"""
V_num_int() = x -> x isa Integer || (x isa Number && isinteger(x))

"""
    V_num_integer()

Compatibility alias of [`V_num_int`](@ref).
"""
V_num_integer() = V_num_int()

"""
    V_num_float()

Return a validator that checks whether `x` is an `AbstractFloat`.
"""
V_num_float() = x -> x isa AbstractFloat

"""
    V_num_percentage()

Alias of `V_num_range(0, 100; closed=true)`.
"""
V_num_percentage() = V_num_range(0, 100; closed=true)

"""
    V_num_gt(v)

Alias of strict greater-than check `x > v`.
"""
V_num_gt(v) = x -> x > v

"""
    V_num_ge(v)

Alias of greater-or-equal check `x >= v`.
"""
V_num_ge(v) = x -> x >= v

"""
    V_num_lt(v)

Alias of strict less-than check `x < v`.
"""
V_num_lt(v) = x -> x < v

"""
    V_num_le(v)

Alias of less-or-equal check `x <= v`.
"""
V_num_le(v) = x -> x <= v

"""
    V_any_oneof(xs)

Return a validator that checks `x in xs`.
"""
function V_any_oneof(xs)
    s = Set(xs)
    return x -> x in s
end

"""
    V_any_in(xs)

Alias of [`V_any_oneof`](@ref).
"""
V_any_in(xs) = V_any_oneof(xs)

"""
    V_any_notin(xs)

Return a validator that checks `x ∉ xs`.
"""
function V_any_notin(xs)
    s = Set(xs)
    return x -> !(x in s)
end

"""
    V_any_equal(v)

Return a validator that checks `x == v`.
"""
V_any_equal(v) = x -> x == v

"""
    V_any_notequal(v)

Return a validator that checks `x != v`.
"""
V_any_notequal(v) = x -> x != v
