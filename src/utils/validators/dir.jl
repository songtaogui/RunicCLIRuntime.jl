#FILEPATH: utils/validators/path_file_dir.jl

"""
    V_dir_readable()

Return a validator that checks a path exists, is a directory, and is readable.
"""
V_dir_readable() = V_AND(V_path_exists(), V_path_isdir(), V_path_readable())

"""
    V_dir_writable()

Return a validator that checks a path is a directory and writable.
"""
V_dir_writable() = V_AND(V_path_isdir(), V_path_writable())

"""
    V_dir_contains(paths...; kind=:file, require_all=true)
    V_dir_contains(paths::AbstractVector{<:AbstractString}; kind=:file, require_all=true)

Return a validator that checks whether a directory contains specified paths.

- `paths` are relative paths.
- `kind=:file`   -> check `isfile(joinpath(dir, p))`
- `kind=:subdir` -> check `isdir(joinpath(dir, p))`
- `require_all=true`  -> all must exist
- `require_all=false` -> any one existing is enough

Notes:
- Target `x` must be an existing directory.
"""
function V_dir_contains(paths::AbstractString...; kind::Symbol=:file, require_all::Bool=true)
    wanted = String.(paths)
    isempty(wanted) && return _ -> false

    checker = if kind === :file
        isfile
    elseif kind === :subdir || kind === :dir
        isdir
    else
        throw(ArgumentError("`kind` must be :file or :subdir (or :dir), got: $kind"))
    end

    return x -> begin
        d = String(x)
        isdir(d) || return false

        checks = (checker(joinpath(d, p)) for p in wanted)
        require_all ? all(checks) : any(checks)
    end
end

function V_dir_contains(paths::AbstractVector{<:AbstractString}; kind::Symbol=:file, require_all::Bool=true)
    return V_dir_contains(paths...; kind=kind, require_all=require_all)
end

# Internal helper: simple glob (* and ?) to Regex
function _glob_to_regex(pattern::AbstractString)
    s = String(pattern)
    io = IOBuffer()
    write(io, '^')
    i = firstindex(s)
    while i <= lastindex(s)
        c = s[i]
        if c == '*'
            write(io, ".*")
        elseif c == '?'
            write(io, ".")
        elseif c in ('.', '^', '$', '+', '(', ')', '[', ']', '{', '}', '|', '\\')
            write(io, '\\')
            write(io, c)
        else
            write(io, c)
        end
        i = nextind(s, i)
    end
    write(io, '$')
    return Regex(String(take!(io)))
end

"""
    V_dir_contains_glob(pattern; min_count=1, max_count=typemax(Int), recursive=false)

Return a validator that checks file entries under a directory matching a glob-like
`pattern` (`*` and `?` supported) satisfy count bounds.

- `min_count` and `max_count` are inclusive.
- `recursive=false` matches direct children only.
- `recursive=true` scans recursively and matches on relative paths using `/`.
"""
function V_dir_contains_glob(
    pattern::AbstractString;
    min_count::Integer=1,
    max_count::Integer=typemax(Int),
    recursive::Bool=false
)
    min_count < 0 && return _ -> false
    max_count < min_count && return _ -> false
    rx = _glob_to_regex(pattern)

    return x -> begin
        d = String(x)
        isdir(d) || return false
        count = 0
        try
            if recursive
                for (root, _, files) in walkdir(d)
                    for f in files
                        full = joinpath(root, f)
                        rel = relpath(full, d)
                        reln = replace(rel, '\\' => '/')
                        if occursin(rx, reln)
                            count += 1
                            count > max_count && return false
                        end
                    end
                end
            else
                for e in readdir(d)
                    full = joinpath(d, e)
                    isfile(full) || continue
                    if occursin(rx, e)
                        count += 1
                        count > max_count && return false
                    end
                end
            end
            return min_count <= count <= max_count
        catch
            return false
        end
    end
end

"""
    V_dir_creatable()

Return a validator that checks whether the target dir is creatable:

- If the dir exists: it must be writable.
- If the dir does not exist: parent dir must exist and be writable.
"""
V_dir_creatable() = x -> begin
    d = abspath(String(x))
    isdir(d) && return iswritable(d)
    parent = dirname(d)
    isdir(parent) && iswritable(parent)
end

"""
    V_dir_empty()

Return a validator that checks a directory exists and has no entries.
"""
V_dir_empty() = x -> begin
    d = String(x)
    isdir(d) || return false
    try
        isempty(readdir(d))
    catch
        false
    end
end

"""
    V_dir_nonempty()

Return a validator that checks a directory exists and has at least one entry.
"""
V_dir_nonempty() = x -> begin
    d = String(x)
    isdir(d) || return false
    try
        !isempty(readdir(d))
    catch
        false
    end
end
