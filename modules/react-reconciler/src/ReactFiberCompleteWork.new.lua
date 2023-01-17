-- ROBLOX upstream: https://github.com/facebook/react/blob/87c023b1c1b00d6776b7031f6e105913ead355da/packages/react-reconciler/src/ReactFiberCompleteWork.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. tostring(message))
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local Packages = script.Parent.Parent

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes
type Lane = ReactFiberLane.Lane
local OffscreenLane = ReactFiberLane.OffscreenLane
-- local type {
--   ReactFundamentalComponentInstance,
--   ReactScopeInstance,
-- } = require(Packages.Shared).ReactTypes
-- local type {FiberRoot} = require(script.Parent.ReactInternalTypes)
local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
type Instance = ReactFiberHostConfig.Instance
type Type = ReactFiberHostConfig.Type
type Props = ReactFiberHostConfig.Props
type Container = ReactFiberHostConfig.Container
type ChildSet = ReactFiberHostConfig.ChildSet
-- local type {
--   SuspenseState,
--   SuspenseListRenderState,
-- } = require(script.Parent.ReactFiberSuspenseComponent.new)
local ReactFiberOffscreenComponent = require(script.Parent.ReactFiberOffscreenComponent)
type OffscreenState = ReactFiberOffscreenComponent.OffscreenState

local ReactMutableSource = require(script.Parent["ReactMutableSource.new"])
local resetMutableSourceWorkInProgressVersions =
	ReactMutableSource.resetWorkInProgressVersions

-- local {now} = require(script.Parent.SchedulerWithReactIntegration.new)

local ReactWorkTags = require(script.Parent.ReactWorkTags)
local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
local FunctionComponent = ReactWorkTags.FunctionComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ContextProvider = ReactWorkTags.ContextProvider
local ContextConsumer = ReactWorkTags.ContextConsumer
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local Mode = ReactWorkTags.Mode
local Profiler = ReactWorkTags.Profiler
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local LazyComponent = ReactWorkTags.LazyComponent
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local ScopeComponent = ReactWorkTags.ScopeComponent
local Block = ReactWorkTags.Block
local OffscreenComponent = ReactWorkTags.OffscreenComponent
local LegacyHiddenComponent = ReactWorkTags.LegacyHiddenComponent
local ReactFiberSuspenseComponent =
	require(script.Parent["ReactFiberSuspenseComponent.new"])
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState
type SuspenseListRenderState = ReactFiberSuspenseComponent.SuspenseState

local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
local NoMode = ReactTypeOfMode.NoMode
local ConcurrentMode = ReactTypeOfMode.ConcurrentMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local ProfileMode = ReactTypeOfMode.ProfileMode

local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local Ref = ReactFiberFlags.Ref
local Update = ReactFiberFlags.Update
local Callback = ReactFiberFlags.Callback
local Passive = ReactFiberFlags.Passive
local Deletion = ReactFiberFlags.Deletion
local NoFlags = ReactFiberFlags.NoFlags
local DidCapture = ReactFiberFlags.DidCapture
local Snapshot = ReactFiberFlags.Snapshot
local MutationMask = ReactFiberFlags.MutationMask
local LayoutMask = ReactFiberFlags.LayoutMask
local PassiveMask = ReactFiberFlags.PassiveMask
local StaticMask = ReactFiberFlags.StaticMask
local PerformedWork = ReactFiberFlags.PerformedWork

local invariant = require(Packages.Shared).invariant

local createInstance = ReactFiberHostConfig.createInstance
local createTextInstance = ReactFiberHostConfig.createTextInstance
local appendInitialChild = ReactFiberHostConfig.appendInitialChild
local finalizeInitialChildren = ReactFiberHostConfig.finalizeInitialChildren
local prepareUpdate = ReactFiberHostConfig.prepareUpdate
local supportsMutation = ReactFiberHostConfig.supportsMutation
local supportsPersistence = ReactFiberHostConfig.supportsPersistence
-- local cloneInstance = ReactFiberHostConfig.cloneInstance
-- local cloneHiddenInstance = ReactFiberHostConfig.cloneHiddenInstance
-- local cloneHiddenTextInstance = ReactFiberHostConfig.cloneHiddenTextInstance
local createContainerChildSet = ReactFiberHostConfig.createContainerChildSet
-- local appendChildToContainerChildSet = ReactFiberHostConfig.appendChildToContainerChildSet
local finalizeContainerChildren = ReactFiberHostConfig.finalizeContainerChildren
-- local getFundamentalComponentInstance = ReactFiberHostConfig.getFundamentalComponentInstance
-- local mountFundamentalComponent = ReactFiberHostConfig.mountFundamentalComponent
-- local cloneFundamentalInstance = ReactFiberHostConfig.cloneFundamentalInstance
-- local shouldUpdateFundamentalComponent = ReactFiberHostConfig.shouldUpdateFundamentalComponent
local preparePortalMount = ReactFiberHostConfig.preparePortalMount
-- local prepareScopeUpdate = ReactFiberHostConfig.prepareScopeUpdate
local ReactFiberHostContext = require(script.Parent["ReactFiberHostContext.new"])
local getRootHostContainer = ReactFiberHostContext.getRootHostContainer
local popHostContext = ReactFiberHostContext.popHostContext
local getHostContext = ReactFiberHostContext.getHostContext
local popHostContainer = ReactFiberHostContext.popHostContainer

local ReactFiberSuspenseContext = require(script.Parent["ReactFiberSuspenseContext.new"])
local popSuspenseContext = ReactFiberSuspenseContext.popSuspenseContext
local suspenseStackCursor = ReactFiberSuspenseContext.suspenseStackCursor
local InvisibleParentSuspenseContext =
	ReactFiberSuspenseContext.InvisibleParentSuspenseContext
local hasSuspenseContext = ReactFiberSuspenseContext.hasSuspenseContext
type SuspenseContext = ReactFiberSuspenseContext.SuspenseContext
-- local pushSuspenseContext = ReactFiberSuspenseContext.pushSuspenseContext
-- local setShallowSuspenseContext = ReactFiberSuspenseContext.setShallowSuspenseContext
-- local ForceSuspenseFallback = ReactFiberSuspenseContext.ForceSuspenseFallback
-- local setDefaultShallowSuspenseContext = ReactFiberSuspenseContext.setDefaultShallowSuspenseContext

-- local {findFirstSuspended} = require(script.Parent.ReactFiberSuspenseComponent.new)
local ReactFiberContext = require(script.Parent["ReactFiberContext.new"])
local isLegacyContextProvider = ReactFiberContext.isContextProvider
local popLegacyContext = ReactFiberContext.popContext
local popTopLevelLegacyContextObject = ReactFiberContext.popTopLevelContextObject
local popProvider = require(script.Parent["ReactFiberNewContext.new"]).popProvider

local ReactFiberHydrationContext =
	require(script.Parent["ReactFiberHydrationContext.new"])
local prepareToHydrateHostSuspenseInstance =
	ReactFiberHydrationContext.prepareToHydrateHostSuspenseInstance
local popHydrationState = ReactFiberHydrationContext.popHydrationState
local resetHydrationState = ReactFiberHydrationContext.resetHydrationState
-- local getIsHydrating = ReactFiberHydrationContext.getIsHydrating
local prepareToHydrateHostInstance =
	ReactFiberHydrationContext.prepareToHydrateHostInstance
