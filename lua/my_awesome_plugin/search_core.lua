local subscription = require("my_awesome_plugin.subscription").subscription
local options = require("my_awesome_plugin.config").options
local signal = require("my_awesome_plugin.signal")
local n = require("nui-components")

local M = {}

function M.toggle()
    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    local padding_horizontal = math.floor(win_width * 0.1)
    local padding_vertical = math.floor(win_height * 0.025)

    local renderer = n.create_renderer({
        width = win_width - 2 * padding_horizontal,
        height = win_height - 2 * padding_vertical,
        relative = "editor",
        position = {
            row = padding_vertical,
            col = padding_horizontal,
        },
    })

    M.renderer = renderer
    renderer:on_mount(function()
        -- M.renderer = renderer

        -- utils.attach_resize(augroup, renderer, ui)

        -- if c.ui.autoclose then
        --   utils.attach_autoclose(renderer)
        -- end
    end)

    local initialize_signals = not options.preserve_querry_on_close or signal.query_signal == nil
    if initialize_signals then
        signal.initialize_signals()
    end

    local subscription_search = signal.query_signal:observe(subscription)

    local body = require("my_awesome_plugin.body")
    M.renderer:render(body)
end

return M
