return function()
  local module_dir = debug.getinfo(1, "S").source:match("^@(.*/)")
  local theme = dofile(module_dir .. "theme.lua")
  hl.config({
    general = {
      gaps_in = 2,
      gaps_out = 4,
      border_size = 0,
      col = {
        active_border = theme.active_border,
        inactive_border = theme.inactive_border,
      },
      resize_on_border = true,
      extend_border_grab_area = 25,
      allow_tearing = false,
      layout = "dwindle",
    },
    decoration = {
      rounding = 16,
      rounding_power = 2,
      active_opacity = 1.0,
      inactive_opacity = 0.75,
      shadow = { enabled = false, range = 12, render_power = 2, color = 0x9911111b },
      blur = { enabled = true, size = 5, passes = 2, vibrancy = 0.12 },
    },
    animations = { enabled = true },
    dwindle = { preserve_split = true },
    master = { new_status = "master" },
    scrolling = { fullscreen_on_one_column = true },
    misc = { force_default_wallpaper = 0, disable_hyprland_logo = true },
  })

  hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
  hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
  hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
  hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
  hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })
  -- A firmer spring keeps the visual style responsive on this high-resolution panel.
  hl.curve("easy", { type = "spring", mass = 1, stiffness = 180, dampening = 22 })

  hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
  hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
  hl.animation({ leaf = "windows", enabled = true, speed = 4.79, spring = "easy" })
  -- Keep window mapping to one subtle visual effect.  Combining a scale and
  -- opacity fade can make a newly mapped client look like it flashes.
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "popin 90%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeInOutCubic", style = "popin 90%" })
  -- Do not animate tiled reflow, resizing or dragging.  Many clients redraw
  -- text only after their final geometry is committed, which otherwise makes
  -- the old buffer visibly stretch during the animation.
  hl.animation({ leaf = "windowsMove", enabled = false })
  hl.animation({ leaf = "fadeIn", enabled = false })
  hl.animation({ leaf = "fadeOut", enabled = false })
  hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
  hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
  hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
  hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
  hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
  hl.animation({ leaf = "workspacesIn", enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
  hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
  hl.animation({ leaf = "zoomFactor", enabled = true, speed = 7, bezier = "quick" })
end
