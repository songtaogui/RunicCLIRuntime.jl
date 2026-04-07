#FILEPATH: utils/validators/bio_index.jl

V_file_bioidx_fa() = V_file_has_index(suffixes=[".fai"], mode=:all)

V_file_bioidx_gvcf() = V_file_has_index(suffixes=[".tbi", ".csi"], mode=:any)

V_file_bioidx_xam() = V_file_has_index(suffixes=[".bai", ".csi"], mode=:any)

V_file_bioidx_csi() = V_file_has_index(suffixes=[".csi"], mode=:all)

function V_file_bioidx_blastdb()
    exts = [".pin", ".phr", ".psq", ".nin", ".nhr", ".nsq"]
    V_file_has_index(replace_ext=exts, mode=:any, strip_all_ext=true)
end

function V_file_bioidx_hisat2()
    exts = [".1.ht2", ".2.ht2", ".3.ht2", ".4.ht2", ".5.ht2", ".6.ht2", ".7.ht2", ".8.ht2"]
    V_file_has_index(replace_ext=exts, mode=:all, strip_all_ext=true)
end

function V_file_bioidx_star()
    needed = ["Genome", "SA", "SAindex"]
    return x -> begin
        d = String(x)
        isdir(d) || return false
        all(f -> isfile(joinpath(d, f)), needed)
    end
end

V_file_bioidx_diamond() = V_file_has_index(replace_ext=[".dmnd"], mode=:all, strip_all_ext=true)

function V_file_bioidx_bowtie2()
    exts = [".1.bt2", ".2.bt2", ".3.bt2", ".4.bt2", ".rev.1.bt2", ".rev.2.bt2"]
    V_file_has_index(replace_ext=exts, mode=:all, strip_all_ext=true)
end

function V_file_bioidx_bwa()
    V_file_has_index(suffixes=[".amb", ".ann", ".bwt", ".pac", ".sa"], mode=:all)
end

function V_file_bioidx_salmon()
    return x -> begin
        d = String(x)
        isdir(d) || return false
        isfile(joinpath(d, "hash.bin")) && isfile(joinpath(d, "versionInfo.json"))
    end
end

V_file_bioidx_kallisto() = V_file_has_index(replace_ext=[".idx"], mode=:all, strip_all_ext=true)
#FILEPATH: utils/validators/cmd.jl
V_cmd_inpath() = x -> Sys.which(String(x)) !== nothing

V_cmd_executable() = x -> begin
    p = Sys.which(String(x))
    p !== nothing && isfile(p) && isexecutable(p)
end

function _cmd_parse_version(s::AbstractString)
    t = strip(s)
    try
        return VersionNumber(t)
    catch
        m = match(r"(\d+(?:\.\d+){0,3})", t)
        m === nothing && return nothing
        try
            return VersionNumber(m.captures[1])
        catch
            return nothing
        end
    end
end

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

function _cmd_get_version(cmdname::AbstractString; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})")
    cpath = Sys.which(cmdname)
    cpath === nothing && return nothing
    args = isempty(strip(vcmd)) ? String[] : split(vcmd)
    full = `$(cpath) $(args...)`
    out = try
        read(full, String)
    catch
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

