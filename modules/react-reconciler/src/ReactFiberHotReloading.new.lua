--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/6edaf6f764f23043f0cd1c2da355b42f641afd8b/packages/react-reconciler/src/ReactFiberHotReloading.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent

local ReactElementType = require(Packages.Shared)
-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes
type ReactElement = ReactElementType.ReactElement<any, any>

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
-- local type {FiberRoot} = require(script.Parent.ReactInternalTypes)
-- local type {Instance} = require(script.Parent.ReactFiberHostConfig)
-- local type {ReactNodeList} = require(Packages.Shared).ReactTypes

-- local {
-- 	flushSync,
-- 	scheduleUpdateOnFiber,
-- 	flushPassiveEffects,
-- } = require(script.Parent.ReactFiberWorkLoop.new)
-- local {updateContainer} = require(script.Parent.ReactFiberReconciler.new)
-- local {emptyContextObject} = require(script.Parent.ReactFiberContext.new)
-- local {SyncLane, NoTimestamp} = require(script.Parent.ReactFiberLane)
-- local {
-- 	ClassComponent,
-- 	FunctionComponent,
-- 	ForwardRef,
-- 	HostComponent,
-- 	HostPortal,
-- 	HostRoot,
-- 	MemoComponent,
-- 	SimpleMemoComponent,
-- } = require(script.Parent.ReactWorkTags)
local ReactSymbols = require(Packages.Shared).ReactSymbols
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
-- 	REACT_MEMO_TYPE,
-- 	REACT_LAZY_TYPE,

export type Family = {
	current: any,
}

-- export type RefreshUpdate = {|
-- 	staleFamilies: Set<Family>,
-- 	updatedFamilies: Set<Family>,
-- |}

-- Resolves type to a family.
type RefreshHandler = (any) -> (Family?)

-- -- Used by React Refresh runtime through DevTools Global Hook.
-- export type SetRefreshHandler = (handler: RefreshHandler | nil) => void
-- export type ScheduleRefresh = (root: FiberRoot, update: RefreshUpdate) => void
-- export type ScheduleRoot = (root: FiberRoot, element: ReactNodeList) => void
-- export type FindHostInstancesForRefresh = (
-- 	root: FiberRoot,
-- 	families: Array<Family>,
-- ) => Set<Instance>

-- FIXME (roblox): restore type 'resolveFamily: RefreshHandler?' when type
-- refinement in Luau works better
local resolveFamily = nil
-- $FlowFixMe Flow gets confused by a WeakSet feature check below.
-- ROBLOX deviation: Using table instead of WeakSet
local failedBoundaries: { [number]: Fiber } | nil = nil

local exports = {}

-- export local setRefreshHandler = (handler: RefreshHandler | nil): void => {
-- 	if _G.__DEV__)
-- 		resolveFamily = handler
-- 	end
-- end

local function resolveFunctionForHotReloading(type: any): any
	if _G.__DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return type
		end
		local family = resolveFamily(type)
		if family == nil then
			return type
		end
		-- Use the latest known implementation.
		return family.current
	else
		return type
	end
end
exports.resolveFunctionForHotReloading = resolveFunctionForHotReloading

local function resolveClassForHotReloading(type: any): any
	-- No implementation differences.
	return resolveFunctionForHotReloading(type)
end
exports.resolveClassForHotReloading = resolveClassForHotReloading

local function resolveForwardRefForHotReloading(type: any): any
	if _G.__DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return type
		end
		local family = resolveFamily(type)
		if family == nil then
			-- Check if we're dealing with a real forwardRef. Don't want to crash early.
			if type ~= nil and typeof(type.render) == "function" then
				-- ForwardRef is special because its resolved .type is an object,
				-- but it's possible that we only have its inner render function in the map.
				-- If that inner render function is different, we'll build a new forwardRef type.
				local currentRender = resolveFunctionForHotReloading(type.render)
				if type.render ~= currentRender then
					local syntheticType = {
						["$$typeof"] = REACT_FORWARD_REF_TYPE,
						render = currentRender,
						-- ROBLOX deviation: Luau needs table initializers to be complete
						displayName = nil,
					}
					if type.displayName ~= nil then
						syntheticType.displayName = type.displayName
					end
					return syntheticType
				end
			end
			return type
		end
		-- Use the latest known implementation.
		return family.current
	else
		return type
	end
