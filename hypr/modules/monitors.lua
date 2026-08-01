return function()
  -- Use the panel's native preferred mode and let Hyprland choose HiDPI scale.
  -- This keeps the 2880x1800 internal display crisp without hard-coding it.
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto",
  })
end