V_cmd_version_ge(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(>=, v; vcmd=vcmd, vreg=vreg)

V_cmd_version_le(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(<=, v; vcmd=vcmd, vreg=vreg)

V_cmd_version_eq(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(==, v; vcmd=vcmd, vreg=vreg)

V_cmd_version_gt(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(>, v; vcmd=vcmd, vreg=vreg)

V_cmd_version_lt(v; vcmd::AbstractString="--version", vreg::Regex=r"(\d+(?:\.\d+){0,3})") =
    _cmd_version_cmp(<, v; vcmd=vcmd, vreg=vreg)
#FILEPATH: utils/validators/file_index.jl
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

V_file_has_any_index(; kwargs...) = V_file_has_index(; mode=:any, kwargs...)

V_file_has_all_indexes(; kwargs...) = V_file_has_index(; mode=:all, kwargs...)

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
#FILEPATH: utils/validators/flow.jl

function V_AND(fs::Function...)
    return x -> begin
        for f in fs
            f(x) || return false
        end
        true
    end
end

function V_OR(fs::Function...)
    return x -> begin
        for f in fs
            f(x) && return true
        end
        false
    end
end

V_NOT(f::Function) = x -> !f(x)
#FILEPATH: utils/validators/num_any.jl
V_num_min(minv) = x -> x >= minv

V_num_max(maxv) = x -> x <= maxv

V_num_range(lo, hi; closed::Bool=true) = closed ? (x -> lo <= x <= hi) : (x -> lo < x < hi)

V_num_positive() = x -> x > 0

V_num_nonnegative() = x -> x >= 0

V_num_negative() = x -> x < 0

V_num_nonpositive() = x -> x <= 0

V_num_nonzero() = x -> x != 0

V_num_finite() = x -> x isa Number && isfinite(x)

V_num_notnan() = x -> x isa Number && !isnan(x)

V_num_real() = x -> x isa Real

V_num_int() = x -> x isa Integer || (x isa Number && isinteger(x))

V_num_integer() = V_num_int()

V_num_float() = x -> x isa AbstractFloat

V_num_percentage() = V_num_range(0, 100; closed=true)

V_num_gt(v) = x -> x > v

V_num_ge(v) = x -> x >= v

V_num_lt(v) = x -> x < v

V_num_le(v) = x -> x <= v

function V_any_oneof(xs)
    s = Set(xs)
    return x -> x in s
end

V_any_in(xs) = V_any_oneof(xs)

function V_any_notin(xs)
    s = Set(xs)
    return x -> !(x in s)
end

V_any_equal(v) = x -> x == v

V_any_notequal(v) = x -> x != v
#FILEPATH: utils/validators/path_file_dir.jl

V_path_exists() = x -> ispath(String(x))

V_path_absent() = x -> !ispath(String(x))

V_path_isfile() = x -> isfile(String(x))

V_path_isdir() = x -> isdir(String(x))

V_path_readable() = x -> isreadable(String(x))

V_path_writable() = x -> iswritable(String(x))

V_path_executable() = x -> isexecutable(String(x))

V_path_symlink() = x -> islink(String(x))

V_path_real() = x -> begin
    p = String(x)
    ispath(p) || return false
    try
        realpath(p) == p
    catch
        false
    end
end

V_path_absolute() = x -> isabspath(String(x))

V_path_relative() = x -> !isabspath(String(x))

V_path_nottraversal() = x -> begin
    p = normpath(String(x))
    parts = splitpath(p)
    !(".." in parts)
end

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

function V_path_ext(ext::AbstractString)
    want = startswith(ext, ".") ? lowercase(String(ext)) : "." * lowercase(String(ext))
    return x -> lowercase(splitext(String(x))[2]) == want
end

V_file_readable() = V_AND(V_path_exists(), V_path_isfile(), V_path_readable())

V_file_writable() = V_AND(V_path_isfile(), V_path_writable())

V_file_creatable() = x -> begin
    p = String(x)
    d = dirname(abspath(p))
    isdir(d) && iswritable(d)
end

V_file_nonempty() = x -> begin
    p = String(x)
    isfile(p) || return false
    try
        filesize(p) > 0
    catch
        false
    end
end

V_dir_readable() = V_AND(V_path_exists(), V_path_isdir(), V_path_readable())

V_dir_writable() = V_AND(V_path_isdir(), V_path_writable())
#FILEPATH: utils/validators/str.jl
V_str_len_min(n::Int) = x -> length(x) >= n

V_str_len_max(n::Int) = x -> length(x) <= n

V_str_len_eq(n::Int) = x -> length(x) == n

V_str_len_range(lo::Int, hi::Int) = x -> lo <= length(x) <= hi

V_str_prefix(prefix::AbstractString) = x -> startswith(String(x), prefix)

V_str_suffix(suffix::AbstractString) = x -> endswith(String(x), suffix)

V_str_contains(substr::AbstractString) = x -> occursin(substr, String(x))

V_str_substrof(pstr::AbstractString) = x -> occursin(String(x), String(pstr))

V_str_regex(re::Regex) = x -> occursin(re, String(x))

V_str_nonempty() = x -> !isempty(String(x))

V_str_empty() = x -> isempty(String(x))

V_str_ascii() = x -> isascii(String(x))

V_str_printable() = x -> begin
    s = String(x)
    all(c -> UInt32(c) >= 0x20 && UInt32(c) <= 0x7e, s)
end

V_str_nowhitespace() = x -> !any(isspace, String(x))

V_str_url() = x -> beginswith(lowercase(String(x)), "http://") || beginswith(lowercase(String(x)), "https://")

V_str_email() = x -> occursin(r"^[^@\s]+@[^@\s]+\.[^@\s]+$", String(x))

V_str_uuid() = x -> occursin(r"^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$", String(x))

V_str_lc() = x -> begin
    s = String(x)
    s == lowercase(s)
end

V_str_uc() = x -> begin
    s = String(x)
    s == uppercase(s)
end

V_str_trimmed() = x -> begin
    s = String(x)
    s == strip(s)
end
#FILEPATH: utils/validators.jl
include("validators/flow.jl")
include("validators/num_any.jl")
include("validators/str.jl")
include("validators/path_file_dir.jl")
include("validators/cmd.jl")
include("validators/file_index.jl")
include("validators/bio_index.jl")