end
exports.resolveForwardRefForHotReloading = resolveForwardRefForHotReloading

exports.isCompatibleFamilyForHotReloading =
	function(fiber: Fiber, element: ReactElement): boolean
		warn("isCompatibleFamilyForHotReloading is stubbed (returns false)")
		return false
		-- if _G.__DEV__ then
		-- 	if resolveFamily == nil then
		-- 		-- Hot reloading is disabled.
		-- 		return false
		-- 	end

		-- 	local prevType = fiber.elementType
		-- 	local nextType = element.type

		-- 	-- If we got here, we know types aren't == equal.
		-- 	local needsCompareFamilies = false

		-- 	local $$typeofNextType =
		-- 		typeof nextType == 'table’' and nextType ~= nil
		-- 			? nextType.$$typeof
		-- 			: nil

		-- 	switch (fiber.tag)
		-- 		case ClassComponent: {
		-- 			if typeof nextType == 'function')
		-- 				needsCompareFamilies = true
		-- 			end
		-- 			break
		-- 		end
		-- 		case FunctionComponent: {
		-- 			if typeof nextType == 'function')
		-- 				needsCompareFamilies = true
		-- 			} else if $$typeofNextType == REACT_LAZY_TYPE)
		-- 				-- We don't know the inner type yet.
		-- 				-- We're going to assume that the lazy inner type is stable,
		-- 				-- and so it is sufficient to avoid reconciling it away.
		-- 				-- We're not going to unwrap or actually use the new lazy type.
		-- 				needsCompareFamilies = true
		-- 			end
		-- 			break
		-- 		end
		-- 		case ForwardRef: {
		-- 			if $$typeofNextType == REACT_FORWARD_REF_TYPE)
		-- 				needsCompareFamilies = true
		-- 			} else if $$typeofNextType == REACT_LAZY_TYPE)
		-- 				needsCompareFamilies = true
		-- 			end
		-- 			break
		-- 		end
		-- 		case MemoComponent:
		-- 		case SimpleMemoComponent: {
		-- 			if $$typeofNextType == REACT_MEMO_TYPE)
		-- 				-- TODO: if it was but can no longer be simple,
		-- 				-- we shouldn't set this.
		-- 				needsCompareFamilies = true
		-- 			} else if $$typeofNextType == REACT_LAZY_TYPE)
		-- 				needsCompareFamilies = true
		-- 			end
		-- 			break
		-- 		end
		-- 		default:
		-- 			return false
		-- 	end

		-- 	-- Check if both types have a family and it's the same one.
		-- 	if needsCompareFamilies)
		-- 		-- Note: memo() and forwardRef() we'll compare outer rather than inner type.
		-- 		-- This means both of them need to be registered to preserve state.
		-- 		-- If we unwrapped and compared the inner types for wrappers instead,
		-- 		-- then we would risk falsely saying two separate memo(Foo)
		-- 		-- calls are equivalent because they wrap the same Foo function.
		-- 		local prevFamily = resolveFamily(prevType)
		-- 		if prevFamily ~= undefined and prevFamily == resolveFamily(nextType))
		-- 			return true
		-- 		end
		-- 	end
		-- 	return false
		-- } else {
		-- 	return false
		-- end
	end

exports.markFailedErrorBoundaryForHotReloading = function(fiber: Fiber)
	if _G.__DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return
		end
		-- if typeof(WeakSet) ~= 'function' then
		-- 	return
		-- end
		-- ROBLOX deviation: {} in place of WeakSet
		if failedBoundaries == nil then
			failedBoundaries = {}
		end
		-- ROBLOX FIXME: remove :: once Luau understands nil check
		table.insert(failedBoundaries :: { [number]: Fiber }, fiber)
	end
end

-- export local scheduleRefresh: ScheduleRefresh = (
-- 	root: FiberRoot,
-- 	update: RefreshUpdate,
-- ): void => {
-- 	if _G.__DEV__)
-- 		if resolveFamily == nil)
-- 			-- Hot reloading is disabled.
-- 			return
-- 		end
-- 		local {staleFamilies, updatedFamilies} = update
-- 		flushPassiveEffects()
-- 		flushSync(() => {
-- 			scheduleFibersWithFamiliesRecursively(
-- 				root.current,
-- 				updatedFamilies,
-- 				staleFamilies,
-- 			)
-- 		})
-- 	end
-- end

