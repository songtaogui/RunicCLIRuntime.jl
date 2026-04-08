"""
    V_path_exists()

Return a ValidatorSpec that checks `ispath(String(x))`.
"""
V_path_exists() = ValidatorSpec("V_path_exists", "Path must exist", x -> ispath(String(x)))

"""
    V_path_absent()

Return a ValidatorSpec that checks `!ispath(String(x))`.
"""
V_path_absent() = ValidatorSpec("V_path_absent", "Path must not exist", x -> !ispath(String(x)))

"""
    V_path_isfile()

Return a ValidatorSpec that checks `isfile(String(x))`.
"""
V_path_isfile() = ValidatorSpec("V_path_isfile", "Path must be a file", x -> isfile(String(x)))

"""
    V_path_isdir()

Return a ValidatorSpec that checks `isdir(String(x))`.
"""
V_path_isdir() = ValidatorSpec("V_path_isdir", "Path must be a directory", x -> isdir(String(x)))

"""
    V_path_readable()

Return a ValidatorSpec that checks `isreadable(String(x))`.
"""
V_path_readable() = ValidatorSpec("V_path_readable", "Path must be readable", x -> isreadable(String(x)))

"""
    V_path_writable()

Return a ValidatorSpec that checks `iswritable(String(x))`.
"""
V_path_writable() = ValidatorSpec("V_path_writable", "Path must be writable", x -> iswritable(String(x)))

"""
    V_path_executable()

Return a ValidatorSpec that checks `isexecutable(String(x))`.
"""
V_path_executable() = ValidatorSpec("V_path_executable", "Path must be executable", x -> isexecutable(String(x)))

"""
    V_path_symlink()

Return a ValidatorSpec that checks whether the path is a symbolic link.
"""
V_path_symlink() = ValidatorSpec("V_path_symlink", "Path must be a symbolic link", x -> islink(String(x)))

"""
    V_path_nosymlink()

Return a ValidatorSpec that checks whether the path is not a symbolic link.
"""
V_path_nosymlink() = ValidatorSpec("V_path_nosymlink", "Path must not be a symbolic link", x -> !islink(String(x)))

"""
    V_path_real()

Return a ValidatorSpec that checks whether `String(x)` equals its canonical `realpath`.

Path must exist.
"""
V_path_real() = ValidatorSpec(
    "V_path_real",
    "Path must be canonical and existing",
    x -> begin
        p = String(x)
        ispath(p) || return false
        try
            realpath(p) == p
        catch
            false
        end
    end
)

"""
    V_path_absolute()

Return a ValidatorSpec that checks `isabspath(String(x))`.
"""
V_path_absolute() = ValidatorSpec("V_path_absolute", "Path must be absolute", x -> isabspath(String(x)))

"""
    V_path_relative()

Return a ValidatorSpec that checks `!isabspath(String(x))`.
"""
V_path_relative() = ValidatorSpec("V_path_relative", "Path must be relative", x -> !isabspath(String(x)))

"""
    V_path_nonblank()

Return a ValidatorSpec that checks the path string is not blank after `strip`.
"""
V_path_nonblank() = ValidatorSpec("V_path_nonblank", "Path must not be blank", x -> !isempty(strip(String(x))))

"""
    V_path_nottraversal()

Return a ValidatorSpec that checks the path does not contain `..` segments.
"""
V_path_nottraversal() = ValidatorSpec(
    "V_path_nottraversal",
    "Path must not contain parent traversal segments",
    x -> begin
        p = normpath(String(x))
        parts = splitpath(p)
        !(".." in parts)
    end
)

"""
    V_path_within(root)

Return a ValidatorSpec that checks whether `x` is within `root`.

Requirements:
- `root` must exist.
- `root` and `x` are compared after `realpath`.
- `x` must exist.
"""
function V_path_within(root::AbstractString)
    rootp = String(root)
    if !ispath(rootp)
        return ValidatorSpec("V_path_within", "Path must be within existing root " * repr(rootp), _ -> false)
    end

    r = try
        realpath(rootp)
    catch
        return ValidatorSpec("V_path_within", "Path must be within existing root " * repr(rootp), _ -> false)
    end

    msg = "Path must be within " * repr(r)
    return ValidatorSpec(
        "V_path_within",
        msg,
        x -> begin
            p = String(x)
            ispath(p) || return false
            rp = try
                realpath(p)
            catch
                return false
            end
            rp == r || startswith(rp, r * Base.Filesystem.path_separator)
        end
    )
end

"""
    V_path_ext_in(exts::AbstractVector{<:AbstractString})
    V_path_ext_in(exts::AbstractString...)

Return a ValidatorSpec that checks whether the path extension is in a whitelist.

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
    isempty(wants) && return ValidatorSpec("V_path_ext_in", "Extension set must not be empty", _ -> false)
    msg = "Extension must be one of: " * repr(sort!(collect(wants)))
    return ValidatorSpec(
        "V_path_ext_in",
        msg,
        x -> lowercase(splitext(String(x))[2]) in wants
    )
end

V_path_ext_in(exts::AbstractString...) = V_path_ext_in(collect(exts))

"""
    V_path_basename_match(rx)

Return a ValidatorSpec that checks whether `basename(path)` matches `rx`.
"""
V_path_basename_match(rx::Regex) = ValidatorSpec(
    "V_path_basename_match",
    "Basename must match regex " * repr(rx),
    x -> occursin(rx, basename(String(x)))
)

"""
    V_path_basename_only()

Return a ValidatorSpec that accepts only a plain basename (no directory components).

Rejects:
- empty string
- "."
- ".."
- strings containing '/' or '\\'
"""
V_path_basename_only() = ValidatorSpec(
    "V_path_basename_only",
    "Value must be a basename only",
    x -> begin
        s = String(x)
        s == basename(s) &&
        s != "" &&
        s != "." &&
        s != ".." &&
        !occursin('/', s) &&
        !occursin('\\', s)
    end
)

"""
    V_path_maxlen(n)

Return a ValidatorSpec that checks `length(String(x)) <= n`.
"""
function V_path_maxlen(n::Integer)
    n < 0 && return ValidatorSpec("V_path_maxlen", "Maximum path length must be non-negative", _ -> false)
    return ValidatorSpec("V_path_maxlen", "Path length must be <= " * string(n), x -> ncodeunits(String(x)) <= n)
end
