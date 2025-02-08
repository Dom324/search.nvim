local engine = require("my_awesome_plugin.engine2")
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
local QUICKFIX_LIST_KEY = "<C-c>"
local CLEAR_KEY = "<C-r>"

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

function initialize_querry_state()
  query_signal = n.create_signal({
    search_query = "",
    replace_query = "",
    is_case_insensitive_checked = false,
    is_whole_word_checked = false,

    globs = {},
    is_hidden_checked = false,
    is_ignored_checked = false,
    search_cwd = SEARCH_CWD_PROJECT,
    search_cwd_str = SEARCH_CWD_PROJECT_STR,
  })
  search_results_signal = n.create_signal({
    search_results = {},
    is_search_loading = false,
    search_info = "",
  })
  file_results_signal = n.create_signal({
    is_file_search_loading = false,
    file_results = {},
    search_info = ""
  })
end

function reset_querry_state()
  query_signal.search_query = ""
  query_signal.replace_query = ""
  query_signal.is_case_insensitive_checked = false
  query_signal.is_whole_word_checked = false

  query_signal.globs = {}
  query_signal.is_hidden_checked = false
  query_signal.is_ignored_checked = false
  query_signal.search_cwd = SEARCH_CWD_PROJECT
  query_signal.search_cwd_str = SEARCH_CWD_PROJECT_STR
end

function reset_search_results_state()
  search_results_signal.search_results = {}
  search_results_signal.is_search_loading = false
  search_results_signal.search_info = ""
end

function reset_file_results_state()
  file_results_signal.is_file_search_loading = false
  file_results_signal.file_results = {}
  file_results_signal.search_info = ""
end

function reset_signal_state()
  reset_querry_state()
  reset_file_results_state()
  reset_search_results_state()
end

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

  local initialize_querry = not options.preserve_querry_on_close or _G["query_signal"] == nil
  if initialize_querry then
    initialize_querry_state()
  end

  local subscription_search = query_signal:observe(function(prev, curr)

    search_signals = { "search_query", "replace_query", "is_case_insensitive_checked", "is_whole_word_checked" }
    local diff_search = fn.isome(search_signals, function(key)
      return not vim.deep_equal(prev[key], curr[key])
    end)

    file_signals = { "globs", "is_ignored_checked", "is_hidden_checked", "search_cwd" }
    local diff_file = fn.isome(file_signals, function(key)
      return not vim.deep_equal(prev[key], curr[key])
    end)

  -- TODO: Refactor into a function
  local expanded_globs = {}
  for _, glob in ipairs(curr.globs) do
    local first_char = string.sub(glob, 1, 1)

    local is_glob_negated = first_char == "!"
    local negate_char = is_glob_negated and '!' or ''
    if is_glob_negated then
      glob = string.sub(glob, 2)
    end

    for _, glob_pre_post_fix in ipairs(options.glob_pre_post_fixes) do
      local glob_prefix = glob_pre_post_fix[1]
      local glob_postfix = glob_pre_post_fix[2]

      local expanded_glob = negate_char .. glob_prefix .. glob .. glob_postfix
      table.insert(expanded_globs, expanded_glob)
    end
  end

  --local args = {'--json', 'hello', '-g', glob_str, search_path}
  local args = {}

  for _, glob in ipairs(expanded_globs) do table.insert(args, '-g') table.insert(args, glob) end     -- Prepend every glob with '-g' flag

  if curr.is_hidden_checked then
    table.insert(args, '--hidden')
  end
  local args_str = table.concat(args, ' ')
  print("search args: " .. args_str)

    if diff_file then
      local glob_str = table.concat(curr.globs, ',')
      if #glob_str > 2 then
        file_search.search(options, curr, file_results_signal, args)
      else
        reset_file_results_state()
      end
    end

    if diff_search then
      if #curr.search_query > 2 then
        engine.search(options, curr, search_results_signal, args)
      else
        reset_search_results_state()
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
        n.columns(
          { size = 2 },
          n.text_input({
            border_label = "File glob",
            autofocus = true,
            max_lines = 1,
            flex = 1,
            value = query_signal.globs:map(function(paths)
              return table.concat(paths, ",")
            end),
            on_change = fn.debounce(function(value)
              query_signal.globs = fn.ireject(fn.imap(vim.split(value, ","), fn.trim), function(path)
                return path == ""
              end)
            end, 400),
          }),
          n.rows(
          { size = 2 },
            n.gap(1),
            n.spinner({
              is_loading = file_results_signal.is_file_search_loading,
              frames = spinner_formats.dots_9,
            })
          )
        ),
        n.gap(1),
        n.columns(
          { size = 2 },
          n.rows(
            n.gap({ flex = 1 }),
            n.paragraph({
              lines = file_results_signal.search_info,
              is_focusable = false,
              padding = {
                left = 1,
                right = 1,
              },
            }),
            n.gap({ flex = 1 })
          ),
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
            label = "Quickfix",
            is_focusable = false,
            border_style = "rounded",
            border_label = QUICKFIX_LIST_KEY,
            global_press_key = QUICKFIX_LIST_KEY,
            on_press = function()
            end,
          }),
          n.button({
            label = "Clear",
            is_focusable = false,
            border_style = "rounded",
            border_label = CLEAR_KEY,
            global_press_key = CLEAR_KEY,
            on_press = function()
              reset_signal_state()
            end,
          }),
          n.button({
            label = query_signal.search_cwd_str,
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
            value = query_signal.is_hidden_checked,
            is_focusable = false,
            border_label = HIDDEN_KEY,
            global_press_key = HIDDEN_KEY,
            on_change = function(is_checked)
             query_signal.is_hidden_checked = is_checked
            end,
          }),
          n.checkbox({
            label = "Ignored",
            default_sign = "",
            checked_sign = "",
            border_style = "rounded",
            value = query_signal.is_ignored_checked,
            is_focusable = false,
            border_label = IGNORED_KEY,
            global_press_key = IGNORED_KEY,
            on_change = function(is_checked)
             query_signal.is_ignored_checked = is_checked
            end,
          }),
          n.gap(2)
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
            value = query_signal.search_query,
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
          value = query_signal.replace_query,
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
