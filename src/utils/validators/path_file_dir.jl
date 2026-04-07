#FILEPATH: utils/validators/path_file_dir.jl

"""
    V_path_exists()

Return a validator that checks `ispath(String(x))`.
"""
V_path_exists() = x -> ispath(String(x))

"""
    V_path_absent()

Return a validator that checks `!ispath(String(x))`.
"""
V_path_absent() = x -> !ispath(String(x))

"""
    V_path_isfile()

Return a validator that checks `isfile(String(x))`.
"""
V_path_isfile() = x -> isfile(String(x))

"""
    V_path_isdir()

Return a validator that checks `isdir(String(x))`.
"""
V_path_isdir() = x -> isdir(String(x))

"""
    V_path_readable()

Return a validator that checks `isreadable(String(x))`.
"""
V_path_readable() = x -> isreadable(String(x))

"""
    V_path_writable()

Return a validator that checks `iswritable(String(x))`.
"""
V_path_writable() = x -> iswritable(String(x))

"""
    V_path_executable()

Return a validator that checks `isexecutable(String(x))`.
"""
V_path_executable() = x -> isexecutable(String(x))

"""
    V_path_symlink()

Return a validator that checks whether the path is a symbolic link.
"""
V_path_symlink() = x -> islink(String(x))

"""
    V_path_real()

Return a validator that checks whether `String(x)` equals its canonical `realpath`.

Path must exist.
"""
V_path_real() = x -> begin
    p = String(x)
    ispath(p) || return false
    try
        realpath(p) == p
    catch
        false
    end
end

"""
    V_path_absolute()

Return a validator that checks `isabspath(String(x))`.
"""
V_path_absolute() = x -> isabspath(String(x))

"""
    V_path_relative()

Return a validator that checks `!isabspath(String(x))`.
"""
V_path_relative() = x -> !isabspath(String(x))

"""
    V_path_nottraversal()

Return a validator that checks the path does not contain `..` segments.
"""
V_path_nottraversal() = x -> begin
    p = normpath(String(x))
    parts = splitpath(p)
    !(".." in parts)
end

"""
    V_path_within(root)

Return a validator that checks whether `x` is within `root`.

Requirements:
- `root` must exist.
- `root` and `x` are compared after `realpath`.
- `x` must exist.
"""
function V_path_within(root::AbstractString)
    rootp = String(root)
    if !ispath(rootp)
        return _ -> false
    end
    r = realpath(rootp)
    return x -> begin
        p = String(x)
        ispath(p) || return false
        rp = try realpath(p) catch; return false end
        rp == r || startswith(rp, r * Base.Filesystem.path_separator)
    end
end

"""
    V_path_ext(ext)

Return a validator that checks file extension.

`ext` may be passed as `".toml"` or `"toml"`.
Comparison is case-insensitive.
"""
function V_path_ext(ext::AbstractString)
    want = startswith(ext, ".") ? lowercase(String(ext)) : "." * lowercase(String(ext))
    return x -> lowercase(splitext(String(x))[2]) == want
end

"""
    V_file_readable()

Return a validator that checks a path exists, is a file, and is readable.
"""
V_file_readable() = V_AND(V_path_exists(), V_path_isfile(), V_path_readable())

"""
    V_file_writable()

Return a validator that checks a path is a file and writable.
"""
V_file_writable() = V_AND(V_path_isfile(), V_path_writable())

"""
    V_file_creatable()

Return a validator that checks whether the parent directory of the target file path\nexists and is writable.
"""
V_file_creatable() = x -> begin
    p = String(x)
    d = dirname(abspath(p))
    isdir(d) && iswritable(d)
end

"""
    V_file_nonempty()

Return a validator that checks a file exists and its size is greater than zero.
"""
V_file_nonempty() = x -> begin
    p = String(x)
    isfile(p) || return false
    try
        filesize(p) > 0
    catch
        false
    end
end

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
    V_dir_contains(files...; require_all=true)
    V_dir_contains(files::AbstractVector{<:AbstractString}; require_all=true)

Return a validator that checks whether a directory contains specified file(s).

- `files` can be one or more relative file paths (e.g. `"a.txt"`, `"conf/app.toml"`).
- When `require_all=true` (default), all files must exist.
- When `require_all=false`, any one file existing is enough.

Notes:
- Target `x` must be an existing directory.
- This validator checks `isfile(joinpath(dir, file))`.
"""
function V_dir_contains(files::AbstractString...; require_all::Bool=true)
    wanted = String.(files)
    isempty(wanted) && return _ -> false

    return x -> begin
        d = String(x)
        isdir(d) || return false

        checks = (isfile(joinpath(d, f)) for f in wanted)
        require_all ? all(checks) : any(checks)
    end
end

function V_dir_contains(files::AbstractVector{<:AbstractString}; require_all::Bool=true)
    return V_dir_contains(files...; require_all=require_all)
end
