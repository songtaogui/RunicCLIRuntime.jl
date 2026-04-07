#FILEPATH: RunicCLIRuntime.jl
module RunicCLIRuntime

using TextWrap
using Base: @kwdef
using TOML

# ===== core/errors.jl =====
export ArgParseError, ArgHelpRequested, ArgHelpTemplate

# ===== core/types.jl =====
export ArgDef, SubcommandDef, CliDef
export ArgRequiresDef, ArgConflictsDef, ArgGroupDef
export ArgKind, AK_FLAG, AK_COUNT, AK_OPTION, AK_OPTION_MULTI, AK_POS_REQUIRED, AK_POS_OPTIONAL, AK_POS_REST
export clidef, CLIDEFREGISTRY

# ===== help/config.jl =====
export HelpStyle, HELP_PLAIN, HELP_COLORED
export HelpLabelStyle, HLS_HIDDEN, HLS_PLAIN, HLS_BOLD, HLS_COLORED
export HelpTheme, HelpFormatOptions, HelpTemplateOptions

# ===== help/template.jl =====
export build_help_template
export default_help_template, colored_help_template

# ===== help/render.jl =====
export render_help

# ===== engine/api.jl =====
export parse_cli, run_cli

# ===== source/source_merge.jl =====
export load_config_file, merge_cli_sources

# ===== utils/completion.jl =====
export generate_completion

# ===== source/config_template.jl =====
export generate_default_config, save_default_config

# ===== utils/validators.jl =====
export V_AND, V_OR, V_NOT

export V_num_min, V_num_max, V_num_range
export V_num_positive, V_num_nonnegative, V_num_negative, V_num_nonpositive
export V_num_nonzero, V_num_finite, V_num_notnan, V_num_real
export V_num_int, V_num_integer, V_num_float, V_num_percentage
export V_num_gt, V_num_ge, V_num_lt, V_num_le

export V_any_oneof, V_any_in, V_any_notin
export V_any_equal, V_any_notequal

export V_str_len_min, V_str_len_max, V_str_len_eq, V_str_len_range
export V_str_prefix, V_str_suffix, V_str_contains, V_str_substrof, V_str_regex
export V_str_nonempty, V_str_empty
export V_str_ascii, V_str_printable, V_str_nowhitespace
export V_str_url, V_str_email, V_str_uuid
export V_str_lc, V_str_uc, V_str_trimmed

export V_path_exists, V_path_absent
export V_path_isfile, V_path_isdir
export V_path_readable, V_path_writable
export V_path_ext
export V_path_real, V_path_absolute, V_path_relative, V_path_nottraversal
export V_path_executable, V_path_symlink, V_path_within
export V_file_readable, V_file_writable, V_file_creatable, V_file_nonempty
export V_dir_readable, V_dir_writable, V_dir_contains

export index_paths_for
export V_file_has_index, V_file_has_any_index, V_file_has_all_indexes, V_file_has_index_groups
export V_file_bioidx_fa, V_file_bioidx_gvcf, V_file_bioidx_xam, V_file_bioidx_csi
export V_file_bioidx_blastdb, V_file_bioidx_hisat2, V_file_bioidx_star, V_file_bioidx_diamond
export V_file_bioidx_bowtie2, V_file_bioidx_bwa, V_file_bioidx_salmon, V_file_bioidx_kallisto

export V_cmd_inpath, V_cmd_executable
export V_cmd_version_ge, V_cmd_version_le, V_cmd_version_eq, V_cmd_version_gt, V_cmd_version_lt

# Runtime core
include("core/types.jl")
include("core/errors.jl")
include("core/parser_utils.jl")

# Help system
include("help/config.jl")
include("help/utils.jl")
include("help/layout.jl")
include("help/template.jl")
include("help/render.jl")

# Runtime execution pipeline
include("engine/messages.jl")
include("engine/execution.jl")

include("parsing/tokenizer.jl")
include("parsing/option_ops.jl")

include("source/source_merge.jl")
include("source/config_template.jl")

include("utils/validators.jl")
include("utils/completion.jl")

include("engine/api.jl")

end
