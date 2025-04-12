local M = require("my_awesome_plugin.search")

local search_tree = require("my_awesome_plugin.search_tree")
local file_tree = require("my_awesome_plugin.file_tree")
local enums = require("my_awesome_plugin.enums")
local utils = require("my_awesome_plugin.utils")

local n = require("nui-components")
local spinner_formats = require("nui-components.utils.spinner-formats")

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
                id = "glob_query",
                border_label = "File glob",
                autofocus = true,
                max_lines = 1,
                flex = 1,
                placeholder = " e.g. \"src/ work/\" \".lua\" \".{lua,md}\"",
                value = M.query_signal.glob_query,
                on_mount = function(component)
                    utils.set_component_value(component, M.defaults.query_signal.glob_query)
                end,
                on_change = function(value)
                    M.query_signal.glob_query = value
                end,
            }),
            n.rows(
                { size = 2 },
                n.gap(1),
                n.spinner({
                    is_loading = M.file_results_signal.is_file_search_loading,
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
                    lines = M.file_results_signal.search_info,
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
                border_label = enums.QUICKFIX_LIST_KEY,
                global_press_key = enums.QUICKFIX_LIST_KEY,
                on_press = function()
                end,
            }),
            n.button({
                label = "Clear",
                is_focusable = false,
                border_style = "rounded",
                border_label = enums.CLEAR_KEY,
                global_press_key = enums.CLEAR_KEY,
                on_press = function()
                    M.reset_signal_state_and_component_buffers()
                end,
            }),
            n.button({
                label = M.query_signal.search_cwd_str,
                is_focusable = false,
                border_style = "rounded",
                border_label = enums.SEARCH_CWD_KEY,
                global_press_key = enums.SEARCH_CWD_KEY,
                on_press = function()
                    -- Carousel option
                    local curr_search_cwd = M.query_signal.search_cwd:get_value()
                    if curr_search_cwd == enums.SEARCH_CWD_PROJECT then
                        M.query_signal.search_cwd = enums.SEARCH_CWD_GLOBAL
                        M.query_signal.search_cwd_str = enums.SEARCH_CWD_GLOBAL_STR
                    else
                        M.query_signal.search_cwd = enums.SEARCH_CWD_PROJECT
                        M.query_signal.search_cwd_str = enums.SEARCH_CWD_PROJECT_STR
                    end
                end,
            }),
            n.checkbox({
                label = "Hidden",
                default_sign = "",
                checked_sign = "",
                border_style = "rounded",
                value = M.query_signal.is_hidden_checked,
                is_focusable = false,
                border_label = enums.HIDDEN_KEY,
                global_press_key = enums.HIDDEN_KEY,
                on_change = function(is_checked)
                    M.query_signal.is_hidden_checked = is_checked
                end,
            }),
            n.checkbox({
                label = "Ignored",
                default_sign = "",
                checked_sign = "",
                border_style = "rounded",
                value = M.query_signal.is_ignored_checked,
                is_focusable = false,
                border_label = enums.IGNORED_KEY,
                global_press_key = enums.IGNORED_KEY,
                on_change = function(is_checked)
                    M.query_signal.is_ignored_checked = is_checked
                end,
            }),
            n.gap(2)
        ),
        n.gap(1),
        file_tree({
            search_query = M.query_signal.search_query,
            replace_query = M.query_signal.replace_query,
            data = M.file_results_signal.file_results,
            --origin_winid = renderer:get_origin_winid(),
            hidden = M.file_results_signal.file_results:map(function(value)
                return #value == 0
            end),
        }),
        n.gap({ flex = 1 })         -- TODO: is needed?
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
                id = "search_query",
                border_label = "Search",
                autofocus = true,
                max_lines = 1,
                flex = 1,
                placeholder = " e.g. \"old_name\" \"old_prefix(.*)_old_post_fix\"",
                value = M.query_signal.search_query,
                on_mount = function(component)
                    utils.set_component_value(component, M.defaults.query_signal.search_query)
                end,
                on_change = function(value)
                    M.query_signal.search_query = value
                end,
            }),
            n.rows(
                { size = 2 },
                n.gap(1),
                n.spinner({
                    is_loading = M.search_results_signal.is_search_loading,
                    frames = spinner_formats.dots_9,
                })
            )
        ),
        n.gap(1),
        n.text_input({
            id = "replace_query",
            border_label = "Replace",
            autofocus = true,
            max_lines = 1,
            placeholder = " e.g. \"new_name\" \"new_prefix\\1_new_post_fix\"",
            value = M.query_signal.replace_query,
            on_mount = function(component)
                utils.set_component_value(component, M.defaults.query_signal.replace_query)
            end,
            on_change = function(value)
                M.query_signal.replace_query = value
            end,
        }),
        n.columns(
            { size = 2 },
            n.rows(
                n.gap({ flex = 1 }),
                n.paragraph({
                    lines = M.search_results_signal.search_info,
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
                border_label = enums.CAPITAL_KEY,
                press_key = enums.CAPITAL_KEY,
                value = M.query_signal.is_case_insensitive_checked,
                on_change = function(is_checked)
                    M.query_signal.is_case_insensitive_checked = is_checked
                end,
            }),
            n.checkbox({
                label = " Word ",
                default_sign = "",
                checked_sign = "",
                border_style = "rounded",
                is_focusable = false,
                border_label = enums.WORD_KEY,
                press_key = enums.WORD_KEY,
                value = M.query_signal.is_whole_word_checked,
                on_change = function(is_checked)
                    M.query_signal.is_whole_word_checked = is_checked
                end,
            })
        ),
        n.gap(1),
        search_tree({
            search_query = M.query_signal.search_query,
            replace_query = M.query_signal.replace_query,
            data = M.search_results_signal.search_results,
            -- origin_winid = renderer:get_origin_winid(),
            hidden = M.search_results_signal.search_results:map(function(value)
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
