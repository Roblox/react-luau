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
local Set = LuauPolyfill.Set
local console = LuauPolyfill.console
type Array<T> = LuauPolyfill.Array<T>
type Map<K, V> = LuauPolyfill.Map<K, V>
type Object = LuauPolyfill.Object
type Set<K> = LuauPolyfill.Set<K>

local EventEmitter = require(script.Parent.Parent.events)
type EventEmitter<T> = EventEmitter.EventEmitter<T>

local prepareProfilingDataFrontendFromBackendAndStore = require(
	script.Parent.views.Profiler.utils
).prepareProfilingDataFrontendFromBackendAndStore

local devtoolsTypes = require(script.Parent.types)
type ProfilingCache = devtoolsTypes.ProfilingCache
export type ProfilerStore = devtoolsTypes.ProfilerStore
type Store = devtoolsTypes.Store

local Bridge = require(script.Parent.Parent.bridge)
type FrontendBridge = Bridge.FrontendBridge

local backendTypes = require(script.Parent.Parent.backend.types)
type ProfilingDataBackend = backendTypes.ProfilingDataBackend

local profilerTypes = require(script.Parent.views.Profiler.types)
type CommitDataFrontend = profilerTypes.CommitDataFrontend
type ProfilingDataForRootFrontend = profilerTypes.ProfilingDataForRootFrontend
type ProfilingDataFrontend = profilerTypes.ProfilingDataFrontend
type SnapshotNode = profilerTypes.SnapshotNode

type ProfilerStore_statics = {
	new: (
		bridge: FrontendBridge,
		store: Store,
		defaultIsProfiling: boolean
	) -> ProfilerStore,
	__index: {},
}

local ProfilingCache = require(script.Parent.ProfilingCache)

local ProfilerStore: ProfilerStore & ProfilerStore_statics = (
	setmetatable({}, { __index = EventEmitter }) :: any
) :: ProfilerStore & ProfilerStore_statics
ProfilerStore.__index = ProfilerStore

