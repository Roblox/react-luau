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

local ReactGlobals = require(Packages.ReactGlobals)
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local Set = LuauPolyfill.Set
-- ROBLOX deviation: use Set until a WeakSet polyfill is added
local WeakSet = Set
type Array<T> = LuauPolyfill.Array<T>
type Set<T> = LuauPolyfill.Set<T>
type WeakSet<T> = Set<T>

local ReactElementType = require(Packages.Shared)
-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes
type ReactElement = ReactElementType.ReactElement<any, any>
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot
local ReactFiberHostConfigModule = require(script.Parent.ReactFiberHostConfig)
type Instance = ReactFiberHostConfigModule.Instance
type ReactNodeList = ReactElementType.ReactNodeList

-- ROBLOX deviation: inline these requires to accommodate cyclic imports
-- local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"])
-- local flushSync = ReactFiberWorkLoop.flushSync
-- local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
-- local flushPassiveEffects = ReactFiberWorkLoop.flushPassiveEffects
-- local updateContainer = require(script.Parent["ReactFiberReconciler.new"]).updateContainer
-- local emptyContextObject = require(script.Parent["ReactFiberContext.new"]).emptyContextObject
local ReactFiberLaneModule = require(script.Parent.ReactFiberLane)
local SyncLane = ReactFiberLaneModule.SyncLane
local NoTimestamp = ReactFiberLaneModule.NoTimestamp
local ReactWorkTagsModule = require(script.Parent.ReactWorkTags)
local ClassComponent = ReactWorkTagsModule.ClassComponent
local FunctionComponent = ReactWorkTagsModule.FunctionComponent
local ForwardRef = ReactWorkTagsModule.ForwardRef
local HostComponent = ReactWorkTagsModule.HostComponent
local HostPortal = ReactWorkTagsModule.HostPortal
local HostRoot = ReactWorkTagsModule.HostRoot
local MemoComponent = ReactWorkTagsModule.MemoComponent
local SimpleMemoComponent = ReactWorkTagsModule.SimpleMemoComponent
local ReactSymbols = require(Packages.Shared).ReactSymbols
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE

local __DEV__ = ReactGlobals.__DEV__

export type Family = {
	current: any,
}

export type RefreshUpdate = {
	staleFamilies: Set<Family>,
	updatedFamilies: Set<Family>,
}

-- Resolves type to a family.
type RefreshHandler = (any) -> Family?

-- Used by React Refresh runtime through DevTools Global Hook.
export type SetRefreshHandler = (handler: RefreshHandler | nil) -> ()
export type ScheduleRefresh = (root: FiberRoot, update: RefreshUpdate) -> ()
export type ScheduleRoot = (root: FiberRoot, element: ReactNodeList) -> ()
export type FindHostInstancesForRefresh = (
	root: FiberRoot,
	families: Array<Family>
) -> Set<Instance>

local resolveFamily: RefreshHandler? = nil
-- $FlowFixMe Flow gets confused by a WeakSet feature check below.
local failedBoundaries: WeakSet<Fiber>? = nil

local exports = {}

-- ROBLOX deviation: pre-delcare shared functions
local findChildHostInstancesForFiberShallowly, findHostInstancesForFiberShallowly, findHostInstancesForMatchingFibersRecursively, scheduleFibersWithFamiliesRecursively

local function setRefreshHandler(handler: RefreshHandler | nil): ()
	if __DEV__ then
		resolveFamily = handler
	end
end
exports.setRefreshHandler = setRefreshHandler

local function resolveFunctionForHotReloading(type: any): any
	if __DEV__ then
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
	if __DEV__ then
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

