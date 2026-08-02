return function()
  local home = os.getenv("HOME")
  local state_home = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
  local cursor_theme = "Banana"
  local state_file = io.open(state_home .. "/ricing/current-cursor", "r")
  if state_file then
    local saved_theme = state_file:read("*l")
    state_file:close()
    if saved_theme and saved_theme:match("^[%w%._%-]+$") then
      cursor_theme = saved_theme
    end
  end

  -- Banana is an XCursor theme.  Leave HYPRCURSOR_THEME unset so Hyprland
  -- falls back to this theme when no Hyprcursor theme is installed.
  hl.env("XCURSOR_THEME", cursor_theme)
  hl.env("XCURSOR_SIZE", "24")
  hl.env("HYPRCURSOR_SIZE", "24")
  -- Make Fcitx5 available to apps launched by Hyprland (including desktop
  -- entries), rather than only to programs started from an interactive shell.
  hl.env("GTK_IM_MODULE", "fcitx")
  hl.env("QT_IM_MODULE", "fcitx")
  hl.env("XMODIFIERS", "@im=fcitx")
  hl.env("SDL_IM_MODULE", "fcitx")
  -- GLFW uses the IBus protocol for input methods; Fcitx5 provides it.
  hl.env("GLFW_IM_MODULE", "ibus")
  -- Desktop-entry launchers inherit Hyprland's environment, not the shell's.
  -- Include user helpers without embedding a username-specific path.
  if home then
    hl.env("PATH", home .. "/.local/bin:" .. (os.getenv("PATH") or "/usr/local/bin:/usr/bin"))
  end
end
