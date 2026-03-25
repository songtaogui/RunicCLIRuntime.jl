@inline _find_flag(args::Vector{String}, flags::Vector{String}) = findfirst(in(flags), args)

@inline _looks_like_flag_token(s::String) = startswith(s, "-") && s != "-"
@inline _looks_like_negative_number_token(s::String) = startswith(s, "-") && tryparse(Float64, s) !== nothing

@inline function _validate_option_value_token!(opt::AbstractString, val::String, allow_empty_option_value::Bool)
    if !allow_empty_option_value && isempty(val)
        _throw_arg_error(_msg_option_disallow_empty_value(opt))
    end
    if _looks_like_flag_token(val) && !_looks_like_negative_number_token(val)
        _throw_arg_error(_msg_option_value_is_option(opt, val))
    end
end

function _pop_flag!(args::Vector{String}, flags::Vector{String})::Bool
    seen = false
    i = 1
    while i <= length(args)
        if args[i] in flags
            deleteat!(args, i)
            seen = true
        else
            i += 1
        end
    end
    return seen
end

function _pop_count!(args::Vector{String}, flag::String)::Int
    n0 = length(args)
    i = 1
    while i <= length(args)
        if args[i] == flag
            deleteat!(args, i)
        else
            i += 1
        end
    end
    n0 - length(args)
end

function _pop_value!(args::Vector{String}, flags::Vector{String}, allow_empty_option_value::Bool)::Union{Nothing,String}
    idx = _find_flag(args, flags)
    isnothing(idx) && return nothing
    idx == length(args) && _throw_arg_error(_msg_option_requires_value(args[idx]))

    val = args[idx+1]
    _validate_option_value_token!(args[idx], val, allow_empty_option_value)

    deleteat!(args, (idx, idx+1))
    return val
end

function _pop_value_last!(args::Vector{String}, flags::Vector{String}, allow_empty_option_value::Bool)::Tuple{Union{Nothing,String},Bool}
    vals = String[]
    while true
        v = _pop_value!(args, flags, allow_empty_option_value)
        isnothing(v) && break
        push!(vals, v)
    end
    isempty(vals) && return (nothing, false)
    return (vals[end], true)
end

function _pop_value_once!(args::Vector{String}, flags::Vector{String}, name::String, allow_empty_option_value::Bool)::Tuple{Union{Nothing,String},Bool}
    vals = _pop_multi_values!(args, flags, allow_empty_option_value)
    if isempty(vals)
        return (nothing, false)
    elseif length(vals) == 1
        return (vals[1], true)
    else
        _throw_arg_error(_msg_option_specified_multiple(flags[end], name))
    end
end

function _pop_multi_values!(args::Vector{String}, flags::Vector{String}, allow_empty_option_value::Bool)::Vector{String}
    vals = String[]
    while true
        v = _pop_value!(args, flags, allow_empty_option_value)
        isnothing(v) && break
        push!(vals, v)
    end
    vals
end

function _reject_unknown_option_tokens(args::Vector{String})
    i = 1
    while i <= length(args)
        tok = args[i]
        if tok == "--"
            return
        end
        if _looks_like_flag_token(tok) && !_looks_like_negative_number_token(tok)
            _throw_arg_error(_msg_unknown_or_unexpected_option(tok))
        end
        i += 1
    end
end
