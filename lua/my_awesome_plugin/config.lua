---@class ConfigModule
---@field defaults Config: default options
---@field options Config: config table extending defaults
local M = {}

M.defaults = {
    round = true,
    glob_pre_post_fixes = {
        -- when glob is a folder
        { "**/",  "*/**" },
        -- when glob is a file
        { "**/*", "*" }
    },
    num_spaces = 20,
    split_path_file = true,
    preserve_querry_on_close = true,
    sort_files = true,
    max_files_to_display = 100,
    max_matches_to_display = 100,
    keymap = {
        close = "<Esc>",
        focus_next = "<Tab>",
        focus_prev = "<S-Tab>",
        focus_left = nil,
        focus_right = nil,
        focus_up = nil,
        focus_down = nil,

        word_key = "<C-w>",
        capital_key = "<C-a>",
        hidden_key = "<C-h>",
        ignored_key = "<C-f>",
        search_cwd_key = "<C-d>",
        quickfix_key = "<C-c>",
        clear_key = "<C-r>"
    }
}

---@class Config
---@field round boolean: round the result after calculation
M.options = {}

--- We will not generate documentation for this function
--- because it has `__` as prefix. This is the one exception
--- Setup options by extending defaults with the options proveded by the user
---@param options Config: config table
M.__setup = function(options)
    M.options = vim.tbl_deep_extend("force", {}, M.defaults, options or {})
end

---Format the defaults options table for documentation
---@return table
M.__format_keys = function()
    local tbl = vim.split(vim.inspect(M.defaults), "\n")
    table.insert(tbl, 1, "<pre>")
    table.insert(tbl, 2, "Defaults: ~")
    table.insert(tbl, #tbl, "</pre>")
    return tbl
end

return M
