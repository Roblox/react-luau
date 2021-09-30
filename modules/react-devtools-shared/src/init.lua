-- ROBLOX note: upstream doesn't have a root index.js, we may want to contribute a proper contract upstream

local Backend = require(script.backend)
export type DevToolsHook = Backend.DevToolsHook
export type ReactRenderer = Backend.ReactRenderer
export type RendererInterface = Backend.RendererInterface

return {
	backend = Backend,
	bridge = require(script.bridge),
	devtools = require(script.devtools),
	hydration = require(script.hydration),
	-- ROBLOX TODO: re-export typed needed outside the module boundary
	-- types = require(script.types),
	utils = require(script.utils),
}
