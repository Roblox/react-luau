--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/devtools/views/Profiler/types.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Packages = script.Parent.Parent.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Map<K, V> = LuauPolyfill.Map<K, V>
type Array<K> = LuauPolyfill.Array<K>
local exports = {}

local ReactDevtoolsSharedTypes = require(script.Parent.Parent.Parent.Parent.types)

type ElementType = ReactDevtoolsSharedTypes.ElementType

export type CommitTreeNode = {
	id: number,
	children: Array<number>,
	displayName: string | nil,
	hocDisplayNames: Array<string> | nil,
	key: number | string | nil,
	parentID: number,
	treeBaseDuration: number,
	type: ElementType,
}

export type CommitTree = { nodes: Map<number, CommitTreeNode>, rootID: number }

export type Interaction = { id: number, name: string, timestamp: number }

export type SnapshotNode = {
	id: number,
	children: Array<number>,
	displayName: string | nil,
	hocDisplayNames: Array<string> | nil,
	key: number | string | nil,
	type: ElementType,
}

export type ChangeDescription = {
	context: Array<string> | boolean | nil,
	didHooksChange: boolean,
	isFirstMount: boolean,
	props: Array<string> | nil,
	state: Array<string> | nil,
}

export type CommitDataFrontend = {
	-- Map of Fiber (ID) to a description of what changed in this commit.
	changeDescriptions: Map<number, ChangeDescription> | nil,

	-- How long was this commit?
	duration: number,

	-- Map of Fiber (ID) to actual duration for this commit;
	-- Fibers that did not render will not have entries in this Map.
	fiberActualDurations: Map<number, number>,

	-- Map of Fiber (ID) to "self duration" for this commit;
	-- Fibers that did not render will not have entries in this Map.
	fiberSelfDurations: Map<number, number>,

	-- Which interactions (IDs) were associated with this commit.
	interactionIDs: Array<number>,

	-- Priority level of the commit (if React provided this info)
	priorityLevel: string | nil,

	-- When did this commit occur (relative to the start of profiling)
	timestamp: number,
}

export type ProfilingDataForRootFrontend = {
	-- Timing, duration, and other metadata about each commit.
	commitData: Array<CommitDataFrontend>,

	-- Display name of the nearest descendant component (ideally a function or class component).
	-- This value is used by the root selector UI.
	displayName: string,

	-- Map of fiber id to (initial) tree base duration when Profiling session was started.
	-- This info can be used along with commitOperations to reconstruct the tree for any commit.
	initialTreeBaseDurations: Map<number, number>,

	-- All interactions recorded (for this root) during the current session.
	interactionCommits: Map<number, Array<number>>,

	-- All interactions recorded (for this root) during the current session.
	interactions: Map<number, Interaction>,

	-- List of tree mutation that occur during profiling.
	-- These mutations can be used along with initial snapshots to reconstruct the tree for any commit.
	operations: Array<Array<number>>,

	-- Identifies the root this profiler data corresponds to.
	rootID: number,

	-- Map of fiber id to node when the Profiling session was started.
	-- This info can be used along with commitOperations to reconstruct the tree for any commit.
	snapshots: Map<number, SnapshotNode>,
}

-- Combination of profiling data collected by the renderer interface (backend) and Store (frontend).
export type ProfilingDataFrontend = {
	-- Profiling data per root.
	dataForRoots: Map<number, ProfilingDataForRootFrontend>,
	imported: boolean,
}

export type CommitDataExport = {
	-- ROBLOX TODO: how to express bracket syntax embedded in Array type?
	--   changeDescriptions: Array<[number, ChangeDescription]> | nil,
	changeDescriptions: Array<Array<number | ChangeDescription>> | nil,
	duration: number,
	-- Tuple of fiber ID and actual duration
	fiberActualDurations: Array<Array<number>>,
	-- Tuple of fiber ID and computed "self" duration
	fiberSelfDurations: Array<Array<number>>,
	interactionIDs: Array<number>,
	priorityLevel: string | nil,
	timestamp: number,
}

export type ProfilingDataForRootExport = {
	commitData: Array<CommitDataExport>,
	displayName: string,
	-- Tuple of Fiber ID and base duration
	initialTreeBaseDurations: Array<Array<number>>,
	-- Tuple of Interaction ID and commit indices
	interactionCommits: Array<Array<number | Array<number>>>,
	interactions: Array<Array<number | Interaction>>,
	operations: Array<Array<number>>,
	rootID: number,
	snapshots: Array<Array<number | SnapshotNode>>,
}

-- Serializable version of ProfilingDataFrontend data.
export type ProfilingDataExport = {
	-- ROBLOX TODO: Luau can't express literals/enums
	--   version: 4,
	version: number,
	dataForRoots: Array<ProfilingDataForRootExport>,
}

return exports
