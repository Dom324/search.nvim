local Job = require('plenary.job')

-- TODO: this should be loaded from some input file
local SEARCH_CWD_PROJECT = 0

local spectre_state = require("spectre.state")
local spectre_utils = require("spectre.utils")

local Tree = require("nui.tree")

local M = {}

function M.process(options)
  options = options or {}

  return fn.kmap(spectre_state.groups, function(group, filename)
    local children = fn.imap(group, function(entry)
      local id = tostring(math.random())

      local diff = spectre_utils.get_hl_line_text({
        search_query = options.search_query,
        replace_query = options.replace_query,
        search_text = entry.text,
        padding = 0,
      }, spectre_state.regex)

      return Tree.Node({ text = diff.text, _id = id, diff = diff, entry = entry })
    end)

    local id = tostring(math.random())
    local node = Tree.Node({ text = filename:gsub("^./", ""), _id = id }, children)

    node:expand()

    return node
  end)
end

local function search_handler(options, results_signal)
  local start_time = 0
  local total = 0

  spectre_state.groups = {}

  return {
    on_start = function()
      spectre_state.is_running = true
      start_time = vim.loop.hrtime()
      results_signal.is_search_loading = true
    end,
    on_result = function(item)
      if not spectre_state.is_running then
        return
      end

      if not spectre_state.groups[item.filename] then
        spectre_state.groups[item.filename] = {}
      end

      table.insert(spectre_state.groups[item.filename], item)
      total = total + 1
    end,
    on_error = function(_) end,
    on_finish = function()
      if not spectre_state.is_running then
        return
      end

      local end_time = (vim.loop.hrtime() - start_time) / 1E9

      results_signal.search_results = M.process(options)
      results_signal.search_info = string.format("Total: %s match, time: %ss", total, end_time)
      results_signal.is_search_loading = false

      spectre_state.finder_instance = nil
      spectre_state.is_running = false
    end,
  }
end

-- function M.stop()
--   if not spectre_state.finder_instance then
--     return
--   end
--
--   spectre_state.finder_instance:stop()
--   spectre_state.finder_instance = nil
-- end

function M.stop(results_signal)
  if results_signal.is_search_loading == true then
      print("stopping search")
      job:shutdown()
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

  local global_search = input_signal.search_cwd ~= SEARCH_CWD_PROJECT
  local search_cwd = global_search and os.getenv( "HOME" ) or vim.fn.getcwd()

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
--hello helohell

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


  local tree = {}
  for filename, file in pairs(new_matches_table) do
    local child_arr = {}
    for _, matched_line in ipairs(file.matched_lines) do
      for _, submatch in pairs(matched_line.submatches) do
        local id = tostring(math.random())
        -- local search = { submatch.start, submatch.end }
        local search = { submatch.start, submatch["end"] }
        local diff = { search = { search }, replace = "", text = matched_line.lines.text }
        local children = Tree.Node({ text = matched_line.lines.text, _id = id, diff = diff, entry = nil })
        table.insert(child_arr, children)
      end
    end
    local node = Tree.Node({ text = filename:gsub("^./", ""), _id = id }, child_arr)
    table.insert(tree, node)
  end

          local end_time_rg = vim.loop.hrtime()
          local total_time_rg = (end_time_rg - start_time_rg) / 1E9

          print("files found: " .. tostring(num_files_found))
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
          results_signal.search_info = string.format("Total: %s match, time: %ss", num_matches_found, total_time_total)
        end))
          --self:on_exit(value)
      end,
  })

  job:start()
end

return M
