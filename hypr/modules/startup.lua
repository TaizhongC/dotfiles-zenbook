return function()
  hl.on("hyprland.start", function()
    hl.exec_cmd("pgrep -x swaync >/dev/null 2>&1 || swaync")
    hl.exec_cmd("pgrep -x waybar >/dev/null 2>&1 || waybar")
    hl.exec_cmd("sh -c 'command -v wallpaperctl >/dev/null 2>&1 && wallpaperctl restore'")
  end)
end
