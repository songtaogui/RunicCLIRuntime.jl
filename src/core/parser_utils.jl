@inline _parse_value(::Type{String}, s::String, ::String) = s
@inline _parse_value(::Type{Symbol}, s::String, ::String) = Symbol(s)
@inline _parse_value(::Type{Bool}, s::String, name::String) = begin
    x = lowercase(strip(s))
    if x in ("1","true","t","yes","y","on")
        true
    elseif x in ("0","false","f","no","n","off")
        false
    else
        _throw_arg_error("Invalid boolean value for $name: $s")
    end
end

@inline function _parse_value(::Type{T}, s::String, name::String) where {T<:Integer}
    try
        return parse(T, s)
    catch
        _throw_arg_error("Invalid integer value for $name: $s")
    end
end

@inline function _parse_value(::Type{T}, s::String, name::String) where {T<:AbstractFloat}
    try
        return parse(T, s)
    catch
        _throw_arg_error("Invalid floating value for $name: $s")
    end
end

@inline function _parse_value(::Type{T}, s::String, name::String) where {T}
    if applicable(Base.tryparse, T, s)
        tp = Base.tryparse(T, s)
        tp !== nothing && return tp
    end

    parse_err = nothing
    if applicable(parse, T, s)
        try
            return parse(T, s)
        catch e
            parse_err = e
        end
    end

    try
        return T(s)
    catch e
        if parse_err === nothing
            _throw_arg_error("Invalid value for $name (type $(T)): $s ($(sprint(showerror, e)))")
        else
            _throw_arg_error("Invalid value for $name (type $(T)): $s (parse: $(sprint(showerror, parse_err)); ctor: $(sprint(showerror, e)))")
        end
    end
end

@inline function _convert_default(::Type{T}, v, name::String) where {T}
    try
        return v isa T ? v : convert(T, v)
    catch e
        _throw_arg_error("Invalid default value for $name: expected $T, got $(typeof(v)) ($(sprint(showerror, e)))")
    end
end

function _build_main_flag_sets(argdefs::Vector{ArgDef})
    flags_need_value = Set{String}()
    flags_no_value = Set{String}()

    for a in argdefs
        if a.kind in (AK_OPTION, AK_OPTION_MULTI)
            for f in a.flags
                push!(flags_need_value, f)
            end
        elseif a.kind in (AK_FLAG, AK_COUNT)
            for f in a.flags
                push!(flags_no_value, f)
            end
        end
    end

    return flags_need_value, flags_no_value
end

function _extract_global_options(
    argv::Vector{String},
    sub_idx::Int,
    flags_need_value::Set{String},
    flags_no_value::Set{String}
)::Tuple{Vector{String},Vector{String}}
    main_tokens = String[]
    sub_tokens = String[]

    i = 1
    passthrough = false

    while i <= length(argv)
        tok = argv[i]

        if i == sub_idx
            i += 1
            continue
        end

        if passthrough
            push!(sub_tokens, tok)
            i += 1
            continue
        end

        if tok == "--"
            push!(sub_tokens, tok)
            passthrough = true
            i += 1
            continue
        end

        if startswith(tok, "-") && tok != "-"
            parts = split(tok, '=', limit=2)
            head = parts[1]
            has_inline_value = (length(parts) == 2)

            if head in flags_need_value
                push!(main_tokens, tok)
                if !has_inline_value
                    i == length(argv) && _throw_arg_error(_msg_option_requires_value(tok))
                    nxt = argv[i+1]
                    nxt == "--" && _throw_arg_error(_msg_option_requires_value(tok))
                    push!(main_tokens, nxt)
                    i += 2
                else
                    i += 1
                end
                continue
            elseif head in flags_no_value
                push!(main_tokens, tok)
                i += 1
                continue
            else
                handled, expanded, tail_requires_value, all_known =
                    _analyze_short_bundle(head, flags_need_value, flags_no_value; strict_unknown_option=false)

                if handled && all_known
                    append!(main_tokens, expanded)
                    if tail_requires_value
                        i == length(argv) && _throw_arg_error(_msg_option_requires_value(expanded[end]))
                        nxt = argv[i+1]
                        nxt == "--" && _throw_arg_error(_msg_option_requires_value(expanded[end]))
                        push!(main_tokens, nxt)
                        i += 2
                    else
                        i += 1
                    end
                    continue
                end
            end
        end

        push!(sub_tokens, tok)
        i += 1
    end

    return main_tokens, sub_tokens
end
