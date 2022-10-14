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
local Error = LuauPolyfill.Error
local Map = LuauPolyfill.Map
local Number = LuauPolyfill.Number

type Map<K, V> = LuauPolyfill.Map<K, V>
type Array<K> = LuauPolyfill.Array<K>

local exports = {}

local PROFILER_EXPORT_VERSION =
	require(script.Parent.Parent.Parent.Parent.constants).PROFILER_EXPORT_VERSION
local backendTypes = require(script.Parent.Parent.Parent.Parent.backend.types)
type ProfilingDataBackend = backendTypes.ProfilingDataBackend
local profilerTypes = require(script.Parent.types)
type ProfilingDataExport = profilerTypes.ProfilingDataExport
type ProfilingDataForRootExport = profilerTypes.ProfilingDataForRootExport
type ProfilingDataForRootFrontend = profilerTypes.ProfilingDataForRootFrontend
type ProfilingDataFrontend = profilerTypes.ProfilingDataFrontend
type SnapshotNode = profilerTypes.SnapshotNode

local commitGradient = {
	"var(--color-commit-gradient-0)",
	"var(--color-commit-gradient-1)",
	"var(--color-commit-gradient-2)",
	"var(--color-commit-gradient-3)",
	"var(--color-commit-gradient-4)",
	"var(--color-commit-gradient-5)",
	"var(--color-commit-gradient-6)",
	"var(--color-commit-gradient-7)",
	"var(--color-commit-gradient-8)",
	"var(--color-commit-gradient-9)",
} -- Combines info from the Store (frontend) and renderer interfaces (backend) into the format required by the Profiler UI.
-- This format can then be quickly exported (and re-imported).
local function prepareProfilingDataFrontendFromBackendAndStore(
	dataBackends: Array<
		ProfilingDataBackend
	>,
	operationsByRootID: Map<
		number,
		Array<Array<number>>
	>,
	snapshotsByRootID: Map<
		number,
		Map<number, SnapshotNode>
	>
): ProfilingDataFrontend
	local dataForRoots: Map<number, ProfilingDataForRootFrontend> = Map.new()
	for _, dataBackend in dataBackends do
		for _, ref in dataBackend.dataForRoots do
			local commitData, displayName, initialTreeBaseDurations, interactionCommits, interactions, rootID =
				ref.commitData,
				ref.displayName,
				ref.initialTreeBaseDurations,
				ref.interactionCommits,
				ref.interactions,
				ref.rootID
			local operations = operationsByRootID:get(rootID)
			if operations == nil then
				error(
					Error.new(
						string.format(
							"Could not find profiling operations for root %s",
							tostring(rootID)
						)
					)
				)
			end
			local snapshots = snapshotsByRootID:get(rootID)
			if snapshots == nil then
				error(
					Error.new(
						string.format(
							"Could not find profiling snapshots for root %s",
							tostring(rootID)
						)
					)
				)
			end

			-- Do not filter empty commits from the profiler data!
			-- We used to do this, but it was error prone (see #18798).
			-- A commit may appear to be empty (no actual durations) because of component filters,
			-- but filtering these empty commits causes interaction commit indices to be off by N.
			-- This not only corrupts the resulting data, but also potentially causes runtime errors.
			--
			-- For that matter, hiding "empty" commits might cause confusion too.
			-- A commit *did happen* even if none of the components the Profiler is showing were involved.
			local convertedCommitData = Array.map(
				commitData,
				function(commitDataBackend, commitIndex)
					return {
						changeDescriptions = if commitDataBackend.changeDescriptions
								~= nil
							then Map.new(commitDataBackend.changeDescriptions)
							else nil,
						duration = commitDataBackend.duration,
						fiberActualDurations = Map.new(
							commitDataBackend.fiberActualDurations
						),
						fiberSelfDurations = Map.new(
							commitDataBackend.fiberSelfDurations
						),
						interactionIDs = commitDataBackend.interactionIDs,
						priorityLevel = commitDataBackend.priorityLevel,
						timestamp = commitDataBackend.timestamp,
					}
				end
			)
			dataForRoots:set(rootID, {
				commitData = convertedCommitData,
				displayName = displayName,
				initialTreeBaseDurations = Map.new(initialTreeBaseDurations),
				interactionCommits = Map.new(interactionCommits),
				interactions = Map.new(interactions),
				-- ROBLOX FIXME Luau: need type states to not need manual annotation
				operations = operations :: Array<Array<number>>,
				rootID = rootID,
				-- ROBLOX FIXME Luau: need type states to not need manual annotation
				snapshots = snapshots :: Map<number, SnapshotNode>,
			})
		end
	end
	return {
		dataForRoots = dataForRoots,
		imported = false,
	}
end

-- Converts a Profiling data export into the format required by the Store.
exports.prepareProfilingDataFrontendFromBackendAndStore =
	prepareProfilingDataFrontendFromBackendAndStore
local function prepareProfilingDataFrontendFromExport(
	profilingDataExport: ProfilingDataExport
): ProfilingDataFrontend
	local version_ = profilingDataExport.version
	if version_ ~= PROFILER_EXPORT_VERSION then
		error(
			string.format('Unsupported profiler export version "%s"', tostring(version_))
		)
	end
	local dataForRoots: Map<number, ProfilingDataForRootFrontend> = Map.new()
	Array.forEach(profilingDataExport.dataForRoots, function(ref)
		local commitData, displayName, initialTreeBaseDurations, interactionCommits, interactions, operations, rootID, snapshots =
			ref.commitData,
			ref.displayName,
			ref.initialTreeBaseDurations,
			ref.interactionCommits,
			ref.interactions,
			ref.operations,
			ref.rootID,
			ref.snapshots
		dataForRoots:set(rootID, {
			commitData = Array.map(commitData, function(ref)
				local changeDescriptions, duration, fiberActualDurations, fiberSelfDurations, interactionIDs, priorityLevel, timestamp =
					ref.changeDescriptions,
					ref.duration,
					ref.fiberActualDurations,
					ref.fiberSelfDurations,
					ref.interactionIDs,
					ref.priorityLevel,
					ref.timestamp
				return {
					changeDescriptions = if changeDescriptions ~= nil
						then Map.new(changeDescriptions)
						else nil,
					duration = duration,
					fiberActualDurations = Map.new(fiberActualDurations),
					fiberSelfDurations = Map.new(fiberSelfDurations),
					interactionIDs = interactionIDs,
					priorityLevel = priorityLevel,
					timestamp = timestamp,
				}
			end),
			displayName = displayName,
			initialTreeBaseDurations = Map.new(initialTreeBaseDurations),
			interactionCommits = Map.new(interactionCommits),
			interactions = Map.new(interactions),
			operations = operations,
			rootID = rootID,
			snapshots = Map.new(snapshots),
		})
	end)
	return { dataForRoots = dataForRoots, imported = true }
end
exports.prepareProfilingDataFrontendFromExport = prepareProfilingDataFrontendFromExport -- Converts a Store Profiling data into a format that can be safely (JSON) serialized for export.
local function prepareProfilingDataExport(
	profilingDataFrontend: ProfilingDataFrontend
): ProfilingDataExport
	local dataForRoots: Array<ProfilingDataForRootExport> = {}
	profilingDataFrontend.dataForRoots:forEach(function(ref)
		local commitData, displayName, initialTreeBaseDurations, interactionCommits, interactions, operations, rootID, snapshots =
			ref.commitData,
			ref.displayName,
			ref.initialTreeBaseDurations,
			ref.interactionCommits,
			ref.interactions,
			ref.operations,
			ref.rootID,
			ref.snapshots
		table.insert(dataForRoots, {
			commitData = Array.map(commitData, function(ref)
				local changeDescriptions, duration, fiberActualDurations, fiberSelfDurations, interactionIDs, priorityLevel, timestamp =
					ref.changeDescriptions,
					ref.duration,
					ref.fiberActualDurations,
					ref.fiberSelfDurations,
					ref.interactionIDs,
					ref.priorityLevel,
					ref.timestamp
				return {
					changeDescriptions = if changeDescriptions ~= nil
						-- ROBLOX FIXME: types aren't flowing from entries through to return value of Array.from
						then Array.from(changeDescriptions:entries()) :: Array<Array<any>>
						else nil,
					duration = duration,
					fiberActualDurations = Array.from(fiberActualDurations:entries()) :: Array<Array<number>>,
					fiberSelfDurations = Array.from(fiberSelfDurations:entries()) :: Array<Array<number>>,
					interactionIDs = interactionIDs,
					priorityLevel = priorityLevel,
					timestamp = timestamp,
				}
			end),
			displayName = displayName,
			-- ROBLOX FIXME: types aren't flowing from entries through to return value of Array.from
			initialTreeBaseDurations = Array.from(initialTreeBaseDurations:entries()) :: Array<Array<number>>,
			interactionCommits = Array.from(interactionCommits:entries()) :: Array<Array<Array<number> | number>>,
			interactions = Array.from(interactions:entries()) :: Array<Array<any>>,
			operations = operations,
			rootID = rootID,
			snapshots = Array.from(snapshots:entries()) :: Array<Array<any>>,
		})
	end)
	return { version = PROFILER_EXPORT_VERSION, dataForRoots = dataForRoots }
end
exports.prepareProfilingDataExport = prepareProfilingDataExport
local function getGradientColor(value: number)
	local maxIndex = #commitGradient
	local index
	if Number.isNaN(value) then
		index = 0
	elseif not Number.isFinite(value) then
		index = maxIndex
	else
		index = math.max(0, math.min(maxIndex, value)) * maxIndex
	end
	return commitGradient[math.round(index)]
end
exports.getGradientColor = getGradientColor
local function formatDuration(duration: number)
	local ref = math.round(duration * 10) / 10
	return if Boolean.toJSBoolean(ref) then ref else "<0.1"
end
exports.formatDuration = formatDuration
local function formatPercentage(percentage: number)
	return math.round(percentage * 100)
end
exports.formatPercentage = formatPercentage
local function formatTime(timestamp: number)
	return math.round(math.round(timestamp) / 100) / 10
end
exports.formatTime = formatTime
local function scale(
	minValue: number,
	maxValue: number,
	minRange: number,
	maxRange: number
)
	return function(value: number, fallbackValue: number)
		return if maxValue - minValue == 0
			then fallbackValue
			else (value - minValue) / (maxValue - minValue) * (maxRange - minRange)
	end
end
exports.scale = scale
return exports
