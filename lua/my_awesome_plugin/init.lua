---@tag my_awesome_plugin

---@brief [[
---This is a template for a plugin. It is meant to be copied and modified.
---The following code is a simple example to show how to use this template and how to take advantage of code
---documentation to generate plugin documentation.
---
---This simple example plugin provides a command to calculate the maximum or minimum of two numbers.
---Moreover, the result can be rounded if specified by the user in its configuration using the setup function.
---
--- <pre>
--- `:PluginName {number} {number} {max|min}`
--- </pre>
---
--- The plugin can be configured using the |my_awesome_plugin.setup()| function.
---
---@brief ]]

---@class PluginNameModule
---@field setup function: setup the plugin
---@field main function: calculate the max or min of two numbers and round the result if specified by options
local my_awesome_plugin = {}

--- Setup the plugin
---@param options Config: config table
---@eval { ['description'] = require('my_awesome_plugin.config').__format_keys() }
my_awesome_plugin.setup = function(options)
  require("my_awesome_plugin.config").__setup(options)
end

---Print the result of the comparison
---@param a number: first number
---@param b number: second number
---@param func string: "max" or "min"
---@param result number: result
my_awesome_plugin.print = function(a, b, func, result)
  local s = "The " .. func .. " of " .. a .. " and " .. b .. " is " .. result
  if require("my_awesome_plugin.config").options.round then
    s = s .. " (rounded)"
  end
  print(s)
end

--local n = require("nui-components")
--
--local renderer = n.create_renderer({
--  width = 60,
--  height = 4,
--})

--local body = function()
--  return n.rows(
--    n.columns(
--      { flex = 0 },
--      n.text_input({
--        autofocus = true,
--        flex = 1,
--        max_lines = 1,
--      }),
--      n.gap(1),
--      n.button({
--        label = "Send",
--        padding = {
--          top = 1,
--        },
--      })
--    ),
--    n.paragraph({
--      lines = "nui.components",
--      align = "center",
--      is_focusable = false,
--    })
--  )
--end

--- Calcululate the max or min of two numbers and round the result if specified by options
---@param a number: first number
---@param b number: second number
---@param func string: "max" or "min"
---@return number: result
my_awesome_plugin.main = function(a, b, func)
  --renderer:render(body)
  --local buf = vim.api.nvim_create_buf(false, true)
  --vim.api.nvim_buf_set_lines(buf, 0, -1, true, {"test", "text"})
----
  --local win_opts = {relative='cursor', width=10, height=2, col=0, row=1, anchor='NW', style='minimal'}
  --local win = vim.api.nvim_open_win(buf, 0, win_opts)

  local options = require("my_awesome_plugin.config").options
  local mymath = require("my_awesome_plugin.math")
  local result = mymath[func](a, b)
  if options.round then
    result = mymath.round(result)
  end
  my_awesome_plugin.print(a, b, func, result)
  return result
end

--function! BreakHabitsWindow() abort
--    " Define the size of the floating window
--    let width = 50
--    let height = 10
--
--    " Create the scratch buffer displayed in the floating window
--    let buf = nvim_create_buf(v:false, v:true)
--
--    " Get the current UI
--    let ui = nvim_list_uis()[0]
--
--    " Create the floating window
--    let opts = {'relative': 'editor',
--                \ 'width': width,
--                \ 'height': height,
--                \ 'col': (ui.width/2) - (width/2),
--                \ 'row': (ui.height/2) - (height/2),
--                \ 'anchor': 'NW',
--                \ 'style': 'minimal',
--                \ }
--    let win = nvim_open_win(buf, 1, opts)
--endfunction

my_awesome_plugin.find_files = function(opts)
  local find_command = (function()
    if 1 == vim.fn.executable "rg" then
      return { "rg", "--files", "--color", "never" }
    elseif 1 == vim.fn.executable "fd" then
      return { "fd", "--type", "f", "--color", "never" }
    elseif 1 == vim.fn.executable "fdfind" then
      return { "fdfind", "--type", "f", "--color", "never" }
    elseif 1 == vim.fn.executable "find" and vim.fn.has "win32" == 0 then
      return { "find", ".", "-type", "f" }
    elseif 1 == vim.fn.executable "where" then
      return { "where", "/r", ".", "*" }
    end
  end)()

  if not find_command then
    utils.notify("builtin.find_files", {
      msg = "You need to install either find, fd, or rg",
      level = "ERROR",
    })
    return
  end

  local command = find_command[1]
  local hidden = opts.hidden
  local no_ignore = opts.no_ignore
  local no_ignore_parent = opts.no_ignore_parent
  local follow = opts.follow
  local search_dirs = opts.search_dirs
  local search_file = opts.search_file

  if search_dirs then
    for k, v in pairs(search_dirs) do
      search_dirs[k] = utils.path_expand(v)
    end
  end

  if command == "fd" or command == "fdfind" or command == "rg" then
    if hidden then
      find_command[#find_command + 1] = "--hidden"
    end
    if no_ignore then
      find_command[#find_command + 1] = "--no-ignore"
    end
    if no_ignore_parent then
      find_command[#find_command + 1] = "--no-ignore-parent"
    end
    if follow then
      find_command[#find_command + 1] = "-L"
    end
    if search_file then
      if command == "rg" then
        find_command[#find_command + 1] = "-g"
        find_command[#find_command + 1] = "*" .. search_file .. "*"
      else
        find_command[#find_command + 1] = search_file
      end
    end
    if search_dirs then
      if command ~= "rg" and not search_file then
        find_command[#find_command + 1] = "."
      end
      vim.list_extend(find_command, search_dirs)
    end
  elseif command == "find" then
    if not hidden then
      table.insert(find_command, { "-not", "-path", "*/.*" })
      find_command = flatten(find_command)
    end
    if no_ignore ~= nil then
      log.warn "The `no_ignore` key is not available for the `find` command in `find_files`."
    end
    if no_ignore_parent ~= nil then
      log.warn "The `no_ignore_parent` key is not available for the `find` command in `find_files`."
    end
    if follow then
      table.insert(find_command, 2, "-L")
    end
    if search_file then
      table.insert(find_command, "-name")
      table.insert(find_command, "*" .. search_file .. "*")
    end
    if search_dirs then
      table.remove(find_command, 2)
      for _, v in pairs(search_dirs) do
        table.insert(find_command, 2, v)
      end
    end
  elseif command == "where" then
    if hidden ~= nil then
      log.warn "The `hidden` key is not available for the Windows `where` command in `find_files`."
    end
    if no_ignore ~= nil then
      log.warn "The `no_ignore` key is not available for the Windows `where` command in `find_files`."
    end
    if no_ignore_parent ~= nil then
      log.warn "The `no_ignore_parent` key is not available for the Windows `where` command in `find_files`."
    end
    if follow ~= nil then
      log.warn "The `follow` key is not available for the Windows `where` command in `find_files`."
    end
    if search_dirs ~= nil then
      log.warn "The `search_dirs` key is not available for the Windows `where` command in `find_files`."
    end
    if search_file ~= nil then
      log.warn "The `search_file` key is not available for the Windows `where` command in `find_files`."
    end
  end

  if opts.cwd then
    opts.cwd = utils.path_expand(opts.cwd)
  end

  opts.entry_maker = opts.entry_maker or make_entry.gen_from_file(opts)

  pickers
    .new(opts, {
      prompt_title = "Find Files",
      __locations_input = true,
      finder = finders.new_oneshot_job(find_command, opts),
      previewer = conf.grep_previewer(opts),
      sorter = conf.file_sorter(opts),
    })
    :find()
end


return my_awesome_plugin
