function split_multiflag(s::AbstractString)::Vector{String}
    isascii(s) || throw_arg_error(msg_invalid_short_option_bundle_non_ascii(s))
    startswith(s, "-") || throw_arg_error(msg_invalid_short_option_bundle(s))
    length(s) > 2 || throw_arg_error(msg_invalid_short_option_bundle(s))

    out = String[]
    max_i = lastindex(s)
    i = 2
    while i <= max_i
        c = s[i]
        if isascii(c) && isletter(c)
            push!(out, "-$c")
            i = nextind(s, i)
        else
            throw_arg_error(msg_invalid_short_option_bundle(s))
        end
    end
    out
end

@inline is_short_bundle_candidate(head::AbstractString) =
    length(head) > 2 &&
    startswith(head, "-") &&
    !startswith(head, "--") &&
    isascii(head[2]) &&
    isletter(head[2])

function analyze_short_bundle(
    tok::AbstractString,
    flags_need_value::Set{String},
    flags_no_value::Set{String};
    strict_unknown_option::Bool=true
)::Tuple{Bool,Vector{String},Bool,Bool}
    if !is_short_bundle_candidate(tok)
        return (false, String[], false, false)
    end

    expanded = split_multiflag(tok)
    tail_requires_value = false
    all_known = true

    for (k, f) in enumerate(expanded)
        if f in flags_need_value
            if k != length(expanded)
                throw_arg_error(msg_bundle_option_requiring_value_must_be_last(tok))
            end
            tail_requires_value = true
        elseif f in flags_no_value
            nothing
        else
            all_known = false
            if strict_unknown_option
                return (true, expanded, false, false)
            end
        end
    end

    return (true, expanded, tail_requires_value, all_known)
end

function split_arguments(args::Vector{String}; allow_short_bundle::Bool=true)::Vector{String}
    out = String[]
    passthrough = false
    for arg in args
        if passthrough
            push!(out, arg)
            continue
        end
        if arg == "--"
            push!(out, arg)
            passthrough = true
            continue
        end
        if startswith(arg, "-")
            parts = split(arg, '=', limit=2)
            head = parts[1]
            is_short_bundle = allow_short_bundle && is_short_bundle_candidate(head)

            if is_short_bundle
                if length(parts) == 2
                    throw_arg_error(msg_ambiguous_short_bundle_with_equals(arg))
                end
                if length(head) > 2 && isletter(head[2]) && (tryparse(Float64, head[3:end]) !== nothing)
                    push!(out, head[1:2])
                    push!(out, head[3:end])
                else
                    append!(out, split_multiflag(head))
                end
            else
                append!(out, String.(parts))
            end
        else
            push!(out, arg)
        end
    end
    out
end

function has_help_flag_before_dd(args::Vector{String})::Bool
    toks = split_arguments(copy(args))
    dd = findfirst(==("--"), toks)
    if !isnothing(dd)
        toks = toks[1:dd-1]
    end
    any(t -> t == "-h" || t == "--help", toks)
end

function has_version_flag_before_dd(args::Vector{String})::Bool
    toks = split_arguments(copy(args))
    dd = findfirst(==("--"), toks)
    if !isnothing(dd)
        toks = toks[1:dd-1]
    end
    any(t -> t == "-V" || t == "--version", toks)
end

function locate_subcommand(
    argv::Vector{String},
    sub_names::Vector{String},
    flags_need_value::Set{String},
    flags_no_value::Set{String};
    strict_unknown_option::Bool=true
)::Tuple{Union{Nothing,String},Int}
    isempty(sub_names) && return (nothing, 0)

    expecting_value = false
    i = 1
    while i <= length(argv)
        tok = argv[i]

        if tok == "--"
            return (nothing, 0)
        end

        if expecting_value
            expecting_value = false
            i += 1
            continue
        end

        if startswith(tok, "-") && tok != "-"
            parts = split(tok, '=', limit=2)
            head = parts[1]
            has_inline_value = (length(parts) == 2)

            if head in flags_need_value
                if !has_inline_value
                    expecting_value = true
                end
                i += 1
                continue
            elseif head in flags_no_value
                i += 1
                continue
            else
                handled, _, tail_requires_value, all_known =
                    analyze_short_bundle(head, flags_need_value, flags_no_value; strict_unknown_option=strict_unknown_option)

                if handled
                    if !all_known && strict_unknown_option
                        return (nothing, 0)
                    end
                    if tail_requires_value
                        expecting_value = true
                    end
                    i += 1
                    continue
                end

                if strict_unknown_option
                    return (nothing, 0)
                end

                i += 1
                continue
            end
        else
            if tok in sub_names
                return (tok, i)
            else
                return (nothing, 0)
            end
        end
    end

    return (nothing, 0)
end
