return function(ctx)
  ctx.terminal = "kitty"
  ctx.file_manager = "thunar"

  -- Quickshell owns the application launcher. Its IPC target is provided by
  -- modules/bar/BarWrapper.qml and is available on the active Wayland session.
  ctx.menu = "qs ipc call shell toggleLauncher"
end