local prepareToHydrateHostTextInstance =
	ReactFiberHydrationContext.prepareToHydrateHostTextInstance
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableSchedulerTracing = ReactFeatureFlags.enableSchedulerTracing
local enableSuspenseCallback = ReactFeatureFlags.enableSuspenseCallback
local enableSuspenseServerRenderer = ReactFeatureFlags.enableSuspenseServerRenderer
local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer

local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"]) :: any

local popRenderLanes = ReactFiberWorkLoop.popRenderLanes
-- ROBLOX deviation: this is a live value in WorkLoop's module state, so it must be accessed directly and not 'cached'
-- local subtreeRenderLanes = ReactFiberWorkLoop.subtreeRenderLanes
local markSpawnedWork = ReactFiberWorkLoop.markSpawnedWork
local renderDidSuspend = ReactFiberWorkLoop.renderDidSuspend
local renderDidSuspendDelayIfPossible = ReactFiberWorkLoop.renderDidSuspendDelayIfPossible
-- local renderHasNotSuspendedYet = ReactFiberWorkLoop.renderHasNotSuspendedYet
-- local getRenderTargetTime = ReactFiberWorkLoop.getRenderTargetTime

-- local {createFundamentalStateInstance} = require(script.Parent.ReactFiberFundamental.new)

-- local OffscreenLane = ReactFiberLane.OffscreenLane
-- local SomeRetryLane = ReactFiberLane.SomeRetryLane
local NoLanes = ReactFiberLane.NoLanes
local includesSomeLane = ReactFiberLane.includesSomeLane
local mergeLanes = ReactFiberLane.mergeLanes
-- local {resetChildFibers} = require(script.Parent.ReactChildFiber.new)
-- local {createScopeInstance} = require(script.Parent.ReactFiberScope.new)
local ReactProfilerTimer = require(script.Parent["ReactProfilerTimer.new"])
local transferActualDuration = ReactProfilerTimer.transferActualDuration

local function markUpdate(workInProgress: Fiber)
	-- Tag the fiber with an update effect. This turns a Placement into
	-- a PlacementAndUpdate.
	workInProgress.flags = bit32.bor(workInProgress.flags, Update)
end

local function markRef(workInProgress: Fiber)
	workInProgress.flags = bit32.bor(workInProgress.flags, Ref)
end

-- ROBLOX FIXME: type refinement
-- local function hadNoMutationsEffects(current: nil | Fiber, completedWork: Fiber)
local function hadNoMutationsEffects(current, completedWork: Fiber)
	local didBailout = current ~= nil and current.child == completedWork.child
	if didBailout then
		return true
	end

	local child = completedWork.child
	while child ~= nil do
		if bit32.band(child.flags, MutationMask) ~= NoFlags then
			return false
		end
		if bit32.band(child.subtreeFlags, MutationMask) ~= NoFlags then
			return false
		end
		child = child.sibling
	end
	return true
end

local appendAllChildren
local updateHostContainer
local updateHostComponent
local updateHostText
if supportsMutation then
	-- Mutation mode

	appendAllChildren = function(
		parent: Instance,
		workInProgress: Fiber,
		needsVisibilityToggle: boolean,
		isHidden: boolean
	)
		-- We only have the top Fiber that was created but we need recurse down its
		-- children to find all the terminal nodes.
		local node = workInProgress.child
		while node ~= nil do
			if node.tag == HostComponent or node.tag == HostText then
				appendInitialChild(parent, node.stateNode)
			elseif enableFundamentalAPI and node.tag == FundamentalComponent then
				appendInitialChild(parent, node.stateNode.instance)
			elseif node.tag == HostPortal then
			-- If we have a portal child, then we don't want to traverse
			-- down its children. Instead, we'll get insertions from each child in
			-- the portal directly.
			elseif node.child ~= nil then
				node.child.return_ = node
				node = node.child
				continue
			end
			if node == workInProgress then
				return
			end
			while node.sibling == nil do
				if node.return_ == nil or node.return_ == workInProgress then
					return
				end
				node = node.return_
			end
			-- ROBLOX FIXME Luau: Luau doesn't understand loop predicates above results in node.sibling ~= nil
			(node.sibling :: Fiber).return_ = node.return_
			node = node.sibling
		end
	end

	updateHostContainer = function(current: nil | Fiber, workInProgress: Fiber)
		-- Noop
	end
	function updateHostComponent(
		current: Fiber,
		workInProgress: Fiber,
		type: Type,
		newProps: Props,
		rootContainerInstance: Container
	)
		-- If we have an alternate, that means this is an update and we need to
		-- schedule a side-effect to do the updates.
		local oldProps = current.memoizedProps
		if oldProps == newProps then
			-- In mutation mode, this is sufficient for a bailout because
			-- we won't touch this node even if children changed.
			return
		end

		-- If we get updated because one of our children updated, we don't
		-- have newProps so we'll have to reuse them.
		-- TODO: Split the update API as separate for the props vs. children.
		-- Even better would be if children weren't special cased at all tho.
		local instance: Instance = workInProgress.stateNode
		local currentHostContext = getHostContext()
		-- TODO: Experiencing an error where oldProps is nil. Suggests a host
		-- component is hitting the resume path. Figure out why. Possibly
		-- related to `hidden`.
		local updatePayload = prepareUpdate(
			instance,
			type,
			oldProps,
			newProps,
			rootContainerInstance,
			currentHostContext
		)
		-- TODO: Type this specific to this type of component.
		workInProgress.updateQueue = updatePayload
		-- If the update payload indicates that there is a change or if there
		-- is a new ref we mark this as an update. All the work is done in commitWork.
		if updatePayload then
			markUpdate(workInProgress)
		end
	end
	function updateHostText(
		current: Fiber,
		workInProgress: Fiber,
		oldText: string,
		newText: string
	)
		-- If the text differs, mark it as an update. All the work in done in commitWork.
		if oldText ~= newText then
			markUpdate(workInProgress)
		end
	end
