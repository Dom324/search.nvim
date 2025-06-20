local Job = require('plenary.job')
local Tree = require("nui.tree")

local enums = require("my_awesome_plugin.enums")

local M = {}

function M.stop(results_signal)
    if results_signal.is_search_loading == true then
        print("stopping search")
        M.job:shutdown()
        results_signal.is_search_loading = false
    end
end

function M.search(options, input_signal, results_signal, file_args)
    M.stop(results_signal)
    local start_time_total = vim.loop.hrtime()

    results_signal.search_results = {}
    results_signal.is_search_loading = true

    local args = {}

    table.insert(args, input_signal.search_query)
    table.insert(args, '--json')
    for _, arg in ipairs(file_args) do
        table.insert(args, arg)
    end
    table.insert(args, '.')

    local args_str = table.concat(args, ' ')
    print("search args: " .. args_str)

    local new_matches_table = {}
    local num_matches_found = 0
    local curr_file = nil

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
                -- print(value)
                local rg_output = vim.json.decode(value)

                if rg_output.type == "begin" then
                    assert(curr_file == nil, "rg error: begin begin for an already existing file")
                    curr_file = rg_output.data.path.text

                    assert(new_matches_table[curr_file] == nil, "rg error: begin for an already existing file")
                    new_matches_table[curr_file] = {}
                    new_matches_table[curr_file].matched_lines = {}
                elseif rg_output.type == "match" then
                    assert(curr_file == rg_output.data.path.text, "rg error: match for incorrect file")
                    table.insert(new_matches_table[curr_file].matched_lines, rg_output.data)
                elseif rg_output.type == "end" then
                    assert(curr_file == rg_output.data.path.text, "rg error: end for incorrect file")
                    -- new_matches_table[curr_file].idk = {}
                    curr_file = nil
                elseif rg_output.type == "summary" then
                    assert(curr_file == nil, "rg error: summary with an open file")
                    num_matches_found = rg_output.data.stats.matches
                else
                    error("rg error: unknown type:" .. rg_output.type)
                end

                --
                --
                -- if num_matches_found < options.max_matches_to_display then
                --   print(tostring(num_matches_found) .. ": \"" .. value .. "\"")
                --   if not new_matches_table.groups[item.filename] then
                --     new_matches_table.groups[item.filename] = {}
                --   end
                --
                --   table.insert(new_matches_table.groups[item.filename], item)
                --   -- table.insert(new_file_table, n.node({ text = value, is_marked = false}))
                -- end
            end))
        end,
        on_stderr = function(_, value)
            if value == nil then
                return
            end

            print("stderr")
            print(value)
            --self:on_error(value)
        end,
        on_exit = function(_, value)
            print("exit: " .. tostring(value))
            pcall(vim.schedule_wrap(function()
                results_signal.is_search_loading = false


                -- local tree = {}
                -- for filename, file in pairs(new_matches_table) do
                --     local file_childs = {}
                --
                --     for _, matched_line in ipairs(file.matched_lines) do
                --         local line_childs = {}
                --
                --         for _, submatch in pairs(matched_line.submatches) do
                --             local id = tostring(math.random())
                --
                --             local children = Tree.Node({
                --                 -- text = "idk",
                --                 -- replace = "",
                --                 -- start_col = submatch.start,
                --                 -- end_col = submatch["end"],
                --                 _id = id
                --             })
                --             table.insert(line_childs, children)
                --         end
                --
                --         local id = tostring(math.random())
                --         local children = Tree.Node({ text = matched_line.lines.text, line_number = matched_line.line_number, _id = id }, line_childs)
                --         table.insert(file_childs, children)
                --     end
                --
                --     local id = tostring(math.random())
                --     local node = Tree.Node({ text = filename:gsub("^./", ""), _id = id }, file_childs)
                --
                --     node:expand()
                --
                --     table.insert(tree, node)
                -- end

                local tree = {}
                for filename, file in pairs(new_matches_table) do
                    local file_childs = {}

                    for _, matched_line in ipairs(file.matched_lines) do
                        local line_childs = {}

                        -- for _, submatch in pairs(matched_line.submatches) do
                        --     local id2 = tostring(math.random())
                        --
                        --     local children2 = Tree.Node({
                        --         text = "idk",
                        --         replace = "",
                        --         start_col = submatch.start,
                        --         end_col = submatch["end"],
                        --         _id = id2
                        --     })
                        --     table.insert(line_childs, children2)
                        --     -- table.insert(file_childs, children)
                        -- end

                        local id = tostring(math.random())
                        local children = Tree.Node({ text = matched_line.lines.text, line_number = matched_line.line_number, submatches = matched_line.submatches, _id = id })
                        table.insert(file_childs, children)
                    end

                    local id = tostring(math.random())
                    local node = Tree.Node({ text = filename:gsub("^./", ""), _id = id }, file_childs)

                    node:expand()

                    table.insert(tree, node)
                end

                local end_time_rg = vim.loop.hrtime()
                local total_time_rg = (end_time_rg - start_time_rg) / 1E9

                -- print("files found: " .. tostring(num_files_found))
                print("rg time: " .. tostring(total_time_rg))

                -- if options.sort_files then
                --   local start_time_sort = vim.loop.hrtime()
                --
                --   table.sort(new_file_table, sort_paths)
                --
                --   local end_time_sort = vim.loop.hrtime()
                --   local total_time_sort = (end_time_sort - start_time_sort) / 1E9
                --   print("sort time: " .. tostring(total_time_sort))
                -- end

                local end_time_total = vim.loop.hrtime()
                local total_time_total = (end_time_total - start_time_total) / 1E9

                results_signal.search_results = tree
                results_signal.search_info = string.format("Total: %s match, time: %ss", num_matches_found,
                    total_time_total)
            end))
        end,
    })

    job:start()
    M.job = job
end

return M
