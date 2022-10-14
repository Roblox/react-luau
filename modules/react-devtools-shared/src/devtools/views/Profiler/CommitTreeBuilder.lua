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
local console = LuauPolyfill.console

type Map<K, V> = LuauPolyfill.Map<K, V>
type Array<K> = LuauPolyfill.Array<K>

local exports = {}
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]
local constantsModule = require(script.Parent.Parent.Parent.Parent.constants)
local __DEBUG__ = constantsModule.__DEBUG__
local TREE_OPERATION_ADD = constantsModule.TREE_OPERATION_ADD
local TREE_OPERATION_REMOVE = constantsModule.TREE_OPERATION_REMOVE
local TREE_OPERATION_REORDER_CHILDREN = constantsModule.TREE_OPERATION_REORDER_CHILDREN
local TREE_OPERATION_UPDATE_TREE_BASE_DURATION =
	constantsModule.TREE_OPERATION_UPDATE_TREE_BASE_DURATION

local devtoolsTypes = require(script.Parent.Parent.Parent.types)
type ProfilerStore = devtoolsTypes.ProfilerStore

local ElementTypeRoot = require(script.Parent.Parent.Parent.Parent.types).ElementTypeRoot
local typesModule = require(script.Parent.Parent.Parent.Parent.types)
type ElementType = typesModule.ElementType

local Profiler_typesModule = require(script.Parent.types)
type CommitTree = Profiler_typesModule.CommitTree
type CommitTreeNode = Profiler_typesModule.CommitTreeNode
type ProfilingDataForRootFrontend = Profiler_typesModule.ProfilingDataForRootFrontend
type ProfilingDataFrontend = Profiler_typesModule.ProfilingDataFrontend

local function debug_(methodName, ...: any)
	if __DEBUG__ then
		print("[CommitTreeBuilder]", methodName, ...)
	end
end

local function __printTree(commitTree: CommitTree)
	if __DEBUG__ then
		local nodes, rootID = commitTree.nodes, commitTree.rootID
		console.group("__printTree()")
		local queue = { rootID, 0 }
		-- ROBLOX TODO Luau? if length check > 0, remove() nil-ability could be removed
		while #queue > 0 do
			local id = table.remove(queue, 1) :: number
			local depth = table.remove(queue, 1) :: number
			local node = nodes:get(id)
			-- ROBLOX FIXME Luau: need to understand error() narrows node nil-ability
			if node == nil then
				error(
					string.format(
						'Could not find node with id "%s" in commit tree',
						tostring(id)
					)
				)
			end
			console.log(
				string.format(
					"%s%s:%s %s (%s)",
					string.rep("\u{2022}", depth),
					tostring((node :: CommitTreeNode).id),
					tostring((node :: CommitTreeNode).displayName or ""),
					if (node :: CommitTreeNode).key
						then string.format('key:"%s"', tostring((node :: CommitTreeNode).key))
						else "",
					tostring((node :: CommitTreeNode).treeBaseDuration)
				)
			)
			Array.forEach((node :: CommitTreeNode).children, function(childID)
				Array.concat(queue, { childID, depth + 1 })
			end)
		end
		console.groupEnd()
	end
end

