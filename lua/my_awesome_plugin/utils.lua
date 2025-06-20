local M = {}

---@param renderer any
function M.attach_autoclose(renderer)
  local popups = renderer._private.flatten_tree
  for _, popup in pairs(popups) do
    popup:on("BufLeave", function()
      vim.schedule(function()
        local bufnr = vim.api.nvim_get_current_buf()
        for _, p in pairs(popups) do
          if p.bufnr == bufnr then
            return
          end
        end
        renderer:close()
      end)
    end)
  end
end

---
---@param component any
---@param content string | string[] | nil
---@return any
function M.set_component_buffer_content(component, content)
    if component.bufnr == nil then
        return component
    end

    ---@type string[]
    local c
    if type(content) == "string" then
        c = vim.fn.split(content, "\n")
    elseif type(content) == "table" then
        c = content
    else
        c = { "" }
    end

    local modifiable = vim.api.nvim_get_option_value("modifiable", { buf = component.bufnr })
    if not modifiable then
        vim.api.nvim_set_option_value("modifiable", true, { buf = component.bufnr })
    end

    vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, false, c)
    vim.api.nvim_set_option_value("modified", false, { buf = component.bufnr })
    vim.api.nvim_set_option_value("modifiable", modifiable, { buf = component.bufnr })

    return component
end

---
---@param component any
---@param value? any
---@return any
function M.set_component_value(component, value)
    vim.schedule(function()
        if not value then
            value = component:get_current_value()
        end

        component:set_current_value(value)
        if type(component.get_lines) == "function" then
            local lines = component:get_lines()
            vim.api.nvim_buf_set_lines(component.bufnr, 0, -1, true, lines)
        end
        component:redraw()
    end)

    return component
end

function M.isome(tbl, func)
    for index, item in ipairs(tbl) do
        if func(item, index) then
            return true
        end
    end

    return false
end

function M.trim(str)
    return (str:gsub("^%s*(.-)%s*$", "%1"))
end

function M.ieach(tbl, func)
    for index, element in ipairs(tbl) do
        func(element, index)
    end
end

return M
