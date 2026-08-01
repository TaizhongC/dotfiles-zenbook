return function(ctx)
  ctx.terminal = "kitty"
  ctx.file_manager = "thunar"

  -- Fuzzel is installed here. Fall back to other common Wayland launchers
  -- without embedding a user or configuration-directory path.
  ctx.menu = "sh -c 'if command -v fuzzel >/dev/null 2>&1; then exec fuzzel; elif command -v wofi >/dev/null 2>&1; then exec wofi --show drun; elif command -v rofi >/dev/null 2>&1; then exec rofi -show drun; fi'"
end