function ProfilerStore.new(
	bridge: FrontendBridge,
	store: Store,
	defaultIsProfiling: boolean
): ProfilerStore
	local profilerStore: ProfilerStore =
		setmetatable(EventEmitter.new() :: any, ProfilerStore)
	profilerStore._dataBackends = {}
	profilerStore._dataFrontend = nil
	profilerStore._initialRendererIDs = Set.new()
	profilerStore._initialSnapshotsByRootID = Map.new()
	profilerStore._inProgressOperationsByRootID = Map.new()
	profilerStore._isProfiling = defaultIsProfiling
	profilerStore._rendererIDsThatReportedProfilingData = Set.new()
	profilerStore._rendererQueue = Set.new()
	profilerStore._bridge = bridge
	profilerStore._store = store

	function profilerStore:_takeProfilingSnapshotRecursive(
		elementID: number,
		profilingSnapshots: Map<number, SnapshotNode>
	)
		local element = self._store:getElementByID(elementID)
		if element ~= nil then
			local snapshotNode: SnapshotNode = {
				id = elementID,
				children = Array.slice(element.children, 0),
				displayName = element.displayName,
				hocDisplayNames = element.hocDisplayNames,
				key = element.key,
				type = element.type,
			}
			profilingSnapshots:set(elementID, snapshotNode)
			Array.forEach(element.children, function(childID)
				return self:_takeProfilingSnapshotRecursive(childID, profilingSnapshots)
			end)
		end
	end
	function profilerStore:onBridgeOperations(operations: Array<number>)
		-- The first two values are always rendererID and rootID
		local rendererID = operations[
			1 --[[ ROBLOX adaptation: added 1 to array index ]]
		]
		local rootID = operations[
			2 --[[ ROBLOX adaptation: added 1 to array index ]]
		]
		if self._isProfiling then
			local profilingOperations = self._inProgressOperationsByRootID:get(rootID)
			if profilingOperations == nil then
				profilingOperations = { operations }
				-- ROBLOX FIXME Luau: nil-ability always remove due to assignment if nil
				self._inProgressOperationsByRootID:set(
					rootID,
					profilingOperations :: Array<Array<number>>
				)
			else
				table.insert(profilingOperations, operations)
			end

			if not self._initialRendererIDs:has(rendererID) then
				self._initialRendererIDs:add(rendererID)
			end

			if not self._initialSnapshotsByRootID:has(rootID) then
				self._initialSnapshotsByRootID:set(rootID, Map.new())
			end
			self._rendererIDsThatReportedProfilingData:add(rendererID)
		end
	end
	function profilerStore:onBridgeProfilingData(dataBackend: ProfilingDataBackend)
		if self._isProfiling then
			-- This should never happen, but if it does- ignore previous profiling data.
			return
		end
		local rendererID = dataBackend.rendererID
		if not self._rendererQueue:has(rendererID) then
			error(
				string.format(
					'Unexpected profiling data update from renderer "%s"',
					tostring(rendererID)
				)
			)
		end
		table.insert(self._dataBackends, dataBackend)
		self._rendererQueue:delete(rendererID)
		if self._rendererQueue.size == 0 then
			self._dataFrontend = prepareProfilingDataFrontendFromBackendAndStore(
				self._dataBackends,
				self._inProgressOperationsByRootID,
				self._initialSnapshotsByRootID
			)
			Array.splice(self._dataBackends, 0)
			self:emit("isProcessingData")
		end
	end
	function profilerStore:onBridgeShutdown()
		self._bridge:removeListener("operations", self.onBridgeOperations)
		self._bridge:removeListener("profilingData", self.onBridgeProfilingData)
		self._bridge:removeListener("profilingStatus", self.onProfilingStatus)
		self._bridge:removeListener("shutdown", self.onBridgeShutdown)
	end
	function profilerStore:onProfilingStatus(isProfiling: boolean)
		if isProfiling then
			Array.splice(self._dataBackends, 0)
			self._dataFrontend = nil
			self._initialRendererIDs:clear()
			self._initialSnapshotsByRootID:clear()
			self._inProgressOperationsByRootID:clear()
			self._rendererIDsThatReportedProfilingData:clear()
			self._rendererQueue:clear()
			-- Record all renderer IDs initially too (in case of unmount)
			-- eslint-disable-next-line no-for-of-loops/no-for-of-loops
			for _, rendererID in self._store:getRootIDToRendererID() do
				if not self._initialRendererIDs:has(rendererID) then
					self._initialRendererIDs:add(rendererID)
				end
			end
			-- Record snapshot of tree at the time profiling is started.
			-- This info is required to handle cases of e.g. nodes being removed during profiling.
			for _, rootID in self._store:getRoots() do
				local profilingSnapshots = Map.new()
				self._initialSnapshotsByRootID:set(rootID, profilingSnapshots)
				self:_takeProfilingSnapshotRecursive(rootID, profilingSnapshots)
			end
		end
		if self._isProfiling ~= isProfiling then
			self._isProfiling = isProfiling -- Invalidate suspense cache if profiling data is being (re-)recorded.
			-- Note that we clear again, in case any views read from the cache while profiling.
			-- (That would have resolved a now-stale value without any profiling data.)
			self._cache:invalidate()
			self:emit("isProfiling") -- If we've just finished a profiling session, we need to fetch data stored in each renderer interface
			-- and re-assemble it on the front-end into a format (ProfilingDataFrontend) that can power the Profiler UI.
			-- During this time, DevTools UI should probably not be interactive.
			if not isProfiling then
				Array.splice(self._dataBackends, 0)
				self._rendererQueue:clear() -- Only request data from renderers that actually logged it.
				-- This avoids unnecessary bridge requests and also avoids edge case mixed renderer bugs.
				-- (e.g. when v15 and v16 are both present)
				for _, rendererID in self._rendererIDsThatReportedProfilingData do
					if not self._rendererQueue:has(rendererID) then
						self._rendererQueue:add(rendererID)
						self._bridge:send("getProfilingData", {
							rendererID = rendererID,
						})
					end
				end
				self:emit("isProcessingData")
			end
		end
	end

	bridge:addListener("operations", function(...)
		return profilerStore:onBridgeOperations(...)
	end)
	bridge:addListener("profilingData", function(...)
		return profilerStore:onBridgeProfilingData(...)
	end)
	bridge:addListener("profilingStatus", function(...)
		return profilerStore:onProfilingStatus(...)
	end)
	bridge:addListener("shutdown", function(...)
		return profilerStore:onBridgeShutdown(...)
	end)

	-- It's possible that profiling has already started (e.g. "reload and start profiling")
	-- so the frontend needs to ask the backend for its status after mounting.
	bridge:send("getProfilingStatus")
	profilerStore._cache = ProfilingCache.new(profilerStore)

	return profilerStore
