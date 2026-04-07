
"""
    V_AND(fs...)

Return a composed validator that requires all validators to pass.
"""
function V_AND(fs::Function...)
    return x -> begin
        for f in fs
            f(x) || return false
        end
        true
    end
end

"""
    V_OR(fs...)

Return a composed validator that requires at least one validator to pass.
"""
function V_OR(fs::Function...)
    return x -> begin
        for f in fs
            f(x) && return true
        end
        false
    end
end

"""
    V_NOT(f)

Return a validator that negates validator `f`.
"""
V_NOT(f::Function) = x -> !f(x)
