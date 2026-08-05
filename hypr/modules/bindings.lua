return function(ctx)
  local mod = "SUPER"
  hl.bind(mod .. " + C", hl.dsp.exec_cmd(ctx.terminal))
  hl.bind(mod .. " + Q", hl.dsp.window.close())
  hl.bind(mod .. " + M", hl.dsp.exec_cmd("hyprlock"))
  hl.bind(mod .. " + E", hl.dsp.exec_cmd(ctx.file_manager))
  hl.bind(mod .. " + SPACE", hl.dsp.exec_cmd(ctx.menu))
  -- Unified quickshell central panel (modules/centric/CentricPanelWindow.qml)
  hl.bind(mod .. " + W", hl.dsp.exec_cmd("qs ipc call shell toggleWallpaper"))
  hl.bind(mod .. " + P", hl.dsp.exec_cmd("qs ipc call shell toggleControl"))
  hl.bind(mod .. " + N", hl.dsp.exec_cmd("qs ipc call shell toggleNotifications"))
  hl.bind(mod .. " + D", hl.dsp.exec_cmd("qs ipc call shell toggleCalendar"))
  hl.bind(mod .. " + F", hl.dsp.window.fullscreen())
  hl.bind(mod .. " + T", hl.dsp.window.float({ action = "toggle" }))
  hl.bind("XF86Launch1", hl.dsp.exec_cmd("env GTK_THEME=Adwaita:dark nwg-displays"), { locked = true })
  hl.bind(mod .. " + V", hl.dsp.layout("togglesplit"))
  -- Toggle Fcitx5 between the UK keyboard and Rime Chinese input.
  -- Quickshell polls the input state itself; it has no Waybar signal to send.
  hl.bind("ALT + SHIFT_L", hl.dsp.exec_cmd("fcitx5-remote -t"))
  hl.bind("ALT + SHIFT_R", hl.dsp.exec_cmd("fcitx5-remote -t"))

  for _, direction in ipairs({ "left", "down", "up", "right" }) do
    hl.bind(mod .. " + " .. direction, hl.dsp.focus({ direction = direction }))
  end
  for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ direction = direction }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ direction = direction }))
  end
  for i = 1, 10 do
    local key = i % 10
    hl.bind(mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
  end

  hl.bind(mod .. " + S", hl.dsp.workspace.toggle_special("magic"))
  hl.bind(mod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))
  hl.bind(mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
  hl.bind(mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))
  hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
  hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

  -- Use PipeWire directly. Quickshell observes these changes and shows its OSD.
  hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
  hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true })
  hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true })
  hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true })
  hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { locked = true, repeating = true })
  hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { locked = true, repeating = true })
  hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
  hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
  hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
  hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
  -- Laptop firmware varies: the display-switch key may be XF86Display or F7.
  -- nwg-displays provides the GUI for extending, mirroring, and arranging outputs.
  hl.bind("XF86Display", hl.dsp.exec_cmd("env GTK_THEME=Adwaita:dark nwg-displays"), { locked = true })

  hl.bind("PRINT", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | swappy -f -"))
  hl.bind("SHIFT + PRINT", hl.dsp.exec_cmd("grim - | swappy -f -"))
end