local function updateTree(commitTree: CommitTree, operations: Array<number>): CommitTree
	-- Clone the original tree so edits don't affect it.
	local nodes = Map.new(commitTree.nodes)

	-- Clone nodes before mutating them so edits don't affect the original.
	local function getClonedNode(id: number): CommitTreeNode
		local clonedNode = table.clone((nodes:get(id) :: any) :: CommitTreeNode)
		nodes:set(id, clonedNode)
		return clonedNode
	end

	local i = 3 -- Skip rendererID and currentRootID
	local function POSTFIX_INCREMENT()
		local x = i
		i += 1
		return x
	end

	local id: number = (nil :: any) :: number -- Reassemble the string table.
	local stringTable: Array<any> = {
		-- ROBLOX deviation: element 1 corresponds to empty string, this is why key is "" instead of nil in snapshots
		"", -- ID = 0 corresponds to the null string.
	}

	local stringTableSize = operations[POSTFIX_INCREMENT()]
	local stringTableEnd = i + stringTableSize

	while i < stringTableEnd do
		-- ROBLOX deviation: don't binary encode strings, so store string directly rather than length
		-- local nextLength = operations[POSTFIX_INCREMENT()]
		-- local nextString = utfDecodeString(Array.slice(operations, i, i + nextLength))
		local nextString = operations[POSTFIX_INCREMENT()]

		table.insert(stringTable, nextString)
		-- ROBLOX deviation: don't binary encode strings, so no need to move pointer
		-- i = i + nextLength
	end

	while i <= #operations do
		local operation = operations[POSTFIX_INCREMENT()]

		if operation == TREE_OPERATION_ADD then
			id = operations[POSTFIX_INCREMENT()]
			local type_ = (operations[POSTFIX_INCREMENT()] :: any) :: ElementType
			if nodes:has(id) then
				error(
					"Commit tree already contains fiber "
						.. tostring(id)
						.. ". This is a bug in React DevTools."
				)
			end
			if type_ == ElementTypeRoot then
				i += 2 -- supportsProfiling flag and hasOwnerMetadata flag
				if __DEBUG__ then
					debug_("Add", ("new root fiber %s"):format(tostring(id)))
				end
				local node: CommitTreeNode = {
					children = {},
					displayName = nil,
					hocDisplayNames = nil,
					id = id,
					key = nil,
					parentID = 0,
					treeBaseDuration = 0, -- This will be updated by a subsequent operation
					type = type_,
				}
				nodes:set(id, node)
			else
				local parentID = operations[POSTFIX_INCREMENT()]
				i += 1 -- skip ownerID
				local displayNameStringID = operations[POSTFIX_INCREMENT()]
				local displayName = stringTable[displayNameStringID + 1]

				local keyStringID = operations[POSTFIX_INCREMENT()]
				local key = stringTable[keyStringID + 1] -- 1 indexed stringtable

				if __DEBUG__ then
					debug_(
						"Add",
						("fiber %s (%s) as child of %s"):format(
							tostring(id),
							tostring(displayName or "null"),
							tostring(parentID)
						)
					)
				end
				local parentNode = getClonedNode(parentID)
				parentNode.children = Array.concat(parentNode.children, id)
				local node: CommitTreeNode = {
					children = {},
					displayName = displayName,
					hocDisplayNames = nil,
					id = id,
					key = key,
					parentID = parentID,
					treeBaseDuration = 0, -- This will be updated by a subsequent operation
					type = type_,
				}
				nodes:set(id, node)
			end
		elseif operation == TREE_OPERATION_REMOVE then
			local removeLength = operations[POSTFIX_INCREMENT()]
			for _ = 1, removeLength do
				id = operations[POSTFIX_INCREMENT()]
				if not nodes:has(id) then
					error(
						"Commit tree does not contain fiber "
							.. tostring(id)
							.. ". This is a bug in React DevTools."
					)
				end
				local node = getClonedNode(id)
				local parentID = node.parentID
				nodes:delete(id)
				if not nodes:has(parentID) then
					-- No-op
				else
					local parentNode = getClonedNode(parentID)
					if __DEBUG__ then
						debug_(
							"Remove",
							("fiber %s from parent %s"):format(
								tostring(id),
								tostring(parentID)
							)
						)
					end
					parentNode.children = Array.filter(
						parentNode.children,
						function(childID)
							return childID ~= id
						end
					)
				end
			end
		elseif operation == TREE_OPERATION_REORDER_CHILDREN then
			id = operations[POSTFIX_INCREMENT()]
			local numChildren = operations[POSTFIX_INCREMENT()]
			local children =
				(Array.slice(operations, i, i + numChildren) :: any) :: Array<number>
			i += numChildren
			if __DEBUG__ then
				debug_(
					"Re-order",
					("fiber %s children %s"):format(
						tostring(id),
						tostring(Array.join(children, ","))
					)
				)
			end
			local node = getClonedNode(id)
			-- ROBLOX FIXME Luau: this cast shouldn't be necessary
			node.children = Array.from(children) :: Array<number>
		elseif operation == TREE_OPERATION_UPDATE_TREE_BASE_DURATION then
			id = operations[POSTFIX_INCREMENT()]
			local node = getClonedNode(id)
			node.treeBaseDuration = operations[POSTFIX_INCREMENT()] / 1000 -- Convert microseconds back to milliseconds;
			if __DEBUG__ then
				debug_(
					"Update",
					("fiber %s treeBaseDuration to %s"):format(
						tostring(id),
						tostring(node.treeBaseDuration)
					)
				)
			end
		else
			error(
				string.format(
					"Unsupported Bridge operation %s at operation index %d",
					tostring(operation),
					i
				)
			)
		end
	end
	return { nodes = nodes, rootID = commitTree.rootID }