-- export local scheduleRoot: ScheduleRoot = (
-- 	root: FiberRoot,
-- 	element: ReactNodeList,
-- ): void => {
-- 	if _G.__DEV__)
-- 		if root.context ~= emptyContextObject)
-- 			-- Super edge case: root has a legacy _renderSubtree context
-- 			-- but we don't know the parentComponent so we can't pass it.
-- 			-- Just ignore. We'll delete this with _renderSubtree code path later.
-- 			return
-- 		end
-- 		flushPassiveEffects()
-- 		flushSync(() => {
-- 			updateContainer(element, root, nil, nil)
-- 		})
-- 	end
-- end

-- function scheduleFibersWithFamiliesRecursively(
-- 	fiber: Fiber,
-- 	updatedFamilies: Set<Family>,
-- 	staleFamilies: Set<Family>,
-- )
-- 	if _G.__DEV__)
-- 		local {alternate, child, sibling, tag, type} = fiber

-- 		local candidateType = nil
-- 		switch (tag)
-- 			case FunctionComponent:
-- 			case SimpleMemoComponent:
-- 			case ClassComponent:
-- 				candidateType = type
-- 				break
-- 			case ForwardRef:
-- 				candidateType = type.render
-- 				break
-- 			default:
-- 				break
-- 		end

-- 		if resolveFamily == nil)
-- 			throw new Error('Expected resolveFamily to be set during hot reload.')
-- 		end

-- 		local needsRender = false
-- 		local needsRemount = false
-- 		if candidateType ~= nil)
-- 			local family = resolveFamily(candidateType)
-- 			if family ~= undefined)
-- 				if staleFamilies.has(family))
-- 					needsRemount = true
-- 				} else if updatedFamilies.has(family))
-- 					if tag == ClassComponent)
-- 						needsRemount = true
-- 					} else {
-- 						needsRender = true
-- 					end
-- 				end
-- 			end
-- 		end
-- 		if failedBoundaries ~= nil)
-- 			if
-- 				failedBoundaries.has(fiber) or
-- 				(alternate ~= nil and failedBoundaries.has(alternate))
-- 			)
-- 				needsRemount = true
-- 			end
-- 		end

-- 		if needsRemount)
-- 			fiber._debugNeedsRemount = true
-- 		end
-- 		if needsRemount or needsRender)
-- 			scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
-- 		end
-- 		if child ~= nil and !needsRemount)
-- 			scheduleFibersWithFamiliesRecursively(
-- 				child,
-- 				updatedFamilies,
-- 				staleFamilies,
-- 			)
-- 		end
-- 		if sibling ~= nil)
-- 			scheduleFibersWithFamiliesRecursively(
-- 				sibling,
-- 				updatedFamilies,
-- 				staleFamilies,
-- 			)
-- 		end
-- 	end
-- end

