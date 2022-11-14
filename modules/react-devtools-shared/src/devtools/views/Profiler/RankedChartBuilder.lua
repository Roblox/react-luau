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
local Boolean = LuauPolyfill.Boolean
local Map = LuauPolyfill.Map

type Map<K, V> = LuauPolyfill.Map<K, V>
type Array<K> = LuauPolyfill.Array<K>
type Set<T> = LuauPolyfill.Set<T>

local exports = {}

local devtoolsTypes = require(script.Parent.Parent.Parent.types)
type ProfilerStore = devtoolsTypes.ProfilerStore

local typesModule = require(script.Parent.Parent.Parent.Parent.types)
local ElementTypeForwardRef = typesModule.ElementTypeForwardRef
local ElementTypeMemo = typesModule.ElementTypeMemo
local formatDuration = require(script.Parent.utils).formatDuration
local Profiler_typesModule = require(script.Parent.types)
type CommitTree = Profiler_typesModule.CommitTree
type CommitTreeNode = Profiler_typesModule.CommitTreeNode

export type ChartNode = { id: number, label: string, name: string, value: number }
export type ChartData = { maxValue: number, nodes: Array<ChartNode> }
local cachedChartData: Map<string, ChartData> = Map.new()
local function getChartData(ref: {
	commitIndex: number,
	commitTree: CommitTree,
	profilerStore: ProfilerStore,
	rootID: number,
}): ChartData
	local commitIndex, commitTree, profilerStore, rootID =
		ref.commitIndex, ref.commitTree, ref.profilerStore, ref.rootID
	local commitDatum = profilerStore:getCommitData(rootID, commitIndex)
	local fiberActualDurations: Map<number, number>, fiberSelfDurations: Map<number, number> =
		commitDatum.fiberActualDurations, commitDatum.fiberSelfDurations
	local nodes = commitTree.nodes
	local chartDataKey = ("%s-%s"):format(tostring(rootID), tostring(commitIndex))
	if cachedChartData:has(chartDataKey) then
		return (cachedChartData:get(chartDataKey) :: any) :: ChartData
	end
	local maxSelfDuration = 0
	local chartNodes: Array<ChartNode> = {}
	-- ROBLOX deviation? this is a simple Map, but could .forEach() always be generalized into genealized for-in if the loop is 'simple'?
	for id, actualDuration in fiberActualDurations do
		local node = nodes:get(id)
		if node == nil then
			error(
				string.format(
					'Could not find node with id "%s" in commit tree',
					tostring(id)
				)
			)
		end
		-- ROBLOX FIXME Luau: need to understand that error() means `node` has nil-ability stripped
		local displayName, key, parentID, type_ =
			(node :: CommitTreeNode).displayName,
			(node :: CommitTreeNode).key,
			(node :: CommitTreeNode).parentID,
			(node :: CommitTreeNode).type -- Don't show the root node in this chart.
		if parentID == 0 then
			continue
		end
		local selfDuration = fiberSelfDurations:get(id) or 0
		maxSelfDuration = math.max(maxSelfDuration, selfDuration)
		local name = displayName or "Anonymous"
		local maybeKey = if Boolean.toJSBoolean(key)
			then (' key="%s"'):format(tostring(key))
			else ""
		local maybeBadge = ""
		if type_ == ElementTypeForwardRef then
			maybeBadge = " (ForwardRef)"
		elseif type_ == ElementTypeMemo then
			maybeBadge = " (Memo)"
		end
		local label = ("%s%s%s (%sms)"):format(
			tostring(name),
			tostring(maybeBadge),
			tostring(maybeKey),
			tostring(formatDuration(selfDuration))
		)
		table.insert(
			chartNodes,
			{ id = id, label = label, name = name, value = selfDuration }
		)
	end
	local chartData = {
		maxValue = maxSelfDuration,
		nodes = Array.sort(chartNodes, function(a, b)
			return b.value - a.value
		end),
	}
	cachedChartData:set(chartDataKey, chartData)
	return chartData
end
exports.getChartData = getChartData
local function invalidateChartData(): any?
	return cachedChartData:clear()
end
exports.invalidateChartData = invalidateChartData
return exports
