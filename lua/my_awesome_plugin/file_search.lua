local Job = require('plenary.job')
local n = require("nui-components")

local M = {}
-- TODO: this should be loaded from some input file
local SEARCH_CWD_PROJECT = 0
function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

--base.on_error = function(self, value, ref)
--    if value ~= 0 then
--        pcall(vim.schedule_wrap(function()
--            self.handler.on_error({
--                value = value,
--                ref = ref,
--            })
--        end))
--    end
--end
--
--base.on_done = function(self, value, ref)
--    if value == 0 or value == true then
--        pcall(vim.schedule_wrap(function()
--            self.handler.on_done({
--                ref = ref,
--            })
--        end))
--    else
--        base.on_error(self, value, ref)
--    end
--end
--
--base.on_output = function(self, output_text)
--    pcall(vim.schedule_wrap(function()
--        if output_text == nil then
--            return
--        end
--        -- it make vim broken with  (min.js) file has a long line
--        if string.len(output_text) > MAX_LINE_CHARS then
--            output_text = string.sub(output_text, 0, MAX_LINE_CHARS)
--        end
--        local t = utils.parse_line_grep(output_text)
--        if t == nil or t.lnum == nil or t.col == nil then
--            return
--        end
--        self.handler.on_result(t)
--    end))
--end
--
--base.on_error = function(self, output_text)
--    if output_text ~= nil then
--        log.debug('search error ' .. output_text)
--        pcall(vim.schedule_wrap(function()
--            self.handler.on_error(output_text)
--        end))
--    end
--end
--
--base.on_exit = function(self, value)
--    pcall(vim.schedule_wrap(function()
--        self.handler.on_finish(value)
--    end))
--end

function sort_paths(a, b)

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
    for i = 1, shorter_len do
      local char_a = path_segment_a:sub(i, i)
      local char_b = path_segment_b:sub(i, i)
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

  --self.handler.on_start()
  M.stop(results_signal)

  results_signal.file_results = {}
  results_signal.is_file_search_loading = true

  local start_time_total = vim.loop.hrtime()

  table.insert(args, '--files')

  local args_str_for_files = table.concat(args, ' ')
  print("file args: " .. args_str_for_files)

  local new_file_table = {}
  local num_files_found = 0

  local global_search = input_signal.search_cwd ~= SEARCH_CWD_PROJECT
  local search_cwd = global_search and os.getenv( "HOME" ) or vim.fn.getcwd()

  local start_time_rg = vim.loop.hrtime()

  job = Job:new({
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
            table.insert(new_file_table, n.node({ text = value, is_marked = false}))
          end
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
          results_signal.search_info = string.format("Total: %s match, time: %ss", num_files_found, total_time_total)
        end))
          --self:on_exit(value)
      end,
  })

  job:start()
end

function M.stop(results_signal)
  if results_signal.is_file_search_loading == true then
      print("stopping search")
      job:shutdown()
      results_signal.is_file_search_loading = false
  end
end

--function M.process(options)
--  options = options or {}
--
--  return fn.kmap(spectre_state.groups, function(group, filename)
--    local children = fn.imap(group, function(entry)
--      local id = tostring(math.random())
--
--      local diff = spectre_utils.get_hl_line_text({
--        search_query = options.search_query,
--        replace_query = options.replace_query,
--        search_text = entry.text,
--        padding = 0,
--      }, spectre_state.regex)
--
--      return Tree.Node({ text = diff.text, _id = id, diff = diff, entry = entry })
--    end)
--
--    local id = tostring(math.random())
--    local node = Tree.Node({ text = filename:gsub("^./", ""), _id = id }, children)
--
--    node:expand()
--
--    return node
--  end)
--end
--
--local function search_handler(options, signal)
--  local start_time = 0
--  local total = 0
--
--  spectre_state.groups = {}
--
--  return {
--    on_start = function()
--      spectre_state.is_running = true
--      start_time = vim.loop.hrtime()
--      signal.is_search_loading = true
--    end,
--    on_result = function(item)
--      if not spectre_state.is_running then
--        return
--      end
--
--      if not spectre_state.groups[item.filename] then
--        spectre_state.groups[item.filename] = {}
--      end
--
--      table.insert(spectre_state.groups[item.filename], item)
--      total = total + 1
--    end,
--    on_error = function(_) end,
--    on_finish = function()
--      if not spectre_state.is_running then
--        return
--      end
--
--      local end_time = (vim.loop.hrtime() - start_time) / 1E9
--
--      signal.search_results = M.process(options)
--      signal.search_info = string.format("Total: %s match, time: %ss", total, end_time)
--      signal.is_search_loading = false
--
--      spectre_state.finder_instance = nil
--      spectre_state.is_running = false
--    end,
--  }
--end
--
--function M.stop()
--  if not spectre_state.finder_instance then
--    return
--  end
--
--  spectre_state.finder_instance:stop()
--  spectre_state.finder_instance = nil
--end
--
--function M.search(options, signal)
--  options = options or {}
--
--  M.stop()
--
--  local search_engine = spectre_search["rg"]
--  spectre_state.options["ignore-case"] = not options.is_case_insensitive_checked
--  spectre_state.finder_instance =
--    search_engine:new(spectre_state_utils.get_search_engine_config(), search_handler(options, signal))
--  spectre_state.regex = require("spectre.regex.vim")
--
--  pcall(function()
--    spectre_state.finder_instance:search({
--      cwd = vim.fn.getcwd(),
--      search_text = options.search_query,
--      replace_query = options.replace_query,
--      -- path = spectre_state.query.path,
--      search_paths = #options.search_paths > 0 and options.search_paths or nil,
--    })
--  end)
--end

return M
