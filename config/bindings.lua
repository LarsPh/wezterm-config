local wezterm = require('wezterm')
local platform = require('utils.platform')
local backdrops = require('utils.backdrops')
local act = wezterm.action
-- local resurrect = require('config.resurrect')
local sessions = wezterm.plugin.require("https://github.com/abidibo/wezterm-sessions")
local workspace_switcher = require('config.workspace_switcher')
local mod = {}

if platform.is_mac then
   mod.SUPER = 'SUPER'
   mod.SUPER_REV = 'SUPER|CTRL'
elseif platform.is_win or platform.is_linux then
   mod.SUPER = 'ALT' -- to not conflict with Windows key shortcuts
   mod.SUPER_REV = 'ALT|CTRL'
end

-- stylua: ignore
local keys = {
   -- misc/useful --
   { key = 'F1', mods = 'NONE', action = 'ActivateCopyMode' },
   { key = 'F2', mods = 'NONE', action = act.ActivateCommandPalette },
   { key = 'F3', mods = 'NONE', action = act.ShowLauncher },
   { key = 'F4', mods = 'NONE', action = act.ShowLauncherArgs({ flags = 'FUZZY|TABS' }) },
   {
      key = 'F5',
      mods = 'NONE',
      action = act.ShowLauncherArgs({ flags = 'FUZZY|WORKSPACES' }),
   },
   { key = 'F11', mods = 'NONE',    action = act.ToggleFullScreen },
   { key = 'F12', mods = 'NONE',    action = act.ShowDebugOverlay },
   { key = 'f',   mods = mod.SUPER, action = act.Search({ CaseInSensitiveString = '' }) },
   {
      key = 'u',
      mods = mod.SUPER_REV,
      action = wezterm.action_callback(function(window, pane)
         local url = window:get_selection_text_for_pane(pane)
         wezterm.log_info('opening: ' .. url)
         wezterm.open_with(url)
      end),
   },

   -- cursor movement --
   { key = 'LeftArrow',  mods = mod.SUPER,     action = act.SendString '\u{1b}OH' },
   { key = 'RightArrow', mods = mod.SUPER,     action = act.SendString '\u{1b}OF' },
   { key = 'Backspace',  mods = mod.SUPER,     action = act.SendString '\u{15}' },

   -- copy/paste --
   { key = 'c',          mods = 'CTRL|SHIFT',  action = act.CopyTo('Clipboard') },
   { key = 'v',          mods = 'CTRL|SHIFT',  action = act.PasteFrom('Clipboard') },

   -- tabs --
   -- tabs: spawn+close
   { key = 't',          mods = mod.SUPER,     action = act.SpawnTab('DefaultDomain') },
   { key = 't',          mods = mod.SUPER_REV, action = act.SpawnTab({ DomainName = 'WSL:Ubuntu' }) },
   { key = 'w',          mods = mod.SUPER_REV, action = act.CloseCurrentTab({ confirm = false }) },

   -- tabs: navigation
   { key = '[',          mods = mod.SUPER,     action = act.ActivateTabRelative(-1) },
   { key = ']',          mods = mod.SUPER,     action = act.ActivateTabRelative(1) },
   { key = '[',          mods = mod.SUPER_REV, action = act.MoveTabRelative(-1) },
   { key = ']',          mods = mod.SUPER_REV, action = act.MoveTabRelative(1) },

   -- tab: title
   { key = '0',          mods = mod.SUPER,     action = act.EmitEvent('tabs.manual-update-tab-title') },
   { key = '0',          mods = mod.SUPER_REV, action = act.EmitEvent('tabs.reset-tab-title') },

   -- tab: hide tab-bar
   { key = '9',          mods = mod.SUPER,     action = act.EmitEvent('tabs.toggle-tab-bar'), },

   -- window --
   -- window: spawn windows
   { key = 'n',          mods = mod.SUPER,     action = act.SpawnWindow },

   -- window: zoom window
   {
      key = '-',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         local dimensions = window:get_dimensions()
         if dimensions.is_full_screen then
            return
         end
         local new_width = dimensions.pixel_width - 50
         local new_height = dimensions.pixel_height - 50
         window:set_inner_size(new_width, new_height)
      end)
   },
   {
      key = '=',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         local dimensions = window:get_dimensions()
         if dimensions.is_full_screen then
            return
         end
         local new_width = dimensions.pixel_width + 50
         local new_height = dimensions.pixel_height + 50
         window:set_inner_size(new_width, new_height)
      end)
   },

   -- background controls --
   {
      key = [[/]],
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:random(window)
      end),
   },
   {
      key = [[,]],
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:cycle_back(window)
      end),
   },
   {
      key = [[.]],
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:cycle_forward(window)
      end),
   },
   {
      key = [[/]],
      mods = mod.SUPER_REV,
      action = act.InputSelector({
         title = 'InputSelector: Select Background',
         choices = backdrops:choices(),
         fuzzy = true,
         fuzzy_description = 'Select Background: ',
         action = wezterm.action_callback(function(window, _pane, idx)
            if not idx then
               return
            end
            ---@diagnostic disable-next-line: param-type-mismatch
            backdrops:set_img(window, tonumber(idx))
         end),
      }),
   },
   {
      key = 'b',
      mods = mod.SUPER,
      action = wezterm.action_callback(function(window, _pane)
         backdrops:toggle_focus(window)
      end)
   },

   -- panes --
   -- panes: split panes
   {
      key = [[\]],
      mods = mod.SUPER,
      action = act.SplitVertical({ domain = 'CurrentPaneDomain' }),
   },
   {
      key = [[\]],
      mods = mod.SUPER_REV,
      action = act.SplitHorizontal({ domain = 'CurrentPaneDomain' }),
   },

   -- panes: zoom+close pane
   { key = 'Enter', mods = mod.SUPER,     action = act.TogglePaneZoomState },
   { key = 'w',     mods = mod.SUPER,     action = act.CloseCurrentPane({ confirm = false }) },

   -- panes: navigation
   { key = 'k',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Up') },
   { key = 'j',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Down') },
   { key = 'h',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Left') },
   { key = 'l',     mods = mod.SUPER_REV, action = act.ActivatePaneDirection('Right') },
   {
      key = 'p',
      mods = mod.SUPER_REV,
      action = act.PaneSelect({ alphabet = '1234567890', mode = 'SwapWithActiveKeepFocus' }),
   },

   -- panes: scroll pane
   { key = 'u',        mods = mod.SUPER, action = act.ScrollByLine(-5) },
   { key = 'd',        mods = mod.SUPER, action = act.ScrollByLine(5) },
   { key = 'PageUp',   mods = 'NONE',    action = act.ScrollByPage(-0.75) },
   { key = 'PageDown', mods = 'NONE',    action = act.ScrollByPage(0.75) },

   -- key-tables --
   -- resizes fonts
   {
      key = 'f',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_font',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
   -- resize panes
   {
      key = 'p',
      mods = 'LEADER',
      action = act.ActivateKeyTable({
         name = 'resize_pane',
         one_shot = false,
         timemout_miliseconds = 1000,
      }),
   },
   -- workspace switcher
   {
      key = 'w',
      mods = mod.SUPER_REV,
      action = workspace_switcher.switch_workspace(),
   },
   {
      key = 'W',
      mods = mod.SUPER_REV,
      action = workspace_switcher.switch_to_prev_workspace(),
   },
   -- rename/create workspace
   {
      key = 'F6',
      mods = 'NONE',
      action = act.PromptInputLine {
         description = 'Enter new workspace name',
         action = wezterm.action_callback(
               function(window, pane, line)
                  if line then
                     wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
                  end
               end
         ),
      },
   },
   {
      key = 'N',
      mods = mod.SUPER,
      action = act.PromptInputLine {
         description = wezterm.format {
            { Attribute = { Intensity = 'Bold' } },
            { Foreground = { AnsiColor = 'Fuchsia' } },
            { Text = 'Enter name for new workspace' },
         },
         action = wezterm.action_callback(function(window, pane, line)
            -- line will be `nil` if they hit escape without entering anything
            -- An empty string if they just hit enter
            -- Or the actual line of text they wrote
            if line then
                  window:perform_action(
                     act.SwitchToWorkspace {
                        name = line,
                     },
                     pane
                  )
            end
         end),
      },
   },
   -- resurrect
   -- {
   --    key = 's',
   --    mods = mod.SUPER_REV,
   --    action = wezterm.action_callback(function(win, pane)
   --       resurrect.state_manager.save_state(resurrect.workspace_state.get_workspace_state())
   --       resurrect.window_state.save_window_action()
   --    end),
   -- },
   -- {
   --    key = 'S',
   --    mods = mod.SUPER_REV,
   --    action = resurrect.tab_state.save_tab_action(),
   -- },
   -- {
   --    key = 'l',
   --    mods = mod.SUPER,
   --    action = wezterm.action_callback(function(win, pane)
   --       wezterm.log_info('Super+L pressed: Initiating fuzzy_load')
   --       resurrect.fuzzy_loader.fuzzy_load(win, pane, function(id, label)
   --          if not id then
   --             wezterm.log_warn('Fuzzy loader cancelled or no selection.')
   --             return
   --          end
   --          wezterm.log_info('Fuzzy loader selected: id=' .. tostring(id) .. ', label=' .. tostring(label))

   --          local type_from_plugin
   --          local file_name_from_plugin
   --          local separator_pos = string.find(id, "[/\\]") -- Find first / or \

   --          if separator_pos then
   --             type_from_plugin = string.sub(id, 1, separator_pos - 1)
   --             file_name_from_plugin = string.sub(id, separator_pos + 1)
   --          else
   --             wezterm.log_error('Could not parse type/file from fuzzy loader ID: ' .. tostring(id))
   --             -- Attempt a fallback if no separator, assuming id might just be filename for a default type
   --             -- or that the plugin might change its id format. This part is speculative.
   --             -- For now, we'll error out if parsing fails.
   --             return
   --          end

   --          -- id_to_load should be the filename without the .json extension
   --          local id_to_load = string.match(file_name_from_plugin, "(.+)%..+$")
   --          if not id_to_load then
   --             id_to_load = file_name_from_plugin -- Fallback if no extension (e.g. if format changes)
   --          end

   --          wezterm.log_info('Parsed: type_from_plugin=' .. tostring(type_from_plugin) .. ', file_name_from_plugin=' .. tostring(file_name_from_plugin) .. ', id_to_load=' .. tostring(id_to_load))

   --          local opts = {
   --             relative = true,
   --             restore_text = true,
   --             on_pane_restore = resurrect.tab_state.default_on_pane_restore,
   --          }
   --          -- Create a loggable version of opts
   --          local loggable_opts = {}
   --          for k, v in pairs(opts) do
   --             if type(v) == "function" then
   --                loggable_opts[k] = "<function>"
   --             else
   --                loggable_opts[k] = v
   --             end
   --          end
   --          wezterm.log_info('Using opts: ' .. wezterm.json_encode(loggable_opts))

   --          if type_from_plugin == "workspace" then
   --             wezterm.log_info('Attempting to load and restore workspace: ' .. tostring(id_to_load))
   --             local state = resurrect.state_manager.load_state(id_to_load, "workspace")
   --             wezterm.log_info('Loaded workspace state: ' .. (state and wezterm.json_encode(state) or "nil"))
   --             if state then
   --                resurrect.workspace_state.restore_workspace(state, opts)
   --                wezterm.log_info('Called restore_workspace for: ' .. tostring(id_to_load))
   --             else
   --                wezterm.log_warn('Failed to load workspace state for: ' .. tostring(id_to_load))
   --             end
   --          elseif type_from_plugin == "window" then
   --             wezterm.log_info('Attempting to load and restore window: ' .. tostring(id_to_load))
   --             local state = resurrect.state_manager.load_state(id_to_load, "window")
   --             wezterm.log_info('Loaded window state: ' .. (state and wezterm.json_encode(state) or "nil"))
   --             if state then
   --                resurrect.window_state.restore_window(pane:window(), state, opts)
   --                wezterm.log_info('Called restore_window for: ' .. tostring(id_to_load))
   --             else
   --                wezterm.log_warn('Failed to load window state for: ' .. tostring(id_to_load))
   --             end
   --          elseif type_from_plugin == "tab" then
   --             wezterm.log_info('Attempting to load and restore tab: ' .. tostring(id_to_load))
   --             local state = resurrect.state_manager.load_state(id_to_load, "tab")
   --             wezterm.log_info('Loaded tab state: ' .. (state and wezterm.json_encode(state) or "nil"))
   --             if state then
   --                resurrect.tab_state.restore_tab(pane:tab(), state, opts)
   --                wezterm.log_info('Called restore_tab for: ' .. tostring(id_to_load))
   --             else
   --                wezterm.log_warn('Failed to load tab state for: ' .. tostring(id_to_load))
   --             end
   --          else
   --             wezterm.log_warn('Unknown type_from_plugin for restoration: ' .. tostring(type_from_plugin) .. ' from original id: ' .. tostring(id))
   --          end
   --       end)
   --    end),
   -- },
   {
      key = 's',
      mods = mod.SUPER,
      action = act({ EmitEvent = "save_session" }),
   },
   {
      key = 'l',
      mods = mod.SUPER,
      action = act({ EmitEvent = "load_session" }),
   },
   {
      key = 'r',
      mods = mod.SUPER_REV,
      action = act({ EmitEvent = "restore_session" }),
   },
   {
      key = 'D',
      mods = mod.SUPER,
      action = act({ EmitEvent = "delete_session" }),
   },
   {
      key = 'e',
      mods = mod.SUPER,
      action = act({ EmitEvent = "edit_session" }),
   },
}

-- stylua: ignore
local key_tables = {
   resize_font = {
      { key = 'k',      action = act.IncreaseFontSize },
      { key = 'j',      action = act.DecreaseFontSize },
      { key = 'r',      action = act.ResetFontSize },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
   resize_pane = {
      { key = 'k',      action = act.AdjustPaneSize({ 'Up', 1 }) },
      { key = 'j',      action = act.AdjustPaneSize({ 'Down', 1 }) },
      { key = 'h',      action = act.AdjustPaneSize({ 'Left', 1 }) },
      { key = 'l',      action = act.AdjustPaneSize({ 'Right', 1 }) },
      { key = 'Escape', action = 'PopKeyTable' },
      { key = 'q',      action = 'PopKeyTable' },
   },
}

local mouse_bindings = {
   -- Ctrl-click will open the link under the mouse cursor
   {
      event = { Up = { streak = 1, button = 'Left' } },
      mods = 'CTRL',
      action = act.OpenLinkAtMouseCursor,
   },
}

return {
   disable_default_key_bindings = true,
   -- disable_default_mouse_bindings = true,
   leader = { key = 'Space', mods = mod.SUPER_REV },
   keys = keys,
   key_tables = key_tables,
   mouse_bindings = mouse_bindings,
}
