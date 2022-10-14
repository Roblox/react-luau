--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Map = LuauPolyfill.Map

type Map<K, V> = LuauPolyfill.Map<K, V>
type Array<T> = LuauPolyfill.Array<T>

local ProfilerViews = script.Parent.views.Profiler

local CommitTreeBuilderModule = require(ProfilerViews.CommitTreeBuilder)
local getCommitTree = CommitTreeBuilderModule.getCommitTree
local invalidateCommitTrees = CommitTreeBuilderModule.invalidateCommitTrees

local FlamegraphChartBuilderModule = require(ProfilerViews.FlamegraphChartBuilder)
local getFlamegraphChartData = FlamegraphChartBuilderModule.getChartData
local invalidateFlamegraphChartData = FlamegraphChartBuilderModule.invalidateChartData

local InteractionsChartBuilderModule = require(ProfilerViews.InteractionsChartBuilder)
local getInteractionsChartData = InteractionsChartBuilderModule.getChartData
local invalidateInteractionsChartData = InteractionsChartBuilderModule.invalidateChartData

local RankedChartBuilderModule = require(ProfilerViews.RankedChartBuilder)
local getRankedChartData = RankedChartBuilderModule.getChartData
local invalidateRankedChartData = RankedChartBuilderModule.invalidateChartData

local typesModule = require(ProfilerViews.types)
type CommitTree = typesModule.CommitTree

type FlamegraphChartData = FlamegraphChartBuilderModule.ChartData
type InteractionsChartData = InteractionsChartBuilderModule.ChartData
type RankedChartData = RankedChartBuilderModule.ChartData

local devtoolsTypes = require(script.Parent.types)
type ProfilingCache = devtoolsTypes.ProfilingCache
type ProfilerStore = devtoolsTypes.ProfilerStore

type ProfilingCache_statics = { new: (profilerStore: ProfilerStore) -> ProfilingCache }

local ProfilingCache = {} :: ProfilingCache & ProfilingCache_statics;
(ProfilingCache :: any).__index = ProfilingCache

function ProfilingCache.new(profilerStore: ProfilerStore): ProfilingCache
	local profilingCache: ProfilingCache =
		(setmetatable({}, ProfilingCache) :: any) :: ProfilingCache
	profilingCache._fiberCommits = Map.new()
	profilingCache._profilerStore = profilerStore

	function profilingCache:getCommitTree(ref: { commitIndex: number, rootID: number })
		local commitIndex, rootID = ref.commitIndex, ref.rootID
		return getCommitTree({
			commitIndex = commitIndex,
			profilerStore = self._profilerStore,
			rootID = rootID,
		})
	end
	function profilingCache:getFiberCommits(
		ref: { fiberID: number, rootID: number }
	): Array<number>
		local fiberID, rootID = ref.fiberID, ref.rootID
		local cachedFiberCommits = self._fiberCommits:get(fiberID)
		if cachedFiberCommits ~= nil then
			return cachedFiberCommits
		end
		local fiberCommits = {} :: Array<number>
		local dataForRoot = self._profilerStore:getDataForRoot(rootID)
		Array.forEach(dataForRoot.commitData, function(commitDatum, commitIndex)
			if commitDatum.fiberActualDurations:has(fiberID) then
				table.insert(fiberCommits, commitIndex)
			end
		end)
		self._fiberCommits:set(fiberID, fiberCommits)
		return fiberCommits
	end
	function profilingCache:getFlamegraphChartData(
		ref: {
			commitIndex: number,
			commitTree: CommitTree,
			rootID: number,
		}
	): FlamegraphChartData
		local commitIndex, commitTree, rootID =
			ref.commitIndex, ref.commitTree, ref.rootID
		return getFlamegraphChartData({
			commitIndex = commitIndex,
			commitTree = commitTree,
			profilerStore = self._profilerStore,
			rootID = rootID,
		})
	end
	function profilingCache:getInteractionsChartData(
		ref: { rootID: number }
	): InteractionsChartData
		local rootID = ref.rootID
		return getInteractionsChartData({
			profilerStore = self._profilerStore,
			rootID = rootID,
		})
	end
	function profilingCache:getRankedChartData(
		ref: {
			commitIndex: number,
			commitTree: CommitTree,
			rootID: number,
		}
	): RankedChartData
		local commitIndex, commitTree, rootID =
			ref.commitIndex, ref.commitTree, ref.rootID
		return getRankedChartData({
			commitIndex = commitIndex,
			commitTree = commitTree,
			profilerStore = self._profilerStore,
			rootID = rootID,
		})
	end

	return profilingCache
end
function ProfilingCache:invalidate()
	self._fiberCommits:clear()
	invalidateCommitTrees()
	invalidateFlamegraphChartData()
	invalidateInteractionsChartData()
	invalidateRankedChartData()
end

return ProfilingCache
