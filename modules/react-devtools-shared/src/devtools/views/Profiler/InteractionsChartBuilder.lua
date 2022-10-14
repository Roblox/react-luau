--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local Packages = script.Parent.Parent.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Map = LuauPolyfill.Map

type Map<K, V> = LuauPolyfill.Map<K, V>
type Array<K> = LuauPolyfill.Array<K>

local exports = {}

local devtoolsTypes = require(script.Parent.Parent.Parent.types)
type ProfilerStore = devtoolsTypes.ProfilerStore
local typesModule = require(script.Parent.types)
type Interaction = typesModule.Interaction
export type ChartData = {
	interactions: Array<Interaction>,
	lastInteractionTime: number,
	maxCommitDuration: number,
}
local cachedChartData: Map<number, ChartData> = Map.new()
local function getChartData(
	ref: { profilerStore: ProfilerStore, rootID: number }
): ChartData
	local profilerStore, rootID = ref.profilerStore, ref.rootID
	if cachedChartData:has(rootID) then
		return (cachedChartData:get(rootID) :: any) :: ChartData
	end
	local dataForRoot = profilerStore:getDataForRoot(rootID)
	if dataForRoot == nil then
		error(
			string.format('Could not find profiling data for root "%s"', tostring(rootID))
		)
	end
	-- ROBLOX FIXME Luau: any cast necessary to work around: Property 'interactions' is not compatible. Type 'Array<Interaction> | Array<a> | Array<string>' could not be converted into 'Array<Interaction>'
	local commitData, interactions: any = dataForRoot.commitData, dataForRoot.interactions
	local lastInteractionTime = if #commitData > 0
		then commitData[#commitData].timestamp
		else 0
	local maxCommitDuration = 0
	Array.forEach(commitData, function(commitDatum)
		maxCommitDuration = math.max(maxCommitDuration, commitDatum.duration)
	end)
	local chartData = {
		interactions = Array.from(interactions:values()) :: Array<Interaction>,
		lastInteractionTime = lastInteractionTime,
		maxCommitDuration = maxCommitDuration,
	}
	cachedChartData:set(rootID, chartData)
	return chartData
end
exports.getChartData = getChartData
local function invalidateChartData(): any?
	return cachedChartData:clear()
end
exports.invalidateChartData = invalidateChartData
return exports
