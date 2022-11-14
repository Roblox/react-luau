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
local Boolean = LuauPolyfill.Boolean
local Map = LuauPolyfill.Map
local Set = LuauPolyfill.Set

type Map<K, V> = LuauPolyfill.Map<K, V>
type Array<K> = LuauPolyfill.Array<K>
type Set<T> = LuauPolyfill.Set<T>

local exports = {}

local devtoolsTypes = require(script.Parent.Parent.Parent.types)
type ProfilerStore = devtoolsTypes.ProfilerStore

local formatDuration = require(script.Parent.utils).formatDuration
local typesModule = require(script.Parent.types)
type CommitTree = typesModule.CommitTree
type CommitTreeNode = typesModule.CommitTreeNode

export type ChartNode = {
	actualDuration: number,
	didRender: boolean,
	id: number,
	label: string,
	name: string,
	offset: number,
	selfDuration: number,
	treeBaseDuration: number,
}
export type ChartData = {
	baseDuration: number,
	depth: number,
	idToDepthMap: Map<number, number>,
	maxSelfDuration: number,
	renderPathNodes: Set<number>,
	rows: Array<Array<ChartNode>>,
}
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
	local fiberActualDurations, fiberSelfDurations =
		commitDatum.fiberActualDurations, commitDatum.fiberSelfDurations
	local nodes = commitTree.nodes
	local chartDataKey = ("%s-%s"):format(tostring(rootID), tostring(commitIndex))
	if cachedChartData:has(chartDataKey) then
		return (cachedChartData:get(chartDataKey) :: any) :: ChartData
	end
	local idToDepthMap: Map<number, number> = Map.new()
	local renderPathNodes: Set<number> = Set.new()
	local rows: Array<Array<ChartNode>> = {}
	local maxDepth = 0
	local maxSelfDuration = 0

	-- Generate flame graph structure using tree base durations.
	local function walkTree(id: number, rightOffset: number, currentDepth: number)
		idToDepthMap:set(id, currentDepth)

		local node = nodes:get(id)
		if node == nil then
			error(
				string.format(
					'Could not find node with id "%s" in commit tree',
					tostring(id)
				)
			)
		end
		-- ROBLOX FIXME Luau: Luau doesn't understand error() narrows, needs type states
		local children, displayName, hocDisplayNames, key, treeBaseDuration =
			(node :: CommitTreeNode).children,
			(node :: CommitTreeNode).displayName,
			(node :: CommitTreeNode).hocDisplayNames,
			(node :: CommitTreeNode).key,
			(node :: CommitTreeNode).treeBaseDuration

		local actualDuration = fiberActualDurations:get(id) or 0
		local selfDuration = fiberSelfDurations:get(id) or 0
		local didRender = fiberActualDurations:has(id)

		local name = displayName or "Anonymous"
		local maybeKey = if Boolean.toJSBoolean(key)
			then (' key="%s"'):format(tostring(key))
			else ""

		local maybeBadge = ""
		if hocDisplayNames ~= nil and #hocDisplayNames > 0 then
			maybeBadge = string.format(" (%s)", tostring(hocDisplayNames[1]))
		end

		local label = string.format(
			"%s%s%s%s",
			tostring(name),
			tostring(maybeBadge),
			tostring(maybeKey),
			if didRender
				then string.format(
					" (%sms of %sms)",
					tostring(formatDuration(selfDuration)),
					tostring(formatDuration(actualDuration))
				)
				else ""
		)

		maxDepth = math.max(maxDepth, currentDepth)
		maxSelfDuration = math.max(maxSelfDuration, selfDuration)
		local chartNode: ChartNode = {
			actualDuration = actualDuration,
			didRender = didRender,
			id = id,
			label = label,
			name = name,
			offset = rightOffset - treeBaseDuration,
			selfDuration = selfDuration,
			treeBaseDuration = treeBaseDuration,
		}
		if currentDepth > #rows then
			table.insert(rows, { chartNode })
		else
			table.insert(rows[currentDepth - 1], chartNode)
		end
		do
			local i = #children
			while i >= 1 do
				local childID = children[i]
				local childChartNode = walkTree(childID, rightOffset, currentDepth)
				rightOffset -= childChartNode.treeBaseDuration
				i -= 1
			end
		end
		return chartNode
	end
	local baseDuration = 0 -- Special case to handle unmounted roots.
	if nodes.size > 0 then
		-- Skip over the root; we don't want to show it in the flamegraph.
		local root = nodes:get(rootID)
		if root == nil then
			error(
				string.format(
					'Could not find root node with id "%s" in commit tree',
					tostring(rootID)
				)
			)
		end
		-- Don't assume a single root.
		-- Component filters or Fragments might lead to multiple "roots" in a flame graph.
		do
			-- ROBLOX FIXME Luau: Luau doesn't understand error() narrows, needs type states
			local i = #(root :: CommitTreeNode).children
			while i >= 1 do
				local id = (root :: CommitTreeNode).children[i]
				local node = nodes:get(id)
				if node == nil then
					error(
						string.format(
							'Could not find node with id "%s" in commit tree',
							tostring(id)
						)
					)
				end
				-- ROBLOX FIXME Luau: Luau doesn't understand error() narrows, needs type states
				baseDuration += (node :: CommitTreeNode).treeBaseDuration
				-- ROBLOX deviation START: walkTree does table.insert(tbl, currentDepth - 1), so the parameter here needs to be a valid index with after substracting 1 at the start
				walkTree(id, baseDuration, 2)
				-- ROBLOX deviation END
				i -= 1
			end
		end
		for id, duration in fiberActualDurations do
			local node = nodes:get(id)
			if node ~= nil then
				local currentID = node.parentID
				while currentID ~= 0 do
					if renderPathNodes:has(currentID) then
						-- We've already walked this path; we can skip it.
						break
					else
						renderPathNodes:add(currentID)
					end
					node = nodes:get(currentID)
					currentID = if node ~= nil then node.parentID else 0
				end
			end
		end
	end
	local chartData = {
		baseDuration = baseDuration,
		depth = maxDepth,
		idToDepthMap = idToDepthMap,
		maxSelfDuration = maxSelfDuration,
		renderPathNodes = renderPathNodes,
		rows = rows,
	}
	cachedChartData:set(chartDataKey, chartData)
	return chartData
end
exports.getChartData = getChartData
local function invalidateChartData(): any
	return cachedChartData:clear()
end
exports.invalidateChartData = invalidateChartData
return exports
