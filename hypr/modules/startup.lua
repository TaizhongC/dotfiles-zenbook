return function()
  hl.on("hyprland.start", function()
    -- Replace an autostarted instance so it always reloads this profile
    -- (notably the Rime Pinyin input method).
    hl.exec_cmd("fcitx5 -r -d --disable notificationitem")
    -- Quickshell owns the bar, notifications, launcher, dashboard, and OSD.
    -- Keep this guarded so a missing package cannot prevent the rest of the
    -- desktop session from starting during a package upgrade.
    hl.exec_cmd("sh -c 'command -v quickshell >/dev/null 2>&1 && (pgrep -x quickshell >/dev/null 2>&1 || quickshell)'")
    hl.exec_cmd("pgrep -x hypridle >/dev/null 2>&1 || hypridle")
    hl.exec_cmd("sh -c 'command -v cursorctl >/dev/null 2>&1 && cursorctl apply'")
    hl.exec_cmd("sh -c 'command -v wallpaperctl >/dev/null 2>&1 && wallpaperctl restore'")
  end)
end
