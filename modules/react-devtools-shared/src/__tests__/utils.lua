--!nonstrict
local HttpService = game:GetService("HttpService")
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/utils.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent
local ReactGlobals = require(Packages.ReactGlobals)
local JestGlobals = require(Packages.Dev.JestGlobals)
local jest = JestGlobals.jest
local jestExpect = JestGlobals.expect

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Number = LuauPolyfill.Number
local Object = LuauPolyfill.Object
type Function = (...any) -> any?
local global = ReactGlobals :: any
local exports = {}

local Bridge = require(script.Parent.Parent.bridge)
type FrontendBridge = Bridge.FrontendBridge
local devtoolsTypes = require(script.Parent.Parent.devtools.types)
type Store = devtoolsTypes.Store
local ProfilerTypes = require(script.Parent.Parent.devtools.views.Profiler.types)
type ProfilingDataFrontend = ProfilerTypes.ProfilingDataFrontend
local Types = require(script.Parent.Parent.types)
type ElementType = Types.ElementType

exports.act = function(callback: () -> ()): ()
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

	while jest.getTimerCount() > 0 do
		actDOM(function()
			-- actTestRenderer(function()
			jest.runAllTimers()
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
			end)
		end
	else
		-- $FlowFixMe Flow doesn't know about "await act()" yet
		actDOM(function()
			-- return actTestRenderer(function()
			jest.runOnlyPendingTimers()
			-- end):await()
		end)
	end
end

exports.beforeEachProfiling = function(): ()
	-- ROBLOX deviation BEGIN: we handle this differently until jest-roblox 27.5 is available
	-- Mock React's timing information so that test runs are predictable.
	jest.mock(Packages.Dev.Scheduler, function()
		return require(Packages.Parent.Scheduler.Scheduler.unstable_mock)
	end)
	-- DevTools itself uses performance.now() to offset commit times
	-- so they appear relative to when profiling was started in the UI.
	-- ROBLOX deviation: os.clock not performance
	-- ROBLOX TODO: Can you actually spy on os.clock?
	-- ROBLOX deviation BEGIN: We need to do slightly more targeted mocking until
	local Scheduler = require(Packages.Dev.Scheduler)
	jest.mockOsClock(Scheduler.unstable_now)
	-- jest.spyOn(os, "clock").mockImplementation(
	-- 	jest.requireActual("scheduler/unstable_mock").unstable_now
	-- )
	-- ROBLOX deviation END
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
	-- ROBLOX FIXME Luau: if-expression boolean doesn't narrow id correctly
	return if id then tonumber(id) :: number else Number.NaN
end
exports.requireTestRenderer = function(): any
	-- Hide the hook before requiring TestRenderer, so we don't end up with a loop.
	local hook = ReactGlobals.__REACT_DEVTOOLS_GLOBAL_HOOK__
	ReactGlobals.__REACT_DEVTOOLS_GLOBAL_HOOK__ = nil

	local success, module = pcall(function()
		return require(Packages.Dev.ReactTestRenderer)
	end)

	ReactGlobals.__REACT_DEVTOOLS_GLOBAL_HOOK__ = hook

	if not success then
		warn("Failed to require TestRenderer", module)
		return nil
	else
		return module
	end
end

exports.exportImportHelper = function(bridge: FrontendBridge, store: Store): ()
	local utils = require(script.Parent.Parent.devtools.views.Profiler.utils)
	local prepareProfilingDataExport = utils.prepareProfilingDataExport
	local prepareProfilingDataFrontendFromExport =
		utils.prepareProfilingDataFrontendFromExport
	local profilerStore = store._profilerStore

	local profilingDataFrontendInitial = profilerStore:profilingData()
	jestExpect(profilingDataFrontendInitial).never.toBeNull()
	-- ROBLOX deviation: luau needs the assert since .never.toBeNull() doesn't have narrowing side-effects right now
	assert(profilingDataFrontendInitial, "profilingDataFrontendInitial was nil")

	jestExpect(profilingDataFrontendInitial.imported).toBe(false)

	local profilingDataExport = prepareProfilingDataExport(profilingDataFrontendInitial)

	-- Simulate writing/reading to disk.
	local serializedProfilingDataExport = HttpService:JSONEncode(profilingDataExport)
	local parsedProfilingDataExport =
		HttpService:JSONDecode(serializedProfilingDataExport)

	local profilingDataFrontend =
		prepareProfilingDataFrontendFromExport(parsedProfilingDataExport)
	jestExpect(profilingDataFrontend.imported).toBe(true)

	-- Sanity check that profiling snapshots are serialized correctly.
	jestExpect(profilingDataFrontendInitial.dataForRoots).toEqual(
		profilingDataFrontend.dataForRoots
	)

	-- Snapshot the JSON-parsed object, rather than the raw string, because Jest formats the diff nicer.
	jestExpect(parsedProfilingDataExport).toMatchSnapshot("imported data")

	exports.act(function()
		-- Apply the new exported-then-imported data so tests can re-run assertions.
		profilerStore:profilingData(profilingDataFrontend)
	end)
end

return exports