end

local function recursivelyInitializeTree(
	id: number,
	parentID: number,
	nodes: Map<number, CommitTreeNode>,
	dataForRoot: ProfilingDataForRootFrontend
): ()
	local node = dataForRoot.snapshots:get(id)
	if node ~= nil then
		nodes:set(id, {
			id = id,
			children = node.children,
			displayName = node.displayName,
			hocDisplayNames = node.hocDisplayNames,
			key = node.key,
			parentID = parentID,
			treeBaseDuration = (dataForRoot.initialTreeBaseDurations:get(id) :: any) :: number,
			type = node.type,
		})
		for _, childID in node.children do
			recursivelyInitializeTree(childID, id, nodes, dataForRoot)
		end
	end
end

local rootToCommitTreeMap: Map<number, Array<CommitTree>> = Map.new()
local function getCommitTree(
	ref: {
		commitIndex: number,
		profilerStore: ProfilerStore,
		rootID: number,
	}
): CommitTree
	local commitIndex, profilerStore, rootID =
		ref.commitIndex, ref.profilerStore, ref.rootID
	if not rootToCommitTreeMap:has(rootID) then
		rootToCommitTreeMap:set(rootID, {})
	end
	local commitTrees = (rootToCommitTreeMap:get(rootID) :: any) :: Array<CommitTree>
	if commitIndex <= #commitTrees then
		return commitTrees[commitIndex]
	end
	local profilingData = profilerStore:profilingData()
	-- ROBLOX FIXME Luau: need to understand error() means profilingData gets nil-ability stripped. needs type states.
	if profilingData == nil then
		error("No profiling data available")
	end
	local dataForRoot = (profilingData :: ProfilingDataFrontend).dataForRoots:get(rootID)
	-- ROBLOX FIXME Luau: need to understand error() means profilingData gets nil-ability stripped. needs type states.
	if dataForRoot == nil then
		error(
			string.format('Could not find profiling data for root "%s"', tostring(rootID))
		)
	end
	local operations = (dataForRoot :: ProfilingDataForRootFrontend).operations -- Commits are generated sequentially and cached.
	-- If this is the very first commit, start with the cached snapshot and apply the first mutation.
	-- Otherwise load (or generate) the previous commit and append a mutation to it.
	if commitIndex == 1 then
		local nodes = Map.new() -- Construct the initial tree.
		recursivelyInitializeTree(
			rootID,
			0,
			nodes,
			dataForRoot :: ProfilingDataForRootFrontend
		) -- Mutate the tree
		if operations ~= nil and commitIndex <= #operations then
			local commitTree = updateTree(
				{ nodes = nodes, rootID = rootID },
				operations[commitIndex]
			)
			if __DEBUG__ then
				__printTree(commitTree)
			end
			table.insert(commitTrees, commitTree)
			return commitTree
		end
	else
		local previousCommitTree = getCommitTree({
			commitIndex = commitIndex - 1,
			profilerStore = profilerStore,
			rootID = rootID,
		})
		if operations ~= nil and commitIndex <= #operations then
			local commitTree = updateTree(previousCommitTree, operations[commitIndex])
			if __DEBUG__ then
				__printTree(commitTree)
			end
			table.insert(commitTrees, commitTree)
			return commitTree
		end
	end
	error(
		string.format(
			'getCommitTree(): Unable to reconstruct tree for root "%s" and commit %s',
			tostring(rootID),
			tostring(commitIndex)
		)
	)
end
exports.getCommitTree = getCommitTree

local function invalidateCommitTrees(): any?
	return rootToCommitTreeMap:clear()
end
exports.invalidateCommitTrees = invalidateCommitTrees -- DEBUG

return exports
