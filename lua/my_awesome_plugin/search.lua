local engine = require("my_awesome_plugin.engine")
local options = require("my_awesome_plugin.config").options
require("my_awesome_plugin.highlight")
local fn = require("my_awesome_plugin.fn")
local search_tree = require("my_awesome_plugin.search_tree")
local file_tree = require("my_awesome_plugin.file_tree")
local file_search = require("my_awesome_plugin.file_search")

local n = require("nui-components")
local spinner_formats = require("nui-components.utils.spinner-formats")

local WORD_KEY = "<C-w>"
local CAPITAL_KEY = "<C-a>"
local HIDDEN_KEY = "<C-h>"
local IGNORED_KEY = "<C-i>"
local SEARCH_CWD_KEY = "<C-d>"
local SEARCH_CMD_KEY = "<C-c>"

local SEARCH_CWD_PROJECT_STR = "Project"
local SEARCH_CWD_GLOBAL_STR = "Global "

local SEARCH_CWD_PROJECT = 0
local SEARCH_CWD_GLOBAL = 1

--local SEARCH_CMD_GLOB_STR = "Glob "
--local SEARCH_CMD_REGEX_STR = "Regex"
--local SEARCH_CMD_FUZZY_STR = "Fuzzy"
--
--local SEARCH_CMD_GLOB = 0
--local SEARCH_CMD_REGEX = 1
--local SEARCH_CMD_FUZZY = 2

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

  local query_signal = n.create_signal({
    search_query = "",
    replace_query = "",
    is_case_insensitive_checked = false,
    is_whole_word_checked = false,

    search_paths = {},
    exclude_paths = {},
    is_hidden_checked = false,
    is_ignored_checked = false,
    search_cwd = SEARCH_CWD_PROJECT,
    search_cwd_str = SEARCH_CWD_PROJECT_STR,
  })

  local search_results_signal = n.create_signal({
    search_results = {},
    is_search_loading = false,
    search_info = "",
  })

  local file_results_signal = n.create_signal({
    is_file_search_loading = false,
    file_results = {}
  })

  local subscription_search = query_signal:observe(function(prev, curr)
    local diff_search = fn.isome({ "search_query", "replace_query", "is_case_insensitive_checked", "is_whole_word_checked" }, function(key)
      return not vim.deep_equal(prev[key], curr[key])
    end)
    local diff_file = fn.isome({ "search_paths", "exclude_paths", "is_ignored_checked", "is_hidden_checked", "search_cwd" }, function(key)
      return not vim.deep_equal(prev[key], curr[key])
    end)

    if diff_file then
      glob_str = table.concat(curr.search_paths, ',')
      if #glob_str > 2 then
        file_search.search(options, curr, file_results_signal)
      --else
      --  search_results_signal.search_info = ""
      --  search_results_signal.search_results = {}
      end
    end

    if diff_search or diff_file then
      if #curr.search_query > 2 then
        engine.search(curr, search_results_signal)
      else
        search_results_signal.search_info = ""
        search_results_signal.search_results = {}
      end
    end

    if not (prev.replace_query == curr.replace_query) and #curr.search_query > 2 then
      search_results_signal.search_results = engine.process(curr)
    end
  end)

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
          value = query_signal.search_paths:map(function(paths)
            return table.concat(paths, ",")
          end),
          on_change = fn.debounce(function(value)
            query_signal.search_paths = fn.ireject(fn.imap(vim.split(value, ","), fn.trim), function(path)
              return path == ""
            end)
          end, 400),
        }),
        n.text_input({
          border_label = "Exclude files",
          autofocus = true,
          max_lines = 1,
          on_change = fn.debounce(function(value)
            query_signal.exclude_paths = value
          end, 400),
        }),
        n.columns(
          { size = 2 },
          n.gap({ flex = 1 }),
          --n.button({
          --  label =query_signal.search_cmd_str,
          --  is_focusable = false,
          --  border_style = "rounded",
          --  border_label = SEARCH_CMD_KEY,
          --  global_press_key = SEARCH_CMD_KEY,
          --  on_press = function()
          --      -- Carousel option
          --      local curr_search_cmd = query_signal.search_cmd:get_value()
          --      if curr_search_cmd == SEARCH_CMD_GLOB then
          --         query_signal.search_cmd = SEARCH_CMD_REGEX
          --         query_signal.search_cmd_str = SEARCH_CMD_REGEX_STR
          --      elseif curr_search_cmd == SEARCH_CMD_REGEX then
          --         query_signal.search_cmd = SEARCH_CMD_FUZZY
          --         query_signal.search_cmd_str = SEARCH_CMD_FUZZY_STR
          --      else
          --         query_signal.search_cmd = SEARCH_CMD_GLOB
          --         query_signal.search_cmd_str = SEARCH_CMD_GLOB_STR
          --      end
          --  end,
          --}),
          n.button({
            label =query_signal.search_cwd_str,
            is_focusable = false,
            border_style = "rounded",
            border_label = SEARCH_CWD_KEY,
            global_press_key = SEARCH_CWD_KEY,
            on_press = function()
                -- Carousel option
                local curr_search_cwd =query_signal.search_cwd:get_value()
                if curr_search_cwd == SEARCH_CWD_PROJECT then
                   query_signal.search_cwd = SEARCH_CWD_GLOBAL
                   query_signal.search_cwd_str = SEARCH_CWD_GLOBAL_STR
                else
                   query_signal.search_cwd = SEARCH_CWD_PROJECT
                   query_signal.search_cwd_str = SEARCH_CWD_PROJECT_STR
                end
            end,
          }),
          n.checkbox({
            label = "Hidden",
            default_sign = "",
            checked_sign = "",
            border_style = "rounded",
            value =query_signal.is_hidden_checked,
            is_focusable = false,
            border_label = HIDDEN_KEY,
            press_key = HIDDEN_KEY,
            on_change = function(is_checked)
             query_signal.is_hidden_checked = is_checked
            end,
          }),
          n.checkbox({
            label = "Ignored",
            default_sign = "",
            checked_sign = "",
            border_style = "rounded",
            value =query_signal.is_ignored_checked,
            is_focusable = false,
            border_label = IGNORED_KEY,
            press_key = IGNORED_KEY,
            on_change = function(is_checked)
             query_signal.is_ignored_checked = is_checked
            end,
          })
        ),
        n.gap(1),
        file_tree({
          search_query = query_signal.search_query,
          replace_query = query_signal.replace_query,
          data = file_results_signal.file_results,
          --origin_winid = renderer:get_origin_winid(),
          hidden = file_results_signal.file_results:map(function(value)
            return #value == 0
          end),
        }),
        n.gap({ flex = 1 })     -- TODO: is needed?
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
              query_signal.search_query = value
            end, 400),
          }),
          n.rows(
          { size = 2 },
            n.gap(1),
            n.spinner({
              is_loading = search_results_signal.is_search_loading,
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
            query_signal.replace_query = value
          end, 400),
        }),
        n.columns(
          { size = 2 },
          n.rows(
          n.gap({ flex = 1 }),
              n.paragraph({
                lines = search_results_signal.search_info,
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
            value = query_signal.is_case_insensitive_checked,
            on_change = function(is_checked)
              query_signal.is_case_insensitive_checked = is_checked
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
            value = query_signal.is_whole_word_checked,
            on_change = function(is_checked)
              query_signal.is_whole_word_checked = is_checked
            end,
          })
        ),
        n.gap(1),
        search_tree({
          search_query = query_signal.search_query,
          replace_query = query_signal.replace_query,
          data = search_results_signal.search_results,
          origin_winid = renderer:get_origin_winid(),
          hidden = search_results_signal.search_results:map(function(value)
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
