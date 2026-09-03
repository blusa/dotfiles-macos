-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- Set a custom font and font size
config.font = wezterm.font("JetBrains Mono", { weight = "Regular" })
config.font_size = 15.0

-- Set a color scheme
config.window_decorations = "RESIZE"
config.window_background_opacity = 0.85
config.macos_window_background_blur = 20
config.enable_tab_bar = false
config.color_scheme = "tokyonight_night"

-- Set initial window dimensions
config.initial_cols = 120
config.initial_rows = 30

-- Define some key assignments
config.keys = {
	{
		key = "r",
		mods = "CMD|SHIFT",
		action = wezterm.action.ReloadConfiguration,
	},
}

-- Return the configuration to wezterm
return config
