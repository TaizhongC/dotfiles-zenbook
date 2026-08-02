return function()
  -- nwg-displays writes its applied layout to ~/.config/hypr/monitors.lua.
  -- Use that layout when present; retain a safe generic fallback until the
  -- first layout is applied through the GUI.
  local configured = pcall(require, "monitors")
  if configured then
    return
  end

  -- Use the panel's native preferred mode with a comfortable fractional HiDPI
  -- scale, without binding the setup to a particular connector or resolution.
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1.6,
  })
end
