module RunicCLIRuntime

using TextWrap
using Base: @kwdef
using TOML

export ArgParseError, ArgHelpRequested, ArgHelpTemplate
export ArgDef, SubcommandDef, CliDef
export ArgRequiresDef, ArgConflictsDef
export ArgKind, AK_FLAG, AK_COUNT, AK_OPTION, AK_OPTION_MULTI, AK_POS_REQUIRED, AK_POS_OPTIONAL, AK_POS_REST

export HelpStyle, HELP_PLAIN, HELP_COLORED
export HelpLabelStyle, HLS_HIDDEN, HLS_PLAIN, HLS_BOLD, HLS_COLORED
export HelpTheme, HelpFormatOptions, HelpTemplateOptions, build_help_template

export parse_cli, run_cli, render_help, default_help_template, colored_help_template
export load_config_file, merge_cli_sources, generate_completion
export generate_default_config, save_default_config

export v_min, v_max, v_range, v_oneof, v_include, v_exclude
export v_length, v_prefix, v_suffix, v_regex
export v_exists, v_isfile, v_isdir, v_readable, v_writable
export v_and, v_or

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
