return function()
  -- Use the panel's native preferred mode with a comfortable fractional HiDPI
  -- scale, without binding the setup to a particular connector or resolution.
  hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = 1.6,
  })
end
