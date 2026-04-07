
"""
    V_any_oneof(xs)
    V_any_oneof(x, xs...)

Return a validator that checks `x in xs`.
"""
function V_any_oneof(xs)
    s = Set(xs)
    return x -> x in s
end
V_any_oneof(x, xs...) = V_any_oneof((x, xs...))

"""
    V_any_in(xs)
    V_any_in(x, xs...)

Alias of [`V_any_oneof`](@ref).
"""
V_any_in(xs) = V_any_oneof(xs)
V_any_in(x, xs...) = V_any_oneof(x, xs...)

"""
    V_any_notin(xs)
    V_any_notin(x, xs...)
    
Return a validator that checks `x ∉ xs`.
"""
function V_any_notin(xs)
    s = Set(xs)
    return x -> !(x in s)
end
V_any_notin(x, xs...) = V_any_notin((x, xs...))

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
