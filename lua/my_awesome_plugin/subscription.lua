local utils = require("my_awesome_plugin.utils")
local options = require("my_awesome_plugin.config").options

local engine = require("my_awesome_plugin.engine2")
local signal = require("my_awesome_plugin.signal")
local file_search = require("my_awesome_plugin.file_search")

local M = {}

function M.subscription(prev, curr)
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
            file_search.search(options, curr, signal.file_results_signal, args)
        else
            signal.reset_file_results_state()
        end
    end

    if diff_search then
        if #curr.search_query > 2 then
            engine.search(options, curr, signal.search_results_signal, args)
        else
            signal.reset_search_results_state()
        end
    end

    if not (prev.replace_query == curr.replace_query) and #curr.search_query > 2 then
        signal.search_results_signal.search_results = engine.process(curr)
    end
end

return M
