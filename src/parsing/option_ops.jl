@inline find_flag(args::Vector{String}, flags::Vector{String}) = findfirst(in(flags), args)

@inline looks_like_flag_token(s::String) = startswith(s, "-") && s != "-"
@inline looks_like_negative_number_token(s::String) = startswith(s, "-") && tryparse(Float64, s) !== nothing

@inline function validate_option_value_token!(opt::AbstractString, val::String, allow_empty_option_value::Bool)
    if !allow_empty_option_value && isempty(val)
        throw_arg_error(msg_option_disallow_empty_value(opt))
    end
    if looks_like_flag_token(val) && !looks_like_negative_number_token(val)
        throw_arg_error(msg_option_value_is_option(opt, val))
    end
end

function pop_flag!(args::Vector{String}, flags::Vector{String})::Bool
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

function pop_count!(args::Vector{String}, flag::String)::Int
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

function pop_value!(args::Vector{String}, flags::Vector{String}, allow_empty_option_value::Bool)::Union{Nothing,String}
    idx = find_flag(args, flags)
    isnothing(idx) && return nothing
    idx == length(args) && throw_arg_error(msg_option_requires_value(args[idx]))

    val = args[idx+1]
    validate_option_value_token!(args[idx], val, allow_empty_option_value)

    deleteat!(args, (idx, idx+1))
    return val
end

function pop_value_last!(args::Vector{String}, flags::Vector{String}, allow_empty_option_value::Bool)::Tuple{Union{Nothing,String},Bool}
    vals = String[]
    while true
        v = pop_value!(args, flags, allow_empty_option_value)
        isnothing(v) && break
        push!(vals, v)
    end
    isempty(vals) && return (nothing, false)
    return (vals[end], true)
end

function pop_value_once!(args::Vector{String}, flags::Vector{String}, name::String, allow_empty_option_value::Bool)::Tuple{Union{Nothing,String},Bool}
    vals = pop_multi_values!(args, flags, allow_empty_option_value)
    if isempty(vals)
        return (nothing, false)
    elseif length(vals) == 1
        return (vals[1], true)
    else
        throw_arg_error(msg_option_specified_multiple(flags[end], name))
    end
end

function pop_multi_values!(args::Vector{String}, flags::Vector{String}, allow_empty_option_value::Bool)::Vector{String}
    vals = String[]
    while true
        v = pop_value!(args, flags, allow_empty_option_value)
        isnothing(v) && break
        push!(vals, v)
    end
    vals
end

function reject_unknown_option_tokens(args::Vector{String})
    i = 1
    while i <= length(args)
        tok = args[i]
        if tok == "--"
            return
        end
        if looks_like_flag_token(tok) && !looks_like_negative_number_token(tok)
            throw_arg_error(msg_unknown_or_unexpected_option(tok))
        end
        i += 1
    end
end
