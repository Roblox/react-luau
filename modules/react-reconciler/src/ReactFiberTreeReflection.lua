--!nonstrict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberTreeReflection.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
type Container = ReactFiberHostConfig.Container
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
local ReactFiberSuspenseComponent =
	require(script.Parent["ReactFiberSuspenseComponent.new"])
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local invariant = require(Packages.Shared).invariant

local getInstance = require(Packages.Shared).ReactInstanceMap.get
local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local getComponentName = require(Packages.Shared).getComponentName
local ReactWorkTags = require(script.Parent.ReactWorkTags)
local ClassComponent = ReactWorkTags.ClassComponent
local HostComponent = ReactWorkTags.HostComponent
local HostRoot = ReactWorkTags.HostRoot
local HostPortal = ReactWorkTags.HostPortal
local HostText = ReactWorkTags.HostText
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local NoFlags = ReactFiberFlags.NoFlags
local Placement = ReactFiberFlags.Placement
local Hydrating = ReactFiberFlags.Hydrating
local enableFundamentalAPI =
	require(Packages.Shared).ReactFeatureFlags.enableFundamentalAPI

local ReactCurrentOwner = ReactSharedInternals.ReactCurrentOwner

local exports = {}

local function getNearestMountedFiber(fiber: Fiber): Fiber?
	local node = fiber
	-- ROBLOX FIXME Luau: Luau should infer this annotation
	local nearestMounted: Fiber | nil = fiber
	if not fiber.alternate then
		-- If there is no alternate, this might be a new tree that isn't inserted
		-- yet. If it is, then it will have a pending insertion effect on it.
		local nextNode = node
		repeat
			node = nextNode
			if bit32.band(node.flags, bit32.bor(Placement, Hydrating)) ~= NoFlags then
				-- This is an insertion or in-progress hydration. The nearest possible
				-- mounted fiber is the parent but we need to continue to figure out
				-- if that one is still mounted.
				nearestMounted = node.return_
			end
			nextNode = node.return_
		until not nextNode
	else
		while node.return_ do
			node = node.return_
		end
	end
	if node.tag == HostRoot then
		-- TODO: Check if this was a nested HostRoot when used with
		-- renderContainerIntoSubtree.
		return nearestMounted
	end
	-- If we didn't hit the root, that means that we're in an disconnected tree
	-- that has been unmounted.
	return nil
end
exports.getNearestMountedFiber = getNearestMountedFiber

exports.getSuspenseInstanceFromFiber = function(fiber: Fiber): SuspenseInstance?
	if fiber.tag == SuspenseComponent then
		local suspenseState: SuspenseState? = fiber.memoizedState
		if suspenseState == nil then
			local current = fiber.alternate
			if current ~= nil then
				suspenseState = current.memoizedState
			end
		end
		if suspenseState then
			return suspenseState.dehydrated
		end
	end
	return nil
end

exports.getContainerFromFiber = function(fiber: Fiber): Container?
	return if fiber.tag == HostRoot then fiber.stateNode.containerInfo else nil
end

exports.isFiberMounted = function(fiber: Fiber): boolean
	return getNearestMountedFiber(fiber) == fiber
end

-- ROBLOX TODO: Missing React$ internal flow types
-- exports.isMounted = function(component: React$Component<any, any>): boolean
exports.isMounted = function(component): boolean
	if _G.__DEV__ then
		local owner: any = ReactCurrentOwner.current
		if owner ~= nil and owner.tag == ClassComponent then
			local ownerFiber: Fiber = owner
			local instance = ownerFiber.stateNode
			if not instance._warnedAboutRefsInRender then
				console.error(
					"%s is accessing isMounted inside its render() function. "
						.. "render() should be a pure function of props and state. It should "
						.. "never access something that requires stale data from the previous "
						.. "render, such as refs. Move this logic to componentDidMount and "
						.. "componentDidUpdate instead.",
					getComponentName(ownerFiber.type) or "A component"
				)
			end
			instance._warnedAboutRefsInRender = true
		end
	end

	local fiber: Fiber? = getInstance(component)
	if not fiber then
		return false
	else
		-- ROBLOX FIXME: remove any cast once Luau understands if-statement nil check
		local fiberNonNil: any = fiber
		return getNearestMountedFiber(fiberNonNil) == fiber
	end
end

local function assertIsMounted(fiber)
	invariant(
		getNearestMountedFiber(fiber) == fiber,
		"Unable to find node on an unmounted component."
	)
end

