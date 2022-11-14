-- ROBLOX upstream: https://github.com/facebook/react/blob/43363e2795393a00fd77312a16d6b80e626c29de/packages/react-reconciler/src/DebugTracing.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Packages = script.Parent.Parent
type Array<T> = { [number]: T }
type Map<K, V> = { [K]: V }
type Object = { [string]: any }
type Function = (any) -> any?
local Shared = require(Packages.Shared)
local console = Shared.console
local exports = {}

-- ROBLOX deviation: hoist log so it's visible
local log
-- ROBLOX deviation: the nucelus emoji `(%c\u{269B}\u{FE0F}%c)` has been replaced with `*`

local ReactFiberLaneModule = require(script.Parent.ReactFiberLane)
type Lane = ReactFiberLaneModule.Lane
type Lanes = ReactFiberLaneModule.Lanes
type Wakeable = Shared.Wakeable

local enableDebugTracing = require(Packages.Shared).ReactFeatureFlags.enableDebugTracing

local nativeConsole: Object = console
local nativeConsoleLog: nil | Function = nil

local pendingGroupArgs: Array<any> = {}
-- ROBLOX deviation: adjust starting indea for Lua 1-based arrays
local printedGroupIndex: number = 0

-- ROBLOX deviation: Luau has no built-in way to convert decimal number to binary string
function decimalToBinaryString(decimal: number): string
	local result = ""
	repeat
		local divres = decimal / 2
		local int, frac = math.modf(divres)
		decimal = int
		result = math.ceil(frac) .. result
	until decimal == 0

	local nbZero = 31 - string.len(result)
	return string.rep("0", nbZero) .. result
end

local function formatLanes(laneOrLanes: Lane | Lanes): string
	return "0b"
		-- ROBLOX deviation: Luau has no built-in way to convert decimal number to binary string
		.. decimalToBinaryString(laneOrLanes)
end

local function group(...): ()
	for _, groupArg in { ... } do
		table.insert(pendingGroupArgs, groupArg)
	end
	if nativeConsoleLog == nil then
		nativeConsoleLog = nativeConsole.log
		nativeConsole.log = log
	end
end

local function groupEnd(): ()
	table.remove(pendingGroupArgs, 1)
	while printedGroupIndex > #pendingGroupArgs do
		nativeConsole.groupEnd()
		printedGroupIndex -= 1
	end
	if #pendingGroupArgs == 0 then
		nativeConsole.log = nativeConsoleLog
		nativeConsoleLog = nil
	end
end

function log(...): ()
	if printedGroupIndex < #pendingGroupArgs then
		for i = printedGroupIndex + 1, #pendingGroupArgs do
			local groupArgs = pendingGroupArgs[i]
			nativeConsole.group(groupArgs)
		end
		printedGroupIndex = #pendingGroupArgs
	end
	if typeof(nativeConsoleLog) == "function" then
		(nativeConsoleLog :: any)(...)
	else
		nativeConsole.log(...)
	end
end

-- ROBLOX deviation: remove color styling
local REACT_LOGO_STYLE = ""

local function logCommitStarted(lanes: Lanes): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			group(
				string.format("* commit (%s)", formatLanes(lanes)),
				REACT_LOGO_STYLE,
				"",
				-- ROBLOX deviation: remove style
				""
			)
		end
	end
end
exports.logCommitStarted = logCommitStarted

local function logCommitStopped(): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			groupEnd()
		end
	end
end
exports.logCommitStopped = logCommitStopped

-- ROBLOX deviation: use raw Lua table
-- const PossiblyWeakMap = typeof WeakMap === 'function' ? WeakMap : Map;
-- $FlowFixMe: Flow cannot handle polymorphic WeakMaps

-- ROBLOX TODO: restore the color message formatting from upstream
-- local wakeableIDs: Map<Wakeable, number> = {}
-- local wakeableID: number = 0
-- local function getWakeableID(wakeable: Wakeable): number
-- 	if not wakeableIDs[wakeable] ~= nil then
-- 		wakeableIDs[wakeable] =
-- 			(function()
-- 				local result = wakeableID
-- 				wakeableID += 1
-- 				return result
-- 			end)()
-- 	end
-- 	return wakeableIDs[wakeable]
-- end

local function logComponentSuspended(componentName: string, wakeable: Wakeable): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			-- local _id = getWakeableID(wakeable)
			-- ROBLOX deviation: our Wakeable can be a function or a callable table
			-- local _display = wakeable.displayName or wakeable
			log(
				string.format("* %s suspended", componentName)
				-- REACT_LOGO_STYLE,
				-- ROBLOX deviation: remove color styling
				-- "",
				-- id,
				-- display
			)
			wakeable:andThen(function()
				log(
					string.format("* %s resolved", componentName)
					-- REACT_LOGO_STYLE,
					-- ROBLOX deviation: remove color styling
					-- "",
					-- id,
					-- display
				)
			end, function()
				log(
					string.format("* %s rejected", componentName)
					-- REACT_LOGO_STYLE,
					-- ROBLOX deviation: remove color styling
					-- "",
					-- id,
					-- display
				)
			end)
		end
	end
end
exports.logComponentSuspended = logComponentSuspended

local function logLayoutEffectsStarted(lanes: Lanes): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			group(
				string.format("* layout effects (%s)", formatLanes(lanes))
				-- REACT_LOGO_STYLE,
				-- "",
				-- ROBLOX deviation: strip color styling
				-- ""
			)
		end
	end
end
exports.logLayoutEffectsStarted = logLayoutEffectsStarted

local function logLayoutEffectsStopped(): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			groupEnd()
		end
	end
end
exports.logLayoutEffectsStopped = logLayoutEffectsStopped

local function logPassiveEffectsStarted(lanes: Lanes): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			group(
				string.format("* passive effects (%s)", formatLanes(lanes))
				-- REACT_LOGO_STYLE,
				-- "",
				-- ROBLOX deviation: strip color styling
				-- ""
			)
		end
	end
end
exports.logPassiveEffectsStarted = logPassiveEffectsStarted

local function logPassiveEffectsStopped(): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			groupEnd()
		end
	end
end
exports.logPassiveEffectsStopped = logPassiveEffectsStopped

local function logRenderStarted(lanes: Lanes): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			group(
				string.format("* render (%s)", formatLanes(lanes))
				-- REACT_LOGO_STYLE,
				-- "",
				-- ROBLOX deviation: strip color styling
				-- ""
			)
		end
	end
end
exports.logRenderStarted = logRenderStarted

local function logRenderStopped(): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			groupEnd()
		end
	end
end
exports.logRenderStopped = logRenderStopped

local function logForceUpdateScheduled(componentName: string, lane: Lane): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			log(
				string.format("* %s forced update (%s)", componentName, formatLanes(lane))
				-- REACT_LOGO_STYLE,
				-- ROBLOX deviation: strip color styling
				-- "",
				-- ""
			)
		end
	end
end
exports.logForceUpdateScheduled = logForceUpdateScheduled

local function logStateUpdateScheduled(
	componentName: string,
	lane: Lane,
	payloadOrAction: any
): ()
	if _G.__DEV__ then
		if enableDebugTracing then
			log(
				string.format("* %s updated state (%s)", componentName, formatLanes(lane))
				-- REACT_LOGO_STYLE,
				-- ROBLOX deviation: strip color styling
				-- "",
				-- "",
				-- payloadOrAction
			)
		end
	end
end
exports.logStateUpdateScheduled = logStateUpdateScheduled
return exports