end
function ProfilerStore:getCommitData(
	rootID: number,
	commitIndex: number
): CommitDataFrontend
	if self._dataFrontend ~= nil then
		local dataForRoot = self._dataFrontend.dataForRoots:get(rootID)
		if dataForRoot ~= nil then
			local commitDatum = dataForRoot.commitData[commitIndex]
			if commitDatum ~= nil then
				return commitDatum
			end
		end
	end
	error(
		string.format(
			'Could not find commit data for root "%s" and commit %s',
			tostring(rootID),
			tostring(commitIndex)
		)
	)
end
function ProfilerStore:getDataForRoot(rootID: number): ProfilingDataForRootFrontend
	if self._dataFrontend ~= nil then
		local dataForRoot = self._dataFrontend.dataForRoots:get(rootID)
		if dataForRoot ~= nil then
			return dataForRoot
		end
	end
	error(string.format('Could not find commit data for root "%s"', tostring(rootID)))
end
function ProfilerStore:didRecordCommits(): boolean
	return self._dataFrontend ~= nil and self._dataFrontend.dataForRoots.size > 0
end
function ProfilerStore:isProcessingData(): boolean
	return self._rendererQueue.size > 0 or #self._dataBackends > 0
end
function ProfilerStore:isProfiling(): boolean
	return self._isProfiling
end
function ProfilerStore:profilingCache(): ProfilingCache
	return self._cache
end
function ProfilerStore:profilingData(
	value: ProfilingDataFrontend | nil
): (...ProfilingDataFrontend?)
	if value == nil then
		return self._dataFrontend
	end

	if self._isProfiling then
		console.warn("Profiling data cannot be updated while profiling is in progress.")
		return
	end
	Array.splice(self._dataBackends, 0)
	self._dataFrontend = value
	self._initialRendererIDs:clear()
	self._initialSnapshotsByRootID:clear()
	self._inProgressOperationsByRootID:clear()
	self._cache:invalidate()
	self:emit("profilingData")
	return
end
function ProfilerStore:clear(): (...any?)
	Array.splice(self._dataBackends, 0)
	self._dataFrontend = nil
	self._initialRendererIDs:clear()
	self._initialSnapshotsByRootID:clear()
	self._inProgressOperationsByRootID:clear()
	self._rendererQueue:clear() -- Invalidate suspense cache if profiling data is being (re-)recorded.
	-- Note that we clear now because any existing data is "stale".
	self._cache:invalidate()
	self:emit("profilingData")
end
function ProfilerStore:startProfiling(): (...any?)
	self._bridge:send("startProfiling", self._store:getRecordChangeDescriptions()) -- Don't actually update the local profiling boolean yet!
	-- Wait for onProfilingStatus() to confirm the status has changed.
	-- This ensures the frontend and backend are in sync wrt which commits were profiled.
	-- We do this to avoid mismatches on e.g. CommitTreeBuilder that would cause errors.
end
function ProfilerStore:stopProfiling(): (...any?)
	self._bridge:send("stopProfiling") -- Don't actually update the local profiling boolean yet!
	-- Wait for onProfilingStatus() to confirm the status has changed.
	-- This ensures the frontend and backend are in sync wrt which commits were profiled.
	-- We do this to avoid mismatches on e.g. CommitTreeBuilder that would cause errors.
end

return ProfilerStore
