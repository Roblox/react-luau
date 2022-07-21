-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-extensions/src/backend.js
local Packages = script.Parent.Parent
local ReactDevtoolsShared = require(Packages.ReactDevtoolsShared)

local backend = ReactDevtoolsShared.backend
local Agent = backend.agent
local initBackend = backend.initBackend
local Bridge = ReactDevtoolsShared.bridge

local insert = table.insert
local remove = table.remove

type Array<T> = { [number]: T }
type BridgeEvent = {
	source: string,
	event: any,
	payload: any,
}
type BridgeListener = (BridgeEvent) -> ()

local function setup(hook)
	local bridgeListeners: Array<BridgeListener> = {}
	local bridge = Bridge.new({
		listen = function(fn: BridgeListener)
			-- ROBLOX deviation: Because we don't listen for all messages on window like in browser,
			-- we don't need to verify their source
			insert(bridgeListeners, fn)
			return function()
				for index, value in bridgeListeners do
					if value == fn then
						remove(bridgeListeners, index)
						return
					end
				end
			end
		end,
		send = function(event: string, payload: any, transferable: Array<any>?)
			for _, fn in bridgeListeners do
				fn({
					source = "react-devtools-bridge",
					event = event,
					payload = payload,
				})
			end
		end,
	})

	local agent = Agent.new(bridge)
	agent:addListener("shutdown", function()
		-- If we received 'shutdown' from `agent`, we assume the `bridge` is already shutting down,
		-- and that caused the 'shutdown' event on the `agent`, so we don't need to call `bridge.shutdown()` here.
		hook.emit("shutdown")
	end)

	initBackend(hook, agent, _G)

	-- Let the frontend know that the backend has attached listeners and is ready for messages.
	-- This covers the case of syncing saved values after reloading/navigating while DevTools remain open.
	bridge:send("extensionBackendInitialized")

	return {
		agent = agent,
		hook = hook,
		bridge = bridge,
	}
end

return {
	setup = setup,
}
