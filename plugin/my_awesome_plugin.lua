vim.api.nvim_create_user_command("Search", function(args)
    require("my_awesome_plugin.search_core").toggle()
end, { nargs = 0 })
