function help_usage_fallback(def::CliDef, path::String)
    cmd = isempty(path) ? def.cmd_name : path
    parts = String[cmd]

    has_opts = any(a -> a.kind in (AK_FLAG, AK_COUNT, AK_OPTION, AK_OPTION_MULTI), def.args)
    has_pos = any(a -> a.kind in (AK_POS_REQUIRED, AK_POS_OPTIONAL, AK_POS_REST), def.args)
    has_sub = !isempty(def.subcommands)

    has_opts && push!(parts, "[OPTIONS]")
    has_sub && push!(parts, "[SUBCOMMAND]")
    has_pos && push!(parts, "[ARGS...]")

    return join(parts, " ")
end

function type_text(a::ArgDef, opts::HelpFormatOptions)
    if a.kind == AK_FLAG
        return "Bool"
    elseif a.kind == AK_COUNT
        return "Int"
    else
        return string(opts.type_formatter(a.T))
    end
end

function metavar_text(a::ArgDef, opts::HelpFormatOptions)
    Ttxt = type_text(a, opts)
    l, r = opts.metavar_brackets

    if a.kind == AK_POS_REST
        return string(l, Ttxt, "...", r)
    elseif a.kind in (AK_OPTION, AK_OPTION_MULTI, AK_POS_REQUIRED, AK_POS_OPTIONAL)
        return string(l, Ttxt, r)
    else
        return ""
    end
end

function item_style_for_arg(a::ArgDef, theme::HelpTheme, opts::HelpFormatOptions)
    if !opts.emphasize_item_by_kind
        return theme.item_name
    end
    if a.kind == AK_OPTION && a.required
        return theme.item_required
    elseif a.kind == AK_POS_REQUIRED
        return theme.item_required
    elseif a.kind == AK_OPTION_MULTI || a.kind == AK_POS_REST
        return theme.item_repeated
    else
        return theme.item_optional
    end
end

function label_render(text::String, style::HelpLabelStyle, color::String, theme::HelpTheme, color_enabled::Bool)
    if style == HLS_HIDDEN
        return ""
    elseif style == HLS_PLAIN
        return text
    elseif style == HLS_BOLD
        return styled_text(text, theme.bold, color_enabled, theme.reset)
    else
        return styled_text(text, color, color_enabled, theme.reset)
    end
end

function format_positional_spec(a::ArgDef, opts::HelpFormatOptions, theme::HelpTheme, color_enabled::Bool)
    n = isempty(a.help_name) ? String(a.name) : a.help_name
    mv = metavar_text(a, opts)

    if a.kind == AK_POS_REST
        return string(n, " ", mv)
    elseif a.kind in (AK_POS_REQUIRED, AK_POS_OPTIONAL)
        return isempty(mv) ? n : string(n, " ", mv)
    else
        return n
    end
end

function format_option_spec(a::ArgDef, opts::HelpFormatOptions, theme::HelpTheme, color_enabled::Bool)
    names = join(a.flags, ", ")

    if !opts.show_option_metavar
        return names
    end

    if a.kind in (AK_OPTION, AK_OPTION_MULTI)
        mv = metavar_text(a, opts)
        return isempty(mv) ? names : string(names, " ", mv)
    end

    return names
end

function status_parts(a::ArgDef, opts::HelpFormatOptions, theme::HelpTheme, color_enabled::Bool)
    parts = String[]

    if opts.show_status_labels
        if (a.kind == AK_OPTION && a.required) || a.kind == AK_POS_REQUIRED
            lbl = label_render("Required", opts.required_style, theme.required_mark, theme, color_enabled)
            isempty(lbl) || push!(parts, lbl)
        end
    end

    return parts
end

function meta_parts(a::ArgDef, opts::HelpFormatOptions, theme::HelpTheme, color_enabled::Bool)
    parts = String[]

    append!(parts, status_parts(a, opts, theme, color_enabled))

    if a.kind == AK_COUNT && opts.count_style != HLS_HIDDEN && !isempty(a.flags)
        ctxt = label_render("Count occurrences", opts.count_style, theme.meta, theme, color_enabled)
        isempty(ctxt) || push!(parts, ctxt)
    end

    if getfield(a, :env) !== nothing
        push!(parts, "Env: " * String(a.env))
    end

    if ((a.kind == AK_OPTION && !a.required && a.default !== nothing) || a.kind == AK_POS_OPTIONAL) && a.default !== nothing
        push!(parts, "Default: " * String(opts.default_formatter(a.default)))
    end

    if getfield(a, :fallback) !== nothing
        push!(parts, "Fallback: " * String(a.fallback))
    end

    return parts
