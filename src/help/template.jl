"""
    build_help_template(options::HelpTemplateOptions)

Build or resolve an [`ArgHelpTemplate`](@ref) from a [`HelpTemplateOptions`](@ref)
configuration object.

This is the central entry point for help-template resolution.

Behavior:

- if `options.template !== nothing`, that template is returned unchanged;
- otherwise, a new template is constructed from `options.style`,
  `options.theme`, `options.format`, and any non-`nothing` override fields.

For a complete description of supported fields and resolution behavior, see
[`HelpTemplateOptions`](@ref).

# Example

```julia
help = HelpTemplateOptions(
    style = HELP_COLORED,
    wrap_width = 100
)

tpl = build_help_template(help)
```

# See also

[`HelpTemplateOptions`](@ref), [`default_help_template`](@ref),
[`colored_help_template`](@ref), [`render_help`](@ref)
"""
function build_help_template(options::HelpTemplateOptions)
    options.template !== nothing && return options.template

    format = options.format
    theme = options.theme
    style = options.style

    wd = isnothing(options.wrap_description) ? format.wrap_description : options.wrap_description
    we = isnothing(options.wrap_epilog) ? format.wrap_epilog : options.wrap_epilog

    ww = isnothing(options.wrap_width) ? format.wrap_width : options.wrap_width

    opts = HelpFormatOptions(
        indent_item = isnothing(options.indent_item) ? format.indent_item : options.indent_item,
        indent_text = isnothing(options.indent_text) ? format.indent_text : options.indent_text,
        section_gap = isnothing(options.section_gap) ? format.section_gap : options.section_gap,

        item_column_width = isnothing(options.item_column_width) ? format.item_column_width : options.item_column_width,
        item_column_width_min = format.item_column_width_min,
        item_column_width_max = format.item_column_width_max,
        subcommand_col_gap = format.subcommand_col_gap,
        item_desc_gap = format.item_desc_gap,

        title_usage = isnothing(options.title_usage) ? format.title_usage : options.title_usage,
        title_version = isnothing(options.title_version) ? format.title_version : options.title_version,
        title_positionals = isnothing(options.title_positionals) ? format.title_positionals : options.title_positionals,
        title_options = isnothing(options.title_options) ? format.title_options : options.title_options,
        title_subcommands = isnothing(options.title_subcommands) ? format.title_subcommands : options.title_subcommands,
        title_constraints = isnothing(options.title_constraints) ? format.title_constraints : options.title_constraints,

        required_style = isnothing(options.required_style) ? format.required_style : options.required_style,
        default_style = isnothing(options.default_style) ? format.default_style : options.default_style,
        type_style = isnothing(options.type_style) ? format.type_style : options.type_style,
        count_style = isnothing(options.count_style) ? format.count_style : options.count_style,

        show_option_metavar = isnothing(options.show_option_metavar) ? format.show_option_metavar : options.show_option_metavar,
        show_status_labels = isnothing(options.show_status_labels) ? format.show_status_labels : options.show_status_labels,
        show_constraints = isnothing(options.show_constraints) ? format.show_constraints : options.show_constraints,
        show_relations = isnothing(options.show_relations) ? format.show_relations : options.show_relations,

        metavar_brackets = format.metavar_brackets,
        emphasize_item_by_kind = isnothing(options.emphasize_item_by_kind) ? format.emphasize_item_by_kind : options.emphasize_item_by_kind,

        wrap_description = wd,
        wrap_epilog = we,
        wrap_width = ww,

        type_formatter = format.type_formatter,
        default_formatter = format.default_formatter
    )

    color_enabled = style == HELP_COLORED

    return ArgHelpTemplate(
        header = (io, def, path)->begin
            local _name = isempty(path) ? def.cmd_name : path
            if isempty(_name)
                _name = def.cmd_name
            end
            if isempty(_name)
                _name = "CLI"
            end

            local _wrapw = effective_wrap_width(io, opts.wrap_width)

            if isempty(def.version)
                paint(io, _name, theme.usage_title, color_enabled, theme.reset)
                println(io)
            else
                local vlabel = isempty(opts.title_version) ? "" : opts.title_version
                paint(io, string(_name, " (", vlabel, def.version, ")"), theme.usage_title, color_enabled, theme.reset)
                println(io)
            end

            if !isempty(def.description)
                if opts.wrap_description
                    print_wrapped(io, def.description, initial_indent=0, subsequent_indent=0, width=_wrapw)
                else
                    println(io, def.description)
                end
            end

            println(io)
        end,

        section_usage = (io, def, path)->begin
            local u = isempty(def.usage) ? help_usage_fallback(def, path) : def.usage
            paint(io, opts.title_usage, theme.section_title, color_enabled, theme.reset)
            println(io)
            println(io, u)
            opts.section_gap && println(io)
        end,

        section_version = (io, def, path)->nothing,

        section_description = (io, def, path)->nothing,

        section_positionals = (io, def, path)->begin
            grouped = arg_group_membership(def)
            pos = filter(a -> a.kind in (AK_POS_REQUIRED, AK_POS_OPTIONAL, AK_POS_REST) && !haskey(grouped, a.name), def.args)
            isempty(pos) && return

            paint(io, opts.title_positionals, theme.section_title, color_enabled, theme.reset)
            println(io)

            specs = [format_positional_spec(a, opts, theme, color_enabled) for a in pos]
            spec_width = compute_item_column_width(pos, specs, opts)
            local _wrapw = effective_wrap_width(io, opts.wrap_width)

            for (a, spec) in zip(pos, specs)
                render_item_inline(io, a, spec, spec_width, opts, theme, color_enabled, _wrapw)
            end
            opts.section_gap && println(io)
        end,

        section_options = (io, def, path)->begin
            grouped = arg_group_membership(def)
            opt = filter(a -> a.kind in (AK_FLAG, AK_COUNT, AK_OPTION, AK_OPTION_MULTI) && !haskey(grouped, a.name), def.args)

            auto_help = ArgDef(
                kind = AK_FLAG,
                name = :help,
                T = Bool,
                flags = ["-h", "--help"],
                default = false,
                help = "Show this help message and exit."
            )

            auto_version = ArgDef(
                kind = AK_FLAG,
                name = :version,
                T = Bool,
                flags = ["-V", "--version"],
                default = false,
                help = "Show version information and exit."
            )

            push!(opt, auto_help)
            if !isempty(def.version)
                push!(opt, auto_version)
            end

            isempty(opt) && return

            paint(io, opts.title_options, theme.section_title, color_enabled, theme.reset)
            println(io)

            specs = [format_option_spec(a, opts, theme, color_enabled) for a in opt]
            spec_width = compute_item_column_width(opt, specs, opts)
            local _wrapw = effective_wrap_width(io, opts.wrap_width)

            for (a, spec) in zip(opt, specs)
                render_item_inline(io, a, spec, spec_width, opts, theme, color_enabled, _wrapw)
            end
            opts.section_gap && println(io)
        end,

        section_subcommands = (io, def, path)->begin
            if !isempty(def.arg_groups)
                for g in def.arg_groups
                    members = ArgDef[a for a in def.args if a.name in Set(g.members)]
                    isempty(members) && continue

                    paint(io, g.title * ":", theme.section_title, color_enabled, theme.reset)
                    println(io)

                    specs = [
                        a.kind in (AK_FLAG, AK_COUNT, AK_OPTION, AK_OPTION_MULTI) ?
                        format_option_spec(a, opts, theme, color_enabled) :
                        format_positional_spec(a, opts, theme, color_enabled)
                        for a in members
                    ]
                    spec_width = compute_item_column_width(members, specs, opts)
                    local _wrapw = effective_wrap_width(io, opts.wrap_width)
                    for (a, spec) in zip(members, specs)
                        render_item_inline(io, a, spec, spec_width, opts, theme, color_enabled, _wrapw)
                    end
                    opts.section_gap && println(io)
                end
            end

            isempty(def.subcommands) && return
            paint(io, opts.title_subcommands, theme.section_title, color_enabled, theme.reset)
            println(io)

            w = maximum(textwidth(s.name) for s in def.subcommands)
            for s in def.subcommands
                print(io, " "^opts.indent_item)
                name_cell = rpad_display(s.name, w + opts.subcommand_col_gap)
                paint(io, name_cell, theme.item_name, color_enabled, theme.reset)
                println(io, s.description)
            end
            opts.section_gap && println(io)
        end,

        section_epilog = (io, def, path)->begin
            local _wrapw = effective_wrap_width(io, opts.wrap_width)

            if opts.show_constraints && opts.show_relations && !isempty(def.relations)
                paint(io, opts.title_constraints, theme.section_title, color_enabled, theme.reset)
                println(io)

                for rd in def.relations
                    local line = relation_def_string(rd)
                    if opts.wrap_description
                        print_wrapped(io, line, initial_indent=opts.indent_item, subsequent_indent=opts.indent_text, width=_wrapw)
                    else
                        println(io, " "^opts.indent_item * line)
                    end
                end

                opts.section_gap && println(io)
            end

            isempty(def.epilog) && return
            if opts.wrap_epilog
                print_wrapped(io, def.epilog, initial_indent=0, subsequent_indent=0, width=_wrapw)
            else
                println(io, def.epilog)
            end
            opts.section_gap && println(io)
        end
    )
