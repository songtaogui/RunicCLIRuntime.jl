"""
    index_paths_for(file; suffixes=String[], replace_ext=String[], strip_all_ext=false, in_dir=nothing)

Generate candidate index paths for `file`.

- `suffixes`: append-style index suffixes, e.g. `[".csi", ".tbi"]`
- `replace_ext`: replacement-style extensions, e.g. `[".idx", ".bai"]`
- `strip_all_ext=false`:
  - `false`: strip only last extension before replacement
  - `true`: strip all extensions before replacement
- `in_dir`:
  - `nothing`: same directory as `file`
  - otherwise: place index files under `in_dir`
"""
function index_paths_for(file;
    suffixes::Vector{String}=String[],
    replace_ext::Vector{String}=String[],
    strip_all_ext::Bool=false,
    in_dir=nothing
)
    f = String(file)
    d = in_dir === nothing ? dirname(f) : String(in_dir)
    b = basename(f)

    paths = String[]

    for s in suffixes
        push!(paths, joinpath(d, b * s))
    end

    base_noext = b
    if strip_all_ext
        while true
            b2, ext = splitext(base_noext)
            isempty(ext) && break
            base_noext = b2
        end
    else
        base_noext = splitext(base_noext)[1]
    end

    for e in replace_ext
        ext = startswith(e, ".") ? e : "." * e
        push!(paths, joinpath(d, base_noext * ext))
    end

    unique(paths)
end

function _index_mode_ok(cands::Vector{String}, mode::Symbol; require_readable::Bool=true)
    check_one(p) = isfile(p) && (!require_readable || isreadable(p))
    if mode == :any
        return any(check_one, cands)
    elseif mode == :all
        return all(check_one, cands)
    elseif mode == :none
        return all(p -> !isfile(p), cands)
    else
        return false
    end
end

"""
    V_file_has_index(; suffixes=String[], replace_ext=String[], mode=:any, strip_all_ext=false, in_dir=nothing, require_readable=true)

Return a validator checking index file existence strategy for a data file.

`mode` supports:
- `:any`
- `:all`
- `:none`
"""
function V_file_has_index(;
    suffixes::Vector{String}=String[],
    replace_ext::Vector{String}=String[],
    mode::Symbol=:any,
    strip_all_ext::Bool=false,
    in_dir=nothing,
    require_readable::Bool=true
)
    return x -> begin
        f = String(x)
        cands = index_paths_for(f;
            suffixes=suffixes,
            replace_ext=replace_ext,
            strip_all_ext=strip_all_ext,
            in_dir=in_dir
        )
        isempty(cands) && return false
        _index_mode_ok(cands, mode; require_readable=require_readable)
    end
end

"""
    V_file_has_any_index(; kwargs...)

Alias of [`V_file_has_index`](@ref) with `mode=:any`.
"""
V_file_has_any_index(; kwargs...) = V_file_has_index(; mode=:any, kwargs...)

"""
    V_file_has_all_indexes(; kwargs...)

Alias of [`V_file_has_index`](@ref) with `mode=:all`.
"""
V_file_has_all_indexes(; kwargs...) = V_file_has_index(; mode=:all, kwargs...)

"""
    V_file_has_index_groups(groups; group_mode=:all, require_readable=true, strip_all_ext=false, in_dir=nothing)

Grouped index validation.

Each element in `groups` should be a named tuple, for example:
`(; suffixes=[".bai", ".csi"], replace_ext=String[], mode=:any)`.
"""
function V_file_has_index_groups(groups;
    group_mode::Symbol=:all,
    require_readable::Bool=true,
    strip_all_ext::Bool=false,
    in_dir=nothing
)
    return x -> begin
        f = String(x)
        res = Bool[]
        for g in groups
            suffixes = hasproperty(g, :suffixes) ? Vector{String}(getproperty(g, :suffixes)) : String[]
            replace_ext = hasproperty(g, :replace_ext) ? Vector{String}(getproperty(g, :replace_ext)) : String[]
            mode = hasproperty(g, :mode) ? Symbol(getproperty(g, :mode)) : :any
            cands = index_paths_for(f;
                suffixes=suffixes,
                replace_ext=replace_ext,
                strip_all_ext=strip_all_ext,
                in_dir=in_dir
            )
            push!(res, _index_mode_ok(cands, mode; require_readable=require_readable))
        end
        if group_mode == :all
            all(res)
        elseif group_mode == :any
            any(res)
        else
            false
        end
    end
end
