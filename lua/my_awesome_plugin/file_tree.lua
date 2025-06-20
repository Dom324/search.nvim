local n = require("nui-components")
local options = require("my_awesome_plugin.config").options

local function on_select(node, component)
    local tree = component:get_tree()
    node.is_marked = not node.is_marked
    tree:render()
end

local function prepare_node(node, line, component)
    if node.is_marked then
        line:append("● ", "String")
    else
        line:append("○ ", "Comment")
    end

    local _, devicons = pcall(require, "nvim-web-devicons")
    local icon, icon_highlight = devicons.get_icon(node.text, string.match(node.text, "%a+$"), { default = true })
    line:append(icon .. "  ", icon_highlight)

    local fullpath = node.text
    local filename = vim.fn.fnamemodify(fullpath, ":t")
    local path = vim.fn.fnamemodify(fullpath, ":h")

    -- Fixup path for files in the top directory
    -- if path == "." then
    --   path = ""
    -- end

    local highlight_group_path = component:hl_group(node.is_marked and "SpectreSearchNewValue" or "SpectreCodeLine")
    local highlight_group_file = component:hl_group(node.is_marked and "BufferDeffaultCurrent" or "BufferDeffaultCurrent")
    --local search_highlight_group = component:hl_group(is_replacing and "SpectreSearchOldValue" or "SpectreSearchValue")
    --local default_text_highlight = component:hl_group("SpectreCodeLine")

    if options.split_path_file then
        line:append(filename, highlight_group_file)
        local padding = options.num_spaces - string.len(filename)
        line:append(string.rep(' ', padding), highlight_group_file)
        line:append(' ', highlight_group_file)
        line:append(path, highlight_group_path)
    else
        line:append(path .. '/', highlight_group_path)
        line:append(filename, highlight_group_file)
    end

    return line
end

local function file_tree(props)
    return n.tree({
        border_style = "none",
        flex = 50,
        padding = {
            left = 1,
            right = 1,
        },
        hidden = props.hidden,
        data = props.data,
        --mappings = mappings,
        prepare_node = prepare_node,
        on_select = on_select,
    })
end

return file_tree