end


"""
    build_help_template(; kwargs...)

Convenience wrapper that constructs a [`HelpTemplateOptions`](@ref) from keyword
arguments and then calls [`build_help_template(options::HelpTemplateOptions)`](@ref).

This is useful when you want to build a help template inline without explicitly
constructing a `HelpTemplateOptions` object first.

For the full set of supported keywords and their meanings, see
[`HelpTemplateOptions`](@ref).

# Example

```julia
tpl = build_help_template(
    style = HELP_COLORED,
    wrap_width = 96
)
```

# See also

[`HelpTemplateOptions`](@ref), [`build_help_template(options::HelpTemplateOptions)`](@ref)
"""
build_help_template(; kwargs...) = build_help_template(HelpTemplateOptions(; kwargs...))

"""
    default_help_template() -> ArgHelpTemplate

Construct the package's default plain help template.

This is equivalent to:

```julia
build_help_template(HelpTemplateOptions(style=HELP_PLAIN))
```

# See also

[`colored_help_template`](@ref), [`build_help_template`](@ref),
[`HelpTemplateOptions`](@ref)
"""
default_help_template() = build_help_template(HelpTemplateOptions(style=HELP_PLAIN))

"""
    colored_help_template() -> ArgHelpTemplate

Construct the package's default ANSI-colored help template.

This is equivalent to:

```julia
build_help_template(HelpTemplateOptions(style=HELP_COLORED))
```

# See also

[`default_help_template`](@ref), [`build_help_template`](@ref),
[`HelpTemplateOptions`](@ref), [`HelpTheme`](@ref)
"""
colored_help_template() = build_help_template(HelpTemplateOptions(style=HELP_COLORED))
