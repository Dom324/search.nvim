local Job = require('plenary.job')
local n = require("nui-components")

local M = {}
-- TODO: this should be loaded from some input file
local SEARCH_CWD_PROJECT = 0

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

function M.search(options, input_signal, results_signal)

  --self.handler.on_start()
  M.stop(results_signal)
  local start_time = vim.loop.hrtime()

  -- TODO: Refactor into a function
  local expanded_globs = {}
  for _, glob in ipairs(input_signal.globs) do
    local first_char = string.sub(glob, 1, 1)
    local is_glob_negated = first_char == "!"
    if is_glob_negated then
      negate_char = '!'
      glob = string.sub(glob, 2)
    else
      negate_char = ''
    end

    for _, glob_pre_post_fix in ipairs(options.glob_pre_post_fixes) do
      glob_prefix = glob_pre_post_fix[1]
      glob_postfix = glob_pre_post_fix[2]

      expanded_glob = negate_char .. glob_prefix .. glob .. glob_postfix
      table.insert(expanded_globs, expanded_glob)
    end
  end

  --local args = {'--json', 'hello', '-g', glob_str, search_path}
  local args = {}

  if input_signal.is_hidden_checked then
    table.insert(args, '--hidden')
  end

  table.insert(args, '--files')

  for _, glob in ipairs(expanded_globs) do table.insert(args, '-g') table.insert(args, glob) end     -- Prepend every glob with '-g' flag

  args_str = table.concat(args, ' ')
  print(args_str)

  results_signal.file_results = {}
  results_signal.is_file_search_loading = true

  local new_file_table = {}
  local num_files_found = 0

  local global_search = input_signal.search_cwd ~= SEARCH_CWD_PROJECT
  local search_cwd = global_search and os.getenv( "HOME" ) or vim.fn.getcwd()

  job = Job:new({
      enable_recording = false,
      command = 'rg',
      cwd = search_cwd,
      detached = true,
      args = args,
      on_stdout = function(_, value)
        pcall(vim.schedule_wrap(function()
          print("first")
          table.insert(new_file_table, n.node({ text = value, is_marked = false}))
          num_files_found = num_files_found + 1
          -- if num_files_found == 1 then
          --   results_signal.file_results = new_file_table
          -- end
        end))
          --print(new_file_table[0].text)
          --results_signal.file_results = n.node({ text = "docs/readme.lua", is_marked = false })
          --print("stdout")
          --print(value)
          --self:on_output(value)
      end,
      on_stderr = function(_, value)
          print("stderr")
          print(value)
          --self:on_error(value)
      end,
      on_exit = function(_, value)
          print("exit")
          print(value)
        pcall(vim.schedule_wrap(function()
          results_signal.file_results = new_file_table
          results_signal.is_file_search_loading = false
          local end_time = (vim.loop.hrtime() - start_time) / 1E9
          local total = num_files_found
          results_signal.search_info = string.format("Total: %s match, time: %ss", total, end_time)
          print(end_time)
          print(num_files_found)
        end))
          --results_signal.file_results = new_file_table
          --self:on_exit(value)
      end,
  })

  job:start()
end

function M.stop(results_signal)
  print("stop")
  if results_signal.is_file_search_loading == true then
      print("shutting down")
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
