return function()
  hl.device({ name = "epic-mouse-v1", sensitivity = -0.5 })
  hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
  })
  hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
  })
  hl.window_rule({
    name = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move = "20 monitor_h-120",
    float = true,
  })
  hl.window_rule({
    name = "center-nwg-displays",
    match = { class = "nwg-displays" },
    float = true,
    center = true,
    size = "1000 700",
  })
  hl.layer_rule({
    name = "no-anim-quickshell",
    match = { namespace = "^(quickshell.*)$" },
    no_anim = true,
  })
end
