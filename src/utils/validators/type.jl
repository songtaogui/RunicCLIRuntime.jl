"""
    ValidatorSpec{F}

A validator descriptor that stores:

- `name`: a short validator name, typically the validator constructor name
- `msg`: a human-readable validation message
- `fn`: the predicate function used to validate a value

A `ValidatorSpec` is the canonical validator representation used across the
validation helpers in this package.


Fields:
- `name::String`
- `msg::String`
- `fn::F`

Notes:
- `fn(x)` should return `true` when validation succeeds and `false` otherwise.
- `name` is intended for machine-friendly or structural reporting.
- `msg` is intended for user-facing error descriptions.
"""
Base.@kwdef struct ValidatorSpec{F}
    name::String
    msg::String = ""
    fn::F
end

"""
    ValidatorSpec(name, msg, fn)

Construct a `ValidatorSpec` from a validator name, a validation message,
and a predicate function.

This is the only supported positional constructor.

Equivalent to:

    ValidatorSpec(name=name, msg=msg, fn=fn)
"""
ValidatorSpec(name::AbstractString, msg::AbstractString, fn::F) where {F} =
    ValidatorSpec{F}(name=String(name), msg=String(msg), fn=fn)

"""
    validator(v::ValidatorSpec)

Return `v` unchanged.

This is the identity overload for already constructed validator specs.
"""
validator(v::ValidatorSpec) = v

"""
    validator(f::Function)

Wrap a plain function as a `ValidatorSpec`.

The resulting validator uses:

- `name = validator_name(f)`
- `msg = ""`

This is primarily intended for interoperability with ad-hoc lambda validators.
"""
validator(f::Function) = ValidatorSpec(name=validator_name(f), fn=f)

"""
    validator(p::Pair{<:AbstractString,<:Function})

Wrap a `(message => function)` pair as a `ValidatorSpec`.

The resulting validator uses:

- `name = validator_name(function)`
- `msg = message`
"""
validator(p::Pair{<:AbstractString,<:Function}) =
    ValidatorSpec(name=validator_name(last(p)), msg=String(first(p)), fn=last(p))

"""
    validator(p::Pair{<:AbstractString,Pair{<:AbstractString,<:Function}})

Wrap a nested pair as a `ValidatorSpec`.

Expected structure:

    name => (message => function)

The resulting validator uses:

- `name = first(p)`
- `msg = first(last(p))`
- `fn = last(last(p))`
"""
validator(p::Pair{<:AbstractString,Pair{<:AbstractString,<:Function}}) =
    ValidatorSpec(name=String(first(p)), msg=String(first(last(p))), fn=last(last(p)))

"""
    validator_fn(v::ValidatorSpec)

Return the predicate function stored in `v`.
"""
validator_fn(v::ValidatorSpec) = v.fn

"""
    validator_message(v::ValidatorSpec)

Return the human-readable validation message stored in `v`.
"""
validator_message(v::ValidatorSpec) = v.msg

"""
    validator_name(v::ValidatorSpec)

Return the validator name stored in `v`.
"""
validator_name(v::ValidatorSpec) = v.name

"""
    validator_name(f)

Try to derive a readable validator name from a function object.

Behavior:

- if `nameof(f)` is available, return it as a string
- otherwise return `"Lambda validator"`

This fallback is mainly used for plain anonymous functions or closures.
"""
function validator_name(f)
    try
        return String(nameof(f))
    catch
        return "Lambda validator"
    end
end

"""
    validator_resolve_message(v, explicit_msg, fallback)

Resolve the final validation message using the following precedence:

1. `explicit_msg`, if it is not `nothing` and not empty after conversion to `String`
2. `v.msg`, if it is not empty
3. `fallback`

Returns the selected message as a `String`.
"""
function validator_resolve_message(v::ValidatorSpec, explicit_msg, fallback::AbstractString)
    if explicit_msg !== nothing
        s = String(explicit_msg)
        isempty(s) || return s
    end
    isempty(v.msg) || return v.msg
    return String(fallback)
end

"""
    _validator_msg_bullet(vs)

Convert a validator message into a bullet list item.

If `vs.msg` is empty, `validator_name(vs)` is used instead.
"""
function _validator_msg_bullet(vs::ValidatorSpec)
    msg = strip(vs.msg)
    isempty(msg) && (msg = validator_name(vs))
    return "- " * msg
end

"""
    _validator_join_msgs(title, specs)

Join non-empty validator messages from `specs` into a bullet list prefixed by `title`.

Returns an empty string if all validator messages are empty.
"""
function _validator_join_msgs(title::AbstractString, specs::Vector{ValidatorSpec})
    items = String[]
    for s in specs
        m = strip(s.msg)
        isempty(m) && continue
        push!(items, _validator_msg_bullet(s))
    end
    isempty(items) && return ""
    return String(title) * "\n" * join(items, "\n")
end
