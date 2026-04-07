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
    V_path_nosymlink()

Return a validator that checks whether the path is not a symbolic link.
"""
V_path_nosymlink() = x -> !islink(String(x))

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
    V_path_nonblank()

Return a validator that checks the path string is not blank after `strip`.
"""
V_path_nonblank() = x -> !isempty(strip(String(x)))

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

    r = try
        realpath(rootp)
    catch
        return _ -> false
    end

    return x -> begin
        p = String(x)
        ispath(p) || return false
        rp = try
            realpath(p)
        catch
            return false
        end
        rp == r || startswith(rp, r * Base.Filesystem.path_separator)
    end
end

"""
    V_path_ext_in(exts::AbstractVector{<:AbstractString})
    V_path_ext_in(exts::AbstractString...)

Return a validator that checks whether the path extension is in a whitelist.

- Accepts extensions with or without leading dot.
- Comparison is case-insensitive.
- Supports both vector input and varargs input.
"""
function V_path_ext_in(exts::AbstractVector{<:AbstractString})
    wants = Set(
        begin
            e = lowercase(String(ext))
            startswith(e, ".") ? e : "." * e
        end for ext in exts
    )
    isempty(wants) && return _ -> false
    return x -> lowercase(splitext(String(x))[2]) in wants
end

V_path_ext_in(exts::AbstractString...) = V_path_ext_in(collect(exts))

"""
    V_path_basename_match(rx)

Return a validator that checks whether `basename(path)` matches `rx`.
"""
V_path_basename_match(rx::Regex) = x -> occursin(rx, basename(String(x)))

"""
    V_path_basename_only()

Return a validator that accepts only a plain basename (no directory components).

Rejects:
- empty string
- "."
- ".."
- strings containing '/' or '\\'
"""
V_path_basename_only() = x -> begin
    s = String(x)
    s == basename(s) &&
    s != "" &&
    s != "." &&
    s != ".." &&
    !occursin('/', s) &&
    !occursin('\\', s)
end

"""
    V_path_maxlen(n)

Return a validator that checks `length(String(x)) <= n`.
"""
function V_path_maxlen(n::Integer)
    n < 0 && return _ -> false
    return x -> ncodeunits(String(x)) <= n
end