-- export local findHostInstancesForRefresh: FindHostInstancesForRefresh = (
-- 	root: FiberRoot,
-- 	families: Array<Family>,
-- ): Set<Instance> => {
-- 	if _G.__DEV__)
-- 		local hostInstances = new Set()
-- 		local types = new Set(families.map(family => family.current))
-- 		findHostInstancesForMatchingFibersRecursively(
-- 			root.current,
-- 			types,
-- 			hostInstances,
-- 		)
-- 		return hostInstances
-- 	} else {
-- 		throw new Error(
-- 			'Did not expect findHostInstancesForRefresh to be called in production.',
-- 		)
-- 	end
-- end

-- function findHostInstancesForMatchingFibersRecursively(
-- 	fiber: Fiber,
-- 	types: Set<any>,
-- 	hostInstances: Set<Instance>,
-- )
-- 	if _G.__DEV__)
-- 		local {child, sibling, tag, type} = fiber

-- 		local candidateType = nil
-- 		switch (tag)
-- 			case FunctionComponent:
-- 			case SimpleMemoComponent:
-- 			case ClassComponent:
-- 				candidateType = type
-- 				break
-- 			case ForwardRef:
-- 				candidateType = type.render
-- 				break
-- 			default:
-- 				break
-- 		end

-- 		local didMatch = false
-- 		if candidateType ~= nil)
-- 			if types.has(candidateType))
-- 				didMatch = true
-- 			end
-- 		end

-- 		if didMatch)
-- 			-- We have a match. This only drills down to the closest host components.
-- 			-- There's no need to search deeper because for the purpose of giving
-- 			-- visual feedback, "flashing" outermost parent rectangles is sufficient.
-- 			findHostInstancesForFiberShallowly(fiber, hostInstances)
-- 		} else {
-- 			-- If there's no match, maybe there will be one further down in the child tree.
-- 			if child ~= nil)
-- 				findHostInstancesForMatchingFibersRecursively(
-- 					child,
-- 					types,
-- 					hostInstances,
-- 				)
-- 			end
-- 		end

-- 		if sibling ~= nil)
-- 			findHostInstancesForMatchingFibersRecursively(
-- 				sibling,
-- 				types,
-- 				hostInstances,
-- 			)
-- 		end
-- 	end
-- end

-- function findHostInstancesForFiberShallowly(
-- 	fiber: Fiber,
-- 	hostInstances: Set<Instance>,
-- ): void {
-- 	if _G.__DEV__)
-- 		local foundHostInstances = findChildHostInstancesForFiberShallowly(
-- 			fiber,
-- 			hostInstances,
-- 		)
-- 		if foundHostInstances)
-- 			return
-- 		end
-- 		-- If we didn't find any host children, fallback to closest host parent.
-- 		local node = fiber
-- 		while (true)
-- 			switch (node.tag)
-- 				case HostComponent:
-- 					hostInstances.add(node.stateNode)
-- 					return
-- 				case HostPortal:
-- 					hostInstances.add(node.stateNode.containerInfo)
-- 					return
-- 				case HostRoot:
-- 					hostInstances.add(node.stateNode.containerInfo)
-- 					return
-- 			end
-- 			if node.return == nil)
-- 				throw new Error('Expected to reach root first.')
-- 			end
-- 			node = node.return
-- 		end
-- 	end
-- end

-- function findChildHostInstancesForFiberShallowly(
-- 	fiber: Fiber,
-- 	hostInstances: Set<Instance>,
-- ): boolean {
-- 	if _G.__DEV__)
-- 		local node: Fiber = fiber
-- 		local foundHostInstances = false
-- 		while (true)
-- 			if node.tag == HostComponent)
-- 				-- We got a match.
-- 				foundHostInstances = true
-- 				hostInstances.add(node.stateNode)
-- 				-- There may still be more, so keep searching.
-- 			} else if node.child ~= nil)
-- 				node.child.return = node
-- 				node = node.child
-- 				continue
-- 			end
-- 			if node == fiber)
-- 				return foundHostInstances
-- 			end
-- 			while (node.sibling == nil)
-- 				if node.return == nil or node.return == fiber)
-- 					return foundHostInstances
-- 				end
-- 				node = node.return
-- 			end
-- 			node.sibling.return = node.return
-- 			node = node.sibling
-- 		end
-- 	end
-- 	return false
-- end

return exports
