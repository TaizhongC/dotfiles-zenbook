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
    -- Fullscreen is implemented as a compositor-driven resize.  Hyprland
    -- skips that animation unless manual resizes are explicitly enabled.
    misc = {
      force_default_wallpaper = 0,
      disable_hyprland_logo = true,
      animate_manual_resizes = true,
      -- The internal panel supports Adaptive Sync from 48 to 120 Hz.
      vrr = 1,
    },
  })

  hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
  hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
  hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
  hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1 } } })
  hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

  hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
  hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
  -- Fullscreen changes (Super+F) use the regular window animation.  A slide
  -- transition makes the change visible without the spring overshoot/bounce.
  hl.animation({ leaf = "windows", enabled = true, speed = 4.79, bezier = "easeInOutCubic", style = "slide" })
  -- Keep window mapping to one subtle visual effect.  Combining a scale and
  -- opacity fade can make a newly mapped client look like it flashes.
  hl.animation({ leaf = "windowsIn", enabled = true, speed = 2.5, bezier = "easeOutQuint", style = "popin 90%" })
  hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "easeInOutCubic", style = "popin 90%" })
  -- Fullscreen toggles are geometry changes, so they use windowsMove rather
  -- than the parent windows animation.  Keep it enabled for a smooth
  -- fullscreen transition while retaining the same timing and easing.
  hl.animation({ leaf = "windowsMove", enabled = true, speed = 2.8, bezier = "easeInOutCubic", style = "slide" })
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
