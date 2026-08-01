return function()
  hl.config({
    input = {
      kb_layout = "gb",
      kb_variant = "",
      kb_model = "",
      kb_options = "",
      kb_rules = "",
      follow_mouse = 1,
      sensitivity = 0,
      touchpad = { natural_scroll = true },
    },
  })
  hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
end