elseif supportsPersistence then
	-- Persistent host tree mode
	appendAllChildren = function(
		parent: Instance,
		workInProgress: Fiber,
		needsVisibilityToggle: boolean,
		isHidden: boolean
	)
		unimplemented("appendAllChildren")
		--     -- We only have the top Fiber that was created but we need recurse down its
		--     -- children to find all the terminal nodes.
		--     local node = workInProgress.child
		--     while (node ~= nil)
		--       -- eslint-disable-next-line no-labels
		--       branches: if node.tag == HostComponent)
		--         local instance = node.stateNode
		--         if needsVisibilityToggle and isHidden)
		--           -- This child is inside a timed out tree. Hide it.
		--           local props = node.memoizedProps
		--           local type = node.type
		--           instance = cloneHiddenInstance(instance, type, props, node)
		--         end
		--         appendInitialChild(parent, instance)
		--       } else if node.tag == HostText)
		--         local instance = node.stateNode
		--         if needsVisibilityToggle and isHidden)
		--           -- This child is inside a timed out tree. Hide it.
		--           local text = node.memoizedProps
		--           instance = cloneHiddenTextInstance(instance, text, node)
		--         end
		--         appendInitialChild(parent, instance)
		--       } else if enableFundamentalAPI and node.tag == FundamentalComponent)
		--         local instance = node.stateNode.instance
		--         if needsVisibilityToggle and isHidden)
		--           -- This child is inside a timed out tree. Hide it.
		--           local props = node.memoizedProps
		--           local type = node.type
		--           instance = cloneHiddenInstance(instance, type, props, node)
		--         end
		--         appendInitialChild(parent, instance)
		--       } else if node.tag == HostPortal)
		--         -- If we have a portal child, then we don't want to traverse
		--         -- down its children. Instead, we'll get insertions from each child in
		--         -- the portal directly.
		--       } else if node.tag == SuspenseComponent)
		--         if (node.flags & Update) ~= NoFlags)
		--           -- Need to toggle the visibility of the primary children.
		--           local newIsHidden = node.memoizedState ~= nil
		--           if newIsHidden)
		--             local primaryChildParent = node.child
		--             if primaryChildParent ~= nil)
		--               if primaryChildParent.child ~= nil)
		--                 primaryChildParent.child.return = primaryChildParent
		--                 appendAllChildren(
		--                   parent,
		--                   primaryChildParent,
		--                   true,
		--                   newIsHidden,
		--                 )
		--               end
		--               local fallbackChildParent = primaryChildParent.sibling
		--               if fallbackChildParent ~= nil)
		--                 fallbackChildParent.return = node
		--                 node = fallbackChildParent
		--                 continue
		--               end
		--             end
		--           end
		--         end
		--         if node.child ~= nil)
		--           -- Continue traversing like normal
		--           node.child.return = node
		--           node = node.child
		--           continue
		--         end
		--       } else if node.child ~= nil)
		--         node.child.return = node
		--         node = node.child
		--         continue
		--       end
		--       -- $FlowFixMe This is correct but Flow is confused by the labeled break.
		--       node = (node: Fiber)
		--       if node == workInProgress)
		--         return
		--       end
		--       while (node.sibling == nil)
		--         if node.return == nil or node.return == workInProgress)
		--           return
		--         end
		--         node = node.return
		--       end
		--       node.sibling.return = node.return
		--       node = node.sibling
		--     end
	end

	-- An unfortunate fork of appendAllChildren because we have two different parent types.
	local function appendAllChildrenToContainer(
		containerChildSet: ChildSet,
		workInProgress: Fiber,
		needsVisibilityToggle: boolean,
		isHidden: boolean
	)
		unimplemented("appendAllChildrenToContainer")
		-- -- We only have the top Fiber that was created but we need recurse down its
		-- -- children to find all the terminal nodes.
		-- local node = workInProgress.child
		-- while node ~= nil do
		--   -- eslint-disable-next-line no-labels
		--   if node.tag == HostComponent then
		--     local instance = node.stateNode
		--     if needsVisibilityToggle and isHidden then
		--       -- This child is inside a timed out tree. Hide it.
		--       local props = node.memoizedProps
		--       local type = node.type
		--       instance = cloneHiddenInstance(instance, type, props, node)
		--     end
		--     appendChildToContainerChildSet(containerChildSet, instance)
		--   elseif node.tag == HostText then
		--     local instance = node.stateNode
		--     if needsVisibilityToggle and isHidden then
		--       -- This child is inside a timed out tree. Hide it.
		--       local text = node.memoizedProps
		--       instance = cloneHiddenTextInstance(instance, text, node)
		--     end
		--     appendChildToContainerChildSet(containerChildSet, instance)
		--   elseif enableFundamentalAPI and node.tag == FundamentalComponent then
		--     local instance = node.stateNode.instance
		--     if needsVisibilityToggle and isHidden then
		--       -- This child is inside a timed out tree. Hide it.
		--       local props = node.memoizedProps
		--       local type = node.type
		--       instance = cloneHiddenInstance(instance, type, props, node)
		--     end
		--     appendChildToContainerChildSet(containerChildSet, instance)
		--   elseif node.tag == HostPortal then
		--     -- If we have a portal child, then we don't want to traverse
		--     -- down its children. Instead, we'll get insertions from each child in
		--     -- the portal directly.
		--   elseif node.tag == SuspenseComponent then
		--     if bit32.band(node.flags, Update) ~= NoFlags then
		--       -- Need to toggle the visibility of the primary children.
		--       local newIsHidden = node.memoizedState ~= nil
		--       if newIsHidden then
		--         local primaryChildParent = node.child
		--         if primaryChildParent ~= nil then
		--           if primaryChildParent.child ~= nil then
		--             primaryChildParent.child.return_ = primaryChildParent
		--             appendAllChildrenToContainer(
		--               containerChildSet,
		--               primaryChildParent,
		--               true,
		--               newIsHidden
		--             )
		--           end
		--           local fallbackChildParent = primaryChildParent.sibling
		--           if fallbackChildParent ~= nil then
		--             fallbackChildParent.return_ = node
		--             node = fallbackChildParent
		--             continue
		--           end
		--         end
		--       end
		--     end
		--     if node.child ~= nil then
		--       -- Continue traversing like normal
		--       node.child.return_ = node
		--       node = node.child
		--       continue
		--     end
		--   elseif node.child ~= nil then
		--     node.child.return_ = node
		--     node = node.child
		--     continue
		--   end
		--   -- $FlowFixMe This is correct but Flow is confused by the labeled break.
		--   -- node = (node: Fiber)
		--   if node == workInProgress then
		--     return
		--   end
		--   while node.sibling == nil do
		--     if node.return_ == nil or node.return_ == workInProgress then
		--       return
		--     end
		--     node = node.return_
		--   end
		--   node.sibling.return_ = node.return_
		--   node = node.sibling
		-- end
	end

	function updateHostContainer(current: nil | Fiber, workInProgress: Fiber)
		local portalOrRoot: {
			containerInfo: Container,
			pendingChildren: ChildSet,
			-- ...
			[any]: any,
		} =
			workInProgress.stateNode
		local childrenUnchanged = hadNoMutationsEffects(current, workInProgress)
		if childrenUnchanged then
		-- No changes, just reuse the existing instance.
		else
			local container = portalOrRoot.containerInfo
			local newChildSet = createContainerChildSet(container)
			-- If children might have changed, we have to add them all to the set.
			appendAllChildrenToContainer(newChildSet, workInProgress, false, false)
			portalOrRoot.pendingChildren = newChildSet
			-- Schedule an update on the container to swap out the container.
			markUpdate(workInProgress)
			finalizeContainerChildren(container, newChildSet)
		end
	end
