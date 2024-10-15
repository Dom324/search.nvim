local engine = require("my_awesome_plugin.engine")
require("my_awesome_plugin.highlight")
local fn = require("my_awesome_plugin.fn")

local n = require("nui-components")
local spinner_formats = require("nui-components.utils.spinner-formats")

local WORD_KEY = "<C-w>"
local CAPITAL_KEY = "<C-a>"
local HIDDEN_KEY = "<C-h>"
local SEARCH_MODE_KEY = "<C-d>"

local SEARCH_MODE_PROJECT_STR = "  Project "
local SEARCH_MODE_GIT_STR = "    Git   "
local SEARCH_MODE_GLOBAL_STR = "  Global  "

local SEARCH_MODE_PROJECT = 0
local SEARCH_MODE_GIT = 1
local SEARCH_MODE_GLOBAL = 2


local M = {}

function M.toggle()

  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)

  local padding_horizontal = math.floor(win_width * 0.1)
  local padding_vertical = math.floor(win_height * 0.025)

  local renderer = n.create_renderer({
    width = win_width - 2 * padding_horizontal,
    height = win_height - 2 * padding_vertical,
    relative = "editor",
    position = {
      row = padding_vertical,
      col = padding_horizontal,
    },
  })

  local signal = n.create_signal({
    search_query = "",
    replace_query = "",
    search_paths = {},
    exclude_paths = {},
    is_case_insensitive_checked = false,
    is_hidden_checked = false,
    is_whole_word_checked = false,
    search_info = "",
    search_mode = SEARCH_MODE_PROJECT,
    search_mode_str = SEARCH_MODE_PROJECT_STR,
    search_results = {},
    file_results = {},
    is_search_loading = false
  })

  local subscription = signal:observe(function(prev, curr)
    local diff = fn.isome({ "search_query", "is_case_insensitive_checked", "search_paths" }, function(key)
      return not vim.deep_equal(prev[key], curr[key])
    end)

    if diff then
      if #curr.search_query > 2 then
        engine.search(curr, signal)
      else
        signal.search_info = ""
        signal.search_results = {}
      end
    end

    if not (prev.replace_query == curr.replace_query) and #curr.search_query > 2 then
      signal.search_results = engine.process(curr)
    end
  end)

  local function on_select(origin_winid)
    return function(node, component)
      local tree = component:get_tree()

      if node:has_children() then
        if node:is_expanded() then
          node:collapse()
        else
          node:expand()
        end

        return tree:render()
      end

      local entry = node.entry

      if vim.api.nvim_win_is_valid(origin_winid) then
        local escaped_filename = vim.fn.fnameescape(entry.filename)

        vim.api.nvim_set_current_win(origin_winid)
        vim.api.nvim_command([[execute "normal! m` "]])
        vim.cmd("e " .. escaped_filename)
        vim.api.nvim_win_set_cursor(0, { entry.lnum, entry.col - 1 })
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

    local is_replacing = #node.diff.replace > 0
    local search_highlight_group = component:hl_group(is_replacing and "SpectreSearchOldValue" or "SpectreSearchValue")
    local default_text_highlight = component:hl_group("SpectreCodeLine")

    local _, empty_spaces = string.find(node.diff.text, "^%s*")
    local ref = node.ref

    if ref then
      line:append("✔ ", component:hl_group("SpectreReplaceSuccess"))
    end

    if #node.diff.search > 0 then
      local code_text = fn.trim(node.diff.text)

      fn.ieach(node.diff.search, function(value, index)
        local start = value[1] - empty_spaces
        local end_ = value[2] - empty_spaces

        if index == 1 then
          line:append(string.sub(code_text, 1, start), default_text_highlight)
        end

        local search_text = string.sub(code_text, start + 1, end_)
        line:append(search_text, search_highlight_group)

        local replace_diff_value = node.diff.replace[index]

        if replace_diff_value then
          local replace_text =
            string.sub(code_text, replace_diff_value[1] + 1 - empty_spaces, replace_diff_value[2] - empty_spaces)
          line:append(replace_text, component:hl_group("SpectreSearchNewValue"))
          end_ = replace_diff_value[2] - empty_spaces
        end

        if index == #node.diff.search then
          line:append(string.sub(code_text, end_ + 1), default_text_highlight)
        end
      end)
    end

    return line
  end

  local function search_tree(props)
    return n.tree({
      border_style = "none",
      flex = 50,
      padding = {
        left = 1,
        right = 1,
      },
      hidden = props.hidden,
      data = props.data,
      --mappings = mappings(props.search_query, props.replace_query),
      prepare_node = prepare_node,
      on_select = on_select(props.origin_winid),
    })
  end

  local body = function()
    return n.columns(
      n.rows(
        n.paragraph({
          lines = "File tree",
          align = "center",
          is_focusable = false,
        }),
        n.text_input({
          border_label = "Include files",
          autofocus = true,
          max_lines = 1,
          value = signal.search_paths:map(function(paths)
            return table.concat(paths, ",")
          end),
          on_change = fn.debounce(function(value)
            signal.search_paths = fn.ireject(fn.imap(vim.split(value, ","), fn.trim), function(path)
              return path == ""
            end)
          end, 400),
        }),
        n.text_input({
          border_label = "Exclude files",
          autofocus = true,
          max_lines = 1,
          on_change = fn.debounce(function(value)
            signal.exclude_paths = value
          end, 400),
        }),
        n.columns(
          { size = 2 },
          n.gap({ flex = 1 }),
          n.button({
            label = signal.search_mode_str,
            is_focusable = false,
            border_style = "rounded",
            border_label = "Search mode " .. SEARCH_MODE_KEY,
            global_press_key = SEARCH_MODE_KEY,
            on_press = function()
                -- Carousel option
                local curr_search_mode = signal.search_mode:get_value()
                if curr_search_mode == SEARCH_MODE_GIT then
                    signal.search_mode = SEARCH_MODE_PROJECT
                    signal.search_mode_str = SEARCH_MODE_PROJECT_STR
                elseif curr_search_mode == SEARCH_MODE_PROJECT then
                    signal.search_mode = SEARCH_MODE_GLOBAL
                    signal.search_mode_str = SEARCH_MODE_GLOBAL_STR
                else
                    signal.search_mode = SEARCH_MODE_GIT
                    signal.search_mode_str = SEARCH_MODE_GIT_STR
                end
            end,
          }),
          n.checkbox({
            label = "Hidden",
            default_sign = "",
            checked_sign = "",
            border_style = "rounded",
            value = signal.is_hidden_checked,
            is_focusable = false,
            border_label = HIDDEN_KEY,
            press_key = HIDDEN_KEY,
            on_change = function(is_checked)
              signal.is_hidden_checked = is_checked
            end,
          })
        ),
        n.gap(1),
        n.gap({ flex = 1 })
      ),
      n.rows(
        n.paragraph({
          lines = "Search tree",
          align = "center",
          is_focusable = false,
        }),
        n.columns(
          { size = 2 },
          n.text_input({
            border_label = "Search",
            autofocus = true,
            max_lines = 1,
            flex = 1,
            on_change = fn.debounce(function(value)
              signal.search_query = value
            end, 400),
          }),
          n.rows(
          { size = 2 },
            n.gap(1),
            n.spinner({
              is_loading = signal.is_search_loading,
              frames = spinner_formats.dots_9,
            })
          )
        ),
        n.gap(1),
        n.text_input({
          border_label = "Replace",
          autofocus = true,
          max_lines = 1,
          on_change = fn.debounce(function(value)
            signal.replace_query = value
          end, 400),
        }),
        n.columns(
          { size = 2 },
          n.rows(
          n.gap({ flex = 1 }),
              n.paragraph({
                lines = signal.search_info,
                is_focusable = false,
                padding = {
                  left = 1,
                  right = 1,
                },
              }),
          n.gap({ flex = 1 })
          ),
          n.gap({ flex = 1 }),
          n.checkbox({
            label = "",
            default_sign = " abc ",
            checked_sign = " AbC ",
            border_style = "rounded",
            is_focusable = false,
            border_label = CAPITAL_KEY,
            press_key = CAPITAL_KEY,
            value = signal.is_case_insensitive_checked,
            on_change = function(is_checked)
              signal.is_case_insensitive_checked = is_checked
            end,
          }),
          n.checkbox({
            label = " Word ",
            default_sign = "",
            checked_sign = "",
            border_style = "rounded",
            is_focusable = false,
            border_label = WORD_KEY,
            press_key = WORD_KEY,
            value = signal.is_whole_word_checked,
            on_change = function(is_checked)
              signal.is_whole_word_checked = is_checked
            end,
          })
        ),
        n.gap(1),
        search_tree({
          search_query = signal.search_query,
          replace_query = signal.replace_query,
          data = signal.search_results,
          origin_winid = renderer:get_origin_winid(),
          hidden = signal.search_results:map(function(value)
            return #value == 0
          end),
        }),
        n.gap({ flex = 1 })
      ),
        n.paragraph({
          lines = "Preview",
          align = "center",
          is_focusable = false,
        })
    )
  end

  renderer:render(body)

end

return M
