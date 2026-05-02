"""
    V_any_oneof(xs)
    V_any_oneof(x, xs...)

Return a ValidatorSpec that checks `x in xs`.
"""
function V_any_oneof(xs)
    vals = collect(xs)
    s = Set(vals)
    msg = "Should be one of: " * repr(vals)
    return ValidatorSpec("V_any_oneof", msg, x -> x in s)
end

V_any_oneof(x, xs...) = V_any_oneof((x, xs...))

"""
    V_any_in(xs)
    V_any_in(x, xs...)

Return a ValidatorSpec that checks `x in xs`.
Alias of [`V_any_oneof`](@ref).
"""
V_any_in(xs) = ValidatorSpec("V_any_in", validator_message(V_any_oneof(xs)), validator_fn(V_any_oneof(xs)))
V_any_in(x, xs...) = V_any_in((x, xs...))

"""
    V_any_notin(xs)
    V_any_notin(x, xs...)
    
Return a ValidatorSpec that checks `x ∉ xs`.
"""
function V_any_notin(xs)
    vals = collect(xs)
    s = Set(vals)
    msg = "Should not be one of: " * repr(vals)
    return ValidatorSpec("V_any_notin", msg, x -> !(x in s))
end

V_any_notin(x, xs...) = V_any_notin((x, xs...))

"""
    V_any_equal(v)

Return a ValidatorSpec that checks `x == v`.
"""
V_any_equal(v) = ValidatorSpec("V_any_equal", "Should equal: " * repr(v), x -> x == v)

"""
    V_any_notequal(v)

Return a ValidatorSpec that checks `x != v`.
"""
V_any_notequal(v) = ValidatorSpec("V_any_notequal", "Should not equal: " * repr(v), x -> x != v)
