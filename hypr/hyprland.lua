-- Hyprland configuration entry point. Individual concerns live in modules.
-- This file deliberately contains no machine-specific paths or display IDs.
local config_dir = debug.getinfo(1, "S").source:match("^@(.*/)")
local module_dir = config_dir .. "modules/"
local ctx = { config_dir = config_dir }

local function load_module(name)
  local module = dofile(module_dir .. name .. ".lua")
  if type(module) == "function" then
    module(ctx)
  end
end

load_module("monitors")
load_module("programs")
load_module("startup")
load_module("appearance")
load_module("input")
load_module("bindings")
load_module("rules")
