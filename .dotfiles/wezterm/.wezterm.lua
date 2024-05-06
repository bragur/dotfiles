local wezterm = require("wezterm")
local config = wezterm.config_builder()
local defaults = require("defaults")
local ui = require("ui")
local fonts = require("fonts")

defaults.apply_to_config(config)
ui.apply_to_config(config)
fonts.apply_to_config(config)

return config
