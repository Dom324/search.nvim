local hls = {
  require("my_awesome_plugin.highlight.nui"),
}

for _, hl in pairs(hls) do
  for name, col in pairs(hl) do
    vim.api.nvim_set_hl(0, name, col)
  end
end
