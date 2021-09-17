--[[
	ROBLOX deviation: ReactFiberHostConfig captures singleton state across the
	whole workspace. This file and the modules it requires were moved from React
	to untangle a cyclic workspace member dependency.

	Before:
	* ReactFiberHostConfig (and the 5 associated modules) lived in React
	* React had a dependency on Shared
	* Shared reached into React source to re-export ReactFiberHostConfig (cycle)

	After:
	* ReactFiberHostConfig (and the 5 associated modules) live in Shared
	* React depends on Shared
	* Shared has no intra-workspace dependencies (no cycles)
]]

-- types that are common across ReactFiberHostConfig files, moved here to avoid circular deps
type Object = { [string]: any }
export type OpaqueIDType = string | Object

return {
	WithNoHydration = require(script.WithNoHydration),
	WithNoPersistence = require(script.WithNoPersistence),
	WithNoTestSelectors = require(script.WithNoTestSelectors),
}
