local options = require("my_awesome_plugin.config").options

local Enums = {}

-- Use the read-only pattern for each enum for safety
local function make_readonly(data_table, name)
    local mt = {
      __index = data_table,
      __newindex = function(tbl, key, value) error("Attempt to modify read-only enum table '".. name .."'", 2) end,
      __metatable = false
    }
    return setmetatable({}, mt)
    -- Or: setmetatable(data_table, mt); return data_table
end

Enums.WORD_KEY = options.keymap.word_key
Enums.CAPITAL_KEY = options.keymap.capital_key
Enums.HIDDEN_KEY = options.keymap.hidden_key
Enums.IGNORED_KEY = options.keymap.ignored_key
Enums.SEARCH_CWD_KEY = options.keymap.search_cwd_key
Enums.QUICKFIX_LIST_KEY = options.keymap.quickfix_key
Enums.CLEAR_KEY = options.keymap.clear_key

--local SEARCH_CMD_GLOB_STR = "Glob "
--local SEARCH_CMD_REGEX_STR = "Regex"
--local SEARCH_CMD_FUZZY_STR = "Fuzzy"
--
--local SEARCH_CMD_GLOB = 0
--local SEARCH_CMD_REGEX = 1
--local SEARCH_CMD_FUZZY = 2

Enums.cwd = make_readonly({
    PROJECT = 0,
    GLOBAL = 1
}, "cwd")

Enums.cwd_str = make_readonly({
    PROJECT = "Project",
    GLOBAL = "Global "
}, "cwd_str")

return Enums