local function isCompatibleFamilyForHotReloading(
	fiber: Fiber,
	element: ReactElement
): boolean
	if __DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return false
		end

		local prevType = fiber.elementType
		local nextType = element.type

		-- If we got here, we know types aren't === equal.
		local needsCompareFamilies = false

		local __typeofNextType = if typeof(nextType) == "table"
				and nextType ~= nil
			then nextType["$$typeof"]
			else nil

		repeat --[[ ROBLOX comment: switch statement conversion ]]
			local condition_ = fiber.tag
			if condition_ == ClassComponent then
				do
					if typeof(nextType) == "function" then
						needsCompareFamilies = true
					end
					break
				end
			elseif condition_ == FunctionComponent then
				do
					if typeof(nextType) == "function" then
						needsCompareFamilies = true
					elseif __typeofNextType == REACT_LAZY_TYPE then
						-- We don't know the inner type yet.
						-- We're going to assume that the lazy inner type is stable,
						-- and so it is sufficient to avoid reconciling it away.
						-- We're not going to unwrap or actually use the new lazy type.
						needsCompareFamilies = true
					end
					break
				end
			elseif condition_ == ForwardRef then
				do
					if __typeofNextType == REACT_FORWARD_REF_TYPE then
						needsCompareFamilies = true
					elseif __typeofNextType == REACT_LAZY_TYPE then
						needsCompareFamilies = true
					end
					break
				end
			elseif condition_ == MemoComponent or condition_ == SimpleMemoComponent then
				do
					if __typeofNextType == REACT_MEMO_TYPE then
						-- TODO: if it was but can no longer be simple,
						-- we shouldn't set this.
						needsCompareFamilies = true
					elseif __typeofNextType == REACT_LAZY_TYPE then
						needsCompareFamilies = true
					end
					break
				end
			else
				return false
			end
		until true

		-- Check if both types have a family and it's the same one.
		if needsCompareFamilies then
			-- Note: memo() and forwardRef() we'll compare outer rather than inner type.
			-- This means both of them need to be registered to preserve state.
			-- If we unwrapped and compared the inner types for wrappers instead,
			-- then we would risk falsely saying two separate memo(Foo)
			-- calls are equivalent because they wrap the same Foo function.
			local prevFamily = resolveFamily(prevType)
			if prevFamily ~= nil and prevFamily == resolveFamily(nextType) then
				return true
			end
		end
		return false
	else
		return false
	end
end
exports.isCompatibleFamilyForHotReloading = isCompatibleFamilyForHotReloading

local function markFailedErrorBoundaryForHotReloading(fiber: Fiber)
	if __DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return
		end
		-- ROBLOX deviation: WeakSet is always available
		-- if typeof(WeakSet) ~= "function" then
		-- 	return
		-- end
		if failedBoundaries == nil then
			failedBoundaries = WeakSet.new()
		end
		-- ROBLOX Luau FIXME: control flow analysis
		(failedBoundaries :: WeakSet<Fiber>):add(fiber)
	end
end
exports.markFailedErrorBoundaryForHotReloading = markFailedErrorBoundaryForHotReloading

local scheduleRefresh: ScheduleRefresh
function scheduleRefresh(root: FiberRoot, update: RefreshUpdate): ()
	if __DEV__ then
		if resolveFamily == nil then
			-- Hot reloading is disabled.
			return
		end
		local staleFamilies, updatedFamilies =
			update.staleFamilies, update.updatedFamilies
		local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"]) :: any
		local flushPassiveEffects = ReactFiberWorkLoop.flushPassiveEffects
		local flushSync = ReactFiberWorkLoop.flushSync
		flushPassiveEffects()
		flushSync(function()
			scheduleFibersWithFamiliesRecursively(
				root.current,
				updatedFamilies,
				staleFamilies
			)
		end)
	end
end
exports.scheduleRefresh = scheduleRefresh

local scheduleRoot: ScheduleRoot
function scheduleRoot(root: FiberRoot, element: ReactNodeList): ()
	if __DEV__ then
		local emptyContextObject = (
			require(script.Parent["ReactFiberContext.new"]) :: any
		).emptyContextObject
		if root.context ~= emptyContextObject then
			-- Super edge case: root has a legacy _renderSubtree context
			-- but we don't know the parentComponent so we can't pass it.
			-- Just ignore. We'll delete this with _renderSubtree code path later.
			return
		end
		local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"]) :: any
		local flushPassiveEffects = ReactFiberWorkLoop.flushPassiveEffects
		local flushSync = ReactFiberWorkLoop.flushSync
		flushPassiveEffects()
		flushSync(function()
			local updateContainer = (
				require(script.Parent["ReactFiberReconciler.new"]) :: any
			).updateContainer
			updateContainer(element, root, nil, nil)
		end)
	end
end
exports.scheduleRoot = scheduleRoot

function scheduleFibersWithFamiliesRecursively(
	fiber: Fiber,
	updatedFamilies: Set<Family>,
	staleFamilies: Set<Family>
)
	if __DEV__ then
		local alternate, child, sibling, tag, type_ =
			fiber.alternate, fiber.child, fiber.sibling, fiber.tag, fiber.type
		local candidateType = nil
		local condition_ = tag
		if
			condition_ == FunctionComponent
			or condition_ == SimpleMemoComponent
			or condition_ == ClassComponent
		then
			candidateType = type_
		elseif condition_ == ForwardRef then
			candidateType = type_.render
			-- ROBLOX deviation: no default case
			-- else
		end
		if resolveFamily == nil then
			error(Error.new("Expected resolveFamily to be set during hot reload."))
		end
		local needsRender = false
		local needsRemount = false
		if candidateType ~= nil then
			local family = resolveFamily(candidateType)
			if family ~= nil then
				if staleFamilies:has(family) then
					needsRemount = true
				elseif updatedFamilies:has(family) then
					if tag == ClassComponent then
						needsRemount = true
					else
						needsRender = true
					end
				end
			end
		end
		if failedBoundaries ~= nil then
			if
				failedBoundaries:has(fiber)
				or (alternate ~= nil and failedBoundaries:has(alternate))
			then
				needsRemount = true
			end
		end
		if needsRemount then
			fiber._debugNeedsRemount = true
		end
		if needsRemount or needsRender then
			local ReactFiberWorkLoop =
				require(script.Parent["ReactFiberWorkLoop.new"]) :: any
			local scheduleUpdateOnFiber = ReactFiberWorkLoop.scheduleUpdateOnFiber
			scheduleUpdateOnFiber(fiber, SyncLane, NoTimestamp)
		end
		if child ~= nil and not needsRemount then
			scheduleFibersWithFamiliesRecursively(child, updatedFamilies, staleFamilies)
		end
		if sibling ~= nil then
			scheduleFibersWithFamiliesRecursively(sibling, updatedFamilies, staleFamilies)
		end
	end
