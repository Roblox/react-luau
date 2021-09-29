--!strict
local ReactInternalTypes = require(script.ReactInternalTypes)
local ReactRootTags = require(script.ReactRootTags)

export type Dispatcher = ReactInternalTypes.Dispatcher
export type Fiber = ReactInternalTypes.Fiber
export type FiberRoot = ReactInternalTypes.FiberRoot

-- ROBLOX deviation: explicit export for use in createReactNoop
export type UpdateQueue<T> = ReactInternalTypes.UpdateQueue<T>

export type RootTag = ReactRootTags.RootTag

-- ROBLOX deviation: In order to allow host config to be spliced in, we export
-- this top-level package as an initializer function that returns the configured
-- reconciler module
local function initialize(config): { [string]: any }
	local ReactFiberHostConfig = require(script.ReactFiberHostConfig)
	for name, implementation in pairs(config) do
		ReactFiberHostConfig[name] = implementation
	end

	return require(script.ReactFiberReconciler)
end

return initialize