--   updateHostComponent = function(
--     current: Fiber,
--     workInProgress: Fiber,
--     type: Type,
--     newProps: Props,
--     rootContainerInstance: Container,
--   )
--     local currentInstance = current.stateNode
--     local oldProps = current.memoizedProps
--     -- If there are no effects associated with this node, then none of our children had any updates.
--     -- This guarantees that we can reuse all of them.
--     local childrenUnchanged = workInProgress.firstEffect == nil
--     if childrenUnchanged and oldProps == newProps)
--       -- No changes, just reuse the existing instance.
--       -- Note that this might release a previous clone.
--       workInProgress.stateNode = currentInstance
--       return
--     end
--     local recyclableInstance: Instance = workInProgress.stateNode
--     local currentHostContext = getHostContext()
--     local updatePayload = nil
--     if oldProps ~= newProps)
--       updatePayload = prepareUpdate(
--         recyclableInstance,
--         type,
--         oldProps,
--         newProps,
--         rootContainerInstance,
--         currentHostContext,
--       )
--     end
--     if childrenUnchanged and updatePayload == nil)
--       -- No changes, just reuse the existing instance.
--       -- Note that this might release a previous clone.
--       workInProgress.stateNode = currentInstance
--       return
--     end
--     local newInstance = cloneInstance(
--       currentInstance,
--       updatePayload,
--       type,
--       oldProps,
--       newProps,
--       workInProgress,
--       childrenUnchanged,
--       recyclableInstance,
--     )
--     if
--       finalizeInitialChildren(
--         newInstance,
--         type,
--         newProps,
--         rootContainerInstance,
--         currentHostContext,
--       )
--     )
--       markUpdate(workInProgress)
--     end
--     workInProgress.stateNode = newInstance
--     if childrenUnchanged)
--       -- If there are no other effects in this tree, we need to flag this node as having one.
--       -- Even though we're not going to use it for anything.
--       -- Otherwise parents won't know that there are new children to propagate upwards.
--       markUpdate(workInProgress)
--     else
--       -- If children might have changed, we have to add them all to the set.
--       appendAllChildren(newInstance, workInProgress, false, false)
--     end
--   end
--   updateHostText = function(
--     current: Fiber,
--     workInProgress: Fiber,
--     oldText: string,
--     newText: string,
--   )
--     if oldText ~= newText)
--       -- If the text content differs, we'll create a new text instance for it.
--       local rootContainerInstance = getRootHostContainer()
--       local currentHostContext = getHostContext()
--       workInProgress.stateNode = createTextInstance(
--         newText,
--         rootContainerInstance,
--         currentHostContext,
--         workInProgress,
--       )
--       -- We'll have to mark it as having an effect, even though we won't use the effect for anything.
--       -- This lets the parents know that at least one of their children has changed.
--       markUpdate(workInProgress)
--     else
--       workInProgress.stateNode = current.stateNode
--     end
--   end
else
	-- No host operations
	updateHostContainer = function(current: nil | Fiber, workInProgress: Fiber)
		-- Noop
	end
	--   updateHostComponent = function(
	--     current: Fiber,
	--     workInProgress: Fiber,
	--     type: Type,
	--     newProps: Props,
	--     rootContainerInstance: Container,
	--   )
	--     -- Noop
	--   end
	--   updateHostText = function(
	--     current: Fiber,
	--     workInProgress: Fiber,
	--     oldText: string,
	--     newText: string,
	--   )
	--     -- Noop
	--   end
	-- end

	-- function cutOffTailIfNeeded(
	--   renderState: SuspenseListRenderState,
	--   hasRenderedATailFallback: boolean,
	-- )
	--   if getIsHydrating())
	--     -- If we're hydrating, we should consume as many items as we can
	--     -- so we don't leave any behind.
	--     return
	--   end
	--   switch (renderState.tailMode)
	--     case 'hidden': {
	--       -- Any insertions at the end of the tail list after this point
	--       -- should be invisible. If there are already mounted boundaries
	--       -- anything before them are not considered for collapsing.
	--       -- Therefore we need to go through the whole tail to find if
	--       -- there are any.
	--       local tailNode = renderState.tail
	--       local lastTailNode = nil
	--       while (tailNode ~= nil)
	--         if tailNode.alternate ~= nil)
	--           lastTailNode = tailNode
	--         end
	--         tailNode = tailNode.sibling
	--       end
	--       -- Next we're simply going to delete all insertions after the
	--       -- last rendered item.
	--       if lastTailNode == nil)
	--         -- All remaining items in the tail are insertions.
	--         renderState.tail = nil
	--       else
	--         -- Detach the insertion after the last node that was already
	--         -- inserted.
	--         lastTailNode.sibling = nil
	--       end
	--       break
	--     end
	--     case 'collapsed': {
	--       -- Any insertions at the end of the tail list after this point
	--       -- should be invisible. If there are already mounted boundaries
	--       -- anything before them are not considered for collapsing.
	--       -- Therefore we need to go through the whole tail to find if
	--       -- there are any.
	--       local tailNode = renderState.tail
	--       local lastTailNode = nil
	--       while (tailNode ~= nil)
	--         if tailNode.alternate ~= nil)
	--           lastTailNode = tailNode
	--         end
	--         tailNode = tailNode.sibling
	--       end
	--       -- Next we're simply going to delete all insertions after the
	--       -- last rendered item.
	--       if lastTailNode == nil)
	--         -- All remaining items in the tail are insertions.
	--         if !hasRenderedATailFallback and renderState.tail ~= nil)
	--           -- We suspended during the head. We want to show at least one
	--           -- row at the tail. So we'll keep on and cut off the rest.
	--           renderState.tail.sibling = nil
	--         else
	--           renderState.tail = nil
	--         end
	--       else
	--         -- Detach the insertion after the last node that was already
	--         -- inserted.
	--         lastTailNode.sibling = nil
	--       end
	--       break
	--     end
	--   end
end

