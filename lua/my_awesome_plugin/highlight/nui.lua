local colors = require("my_awesome_plugin.highlight.colors")

return {
  NuiComponentsTreeNodeFocused = {
    bg = colors.dark["400"],
  },
  NuiComponentsSelectNodeFocused = {
    bg = colors.dark["400"],
  },
  NuiComponentsSelectOption = {
    fg = colors.dark["100"],
  },
  NuiComponentsSelectOptionSelected = {
    fg = colors.pink["200"],
  },
  NuiComponentsSelectSeparator = {
    fg = colors.yellow["200"],
    -- fg = colors.dark["300"]
  },
  NuiComponentsButtonActive = {
    fg = colors.primary["700"],
    bg = colors.green["100"],
  },
  NuiComponentsButtonFocused = {
    fg = colors.primary["700"],
    bg = colors.yellow["100"],
  },
  NuiComponentsCheckboxLabel = {
    fg = colors.dark["100"],
  },
  NuiComponentsCheckboxLabelChecked = {
    fg = colors.pink["100"],
  },
  NuiComponentsCheckboxIconChecked = {
    fg = colors.pink["100"],
  },
  -- Spectre
  NuiComponentsTreeSpectreIcon = {
    fg = colors.dark["300"],
  },
  -- NuiComponentsTreeSpectreFileName = {
  --   fg = colors.dark["50"]
  -- },
  NuiComponentsTreeSpectreCodeLine = {
    fg = colors.dark["200"],
  },
  NuiComponentsTreeSpectreSearchValue = {
    fg = colors.dark["50"],
    bg = colors.dark["400"],
  },
  NuiComponentsTreeSpectreSearchOldValue = {
    fg = colors.dark["700"],
    bg = colors.red["200"],
    strikethrough = true,
  },
  NuiComponentsTreeSpectreSearchNewValue = {
    fg = colors.dark["700"],
    bg = colors.green["200"],
  },
  NuiComponentsTreeSpectreReplaceSuccess = {
    fg = colors.green["200"],
  },
  NuiComponentsBorderLabel = {
    fg = colors.dark["500"],
    bg = colors.primary["300"],
  },
}
