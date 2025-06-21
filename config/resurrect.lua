local wezterm = require("wezterm")
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")
-- local resurrect = wezterm.plugin.require("file:///C:/Users/forev/.config/wezterm/local_plugins/resurrect.wezterm")

resurrect.state_manager.periodic_save({
	interval_seconds = 1 * 60,
	save_workspaces = true,
	save_windows = true,
	save_tabs = true,
})

wezterm.on("resurrect.error", function(err)
	wezterm.log_error("ERROR!")
	wezterm.gui.gui_windows()[1]:toast_notification("resurrect", err, nil, 3000)
end)

-- Set some directory where Wezterm has write access
return resurrect
