local n = require("nui-components")
local utils = require("my_awesome_plugin.utils")
local search_core = require("my_awesome_plugin.search_core")

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

local function on_select(renderer)
    local origin_winid = renderer:get_origin_winid()
    return function(node, component)
        print(dump(node))
        local tree = component:get_tree()

        if node._depth == 1 then
            if node:is_expanded() then
                node:collapse()
            else
                node:expand()
            end

            return tree:render()
        end

        local parent = tree:get_node(node._parent_id)
        local filename = parent.text
        print(dump(parent))
        print(filename)

        renderer:close()

        if vim.api.nvim_win_is_valid(origin_winid) then
            local escaped_filename = vim.fn.fnameescape(filename)

            vim.api.nvim_set_current_win(origin_winid)
            vim.api.nvim_command([[execute "normal! m` "]])
            vim.cmd("e " .. escaped_filename)
            vim.api.nvim_win_set_cursor(0, { node.line_number, node.submatches[1].start })
        end
    end
end

local function prepare_node(node, line, component)
    local _, devicons = pcall(require, "nvim-web-devicons")
    local has_children = node:has_children()

    line:append(string.rep("  ", node:get_depth() - 1))

    if has_children then
        local icon, icon_highlight = devicons.get_icon(node.text, string.match(node.text, "%a+$"), { default = true })

        line:append(node:is_expanded() and " " or " ", component:hl_group("SpectreIcon"))
        line:append(icon .. " ", icon_highlight)
        line:append(node.text, component:hl_group("SpectreFileName"))

        return line
    end

    local is_replacing = false --#node.diff.replace > 0
    local search_highlight_group = component:hl_group(is_replacing and "@diff.minus" or "@diff.plus")
    print(dump(search_highlight_group))
    local default_text_highlight = component:hl_group("SpectreCodeLine")

    -- local _, empty_spaces = string.find(node.diff.text, "^%s*")
    local ref = node.ref

    if ref then
        line:append("✔ ", component:hl_group("SpectreReplaceSuccess"))
    end

    for _, submatch in ipairs(node.submatches) do
        local start_col = node.submatches[1].start
        local end_col = node.submatches[1]["end"]

        local text_before_match = string.sub(node.text, 1, start_col)
        local match = string.sub(node.text, start_col, end_col)
        print(dump(node.submatches))

        line:append(text_before_match, default_text_highlight)
        line:append(match, search_highlight_group)

        -- local replace_diff_value = node.diff.replace[index]

        if replace_diff_value then
            local replace_text =
                string.sub(code_text, replace_diff_value[1] + 1 - empty_spaces, replace_diff_value[2] - empty_spaces)
            line:append(replace_text, component:hl_group("SpectreSearchNewValue"))
            end_ = replace_diff_value[2] - empty_spaces
        end

        -- if index == #node.diff.search then
            -- line:append(string.sub(code_text, end_col + 1), default_text_highlight)
        -- end
    end

    return line
end

local function mappings(search_query, replace_query)
    return function(component)
        return {
            {
                mode = { "n" },
                key = "r",
                handler = function()
                    local tree = component:get_tree()
                    local focused_node = component:get_focused_node()

                    if not focused_node then
                        return
                    end

                    local has_children = focused_node:has_children()

                    if not has_children then
                        local entry = focused_node.entry

                        -- replacer:replace({
                        --     lnum = entry.lnum,
                        --     col = entry.col,
                        --     cwd = vim.fn.getcwd(),
                        --     display_lnum = 0,
                        --     filename = entry.filename,
                        --     search_text = search_query:get_value(),
                        --     replace_text = replace_query:get_value(),
                        -- })
                    end
                end,
            },
        }
    end
end

local function search_tree(props, renderer)
    return n.tree({
        border_style = "none",
        flex = 50,
        padding = {
            left = 1,
            right = 1,
        },
        hidden = props.hidden,
        data = props.data,
        mappings = mappings(props.search_query, props.replace_query),
        prepare_node = prepare_node,
        on_select = on_select(renderer),
    })
end

return search_tree
