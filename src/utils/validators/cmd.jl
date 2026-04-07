"""
    V_cmd_inpath()

Return a validator that checks whether command name can be found in `PATH`.
"""
V_cmd_inpath() = x -> Sys.which(String(x)) !== nothing

"""
    V_cmd_executable()

Return a validator that checks whether command name resolves to an executable file.
"""
V_cmd_executable() = x -> begin
    p = Sys.which(String(x))
    p !== nothing && isfile(p) && isexecutable(p)
end

# Internal: parse a version string to VersionNumber-like tuple fallback
function _cmd_parse_version(s::AbstractString)
    t = strip(s)
    try
        return VersionNumber(t)
    catch
        # fallback: keep digits/dots only, first chunk
        m = match(r"(\d+(?:\.\d+){0,3})", t)
        m === nothing && return nothing
        try
            return VersionNumber(m.captures[1])
        catch
            return nothing
        end
    end
end

# Internal: extract version text from command output
function _cmd_extract_version_text(out::AbstractString, vreg::Regex)
    m = match(vreg, out)
    m === nothing && return nothing
    if !isempty(m.captures)
        for c in m.captures
            c === nothing || return c
        end
    end
    return m.match
end

# Internal: run command and capture version
function _cmd_get_version(cmdname::AbstractString; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})")
    cpath = Sys.which(cmdname)
    cpath === nothing && return nothing
    args = isempty(strip(vcmd)) ? String[] : split(vcmd)
    full = `$(cpath) $(args...)`
    out = try
        read(full, String)
    catch
        # some commands print version to stderr
        try
            read(pipeline(full, stderr=IOBuffer()), String)
        catch
            return nothing
        end
    end
    vtxt = _cmd_extract_version_text(out, vreg)
    vtxt === nothing && return nothing
    return _cmd_parse_version(vtxt)
end

function _cmd_version_cmp(op::Function, v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})")
    want = try VersionNumber(string(v)) catch; return _ -> false end
    return x -> begin
        got = _cmd_get_version(String(x); vcmd=vcmd, vreg=vreg)
        got === nothing && return false
        op(got, want)
    end
end

"""
    V_cmd_version_ge(v; vcmd="--version", vreg=r"(\\d+(?:\\.\\d+){0,3})")

Return a validator that checks command version `>= v`.
"""
V_cmd_version_ge(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(>=, v; vcmd=vcmd, vreg=vreg)

"""
    V_cmd_version_le(v; vcmd="--version", vreg=r"(\\d+(?:\\.\\d+){0,3})")

Return a validator that checks command version `<= v`.
"""
V_cmd_version_le(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(<=, v; vcmd=vcmd, vreg=vreg)

"""
    V_cmd_version_eq(v; vcmd="--version", vreg=r"(\\d+(?:\\.\\d+){0,3})")

Return a validator that checks command version `== v`.
"""
V_cmd_version_eq(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(==, v; vcmd=vcmd, vreg=vreg)

"""
    V_cmd_version_gt(v; vcmd="--version", vreg=r"(\\d+(?:\\.\\d+){0,3})")

Return a validator that checks command version `> v`.
"""
V_cmd_version_gt(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(>, v; vcmd=vcmd, vreg=vreg)

"""
    V_cmd_version_lt(v; vcmd="--version", vreg=r"(\\d+(?:\\.\\d+){0,3})")

Return a validator that checks command version `< v`.
"""
V_cmd_version_lt(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(<, v; vcmd=vcmd, vreg=vreg)
