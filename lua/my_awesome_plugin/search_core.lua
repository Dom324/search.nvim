local subscription = require("my_awesome_plugin.subscription").subscription
local options = require("my_awesome_plugin.config").options
local signal = require("my_awesome_plugin.signal")
local n = require("nui-components")
require("my_awesome_plugin.highlight")

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
        keymap = {
            close = options.keymap.close,
            focus_next = options.keymap.focus_next,
            focus_prev = options.keymap.focus_prev,
            focus_left = options.keymap.focus_left,
            focus_right = options.keymap.focus_right,
            focus_up = options.keymap.focus_up,
            focus_down = options.keymap.focus_down,
        }
    })

    renderer:on_mount(function()
        -- M.renderer = renderer

        -- utils.attach_resize(augroup, renderer, ui)

        -- if c.ui.autoclose then
        --   utils.attach_autoclose(renderer)
        -- end
        -- utils.attach_autoclose(renderer)
    end)

    renderer:on_unmount(function()
        -- pcall(vim.api.nvim_del_augroup_by_name, augroup)
    end)

    local initialize_signals = not options.preserve_querry_on_close or signal.query_signal == nil
    if initialize_signals then
        signal.initialize_signals()
    end

    local subscription_search = signal.query_signal:observe(subscription)

    local body = require("my_awesome_plugin.body")
    renderer:render(body(renderer))
end

return M
