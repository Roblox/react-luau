-- ROBLOX note: upstream doesn't have a root index.js, we may want to contribute a proper contract upstream

local Bridge = require(script.bridge)
local Types = require(script.types)
local Backend = require(script.backend)

export type BackendBridge = Bridge.BackendBridge
export type ComponentFilter = Types.ComponentFilter
export type DevtoolsHook = Backend.DevToolsHook

return {
	constants = require(script.constants),
	backend = require(script.backend),
	bridge = require(script.bridge),
	devtools = require(script.devtools),
	hydration = require(script.hydration),
	hook = require(script.hook),
	utils = require(script.utils),
}
