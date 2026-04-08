"""
    V_AND(xs...)

Create a composite validator that succeeds only if all child validators succeed.

Each element in `xs` is normalized through [`validator`](@ref), so the inputs may be:

- `ValidatorSpec`
- plain functions
- supported pair forms accepted by `validator`


The resulting validator name is built by joining child validator names with ` && `.

Example:

    V_AND(A, B, C)

produces a validator with name:

    "A && B && C"


The resulting message is a bullet-list summary of all non-empty child messages,
prefixed with:

    "Should satisfy all of:"
"""
function V_AND(xs...)
    specs = ValidatorSpec[validator(x) for x in xs]
    fn = x -> begin
        for s in specs
            s.fn(x) || return false
        end
        true
    end
    name = isempty(specs) ? "V_AND" : join((validator_name(s) for s in specs), " && ")
    msg = _validator_join_msgs("Should satisfy all of:", specs)
    return ValidatorSpec(name, msg, fn)
end

"""
    V_OR(xs...)

Create a composite validator that succeeds if at least one child validator succeeds.

Each element in `xs` is normalized through [`validator`](@ref).


The resulting validator name is built by joining child validator names with ` || `.

Example:

    V_OR(A, B, C)

produces a validator with name:

    "A || B || C"


The resulting message is a bullet-list summary of all non-empty child messages,
prefixed with:

    "Should satisfy at least one of:"
"""
function V_OR(xs...)
    specs = ValidatorSpec[validator(x) for x in xs]
    fn = x -> begin
        for s in specs
            s.fn(x) && return true
        end
        false
    end
    name = isempty(specs) ? "V_OR" : join((validator_name(s) for s in specs), " || ")
    msg = _validator_join_msgs("Should satisfy at least one of:", specs)
    return ValidatorSpec(name, msg, fn)
end

"""
    V_NOT(x)

Create a composite validator that negates a child validator.

The input is normalized through [`validator`](@ref).


If the child validator name is non-empty, the resulting name is:

    "!(" * child_name * ")"

Otherwise the fallback name is `"V_NOT"`.


If the child validator has a non-empty message, the resulting message is:

    "Should not satisfy:\n- " * child_message

Otherwise the message is empty.
"""
function V_NOT(x)
    s = validator(x)
    fn = y -> !s.fn(y)
    child_name = strip(validator_name(s))
    name = isempty(child_name) ? "V_NOT" : "!(" * child_name * ")"
    msg = isempty(strip(s.msg)) ? "" : "Should not satisfy:\n- " * strip(s.msg)
    return ValidatorSpec(name, msg, fn)
end
