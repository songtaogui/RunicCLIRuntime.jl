#FILEPATH: validators/str.jl

"""
    V_str_len_min(n)

Return a ValidatorSpec that checks `length(x) >= n`.
"""
V_str_len_min(n::Int) = ValidatorSpec("V_str_len_min", "Length should be >= " * string(n), x -> length(x) >= n)

"""
    V_str_len_max(n)

Return a ValidatorSpec that checks `length(x) <= n`.
"""
V_str_len_max(n::Int) = ValidatorSpec("V_str_len_max", "Length should be <= " * string(n), x -> length(x) <= n)

"""
    V_str_len_eq(n)

Return a ValidatorSpec that checks `length(x) == n`.
"""
V_str_len_eq(n::Int) = ValidatorSpec("V_str_len_eq", "Length should be exactly " * string(n), x -> length(x) == n)

"""
    V_str_len_range(lo, hi)

Return a ValidatorSpec that checks `lo <= length(x) <= hi`.
"""
V_str_len_range(lo::Int, hi::Int) = ValidatorSpec(
    "V_str_len_range",
    "Length should be in range [" * string(lo) * ", " * string(hi) * "]",
    x -> lo <= length(x) <= hi
)

"""
    V_str_prefix(prefix)

Return a ValidatorSpec that checks `startswith(String(x), prefix)`.
"""
V_str_prefix(prefix::AbstractString) = ValidatorSpec(
    "V_str_prefix",
    "Should start with " * repr(String(prefix)),
    x -> startswith(String(x), prefix)
)

"""
    V_str_suffix(suffix)

Return a ValidatorSpec that checks `endswith(String(x), suffix)`.
"""
V_str_suffix(suffix::AbstractString) = ValidatorSpec(
    "V_str_suffix",
    "Should end with " * repr(String(suffix)),
    x -> endswith(String(x), suffix)
)

"""
    V_str_contains(substr)

Return a ValidatorSpec that checks `occursin(substr, String(x))`.
"""
V_str_contains(substr::AbstractString) = ValidatorSpec(
    "V_str_contains",
    "Should contain " * repr(String(substr)),
    x -> occursin(substr, String(x))
)

"""
    V_str_substrof(pstr)

Return a ValidatorSpec that checks whether `String(x)` is a substring of `pstr`.
"""
V_str_substrof(pstr::AbstractString) = ValidatorSpec(
    "V_str_substrof",
    "Should be a substring of " * repr(String(pstr)),
    x -> occursin(String(x), String(pstr))
)

"""
    V_str_regex(re)

Return a ValidatorSpec that checks `occursin(re, String(x))`.
"""
V_str_regex(re::Regex) = ValidatorSpec("V_str_regex", "Should match regex " * repr(re), x -> occursin(re, String(x)))

"""
    V_str_nonempty()

Return a ValidatorSpec that checks whether `String(x)` is not empty.
"""
V_str_nonempty() = ValidatorSpec("V_str_nonempty", "Should be non-empty", x -> !isempty(String(x)))

"""
    V_str_empty()

Return a ValidatorSpec that checks whether `String(x)` is empty.
"""
V_str_empty() = ValidatorSpec("V_str_empty", "Should be empty", x -> isempty(String(x)))

"""
    V_str_ascii()

Return a ValidatorSpec that checks whether all characters are ASCII.
"""
V_str_ascii() = ValidatorSpec("V_str_ascii", "Should contain only ASCII characters", x -> isascii(String(x)))

"""
    V_str_printable()

Return a ValidatorSpec that checks whether all characters are printable ASCII
(ASCII code points 0x20..0x7E).
"""
V_str_printable() = ValidatorSpec(
    "V_str_printable",
    "Should contain only printable ASCII characters",
    x -> begin
        s = String(x)
        all(c -> UInt32(c) >= 0x20 && UInt32(c) <= 0x7e, s)
    end
)

"""
    V_str_nowhitespace()

Return a ValidatorSpec that checks whether `String(x)` contains no whitespace.
"""
V_str_nowhitespace() = ValidatorSpec("V_str_nowhitespace", "Should not contain whitespace", x -> !any(isspace, String(x)))

"""
    V_str_url()

Return a ValidatorSpec for a simple URL format check.
"""
V_str_url() = ValidatorSpec(
    "V_str_url",
    "Should be an HTTP or HTTPS URL",
    x -> startswith(lowercase(String(x)), "http://") || startswith(lowercase(String(x)), "https://")
)

"""
    V_str_email()

Return a ValidatorSpec for a simple email format check.
"""
V_str_email() = ValidatorSpec(
    "V_str_email",
    "Should be a valid email address",
    x -> occursin(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", String(x))
)

"""
    V_str_uuid()

Return a ValidatorSpec for a simple UUID format check (8-4-4-4-12 hex).
"""
V_str_uuid() = ValidatorSpec(
    "V_str_uuid",
    "Should be a valid UUID",
    x -> occursin(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", String(x))
)

"""
    V_str_lc()

Return a ValidatorSpec that checks whether `String(x)` is all lowercase.
"""
V_str_lc() = ValidatorSpec(
    "V_str_lc",
    "Should be lowercase",
    x -> begin
        s = String(x)
        s == lowercase(s)
    end
)

"""
    V_str_uc()

Return a ValidatorSpec that checks whether `String(x)` is all uppercase.
"""
V_str_uc() = ValidatorSpec(
    "V_str_uc",
    "Should be uppercase",
    x -> begin
        s = String(x)
        s == uppercase(s)
    end
)

"""
    V_str_trimmed()

Return a ValidatorSpec that checks whether `String(x)` has no leading/trailing whitespace.
"""
V_str_trimmed() = ValidatorSpec(
    "V_str_trimmed",
    "Should not have leading or trailing whitespace",
    x -> begin
        s = String(x)
        s == strip(s)
    end
)
