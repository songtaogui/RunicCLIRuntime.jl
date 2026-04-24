Base.@kwdef struct ArgHelpTemplate{H,U,V,D,P,O,S,E}
    header::H
    section_usage::U
    section_version::V
    section_description::D
    section_positionals::P
    section_options::O
    section_subcommands::S
    section_epilog::E
end

@enum ArgKind begin
    AK_FLAG
    AK_COUNT
    AK_OPTION
    AK_OPTION_MULTI
    AK_POS_REQUIRED
    AK_POS_OPTIONAL
    AK_POS_REST
end

abstract type RelationExpr end

Base.@kwdef struct RelAll <: RelationExpr
    members::Vector{Symbol} = Symbol[]
end

Base.@kwdef struct RelAny <: RelationExpr
    members::Vector{Symbol} = Symbol[]
end

Base.@kwdef struct RelNot <: RelationExpr
    inner::RelationExpr
end

function relation_expr_members(expr::RelationExpr)::Vector{Symbol}
    out = Symbol[]
    function walk(x::RelationExpr)
        if x isa RelAll
            append!(out, x.members)
        elseif x isa RelAny
            append!(out, x.members)
        elseif x isa RelNot
            walk(x.inner)
        end
    end
    walk(expr)
    return unique(out)
end

function relation_expr_string(expr::RelationExpr)::String
    if expr isa RelAll
        return "all(" * join(string.(expr.members), ", ") * ")"
    elseif expr isa RelAny
        return "any(" * join(string.(expr.members), ", ") * ")"
    elseif expr isa RelNot
        return "not(" * relation_expr_string(expr.inner) * ")"
    else
        return "<?>"
    end
end


Base.@kwdef struct ArgDef
    kind::ArgKind
    name::Symbol
    T::Any
    flags::Vector{String} = String[]
    default::Any = nothing
    help::String = ""
    help_name::String = ""
    required::Bool = false
    env::Union{Nothing,String}=nothing
    fallback::Union{Nothing,Symbol}=nothing
end

Base.@kwdef struct ArgRelationDef
    kind::Symbol
    lhs::Union{Nothing,RelationExpr} = nothing
    rhs::Union{Nothing,RelationExpr} = nothing
    members::Vector{Symbol} = Symbol[]
    help::String = ""
end

Base.@kwdef struct ArgGroupDef
    title::String
    members::Vector{Symbol} = Symbol[]
end

Base.@kwdef struct SubcommandDef
    name::String
    description::String = ""
    usage::String = ""
    epilog::String = ""
    version::String = ""
    body::Union{Nothing,Expr} = nothing
    args::Vector{ArgDef} = ArgDef[]
    allow_extra::Bool = false
    auto_help::Bool = false
    relations::Vector{ArgRelationDef} = ArgRelationDef[]
    arg_groups::Vector{ArgGroupDef} = ArgGroupDef[]
end

Base.@kwdef struct CliDef
    cmd_name::String = ""
    usage::String = ""
    description::String = ""
    epilog::String = ""
    version::String = ""
    args::Vector{ArgDef} = ArgDef[]
    subcommands::Vector{SubcommandDef} = SubcommandDef[]
    allow_extra::Bool = false
    auto_help::Bool = false
    relations::Vector{ArgRelationDef} = ArgRelationDef[]
    arg_groups::Vector{ArgGroupDef} = ArgGroupDef[]
end

const CLIDEFREGISTRY = IdDict{DataType,CliDef}()

function clidef(::Type{T}) where {T}
    get(CLIDEFREGISTRY, T, nothing) === nothing &&
        throw(ArgumentError("no CliDef registered for type $(T)"))
    return CLIDEFREGISTRY[T]
end

function clidef(x)
    return clidef(typeof(x))
end

function CliDef(::Type{T}) where {T}
    get(CLIDEFREGISTRY, T, nothing) === nothing &&
        throw(ArgumentError("no CliDef registered for type $(T)"))
    return CLIDEFREGISTRY[T]
end

function CliDef(x)
    return CliDef(typeof(x))
end
