local n = require("nui-components")
local fn = require("my_awesome_plugin.fn")
local options = require("my_awesome_plugin.config").options

--local function replace_handler(tree, node)
--return {
--  on_done = function(result)
--    if result.ref then
--      node.ref = result.ref
--      tree:render()
--    end
--  end,
--  on_error = function(_) end,
--}
--end

local function on_select(node, component)
    local tree = component:get_tree()
    node.is_marked = not node.is_marked
    tree:render()
end

local function prepare_node(node, line, component)
  if node.is_marked then
    line:append("✔ ", "String")
  else
    line:append("◻ ", "Comment")
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
    line:append(string.rep(' ', padding) , highlight_group_file)
    line:append(' ', highlight_group_file)
    line:append(path, highlight_group_path)
  else
    line:append(path .. '/', highlight_group_path)
    line:append(filename, highlight_group_file)
  end

  return line
end

--local function prepare_node(node, line, component)
--  local _, devicons = pcall(require, "nvim-web-devicons")
--  local has_children = node:has_children()
--
--  line:append(string.rep("  ", node:get_depth() - 1))
--
--  if has_children then
--    local icon, icon_highlight = devicons.get_icon(node.text, string.match(node.text, "%a+$"), { default = true })
--
--    line:append(node:is_expanded() and " " or " ", component:hl_group("SpectreIcon"))
--    line:append(icon .. " ", icon_highlight)
--    line:append(node.text, component:hl_group("SpectreFileName"))
--
--    return line
--  end
--
--  local is_replacing = #node.diff.replace > 0
--  local search_highlight_group = component:hl_group(is_replacing and "SpectreSearchOldValue" or "SpectreSearchValue")
--  local default_text_highlight = component:hl_group("SpectreCodeLine")
--
--  local _, empty_spaces = string.find(node.diff.text, "^%s*")
--  local ref = node.ref
--
--  if ref then
--    line:append("✔ ", component:hl_group("SpectreReplaceSuccess"))
--  end
--
--  if #node.diff.search > 0 then
--    local code_text = fn.trim(node.diff.text)
--
--    fn.ieach(node.diff.search, function(value, index)
--      local start = value[1] - empty_spaces
--      local end_ = value[2] - empty_spaces
--
--      if index == 1 then
--        line:append(string.sub(code_text, 1, start), default_text_highlight)
--      end
--
--      local search_text = string.sub(code_text, start + 1, end_)
--      line:append(search_text, search_highlight_group)
--
--      local replace_diff_value = node.diff.replace[index]
--
--      if replace_diff_value then
--        local replace_text =
--          string.sub(code_text, replace_diff_value[1] + 1 - empty_spaces, replace_diff_value[2] - empty_spaces)
--        line:append(replace_text, component:hl_group("SpectreSearchNewValue"))
--        end_ = replace_diff_value[2] - empty_spaces
--      end
--
--      if index == #node.diff.search then
--        line:append(string.sub(code_text, end_ + 1), default_text_highlight)
--      end
--    end)
--  end
--
--  return line
--end

--local function mappings(search_query, replace_query)
--  local spectre_state_utils = require("spectre.state_utils")
--
--  return function(component)
--    return {
--      {
--        mode = { "n" },
--        key = "r",
--        handler = function()
--          local tree = component:get_tree()
--          local focused_node = component:get_focused_node()
--
--          if not focused_node then
--            return
--          end
--
--          local has_children = focused_node:has_children()
--
--          if not has_children then
--            local replacer_creator = spectre_state_utils.get_replace_creator()
--            local replacer =
--              replacer_creator:new(spectre_state_utils.get_replace_engine_config(), replace_handler(tree, focused_node))
--
--            local entry = focused_node.entry
--
--            replacer:replace({
--              lnum = entry.lnum,
--              col = entry.col,
--              cwd = vim.fn.getcwd(),
--              display_lnum = 0,
--              filename = entry.filename,
--              search_text = search_query:get_value(),
--              replace_text = replace_query:get_value(),
--            })
--          end
--        end,
--      },
--    }
--  end
--end

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


--      return { "rg", "--files", "--color", "never" }
--      find_command[#find_command + 1] = "--hidden"
--      find_command[#find_command + 1] = "--no-ignore"
--      find_command[#find_command + 1] = "-L"
--        find_command[#find_command + 1] = "-g"
--        find_command[#find_command + 1] = "*" .. search_file .. "*"