local function bubbleProperties(completedWork: Fiber)
	local didBailout = completedWork.alternate ~= nil
		and (completedWork.alternate :: Fiber).child == completedWork.child

	local newChildLanes = NoLanes
	local subtreeFlags = NoFlags

	if not didBailout then
		-- Bubble up the earliest expiration time.
		if
			enableProfilerTimer
			and bit32.band(completedWork.mode, ProfileMode) ~= NoMode
		then
			-- In profiling mode, resetChildExpirationTime is also used to reset
			-- profiler durations.
			local actualDuration = completedWork.actualDuration
			local treeBaseDuration = completedWork.selfBaseDuration

			local child = completedWork.child
			while child ~= nil do
				newChildLanes =
					mergeLanes(newChildLanes, mergeLanes(child.lanes, child.childLanes))

				subtreeFlags = bit32.bor(subtreeFlags, child.subtreeFlags)
				subtreeFlags = bit32.bor(subtreeFlags, child.flags)

				-- When a fiber is cloned, its actualDuration is reset to 0. This value will
				-- only be updated if work is done on the fiber (i.e. it doesn't bailout).
				-- When work is done, it should bubble to the parent's actualDuration. If
				-- the fiber has not been cloned though, (meaning no work was done), then
				-- this value will reflect the amount of time spent working on a previous
				-- render. In that case it should not bubble. We determine whether it was
				-- cloned by comparing the child pointer.
				actualDuration += child.actualDuration

				treeBaseDuration += child.treeBaseDuration
				child = child.sibling
			end

			completedWork.actualDuration = actualDuration
			completedWork.treeBaseDuration = treeBaseDuration
		else
			local child = completedWork.child
			while child ~= nil do
				-- ROBLOX performance: inline mergeLanes
				-- newChildLanes = mergeLanes(
				--   newChildLanes,
				--   mergeLanes(child.lanes, child.childLanes)
				-- )
				newChildLanes =
					bit32.bor(newChildLanes, bit32.bor(child.lanes, child.childLanes))

				subtreeFlags = bit32.bor(subtreeFlags, child.subtreeFlags)
				subtreeFlags = bit32.bor(subtreeFlags, child.flags)

				-- ROBLOX note: this was missed in the "new" version of the file in React 17, but is fixed in React 18
				-- Update the return pointer so the tree is consistent. This is a code
				-- smell because it assumes the commit phase is never concurrent with
				-- the render phase. Will address during refactor to alternate model.
				child.return_ = completedWork

				child = child.sibling
			end
		end

		completedWork.subtreeFlags = bit32.bor(completedWork.subtreeFlags, subtreeFlags)
	else
		-- Bubble up the earliest expiration time.
		if
			enableProfilerTimer
			and bit32.band(completedWork.mode, ProfileMode) ~= NoMode
		then
			-- In profiling mode, resetChildExpirationTime is also used to reset
			-- profiler durations.
			local treeBaseDuration = completedWork.selfBaseDuration

			local child = completedWork.child
			while child ~= nil do
				newChildLanes =
					mergeLanes(newChildLanes, mergeLanes(child.lanes, child.childLanes))

				-- "Static" flags share the lifetime of the fiber/hook they belong to,
				-- so we should bubble those up even during a bailout. All the other
				-- flags have a lifetime only of a single render + commit, so we should
				-- ignore them.
				subtreeFlags =
					bit32.bor(subtreeFlags, bit32.band(child.subtreeFlags, StaticMask))
				subtreeFlags =
					bit32.bor(subtreeFlags, bit32.band(child.flags, StaticMask))

				treeBaseDuration += child.treeBaseDuration
				child = child.sibling
			end

			completedWork.treeBaseDuration = treeBaseDuration
		else
			local child = completedWork.child
			while child ~= nil do
				-- ROBLOX performance: inline mergeLanes
				-- newChildLanes = mergeLanes(
				--   newChildLanes,
				--   mergeLanes(child.lanes, child.childLanes)
				-- )
				newChildLanes =
					bit32.bor(newChildLanes, bit32.bor(child.lanes, child.childLanes))

				-- "Static" flags share the lifetime of the fiber/hook they belong to,
				-- so we should bubble those up even during a bailout. All the other
				-- flags have a lifetime only of a single render + commit, so we should
				-- ignore them.
				subtreeFlags =
					bit32.bor(subtreeFlags, bit32.band(child.subtreeFlags, StaticMask))
				subtreeFlags =
					bit32.bor(subtreeFlags, bit32.band(child.flags, StaticMask))

				-- ROBLOX note: this was missed in the "new" version of the file in React 17, but is fixed in React 18
				-- Update the return pointer so the tree is consistent. This is a code
				-- smell because it assumes the commit phase is never concurrent with
				-- the render phase. Will address during refactor to alternate model.
				child.return_ = completedWork

				child = child.sibling
			end
		end

		completedWork.subtreeFlags = bit32.bor(completedWork.subtreeFlags, subtreeFlags)
	end

	completedWork.childLanes = newChildLanes

	return didBailout
end

-- FIXME (roblox): type refinement
-- local function completeWork(
--   current: Fiber | nil,
--   workInProgress: Fiber,
--   renderLanes: Lanes
-- ): Fiber | nil
local function completeWork(
	current,
	workInProgress: Fiber,
	renderLanes: Lanes
): Fiber | nil
	local newProps = workInProgress.pendingProps

	if
		workInProgress.tag == IndeterminateComponent
		or workInProgress.tag == LazyComponent
		or workInProgress.tag == SimpleMemoComponent
		or workInProgress.tag == FunctionComponent
		or workInProgress.tag == ForwardRef
		or workInProgress.tag == Fragment
		or workInProgress.tag == Mode
		or workInProgress.tag == ContextConsumer
		or workInProgress.tag == MemoComponent
	then
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == ClassComponent then
		local Component = workInProgress.type
		if isLegacyContextProvider(Component) then
			popLegacyContext(workInProgress)
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == HostRoot then
		popHostContainer(workInProgress)
		popTopLevelLegacyContextObject(workInProgress)
		resetMutableSourceWorkInProgressVersions()
		-- ROBLOX FIXME: type coercion
		-- local fiberRoot = (workInProgress.stateNode: FiberRoot)
		local fiberRoot = workInProgress.stateNode
		if fiberRoot.pendingContext then
			fiberRoot.context = fiberRoot.pendingContext
			fiberRoot.pendingContext = nil
		end
		if current == nil or current.child == nil then
			-- If we hydrated, pop so that we can delete any remaining children
			-- that weren't hydrated.
			local wasHydrated = popHydrationState(workInProgress)
			if wasHydrated then
				-- If we hydrated, then we'll need to schedule an update for
				-- the commit side-effects on the root.
				markUpdate(workInProgress)
			elseif not fiberRoot.hydrate then
				-- Schedule an effect to clear this container at the start of the next commit.
				-- This handles the case of React rendering into a container with previous children.
				-- It's also safe to do for updates too, because current.child would only be nil
				-- if the previous render was nil (so the the container would already be empty).
				workInProgress.flags = bit32.bor(workInProgress.flags, Snapshot)
			end
		end
		updateHostContainer(current, workInProgress)
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == HostComponent then
		popHostContext(workInProgress)
		local rootContainerInstance = getRootHostContainer()
		local type = workInProgress.type
		if current ~= nil and workInProgress.stateNode ~= nil then
			updateHostComponent(
				current,
				workInProgress,
				type,
				newProps,
				rootContainerInstance
			)

			if current.ref ~= workInProgress.ref then
				markRef(workInProgress)
			end
		else
			if not newProps then
				invariant(
					workInProgress.stateNode ~= nil,
					"We must have new props for new mounts. This error is likely "
						.. "caused by a bug in React. Please file an issue."
				)
				-- This can happen when we abort work.
				bubbleProperties(workInProgress)
				return nil
			end

			local currentHostContext = getHostContext()
			-- TODO: Move createInstance to beginWork and keep it on a context
			-- "stack" as the parent. Then append children as we go in beginWork
			-- or completeWork depending on whether we want to add them top->down or
			-- bottom->up. Top->down is faster in IE11.
			local wasHydrated = popHydrationState(workInProgress)
			if wasHydrated then
				-- TODO: Move this and createInstance step into the beginPhase
				-- to consolidate.
				if
					prepareToHydrateHostInstance(
						workInProgress,
						rootContainerInstance,
						currentHostContext
					)
				then
					-- If changes to the hydrated node need to be applied at the
					-- commit-phase we mark this as such.
					markUpdate(workInProgress)
				end
			else
				local instance = createInstance(
					type,
					newProps,
					rootContainerInstance,
					currentHostContext,
					workInProgress
				)

				appendAllChildren(instance, workInProgress, false, false)

				workInProgress.stateNode = instance

				-- Certain renderers require commit-time effects for initial mount.
				-- (eg DOM renderer supports auto-focus for certain elements).
				-- Make sure such renderers get scheduled for later work.
				if
					finalizeInitialChildren(
						instance,
						type,
						newProps,
						rootContainerInstance,
						currentHostContext
					)
				then
					markUpdate(workInProgress)
				end
			end

			if workInProgress.ref ~= nil then
				-- If there is a ref on a host node we need to schedule a callback
				markRef(workInProgress)
			end
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == HostText then
		local newText = newProps
		if current and workInProgress.stateNode ~= nil then
			local oldText = current.memoizedProps
			-- If we have an alternate, that means this is an update and we need
			-- to schedule a side-effect to do the updates.
			updateHostText(current, workInProgress, oldText, newText)
		else
			if typeof(newText) ~= "string" then
				invariant(
					workInProgress.stateNode ~= nil,
					"We must have new props for new mounts. This error is likely "
						.. "caused by a bug in React. Please file an issue."
				)
				-- This can happen when we abort work.
			end
			local rootContainerInstance = getRootHostContainer()
			local currentHostContext = getHostContext()
			local wasHydrated = popHydrationState(workInProgress)
			if wasHydrated then
				if prepareToHydrateHostTextInstance(workInProgress) then
					markUpdate(workInProgress)
				end
			else
				workInProgress.stateNode = createTextInstance(
					newText,
					rootContainerInstance,
					currentHostContext,
					workInProgress
				)
			end
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == Profiler then
		local didBailout = bubbleProperties(workInProgress)
		if not didBailout then
			-- Use subtreeFlags to determine which commit callbacks should fire.
			-- TODO: Move this logic to the commit phase, since we already check if
			-- a fiber's subtree contains effects. Refactor the commit phase's
			-- depth-first traversal so that we can put work tag-specific logic
			-- before or after committing a subtree's effects.
			local OnRenderFlag = Update
			local OnCommitFlag = Callback
			local OnPostCommitFlag = Passive
			local subtreeFlags = workInProgress.subtreeFlags
			local flags = workInProgress.flags
			local newFlags = flags

			-- Call onRender any time this fiber or its subtree are worked on.
			if
				bit32.band(flags, PerformedWork) ~= NoFlags
				or bit32.band(subtreeFlags, PerformedWork) ~= NoFlags
			then
				newFlags = bit32.bor(newFlags, OnRenderFlag)
			end

			-- Call onCommit only if the subtree contains layout work, or if it
			-- contains deletions, since those might result in unmount work, which
			-- we include in the same measure.
			-- TODO: Can optimize by using a static flag to track whether a tree
			-- contains layout effects, like we do for passive effects.
			if
				bit32.band(flags, bit32.bor(LayoutMask, Deletion)) ~= NoFlags
				or bit32.band(subtreeFlags, bit32.bor(LayoutMask, Deletion))
					~= NoFlags
			then
				newFlags = bit32.bor(newFlags, OnCommitFlag)
			end

			-- Call onPostCommit only if the subtree contains passive work.
			-- Don't have to check for deletions, because Deletion is already
			-- a passive flag.
			if
				bit32.band(flags, PassiveMask) ~= NoFlags
				or bit32.band(subtreeFlags, PassiveMask) ~= NoFlags
			then
				newFlags = bit32.bor(newFlags, OnPostCommitFlag)
			end
			workInProgress.flags = newFlags
		else
			-- This fiber and its subtree bailed out, so don't fire any callbacks.
		end

		return nil
	elseif workInProgress.tag == SuspenseComponent then
		popSuspenseContext(workInProgress)
		local nextState: nil | SuspenseState = workInProgress.memoizedState

		if enableSuspenseServerRenderer then
			-- ROBLOX FIXME: remove :: recast once Luau understands if statement nil check
			if nextState ~= nil and (nextState :: SuspenseState).dehydrated ~= nil then
				if current == nil then
					local wasHydrated = popHydrationState(workInProgress)
					invariant(
						wasHydrated,
						"A dehydrated suspense component was completed without a hydrated node. "
							.. "This is probably a bug in React."
					)
					prepareToHydrateHostSuspenseInstance(workInProgress)
					if enableSchedulerTracing then
						markSpawnedWork(OffscreenLane)
					end
					bubbleProperties(workInProgress)
					if enableProfilerTimer then
						if bit32.band(workInProgress.mode, ProfileMode) ~= NoMode then
							local isTimedOutSuspense = nextState ~= nil
							if isTimedOutSuspense then
								-- Don't count time spent in a timed out Suspense subtree as part of the base duration.
								local primaryChildFragment = workInProgress.child
								if primaryChildFragment ~= nil then
									-- $FlowFixMe Flow doens't support type casting in combiation with the -= operator
									workInProgress.treeBaseDuration = (
										primaryChildFragment.treeBaseDuration :: any
									) :: number
								end
							end
						end
					end
					return nil
				else
					-- We should never have been in a hydration state if we didn't have a current.
					-- However, in some of those paths, we might have reentered a hydration state
					-- and then we might be inside a hydration state. In that case, we'll need to exit out of it.
					resetHydrationState()
					if bit32.band(workInProgress.flags, DidCapture) == NoFlags then
						-- This boundary did not suspend so it's now hydrated and unsuspended.
						workInProgress.memoizedState = nil
					end
					-- If nothing suspended, we need to schedule an effect to mark this boundary
					-- as having hydrated so events know that they're free to be invoked.
					-- It's also a signal to replay events and the suspense callback.
					-- If something suspended, schedule an effect to attach retry listeners.
					-- So we might as well always mark this.
					workInProgress.flags = bit32.bor(workInProgress.flags, Update)
					bubbleProperties(workInProgress)
					if enableProfilerTimer then
						if bit32.band(workInProgress.mode, ProfileMode) ~= NoMode then
							local isTimedOutSuspense = nextState ~= nil
							if isTimedOutSuspense then
								-- Don't count time spent in a timed out Suspense subtree as part of the base duration.
								local primaryChildFragment = workInProgress.child
								if primaryChildFragment ~= nil then
									-- $FlowFixMe Flow doens't support type casting in combiation with the -= operator
									-- ROBLOX deviation: remove recast to silence analyze
									workInProgress.treeBaseDuration -= primaryChildFragment.treeBaseDuration
								end
							end
						end
					end
					return nil
				end
			end
		end

		if bit32.band(workInProgress.flags, DidCapture) ~= NoFlags then
			-- Something suspended. Re-render with the fallback children.
			workInProgress.lanes = renderLanes
			-- Do not reset the effect list.
			if
				enableProfilerTimer
				and bit32.band(workInProgress.mode, ProfileMode) ~= NoMode
			then
				transferActualDuration(workInProgress)
			end
			-- Don't bubble properties in this case.
			return workInProgress
		end

		local nextDidTimeout = nextState ~= nil
		local prevDidTimeout = false
		if current == nil then
			if workInProgress.memoizedProps.fallback ~= nil then
				popHydrationState(workInProgress)
			end
		else
			local prevState: nil | SuspenseState = current.memoizedState
			prevDidTimeout = prevState ~= nil
		end

		if nextDidTimeout and not prevDidTimeout then
			-- If this subtreee is running in blocking mode we can suspend,
			-- otherwise we won't suspend.
			-- TODO: This will still suspend a synchronous tree if anything
			-- in the concurrent tree already suspended during this render.
			-- This is a known bug.
			if bit32.band(workInProgress.mode, BlockingMode) ~= NoMode then
				-- TODO: Move this back to throwException because this is too late
				-- if this is a large tree which is common for initial loads. We
				-- don't know if we should restart a render or not until we get
				-- this marker, and this is too late.
				-- If this render already had a ping or lower pri updates,
				-- and this is the first time we know we're going to suspend we
				-- should be able to immediately restart from within throwException.
				local hasInvisibleChildContext = current == nil
					and workInProgress.memoizedProps.unstable_avoidThisFallback
						~= true
				if
					hasInvisibleChildContext
					or hasSuspenseContext(
						suspenseStackCursor.current,
						InvisibleParentSuspenseContext :: SuspenseContext
					)
				then
					-- If this was in an invisible tree or a new render, then showing
					-- this boundary is ok.
					renderDidSuspend()
				else
					-- Otherwise, we're going to have to hide content so we should
					-- suspend for longer if possible.
					renderDidSuspendDelayIfPossible()
				end
			end
		end

		if supportsPersistence then
			-- TODO: Only schedule updates if not prevDidTimeout.
			if nextDidTimeout then
				-- If this boundary just timed out, schedule an effect to attach a
				-- retry listener to the promise. This flag is also used to hide the
				-- primary children.
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		if supportsMutation then
			-- TODO: Only schedule updates if these values are non equal, i.e. it changed.
			if nextDidTimeout or prevDidTimeout then
				-- If this boundary just timed out, schedule an effect to attach a
				-- retry listener to the promise. This flag is also used to hide the
				-- primary children. In mutation mode, we also need the flag to
				-- *unhide* children that were previously hidden, so check if this
				-- is currently timed out, too.
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end
		if
			enableSuspenseCallback
			and workInProgress.updateQueue ~= nil
			and workInProgress.memoizedProps.suspenseCallback ~= nil
		then
			-- Always notify the callback
			workInProgress.flags = bit32.bor(workInProgress.flags, Update)
		end
		bubbleProperties(workInProgress)
		if enableProfilerTimer then
			if bit32.band(workInProgress.mode, ProfileMode) ~= NoMode then
				if nextDidTimeout then
					-- Don't count time spent in a timed out Suspense subtree as part of the base duration.
					local primaryChildFragment = workInProgress.child
					if primaryChildFragment ~= nil then
						-- $FlowFixMe Flow doens't support type casting in combiation with the -= operator
						-- ROBLOX deviation: remove recast to silence analyze
						workInProgress.treeBaseDuration -= primaryChildFragment.treeBaseDuration
					end
				end
			end
		end
		return nil
	elseif workInProgress.tag == HostPortal then
		popHostContainer(workInProgress)
		updateHostContainer(current, workInProgress)
		if current == nil then
			preparePortalMount(workInProgress.stateNode.containerInfo)
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == ContextProvider then
		-- Pop provider fiber
		popProvider(workInProgress)
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == IncompleteClassComponent then
		-- Same as class component case. I put it down here so that the tags are
		-- sequential to ensure this switch is compiled to a jump table.
		local Component = workInProgress.type
		if isLegacyContextProvider(Component) then
			popLegacyContext(workInProgress)
		end
		bubbleProperties(workInProgress)
		return nil
	elseif workInProgress.tag == SuspenseListComponent then
		unimplemented("SuspenseListComponent")
	-- popSuspenseContext(workInProgress)

	-- local renderState: nil | SuspenseListRenderState =
	--   workInProgress.memoizedState

	-- if renderState == nil)
	--   -- We're running in the default, "independent" mode.
	--   -- We don't do anything in this mode.
	--   bubbleProperties(workInProgress)
	--   return nil
	-- end

	-- local didSuspendAlready = (workInProgress.flags & DidCapture) ~= NoFlags

	-- local renderedTail = renderState.rendering
	-- if renderedTail == nil)
	--   -- We just rendered the head.
	--   if !didSuspendAlready)
	--     -- This is the first pass. We need to figure out if anything is still
	--     -- suspended in the rendered set.

	--     -- If new content unsuspended, but there's still some content that
	--     -- didn't. Then we need to do a second pass that forces everything
	--     -- to keep showing their fallbacks.

	--     -- We might be suspended if something in this render pass suspended, or
	--     -- something in the previous committed pass suspended. Otherwise,
	--     -- there's no chance so we can skip the expensive call to
	--     -- findFirstSuspended.
	--     local cannotBeSuspended =
	--       renderHasNotSuspendedYet() and
	--       (current == nil or (current.flags & DidCapture) == NoFlags)
	--     if !cannotBeSuspended)
	--       local row = workInProgress.child
	--       while (row ~= nil)
	--         local suspended = findFirstSuspended(row)
	--         if suspended ~= nil)
	--           didSuspendAlready = true
	--           workInProgress.flags |= DidCapture
	--           cutOffTailIfNeeded(renderState, false)

	--           -- If this is a newly suspended tree, it might not get committed as
	--           -- part of the second pass. In that case nothing will subscribe to
	--           -- its thennables. Instead, we'll transfer its thennables to the
	--           -- SuspenseList so that it can retry if they resolve.
	--           -- There might be multiple of these in the list but since we're
	--           -- going to wait for all of them anyway, it doesn't really matter
	--           -- which ones gets to ping. In theory we could get clever and keep
	--           -- track of how many dependencies remain but it gets tricky because
	--           -- in the meantime, we can add/remove/change items and dependencies.
	--           -- We might bail out of the loop before finding any but that
	--           -- doesn't matter since that means that the other boundaries that
	--           -- we did find already has their listeners attached.
	--           local newThennables = suspended.updateQueue
	--           if newThennables ~= nil)
	--             workInProgress.updateQueue = newThennables
	--             workInProgress.flags |= Update
	--           end

	--           -- Rerender the whole list, but this time, we'll force fallbacks
	--           -- to stay in place.
	--           -- Reset the child fibers to their original state.
	--           workInProgress.subtreeFlags = NoFlags
	--           resetChildFibers(workInProgress, renderLanes)

	--           -- Set up the Suspense Context to force suspense and immediately
	--           -- rerender the children.
	--           pushSuspenseContext(
	--             workInProgress,
	--             setShallowSuspenseContext(
	--               suspenseStackCursor.current,
	--               ForceSuspenseFallback,
	--             ),
	--           )
	--           -- Don't bubble properties in this case.
	--           return workInProgress.child
	--         end
	--         row = row.sibling
	--       end
	--     end

	--     if renderState.tail ~= nil and now() > getRenderTargetTime())
	--       -- We have already passed our CPU deadline but we still have rows
	--       -- left in the tail. We'll just give up further attempts to render
	--       -- the main content and only render fallbacks.
	--       workInProgress.flags |= DidCapture
	--       didSuspendAlready = true

	--       cutOffTailIfNeeded(renderState, false)

	--       -- Since nothing actually suspended, there will nothing to ping this
	--       -- to get it started back up to attempt the next item. While in terms
	--       -- of priority this work has the same priority as this current render,
	--       -- it's not part of the same transition once the transition has
	--       -- committed. If it's sync, we still want to yield so that it can be
	--       -- painted. Conceptually, this is really the same as pinging.
	--       -- We can use any RetryLane even if it's the one currently rendering
	--       -- since we're leaving it behind on this node.
	--       workInProgress.lanes = SomeRetryLane
	--       if enableSchedulerTracing)
	--         markSpawnedWork(SomeRetryLane)
	--       end
	--     end
	--   else
	--     cutOffTailIfNeeded(renderState, false)
	--   end
	--   -- Next we're going to render the tail.
	-- else
	--   -- Append the rendered row to the child list.
	--   if !didSuspendAlready)
	--     local suspended = findFirstSuspended(renderedTail)
	--     if suspended ~= nil)
	--       workInProgress.flags |= DidCapture
	--       didSuspendAlready = true

	--       -- Ensure we transfer the update queue to the parent so that it doesn't
	--       -- get lost if this row ends up dropped during a second pass.
	--       local newThennables = suspended.updateQueue
	--       if newThennables ~= nil)
	--         workInProgress.updateQueue = newThennables
	--         workInProgress.flags |= Update
	--       end

	--       cutOffTailIfNeeded(renderState, true)
	--       -- This might have been modified.
	--       if
	--         renderState.tail == nil and
	--         renderState.tailMode == 'hidden' and
	--         !renderedTail.alternate and
	--         !getIsHydrating() -- We don't cut it if we're hydrating.
	--       )
	--         -- We're done.
	--         bubbleProperties(workInProgress)
	--         return nil
	--       end
	--     } else if
	--       -- The time it took to render last row is greater than the remaining
	--       -- time we have to render. So rendering one more row would likely
	--       -- exceed it.
	--       now() * 2 - renderState.renderingStartTime >
	--         getRenderTargetTime() and
	--       renderLanes ~= OffscreenLane
	--     )
	--       -- We have now passed our CPU deadline and we'll just give up further
	--       -- attempts to render the main content and only render fallbacks.
	--       -- The assumption is that this is usually faster.
	--       workInProgress.flags |= DidCapture
	--       didSuspendAlready = true

	--       cutOffTailIfNeeded(renderState, false)

	--       -- Since nothing actually suspended, there will nothing to ping this
	--       -- to get it started back up to attempt the next item. If we can show
	--       -- them, then they really have the same priority as this render.
	--       -- So we'll pick it back up the very next render pass once we've had
	--       -- an opportunity to yield for paint.
	--       workInProgress.lanes = SomeRetryLane
	--       if enableSchedulerTracing)
	--         markSpawnedWork(SomeRetryLane)
	--       end
	--     end
	--   end
	--   if renderState.isBackwards)
	--     -- The effect list of the backwards tail will have been added
	--     -- to the end. This breaks the guarantee that life-cycles fire in
	--     -- sibling order but that isn't a strong guarantee promised by React.
	--     -- Especially since these might also just pop in during future commits.
	--     -- Append to the beginning of the list.
	--     renderedTail.sibling = workInProgress.child
	--     workInProgress.child = renderedTail
	--   else
	--     local previousSibling = renderState.last
	--     if previousSibling ~= nil)
	--       previousSibling.sibling = renderedTail
	--     else
	--       workInProgress.child = renderedTail
	--     end
	--     renderState.last = renderedTail
	--   end
	-- end

	-- if renderState.tail ~= nil)
	--   -- We still have tail rows to render.
	--   -- Pop a row.
	--   local next = renderState.tail
	--   renderState.rendering = next
	--   renderState.tail = next.sibling
	--   renderState.renderingStartTime = now()
	--   next.sibling = nil

	--   -- Restore the context.
	--   -- TODO: We can probably just avoid popping it instead and only
	--   -- setting it the first time we go from not suspended to suspended.
	--   local suspenseContext = suspenseStackCursor.current
	--   if didSuspendAlready)
	--     suspenseContext = setShallowSuspenseContext(
	--       suspenseContext,
	--       ForceSuspenseFallback,
	--     )
	--   else
	--     suspenseContext = setDefaultShallowSuspenseContext(suspenseContext)
	--   end
	--   pushSuspenseContext(workInProgress, suspenseContext)
	--   -- Do a pass over the next row.
	--   -- Don't bubble properties in this case.
	--   return next
	-- end
	-- bubbleProperties(workInProgress)
	-- return nil
	-- end
	elseif workInProgress.tag == FundamentalComponent then
		unimplemented("FundamentalComponent")
	--   if enableFundamentalAPI)
	--   local fundamentalImpl = workInProgress.type.impl
	--   local fundamentalInstance: ReactFundamentalComponentInstance<
	--     any,
	--     any,
	--   > | nil = workInProgress.stateNode

	--   if fundamentalInstance == nil)
	--     local getInitialState = fundamentalImpl.getInitialState
	--     local fundamentalState
	--     if getInitialState ~= undefined)
	--       fundamentalState = getInitialState(newProps)
	--     end
	--     fundamentalInstance = workInProgress.stateNode = createFundamentalStateInstance(
	--       workInProgress,
	--       newProps,
	--       fundamentalImpl,
	--       fundamentalState or {},
	--     )
	--     local instance = ((getFundamentalComponentInstance(
	--       fundamentalInstance,
	--     ): any): Instance)
	--     fundamentalInstance.instance = instance
	--     if fundamentalImpl.reconcileChildren == false)
	--       bubbleProperties(workInProgress)
	--       return nil
	--     end
	--     appendAllChildren(instance, workInProgress, false, false)
	--     mountFundamentalComponent(fundamentalInstance)
	--   else
	--     -- We fire update in commit phase
	--     local prevProps = fundamentalInstance.props
	--     fundamentalInstance.prevProps = prevProps
	--     fundamentalInstance.props = newProps
	--     fundamentalInstance.currentFiber = workInProgress
	--     if supportsPersistence)
	--       local instance = cloneFundamentalInstance(fundamentalInstance)
	--       fundamentalInstance.instance = instance
	--       appendAllChildren(instance, workInProgress, false, false)
	--     end
	--     local shouldUpdate = shouldUpdateFundamentalComponent(
	--       fundamentalInstance,
	--     )
	--     if shouldUpdate)
	--       markUpdate(workInProgress)
	--     end
	--   end
	--   bubbleProperties(workInProgress)
	--   return nil
	-- end
	elseif workInProgress.tag == ScopeComponent then
		unimplemented("ScopeComponent")
	-- if enableScopeAPI)
	--   if current == nil)
	--     local scopeInstance: ReactScopeInstance = createScopeInstance()
	--     workInProgress.stateNode = scopeInstance
	--     prepareScopeUpdate(scopeInstance, workInProgress)
	--     if workInProgress.ref ~= nil)
	--       markRef(workInProgress)
	--       markUpdate(workInProgress)
	--     end
	--   else
	--     if workInProgress.ref ~= nil)
	--       markUpdate(workInProgress)
	--     end
	--     if current.ref ~= workInProgress.ref)
	--       markRef(workInProgress)
	--     end
	--   end
	--   bubbleProperties(workInProgress)
	--   return nil
	-- end
	elseif workInProgress.tag == Block then
		unimplemented("Block")
	-- if enableBlocksAPI)
	--   bubbleProperties(workInProgress)
	--   return nil
	-- end
	elseif
		workInProgress.tag == OffscreenComponent
		or workInProgress.tag == LegacyHiddenComponent
	then
		popRenderLanes(workInProgress)
		local nextState: OffscreenState | nil = workInProgress.memoizedState
		local nextIsHidden = nextState ~= nil

		if current ~= nil then
			local prevState: OffscreenState | nil = current.memoizedState

			local prevIsHidden = prevState ~= nil
			if
				prevIsHidden ~= nextIsHidden
				and newProps.mode ~= "unstable-defer-without-hiding"
			then
				workInProgress.flags = bit32.bor(workInProgress.flags, Update)
			end
		end

		-- Don't bubble properties for hidden children.
		if
			not nextIsHidden
			or includesSomeLane(
				ReactFiberWorkLoop.subtreeRenderLanes,
				OffscreenLane :: Lane
			)
			or bit32.band(workInProgress.mode, ConcurrentMode) == NoMode
		then
			bubbleProperties(workInProgress)
		end

		return nil
	end
	invariant(
		false,
		"Unknown unit of work tag (%s). This error is likely caused by a bug in "
			.. "React. Please file an issue.",
		tostring(workInProgress.tag)
	)
	return nil
end

return {
	completeWork = completeWork,
}
