using Dates

"""
    V_file_readable()

Return a ValidatorSpec that checks a path exists, is a file, and is readable.
"""
V_file_readable() = V_AND(V_path_exists(), V_path_isfile(), V_path_readable())

"""
    V_file_writable()

Return a ValidatorSpec that checks a path is a file and writable.
"""
V_file_writable() = V_AND(V_path_isfile(), V_path_writable())

"""
    V_file_executable()

Return a ValidatorSpec that checks a path exists, is a file, and is executable.
"""
V_file_executable() = V_AND(V_path_exists(), V_path_isfile(), V_path_executable())

"""
    V_file_creatable()

Return a ValidatorSpec that checks whether the parent directory of the target
file path exists and is writable.
"""
V_file_creatable() = ValidatorSpec(
    "V_file_creatable",
    "Parent directory must exist and be writable",
    x -> begin
        p = String(x)
        d = dirname(abspath(p))
        isdir(d) && iswritable(d)
    end
)

"""
    V_file_output_safe()

Return a ValidatorSpec for output file path safety:

- `true` when the file does not exist but parent directory is writable.
- `true` when the file exists and is writable.
- otherwise `false`.
"""
V_file_output_safe() = ValidatorSpec(
    "V_file_output_safe",
    "Output path must be a writable file or creatable in a writable parent directory",
    x -> begin
        p = String(x)
        if isfile(p)
            return iswritable(p)
        elseif ispath(p)
            return false
        else
            d = dirname(abspath(p))
            return isdir(d) && iswritable(d)
        end
    end
)

"""
    V_file_nonempty()

Return a ValidatorSpec that checks a file exists and its size is greater than zero.
"""
V_file_nonempty() = ValidatorSpec(
    "V_file_nonempty",
    "File must exist and be non-empty",
    x -> begin
        p = String(x)
        isfile(p) || return false
        try
            filesize(p) > 0
        catch
            false
        end
    end
)

"""
    V_file_empty()

Return a ValidatorSpec that checks a file exists and its size is zero.
"""
V_file_empty() = ValidatorSpec(
    "V_file_empty",
    "File must exist and be empty",
    x -> begin
        p = String(x)
        isfile(p) || return false
        try
            filesize(p) == 0
        catch
            false
        end
    end
)

"""
    V_file_size_between(min_bytes, max_bytes)

Return a ValidatorSpec that checks file size is within `[min_bytes, max_bytes]`.

Invalid bounds produce a ValidatorSpec that always returns `false`.
"""
function V_file_size_between(min_bytes::Integer, max_bytes::Integer)
    min_bytes < 0 && return ValidatorSpec("V_file_size_between", "Minimum file size must be non-negative", _ -> false)
    max_bytes < min_bytes && return ValidatorSpec("V_file_size_between", "Maximum file size must be >= minimum file size", _ -> false)

    msg = "File size must be in range [" * string(min_bytes) * ", " * string(max_bytes) * "] bytes"
    return ValidatorSpec(
        "V_file_size_between",
        msg,
        x -> begin
            p = String(x)
            isfile(p) || return false
            try
                s = filesize(p)
                min_bytes <= s <= max_bytes
            catch
                false
            end
        end
    )
end

"""
    V_file_linecount_between(min_lines, max_lines)

Return a ValidatorSpec that checks text-file line count is within
`[min_lines, max_lines]`.

Invalid bounds produce a ValidatorSpec that always returns `false`.
"""
function V_file_linecount_between(min_lines::Integer, max_lines::Integer)
    min_lines < 0 && return ValidatorSpec("V_file_linecount_between", "Minimum line count must be non-negative", _ -> false)
    max_lines < min_lines && return ValidatorSpec("V_file_linecount_between", "Maximum line count must be >= minimum line count", _ -> false)

    msg = "Line count must be in range [" * string(min_lines) * ", " * string(max_lines) * "]"
    return ValidatorSpec(
        "V_file_linecount_between",
        msg,
        x -> begin
            p = String(x)
            isfile(p) || return false
            c = 0
            try
                open(p, "r") do io
                    for _ in eachline(io)
                        c += 1
                        c > max_lines && return false
                    end
                end
                return min_lines <= c <= max_lines
            catch
                return false
            end
        end
    )
end

function _to_epoch_seconds(ref)
    if ref isa Dates.DateTime
        return datetime2unix(ref)
    elseif ref isa Dates.Date
        return datetime2unix(DateTime(ref))
    elseif ref isa Real
        return Float64(ref)
    elseif ref isa AbstractString
        p = String(ref)
        ispath(p) || throw(ArgumentError("reference path does not exist"))
        return mtime(p)
    else
        throw(ArgumentError("unsupported reference type"))
    end
end

"""
    V_file_newer_than(ref)

Return a ValidatorSpec that checks file `mtime(path) > ref_time`.

`ref` may be:
- `AbstractString`: an existing reference path (its mtime is used)
- `Date`, `DateTime`
- `Real`: Unix epoch seconds
"""
function V_file_newer_than(ref)
    t_ref = try
        _to_epoch_seconds(ref)
    catch
        return ValidatorSpec("V_file_newer_than", "Reference for newer-than check is invalid", _ -> false)
    end

    msg = "File modification time must be newer than reference"
    return ValidatorSpec(
        "V_file_newer_than",
        msg,
        x -> begin
            p = String(x)
            isfile(p) || return false
            try
                mtime(p) > t_ref
            catch
                false
            end
        end
    )
end

"""
    V_file_older_than(ref)

Return a ValidatorSpec that checks file `mtime(path) < ref_time`.

`ref` may be:
- `AbstractString`: an existing reference path (its mtime is used)
- `Date`, `DateTime`
- `Real`: Unix epoch seconds
"""
function V_file_older_than(ref)
    t_ref = try
        _to_epoch_seconds(ref)
    catch
        return ValidatorSpec("V_file_older_than", "Reference for older-than check is invalid", _ -> false)
    end

    msg = "File modification time must be older than reference"
    return ValidatorSpec(
        "V_file_older_than",
        msg,
        x -> begin
            p = String(x)
            isfile(p) || return false
            try
                mtime(p) < t_ref
            catch
                false
            end
        end
    )
end