end

function build_inline_description(a::ArgDef, opts::HelpFormatOptions, theme::HelpTheme, color_enabled::Bool)
    segs = String[]

    meta = meta_parts(a, opts, theme, color_enabled)
    if !isempty(meta)
        push!(segs, join(meta, ". ") * ".")
    end

    if !isempty(a.help)
        push!(segs, a.help)
    end

    return join(segs, " ")
end

function compute_item_column_width(args::Vector{ArgDef}, specs::Vector{String}, opts::HelpFormatOptions)
    isempty(specs) && return opts.item_column_width

    w = maximum(textwidth(s) for s in specs)
    w = max(w, opts.item_column_width_min)
    w = min(w, opts.item_column_width_max)
    return w
end

function render_item_inline(
    io::IO,
    a::ArgDef,
    spec::String,
    spec_width::Int,
    opts::HelpFormatOptions,
    theme::HelpTheme,
    color_enabled::Bool,
    wrap_width::Int
)
    left_pad = " "^opts.indent_item
    desc = build_inline_description(a, opts, theme, color_enabled)

    spec_cell = rpad_display(spec, spec_width)
    gap = " "^opts.item_desc_gap

    desc_width = wrap_width > 0 ? max(10, wrap_width - opts.indent_item - spec_width - opts.item_desc_gap) : 0

    raw_parts = split(desc, '\n')
    desc_lines = String[]

    for p in raw_parts
        if isempty(p)
            push!(desc_lines, "")
            continue
        end

        if desc_width <= 0
            push!(desc_lines, p)
            continue
        end

        m = match(r"^(\s*)", p)
        lead = m === nothing ? "" : m.captures[1]
        rest = p[length(lead)+1:end]

        bullet_m = match(r"^([-*+]\s+)", rest)
        if bullet_m === nothing
            prefix = lead
        else
            prefix = lead * bullet_m.captures[1]
        end

        prefix_w = textwidth(prefix)

        wio = IOBuffer()
        println_wrapped(
            wio,
            p;
            initial_indent = 0,
            subsequent_indent = prefix_w,
            width = desc_width
        )
        wrapped = split(chomp(String(take!(wio))), '\n')
        append!(desc_lines, isempty(wrapped) ? [""] : wrapped)
    end

    isempty(desc_lines) && (desc_lines = [""])

    print(io, left_pad)
    paint(io, spec_cell, item_style_for_arg(a, theme, opts), color_enabled, theme.reset)

    if !isempty(desc_lines[1])
        print(io, gap)
        paint(io, desc_lines[1], theme.inline_description, color_enabled, theme.reset)
    end
    println(io)

    if length(desc_lines) > 1
        cont_prefix = left_pad * " "^spec_width * gap
        for desc_line in desc_lines[2:end]
            print(io, cont_prefix)
            if !isempty(desc_line)
                paint(io, desc_line, theme.inline_description, color_enabled, theme.reset)
            end
            println(io)
        end
    end
end

function arg_group_membership(def::CliDef)
    belongs = Dict{Symbol,String}()
    for g in def.arg_groups
        for s in g.members
            belongs[s] = g.title
        end
    end
    return belongs
end

function relation_members_text(members::Vector{Symbol})::String
    return join(string.(members), ", ")
end

function relation_def_string(rd::ArgRelationDef)::String
    if !isempty(rd.help)
        return rd.help
    end

    if !isempty(rd.members)
        if rd.kind in (:mutex, :mutually_exclusive, :exclusive, :xor)
            return "Mutually exclusive: " * relation_members_text(rd.members)
        elseif rd.kind in (:at_least_one, :oneof, :anyof, :mutually_inclusive)
            return "At least one required: " * relation_members_text(rd.members)
        else
            return string(rd.kind, "(", relation_members_text(rd.members), ")")
        end
    end

    lhs = rd.lhs === nothing ? "<?>" : relation_expr_string(rd.lhs)
    rhs = rd.rhs === nothing ? "<?>" : relation_expr_string(rd.rhs)

    if rd.kind in (:require, :requires)
        return string(lhs, " requires ", rhs)
    elseif rd.kind in (:conflict, :conflicts)
        return string(lhs, " conflicts with ", rhs)
    elseif rd.kind in (:imply, :implies)
        return string(lhs, " implies ", rhs)
    else
        return string(rd.kind, ": ", lhs, " -> ", rhs)
    end
end
