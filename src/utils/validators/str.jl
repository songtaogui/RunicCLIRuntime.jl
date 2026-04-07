"""
    V_str_len_min(n)

Return a validator that checks `length(x) >= n`.
"""
V_str_len_min(n::Int) = x -> length(x) >= n

"""
    V_str_len_max(n)

Return a validator that checks `length(x) <= n`.
"""
V_str_len_max(n::Int) = x -> length(x) <= n

"""
    V_str_len_eq(n)

Return a validator that checks `length(x) == n`.
"""
V_str_len_eq(n::Int) = x -> length(x) == n

"""
    V_str_len_range(lo, hi)

Return a validator that checks `lo <= length(x) <= hi`.
"""
V_str_len_range(lo::Int, hi::Int) = x -> lo <= length(x) <= hi

"""
    V_str_prefix(prefix)

Return a validator that checks `startswith(String(x), prefix)`.
"""
V_str_prefix(prefix::AbstractString) = x -> startswith(String(x), prefix)

"""
    V_str_suffix(suffix)

Return a validator that checks `endswith(String(x), suffix)`.
"""
V_str_suffix(suffix::AbstractString) = x -> endswith(String(x), suffix)

"""
    V_str_contains(substr)

Return a validator that checks `occursin(substr, String(x))`.
"""
V_str_contains(substr::AbstractString) = x -> occursin(substr, String(x))

"""
    V_str_substrof(pstr)

Return a validator that checks whether `String(x)` is a substring of `pstr`.
"""
V_str_substrof(pstr::AbstractString) = x -> occursin(String(x), String(pstr))

"""
    V_str_regex(re)

Return a validator that checks `occursin(re, String(x))`.
"""
V_str_regex(re::Regex) = x -> occursin(re, String(x))

"""
    V_str_nonempty()

Return a validator that checks whether `String(x)` is not empty.
"""
V_str_nonempty() = x -> !isempty(String(x))

"""
    V_str_empty()

Return a validator that checks whether `String(x)` is empty.
"""
V_str_empty() = x -> isempty(String(x))

"""
    V_str_ascii()

Return a validator that checks whether all characters are ASCII.
"""
V_str_ascii() = x -> isascii(String(x))

"""
    V_str_printable()

Return a validator that checks whether all characters are printable ASCII
(ASCII code points 0x20..0x7E).
"""
V_str_printable() = x -> begin
    s = String(x)
    all(c -> UInt32(c) >= 0x20 && UInt32(c) <= 0x7e, s)
end

"""
    V_str_nowhitespace()

Return a validator that checks whether `String(x)` contains no whitespace.
"""
V_str_nowhitespace() = x -> !any(isspace, String(x))

"""
    V_str_url()

Return a validator for a simple URL format check.
"""
V_str_url() = x -> startswith(lowercase(String(x)), "http://") || startswith(lowercase(String(x)), "https://")

"""
    V_str_email()

Return a validator for a simple email format check.
"""
V_str_email() = x -> occursin(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", String(x))

"""
    V_str_uuid()

Return a validator for a simple UUID format check (8-4-4-4-12 hex).
"""
V_str_uuid() = x -> occursin(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", String(x))

"""
    V_str_lc()

Return a validator that checks whether `String(x)` is all lowercase.
"""
V_str_lc() = x -> begin
    s = String(x)
    s == lowercase(s)
end

"""
    V_str_uc()

Return a validator that checks whether `String(x)` is all uppercase.
"""
V_str_uc() = x -> begin
    s = String(x)
    s == uppercase(s)
end

"""
    V_str_trimmed()

Return a validator that checks whether `String(x)` has no leading/trailing whitespace.
"""
V_str_trimmed() = x -> begin
    s = String(x)
    s == strip(s)
end
