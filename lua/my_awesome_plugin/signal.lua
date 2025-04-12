local M = {}

local n = require("nui-components")
local utils = require("my_awesome_plugin.utils")
local enums = require("my_awesome_plugin.enums")

M.defaults = {
    query_signal = {
        search_query = "",
        replace_query = "",
        is_case_insensitive_checked = false,
        is_whole_word_checked = false,

        glob_query = "",
        is_hidden_checked = false,
        is_ignored_checked = false,
        search_cwd = enums.cwd.PROJECT,
        search_cwd_str = enums.cwd_str.PROJECT,
    },
    search_results_signal = {
        search_results = {},
        is_search_loading = false,
        search_info = "",
    },
    file_results_signal = {
        is_file_search_loading = false,
        file_results = {},
        search_info = ""
    }
}

function M.initialize_signals()
    M.query_signal = n.create_signal(M.defaults.query_signal)
    M.search_results_signal = n.create_signal(M.defaults.search_results_signal)
    M.file_results_signal = n.create_signal(M.defaults.file_results_signal)
end

function M.reset_querry_state()
    -- query_signal = M.defaults.query_signal

    utils.set_component_buffer_content(M.renderer:get_component_by_id("search_query"), "")
    utils.set_component_buffer_content(M.renderer:get_component_by_id("replace_query"), "")
    utils.set_component_buffer_content(M.renderer:get_component_by_id("glob_query"), "")
end

function M.reset_search_results_state()
    -- search_results_signal = M.defaults.search_results_signal
end

function M.reset_file_results_state()
    -- file_results_signal = M.defaults.file_results_signal
end

function M.reset_signal_state_and_component_buffers()
    M.reset_querry_state()
    M.reset_file_results_state()
    M.reset_search_results_state()
end

return M
