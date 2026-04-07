
"""
    V_file_bioidx_fa()

FASTA index check: `.fai` append-style.
"""
V_file_bioidx_fa() = V_file_has_index(suffixes=[".fai"], mode=:all)

"""
    V_file_bioidx_gvcf()

gVCF/VCF tabix index check: `.tbi` or `.csi`.
"""
V_file_bioidx_gvcf() = V_file_has_index(suffixes=[".tbi", ".csi"], mode=:any)

"""
    V_file_bioidx_xam()

BAM/CRAM/SAM common index check: `.bai` or `.csi`.
"""
V_file_bioidx_xam() = V_file_has_index(suffixes=[".bai", ".csi"], mode=:any)

"""
    V_file_bioidx_csi()

Generic `.csi` index check.
"""
V_file_bioidx_csi() = V_file_has_index(suffixes=[".csi"], mode=:all)

"""
    V_file_bioidx_blastdb()

BLAST database index check (common extensions, replacement-style from base name).
"""
function V_file_bioidx_blastdb()
    # A pragmatic set for protein/nucleotide db aliases
    exts = [".pin", ".phr", ".psq", ".nin", ".nhr", ".nsq"]
    V_file_has_index(replace_ext=exts, mode=:any, strip_all_ext=true)
end

"""
    V_file_bioidx_hisat2()

HISAT2 index check (`.1.ht2` ... `.8.ht2`, old style).
"""
function V_file_bioidx_hisat2()
    exts = [".1.ht2", ".2.ht2", ".3.ht2", ".4.ht2", ".5.ht2", ".6.ht2", ".7.ht2", ".8.ht2"]
    V_file_has_index(replace_ext=exts, mode=:all, strip_all_ext=true)
end

"""
    V_file_bioidx_star()

STAR index directory marker check.
This validator expects input path to be STAR genomeDir and checks key files.
"""
function V_file_bioidx_star()
    needed = ["Genome", "SA", "SAindex"]
    return x -> begin
        d = String(x)
        isdir(d) || return false
        all(f -> isfile(joinpath(d, f)), needed)
    end
end

"""
    V_file_bioidx_diamond()

DIAMOND index check (`.dmnd` replacement-style).
"""
V_file_bioidx_diamond() = V_file_has_index(replace_ext=[".dmnd"], mode=:all, strip_all_ext=true)

"""
    V_file_bioidx_bowtie2()

Bowtie2 index check (`.1.bt2`...`.4.bt2` and `.rev.1.bt2`, `.rev.2.bt2`).
"""
function V_file_bioidx_bowtie2()
    exts = [".1.bt2", ".2.bt2", ".3.bt2", ".4.bt2", ".rev.1.bt2", ".rev.2.bt2"]
    V_file_has_index(replace_ext=exts, mode=:all, strip_all_ext=true)
end

"""
    V_file_bioidx_bwa()

BWA index check (`.amb`, `.ann`, `.bwt`, `.pac`, `.sa`) append-style.
"""
function V_file_bioidx_bwa()
    V_file_has_index(suffixes=[".amb", ".ann", ".bwt", ".pac", ".sa"], mode=:all)
end

"""
    V_file_bioidx_salmon()

Salmon index directory check (expects directory with `hash.bin` and `versionInfo.json`).
"""
function V_file_bioidx_salmon()
    return x -> begin
        d = String(x)
        isdir(d) || return false
        isfile(joinpath(d, "hash.bin")) && isfile(joinpath(d, "versionInfo.json"))
    end
end

"""
    V_file_bioidx_kallisto()

Kallisto index check (`.idx` replacement-style).
"""
V_file_bioidx_kallisto() = V_file_has_index(replace_ext=[".idx"], mode=:all, strip_all_ext=true)
