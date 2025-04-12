local engine = require("my_awesome_plugin.engine2")
local options = require("my_awesome_plugin.config").options
require("my_awesome_plugin.highlight")

local file_search = require("my_awesome_plugin.file_search")
local enums = require("my_awesome_plugin.enums")
local utils = require("my_awesome_plugin.utils")

local n = require("nui-components")

local M = {}

function M.initialize_signals()
    M.query_signal = n.create_signal(M.defaults.query_signal)
    M.search_results_signal = n.create_signal(M.defaults.search_results_signal)
    M.file_results_signal = n.create_signal(M.defaults.file_results_signal)
end

function M.reset_querry_state()
    -- query_signal = M.defaults.query_signal

    utils.set_component_buffer_content(M.renderer:get_component_by_id("search_query"), "")
    utils.set_component_buffer_content(M.renderer:get_component_by_id("replace_query"), "")
    utils.set_component_buffer_content(M.renderer:get_component_by_id("glob_query"), "")
end

function M.reset_search_results_state()
    -- search_results_signal = M.defaults.search_results_signal
end

function M.reset_file_results_state()
    -- file_results_signal = M.defaults.file_results_signal
end

function M.reset_signal_state_and_component_buffers()
    M.reset_querry_state()
    M.reset_file_results_state()
    M.reset_search_results_state()
end

function M.toggle()
    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    local padding_horizontal = math.floor(win_width * 0.1)
    local padding_vertical = math.floor(win_height * 0.025)

    M.defaults = {
        query_signal = {
            search_query = "",
            replace_query = "",
            is_case_insensitive_checked = false,
            is_whole_word_checked = false,

            glob_query = "",
            is_hidden_checked = false,
            is_ignored_checked = false,
            search_cwd = enums.cwd.PROJECT,
            search_cwd_str = enums.cwd_str.PROJECT,
        },
        search_results_signal = {
            search_results = {},
            is_search_loading = false,
            search_info = "",
        },
        file_results_signal = {
            is_file_search_loading = false,
            file_results = {},
            search_info = ""
        }
    }

    local renderer = n.create_renderer({
        width = win_width - 2 * padding_horizontal,
        height = win_height - 2 * padding_vertical,
        relative = "editor",
        position = {
            row = padding_vertical,
            col = padding_horizontal,
        },
    })

    renderer:on_mount(function()
        M.renderer = renderer

        -- utils.attach_resize(augroup, renderer, ui)

        -- if c.ui.autoclose then
        --   utils.attach_autoclose(renderer)
        -- end
    end)

    local initialize_signals = not options.preserve_querry_on_close or M.query_signal == nil
    if initialize_signals then
        M.initialize_signals()
    end

    local subscription_search = M.query_signal:observe(function(prev, curr)
        local search_signals = { "search_query", "replace_query", "is_case_insensitive_checked", "is_whole_word_checked" }
        local diff_search = utils.isome(search_signals, function(key)
            return not vim.deep_equal(prev[key], curr[key])
        end)

        local file_signals = { "glob_query", "is_ignored_checked", "is_hidden_checked", "search_cwd" }
        local diff_file = utils.isome(file_signals, function(key)
            return not vim.deep_equal(prev[key], curr[key])
        end)

        local function split(str, delimiter)
            local returnTable = {}
            for k, v in string.gmatch(str, "([^" .. delimiter .. "]+)")
            do
                returnTable[#returnTable + 1] = k
            end
            return returnTable
        end

        -- TODO: Refactor into a function
        local expanded_globs = {}
        local globs = split(curr.glob_query, ' ')
        for _, glob in ipairs(globs) do
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

        for _, glob in ipairs(expanded_globs) do
            table.insert(args, '-g')
            table.insert(args, glob)
        end -- Prepend every glob with '-g' flag

        if curr.is_hidden_checked then
            table.insert(args, '--hidden')
        end
        local args_str = table.concat(args, ' ')
        print("search args: " .. args_str)

        if diff_file then
            if #curr.glob_query > 2 then
                file_search.search(options, curr, M.file_results_signal, args)
            else
                M.reset_file_results_state()
            end
        end

        if diff_search then
            if #curr.search_query > 2 then
                engine.search(options, curr, M.search_results_signal, args)
            else
                M.reset_search_results_state()
            end
        end

        if not (prev.replace_query == curr.replace_query) and #curr.search_query > 2 then
            M.search_results_signal.search_results = engine.process(curr)
        end
    end)

    local body = require("my_awesome_plugin.body")
    renderer:render(body)
end

return M