end

local findHostInstancesForRefresh: FindHostInstancesForRefresh
function findHostInstancesForRefresh(
	root: FiberRoot,
	families: Array<Family>
): Set<Instance>
	if __DEV__ then
		local hostInstances = Set.new()
		local types = Set.new(Array.map(families, function(family)
			return family.current
		end))
		findHostInstancesForMatchingFibersRecursively(root.current, types, hostInstances)
		return hostInstances
	else
		error(
			Error.new(
				"Did not expect findHostInstancesForRefresh to be called in production."
			)
		)
	end
end
exports.findHostInstancesForRefresh = findHostInstancesForRefresh

function findHostInstancesForMatchingFibersRecursively(
	fiber: Fiber,
	types: Set<any>,
	hostInstances: Set<Instance>
)
	if __DEV__ then
		local child, sibling, tag, type_ =
			fiber.child, fiber.sibling, fiber.tag, fiber.type
		local candidateType = nil
		local condition_ = tag
		if
			condition_ == FunctionComponent
			or condition_ == SimpleMemoComponent
			or condition_ == ClassComponent
		then
			candidateType = type_
		elseif condition_ == ForwardRef then
			candidateType = type_.render
			-- ROBLOX deviation: no default case
			-- else
		end
		local didMatch = false
		if candidateType ~= nil then
			if types:has(candidateType) then
				didMatch = true
			end
		end
		if didMatch then
			-- We have a match. This only drills down to the closest host components.
			-- There's no need to search deeper because for the purpose of giving
			-- visual feedback, "flashing" outermost parent rectangles is sufficient.
			findHostInstancesForFiberShallowly(fiber, hostInstances)
		else
			-- If there's no match, maybe there will be one further down in the child tree.
			if child ~= nil then
				findHostInstancesForMatchingFibersRecursively(child, types, hostInstances)
			end
		end
		if sibling ~= nil then
			findHostInstancesForMatchingFibersRecursively(sibling, types, hostInstances)
		end
	end
end

function findHostInstancesForFiberShallowly(
	fiber: Fiber,
	hostInstances: Set<Instance>
): ()
	if __DEV__ then
		local foundHostInstances =
			findChildHostInstancesForFiberShallowly(fiber, hostInstances)
		if foundHostInstances then
			return
		end
		-- If we didn't find any host children, fallback to closest host parent.
		local node = fiber
		while true do
			local condition_ = node.tag
			if condition_ == HostComponent then
				hostInstances:add(node.stateNode)
				return
			elseif condition_ == HostPortal then
				hostInstances:add(node.stateNode.containerInfo)
				return
			elseif condition_ == HostRoot then
				hostInstances:add(node.stateNode.containerInfo)
				return
			end
			if node.return_ == nil then
				error(Error.new("Expected to reach root first."))
			end
			node = node.return_
		end
	end
end

function findChildHostInstancesForFiberShallowly(
	fiber: Fiber,
	hostInstances: Set<Instance>
): boolean
	if __DEV__ then
		local node: Fiber = fiber
		local foundHostInstances = false
		while true do
			if node.tag == HostComponent then
				-- We got a match.
				foundHostInstances = true
				hostInstances:add(node.stateNode)
				-- There may still be more, so keep searching.
			elseif node.child ~= nil then
				node.child.return_ = node
				node = node.child
				continue
			end
			if node == fiber then
				return foundHostInstances
			end
			while node.sibling == nil do
				if node.return_ == nil or node.return_ == fiber then
					return foundHostInstances
				end
				node = node.return_
			end
			-- ROBLOX Luau FIXME: control flow analysis
			assert(node.sibling ~= nil, "should be non-nil")
			node.sibling.return_ = node.return_
			node = node.sibling
		end
	end
	return false
end

return exports
