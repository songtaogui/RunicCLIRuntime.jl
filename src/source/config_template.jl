function default_value_for_arg(a::ArgDef)
    if a.default !== nothing
        return a.default
    end
    if a.kind == AK_FLAG
        return false
    elseif a.kind == AK_COUNT
        return 0
    elseif a.kind == AK_OPTION_MULTI || a.kind == AK_POS_REST
        return Any[]
    else
        return ""
    end
end

function generate_default_config(def::CliDef)::String
    d = Dict{String,Any}()

    for a in def.args
        d[string(a.name)] = default_value_for_arg(a)
    end

    for s in def.subcommands
        for a in s.args
            d["$(s.name).$(a.name)"] = default_value_for_arg(a)
        end
        if !isempty(s.version)
            d["$(s.name).version"] = s.version
        end
    end

    if !isempty(def.version)
        d["version"] = def.version
    end

    io = IOBuffer()
    TOML.print(io, d)
    return String(take!(io))
end

function generate_default_config(::Type{T}) where {T}
    return generate_default_config(CliDef(T))
end

function save_default_config(path::AbstractString, def::CliDef; force::Bool=false)
    if isfile(path) && !force
        throw_arg_error("Config file already exists: $(path). Use force=true to overwrite.")
    end
    open(path, "w") do io
        print(io, generate_default_config(def))
    end
    return path
end

function save_default_config(path::AbstractString, ::Type{T}; force::Bool=false) where {T}
    return save_default_config(path, CliDef(T); force=force)
end
