-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/utils.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent
local RobloxJest = require(Packages.Dev.RobloxJest)
local JestGlobals = require(Packages.Dev.JestGlobals)
local jest = JestGlobals.jest

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Number = LuauPolyfill.Number
local Object = LuauPolyfill.Object
type Function = (...any) -> any?
local global = _G
local exports = {}

local Bridge = require(script.Parent.Parent.bridge)
type FrontendBridge = Bridge.FrontendBridge
local Store = require(script.Parent.Parent.devtools.store)
type Store = Store.Store
local ProfilerTypes = require(script.Parent.Parent.devtools.views.Profiler.types)
type ProfilingDataFrontend = ProfilerTypes.ProfilingDataFrontend
local Types = require(script.Parent.Parent.types)
type ElementType = Types.ElementType

exports.act = function(callback: Function): ()
	-- ROBLOX deviation: TestRenderer and RobloxRenderer do not play nice with
	-- one another right now. All of the ported tests in this package are
	-- using only the ReactRoblox renderer, so we only wrap with it directly

	-- local actTestRenderer = require(Packages.Dev.ReactTestRenderer).act

	local actDOM = require(Packages.ReactRoblox).act

	actDOM(function()
		-- actTestRenderer(function()
		callback()
		-- end)
	end)

	while RobloxJest.getTimerCount() > 0 do
		actDOM(function()
			-- actTestRenderer(function()
			RobloxJest.runAllTimers()
			-- end)
		end)
	end
end

exports.actAsync = function(cb: () -> any, recursivelyFlush: boolean?)
	if recursivelyFlush == nil then
		recursivelyFlush = true
	end

	-- ROBLOX deviation: TestRenderer and RobloxRenderer do not play nice with
	-- one another right now. All of the ported tests in this package are
	-- using only the ReactRoblox renderer, so we only wrap with it directly
	-- local actTestRenderer = require(Packages.Dev.ReactTestRenderer).act

	local actDOM = require(Packages.ReactRoblox).act

	if recursivelyFlush then
		while jest.getTimerCount() > 0 do
			-- $FlowFixMe Flow doesn't know about "await act()" yet
			actDOM(function()
				-- return actTestRenderer(function()
				jest.runAllTimers()
				-- end):await()
			end):await()
		end
	else
		-- $FlowFixMe Flow doesn't know about "await act()" yet
		actDOM(function()
			-- return actTestRenderer(function()
			jest.runOnlyPendingTimers()
			-- end):await()
		end):await()
	end
end

exports.beforeEachProfiling = function(): ()
	-- Mock React's timing information so that test runs are predictable.
	jest.mock("scheduler", function()
		return jest.requireActual("scheduler/unstable_mock")
	end)
	-- DevTools itself uses performance.now() to offset commit times
	-- so they appear relative to when profiling was started in the UI.
	-- ROBLOX deviation: os.clock not performance
	-- ROBLOX TODO: Can you actually spy on os.clock?
	jest.spyOn(os, "clock").mockImplementation(
		jest.requireActual("scheduler/unstable_mock").unstable_now
	)
end

exports.createDisplayNameFilter = function(source: string, isEnabled: boolean?)
	if isEnabled == nil then
		isEnabled = true
	end
	-- ROBLOX deviation: Cannot sanitize source as a RegExp so assume valid
	local isValid = true

	return {
		type = Types.ComponentFilterDisplayName,
		isEnabled = isEnabled,
		isValid = isValid,
		value = source,
	}
end

exports.createHOCFilter = function(isEnabled: boolean?)
	if isEnabled == nil then
		isEnabled = true
	end

	return {
		type = Types.ComponentFilterHOC,
		isEnabled = isEnabled,
		isValid = true,
	}
end

exports.createElementTypeFilter = function(elementType: ElementType, isEnabled: boolean?)
	if isEnabled == nil then
		isEnabled = true
	end

	return {
		type = Types.ComponentFilterElementType,
		isEnabled = isEnabled,
		value = elementType,
	}
end

exports.createLocationFilter = function(source: string, isEnabled: boolean?)
	if isEnabled == nil then
		isEnabled = true
	end
	local isValid = true

	return {
		type = Types.ComponentFilterLocation,
		isEnabled = isEnabled,
		isValid = isValid,
		value = source,
	}
end

exports.getRendererID = function(): number
	if global.agent == nil then
		error("Agent unavailable.")
	end

	local ids = Object.keys(global.agent._rendererInterfaces)
	local id = Array.find(ids, function(innerID)
		-- ROBLOX deviation: Let's return all renderers
		-- local rendererInterface = global.agent._rendererInterfaces[innerID]
		-- return rendererInterface.renderer.rendererPackageName == 'react-dom'
		return true
	end)

	if ids == nil then
		error("Could not find renderer.")
	end

	-- ROBLOX FIXME: create Number.parseInt() in luau-polyfill
	return id and tonumber(id) or Number.NaN
end
exports.requireTestRenderer = function()
	local hook
	pcall(function()
		-- Hide the hook before requiring TestRenderer, so we don't end up with a loop.
		hook = global.__REACT_DEVTOOLS_GLOBAL_HOOK__
		global.__REACT_DEVTOOLS_GLOBAL_HOOK__ = nil

		return require(Packages.Dev.ReactTestRenderer)
	end)
	global.__REACT_DEVTOOLS_GLOBAL_HOOK__ = hook
end

-- ROBLOX TODO: currently a stub
exports.exportImportHelper = function(bridge: FrontendBridge, store: Store): ()
	-- local _require5 = require(script.Parent.Parent.Views.Profiler.utils)
	-- local prepareProfilingDataExport = _require5.prepareProfilingDataExport
	-- local prepareProfilingDataFrontendFromExport = _require5.prepareProfilingDataFrontendFromExport
	-- local profilerStore = store.profilerStore

	-- expect(profilerStore.profilingData).never.toBeNull()

	-- local profilingDataFrontendInitial = profilerStore.profilingData

	-- expect(profilingDataFrontendInitial.imported).toBe(false)

	-- local profilingDataExport = prepareProfilingDataExport(profilingDataFrontendInitial)

	-- local serializedProfilingDataExport = JSON:JSONDecode(profilingDataExport, nil, 2)
	-- local parsedProfilingDataExport = JSON:JSONEncode(serializedProfilingDataExport)
	-- local profilingDataFrontend = prepareProfilingDataFrontendFromExport(parsedProfilingDataExport)

	-- expect(profilingDataFrontend.imported).toBe(true)
	-- expect(profilingDataFrontendInitial.dataForRoots).toEqual(profilingDataFrontend.dataForRoots)
	-- expect(parsedProfilingDataExport).toMatchSnapshot('imported data')

	-- exports.act(function()
	-- 	profilerStore.profilingData = profilingDataFrontend
	-- end)
end

return exports