local function findCurrentFiberUsingSlowPath(fiber: Fiber): Fiber?
	local alternate = fiber.alternate
	if not alternate then
		-- If there is no alternate, then we only need to check if it is mounted.
		local nearestMounted = getNearestMountedFiber(fiber)
		invariant(nearestMounted ~= nil, "Unable to find node on an unmounted component.")
		if nearestMounted ~= fiber then
			return nil
		end
		return fiber
	end
	-- If we have two possible branches, we'll walk backwards up to the root
	-- to see what path the root points to. On the way we may hit one of the
	-- special cases and we'll deal with them.
	local a: Fiber = fiber
	local b: Fiber = alternate
	while true do
		local parentA = a.return_
		if parentA == nil then
			-- We're at the root.
			break
		end
		local parentB = parentA.alternate
		if parentB == nil then
			-- There is no alternate. This is an unusual case. Currently, it only
			-- happens when a Suspense component is hidden. An extra fragment fiber
			-- is inserted in between the Suspense fiber and its children. Skip
			-- over this extra fragment fiber and proceed to the next parent.
			local nextParent = parentA.return_
			if nextParent ~= nil then
				a = nextParent
				b = nextParent
				continue
			end
			-- If there's no parent, we're at the root.
			break
		end

		-- If both copies of the parent fiber point to the same child, we can
		-- assume that the child is current. This happens when we bailout on low
		-- priority: the bailed out fiber's child reuses the current child.
		if parentA.child == parentB.child then
			local child = parentA.child
			while child do
				if child == a then
					-- We've determined that A is the current branch.
					assertIsMounted(parentA)
					return fiber
				end
				if child == b then
					-- We've determined that B is the current branch.
					assertIsMounted(parentA)
					return alternate
				end
				child = child.sibling
			end
			-- We should never have an alternate for any mounting node. So the only
			-- way this could possibly happen is if this was unmounted, if at all.
			invariant(false, "Unable to find node on an unmounted component.")
		end

		if a.return_ ~= b.return_ then
			-- The return pointer of A and the return pointer of B point to different
			-- fibers. We assume that return pointers never criss-cross, so A must
			-- belong to the child set of A.return, and B must belong to the child
			-- set of B.return.
			a = parentA
			b = parentB
		else
			-- The return pointers point to the same fiber. We'll have to use the
			-- default, slow path: scan the child sets of each parent alternate to see
			-- which child belongs to which set.
			--
			-- Search parent A's child set
			local didFindChild = false
			local child = parentA.child
			while child do
				if child == a then
					didFindChild = true
					a = parentA
					b = parentB
					break
				end
				if child == b then
					didFindChild = true
					b = parentA
					a = parentB
					break
				end
				child = child.sibling
			end
			if not didFindChild then
				-- Search parent B's child set
				child = parentB.child
				while child do
					if child == a then
						didFindChild = true
						a = parentB
						b = parentA
						break
					end
					if child == b then
						didFindChild = true
						b = parentB
						a = parentA
						break
					end
					child = child.sibling
				end
				invariant(
					didFindChild,
					"Child was not found in either parent set. This indicates a bug "
						.. "in React related to the return pointer. Please file an issue."
				)
			end
		end

		invariant(
			a.alternate == b,
			"Return fibers should always be each others' alternates. "
				.. "This error is likely caused by a bug in React. Please file an issue."
		)
	end
	-- If the root is not a host container, we're in a disconnected tree. I.e.
	-- unmounted.
	invariant(a.tag == HostRoot, "Unable to find node on an unmounted component.")
	if a.stateNode.current == a then
		-- We've determined that A is the current branch.
		return fiber
	end
	-- Otherwise B has to be current branch.
	return alternate
end
exports.findCurrentFiberUsingSlowPath = findCurrentFiberUsingSlowPath

exports.findCurrentHostFiber = function(parent: Fiber): Fiber?
	local currentParent = findCurrentFiberUsingSlowPath(parent)
	if not currentParent then
		return nil
	end

	-- Next we'll drill down this component to find the first HostComponent/Text.
	-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
	local node: Fiber = currentParent :: Fiber
	while true do
		local child = node.child
		if node.tag == HostComponent or node.tag == HostText then
			return node
		elseif child then
			child.return_ = node
			node = child
			continue
		end
		if node == currentParent then
			return nil
		end
		local return_ = node.return_
		local sibling = node.sibling
		while not sibling do
			if not return_ or return_ == currentParent then
				return nil
			end
			-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
			node = return_ :: Fiber
		end
		-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
		(sibling :: Fiber).return_ = return_ :: Fiber
		node = sibling :: Fiber
	end
	-- Flow needs the return nil here, but ESLint complains about it.
	-- eslint-disable-next-line no-unreachable
	return nil
end

exports.findCurrentHostFiberWithNoPortals = function(parent: Fiber): Fiber?
	local currentParent = findCurrentFiberUsingSlowPath(parent)
	if not currentParent then
		return nil
	end

	-- Next we'll drill down this component to find the first HostComponent/Text.
	local node: Fiber = currentParent :: Fiber
	while true do
		local child = node.child
		if
			node.tag == HostComponent
			or node.tag == HostText
			or (enableFundamentalAPI and node.tag == FundamentalComponent)
		then
			return node
		elseif child and node.tag ~= HostPortal then
			child.return_ = node
			node = child
			continue
		end
		if node == currentParent then
			return nil
		end
		local return_ = node.return_
		local sibling = node.sibling
		while not sibling do
			if not return_ or return_ == currentParent then
				return nil
			end
			-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
			node = return_ :: Fiber
		end
		-- ROBLOX FIXME Luau: Luau doesn't narrow based on above branch
		(sibling :: Fiber).return_ = return_ :: Fiber
		node = sibling :: Fiber
	end
	-- Flow needs the return nil here, but ESLint complains about it.
	-- eslint-disable-next-line no-unreachable
	return nil
end

exports.isFiberSuspenseAndTimedOut = function(fiber: Fiber): boolean
	local memoizedState = fiber.memoizedState
	return fiber.tag == SuspenseComponent
		and memoizedState ~= nil
		and memoizedState.dehydrated == nil
end

exports.doesFiberContain = function(parentFiber: Fiber, childFiber: Fiber): boolean
	local node = childFiber
	local parentFiberAlternate = parentFiber.alternate
	while node ~= nil do
		if node == parentFiber or node == parentFiberAlternate then
			return true
		end
		-- ROBLOX FIXME Luau: Luau doesn't understand loop until not nil pattern
		node = node.return_ :: Fiber
	end
	return false
end

return exports
