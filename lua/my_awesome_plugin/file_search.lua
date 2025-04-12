local Job = require('plenary.job')
local n = require("nui-components")

local M = {}

local enums = require("my_awesome_plugin.enums")

local function sort_paths(a, b)
    local split_a = vim.split(a.text, "/", { plain = true, trimempty = true })
    local split_b = vim.split(b.text, "/", { plain = true, trimempty = true })

    local num_a = #split_a
    local num_b = #split_b

    for i, path_segment_a in ipairs(split_a) do
        local path_segment_b = split_b[i]

        -- 1. Files before directories
        local is_last_path_segment_a = i == num_a
        local is_last_path_segment_b = i == num_b
        if is_last_path_segment_a ~= is_last_path_segment_b then
            return is_last_path_segment_a
        end

        if path_segment_a == path_segment_b then
            goto continue
        end

        -- local path_segment_a_len = #path_segment_a
        -- local path_segment_b_len = #path_segment_b
        -- if path_segment_a_len ~= path_segment_b_len then
        --   local shorter = path_segment_a_len < path_segment_b_len
        --   return shorter
        -- end

        local segment_a_shorter = #path_segment_a < #path_segment_b
        local shorter_len = not segment_a_shorter and #path_segment_a or #path_segment_b

        -- 2. Sort alphabetically
        for j = 1, shorter_len do
            local char_a = path_segment_a:sub(j, j)
            local char_b = path_segment_b:sub(j, j)
            if char_a ~= char_b then
                return char_a < char_b
            end
        end

        -- 3. If paths have the same prefix (e.g. "plugins" vs "plugins2") shorter segment goes first
        if segment_a_shorter then
            return true
        else
            return false
        end
        -- For whatever reason the following line is bugged with goto
        -- return segment_a_shorter

        ::continue::
    end
end

function M.search(options, input_signal, results_signal, args)
    M.stop(results_signal)

    results_signal.file_results = {}
    results_signal.is_file_search_loading = true

    local start_time_total = vim.loop.hrtime()

    table.insert(args, '--files')

    local args_str_for_files = table.concat(args, ' ')
    print("file args: " .. args_str_for_files)

    local new_file_table = {}
    local num_files_found = 0

    local global_search = input_signal.search_cwd ~= enums.cwd.PROJECT
    local search_cwd = global_search and os.getenv("HOME") or vim.fn.getcwd()

    local start_time_rg = vim.loop.hrtime()

    local job = Job:new({
        enable_recording = false,
        command = 'rg',
        cwd = search_cwd,
        detached = true,
        args = args,
        on_stdout = function(_, value)
            pcall(vim.schedule_wrap(function()
                if value == nil then
                    return
                end

                num_files_found = num_files_found + 1

                if num_files_found < options.max_files_to_display then
                    print(tostring(num_files_found) .. ": \"" .. value .. "\"")
                    table.insert(new_file_table, n.node({ text = value, is_marked = false }))
                end
            end))
        end,
        on_stderr = function(_, value)
            if value == nil then
                return
            end

            print("stderr")
            print(value)
        end,
        on_exit = function(_, value)
            print("exit: " .. tostring(value))
            pcall(vim.schedule_wrap(function()
                results_signal.is_file_search_loading = false

                local end_time_rg = vim.loop.hrtime()
                local total_time_rg = (end_time_rg - start_time_rg) / 1E9

                print("files found: " .. tostring(num_files_found))
                print("rg time: " .. tostring(total_time_rg))

                if options.sort_files then
                    local start_time_sort = vim.loop.hrtime()

                    table.sort(new_file_table, sort_paths)

                    local end_time_sort = vim.loop.hrtime()
                    local total_time_sort = (end_time_sort - start_time_sort) / 1E9
                    print("sort time: " .. tostring(total_time_sort))
                end

                local end_time_total = vim.loop.hrtime()
                local total_time_total = (end_time_total - start_time_total) / 1E9

                results_signal.file_results = new_file_table
                results_signal.search_info = string.format("Total: %s match, time: %ss", num_files_found,
                    total_time_total)
            end))
        end,
    })

    job:start()
    M.job = job
end

function M.stop(results_signal)
    if results_signal.is_file_search_loading == true then
        print("stopping search")
        M.job:shutdown()
        results_signal.is_file_search_loading = false
    end
end

return M
