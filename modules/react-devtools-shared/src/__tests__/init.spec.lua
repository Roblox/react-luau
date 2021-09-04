return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Array = LuauPolyfill.Array

	local global = _G

	type Array<T> = { [number]: T }

	beforeAll(function()
		jestExpect.extend({
			toErrorDev = RobloxJest.Matchers.toErrorDev,
			toWarnDev = RobloxJest.Matchers.toWarnDev,
		})
	end)

	beforeEach(function()
		-- These files should be required (and re-required) before each test,
		-- rather than imported at the head of the module.
		-- That's because we reset modules between tests,
		-- which disconnects the DevTool's cache from the current dispatcher ref.
		local Agent = require(script.Parent.Parent.backend.agent)
		local initBackend = require(script.Parent.Parent.backend).initBackend
		local Bridge = require(script.Parent.Parent.bridge)
		local Store = require(script.Parent.Parent.devtools.store)
		local installHook = require(script.Parent.Parent.hook).installHook
		local utils = require(script.Parent.Parent.utils)
		local getDefaultComponentFilters = utils.getDefaultComponentFilters
		local saveComponentFilters = utils.saveComponentFilters

		-- Fake timers let us flush Bridge operations between setup and assertions.
		RobloxJest.useFakeTimers()

		-- Initialize filters to a known good state.
		saveComponentFilters(getDefaultComponentFilters())
		global.__REACT_DEVTOOLS_COMPONENT_FILTERS__ = getDefaultComponentFilters()

		installHook(global)

		local bridgeListeners = {}
		local bridge = Bridge.new({
			listen = function(callback)
				table.insert(bridgeListeners, callback)
				return function()
					local index = Array.indexOf(bridgeListeners, callback)
					if index >= 0 then
						Array.splice(bridgeListeners, index, 1)
					end
				end
			end,
			send = function(event: string, payload: any, transferable: Array<any>?)
				for _, callback in ipairs(bridgeListeners) do
					callback({ event = event, payload = payload })
				end
			end,
		})

		local agent = Agent.new(bridge)
		local hook = _G.__REACT_DEVTOOLS_GLOBAL_HOOK__

		initBackend(hook, agent, global)

		local store = Store.new(bridge)

		global.agent = agent
		global.bridge = bridge
		global.store = store
	end)

	afterEach(function()
		_G.__REACT_DEVTOOLS_GLOBAL_HOOK__ = nil

		-- It's important to reset modules between test runs;
		-- Without this, ReactDOM won't re-inject itself into the new hook.
		-- It's also important to reset after tests, rather than before,
		-- so that we don't disconnect the ReactCurrentDispatcher ref.
		RobloxJest.resetModules()
	end)
end
