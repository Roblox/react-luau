--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactFiberHydrationContext.new.js
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

-- FIXME (roblox): remove this when our unimplemented
local function unimplemented(message: string)
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
	print("UNIMPLEMENTED ERROR: " .. message)
	error("FIXME (roblox): " .. message .. " is unimplemented", 2)
end

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
type Instance = ReactFiberHostConfig.Instance
type TextInstance = ReactFiberHostConfig.TextInstance
type HydratableInstance = ReactFiberHostConfig.HydratableInstance
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance
type Container = ReactFiberHostConfig.Container
type HostContext = ReactFiberHostConfig.HostContext

local ReactFiberSuspenseComponent =
	require(script.Parent["ReactFiberSuspenseComponent.new"])
type SuspenseState = ReactFiberSuspenseComponent.SuspenseState

local ReactWorkTags = require(script.Parent.ReactWorkTags)
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostRoot = ReactWorkTags.HostRoot
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local Placement = ReactFiberFlags.Placement
local Hydrating = ReactFiberFlags.Hydrating
-- local Deletion = ReactFiberFlags.Deletion

local invariant = require(Packages.Shared).invariant

local ReactFiber = require(script.Parent["ReactFiber.new"])
-- local createFiberFromHostInstanceForDeletion = ReactFiber.createFiberFromHostInstanceForDeletion
local createFiberFromDehydratedFragment = ReactFiber.createFiberFromDehydratedFragment

local supportsHydration = ReactFiberHostConfig.supportsHydration
local getNextHydratableSibling = ReactFiberHostConfig.getNextHydratableSibling
local getFirstHydratableChild = ReactFiberHostConfig.getFirstHydratableChild
local canHydrateInstance = ReactFiberHostConfig.canHydrateInstance
local canHydrateTextInstance = ReactFiberHostConfig.canHydrateTextInstance
local canHydrateSuspenseInstance = ReactFiberHostConfig.canHydrateSuspenseInstance
local hydrateInstance = ReactFiberHostConfig.hydrateInstance
local hydrateTextInstance = ReactFiberHostConfig.hydrateTextInstance
local hydrateSuspenseInstance = ReactFiberHostConfig.hydrateSuspenseInstance
local getNextHydratableInstanceAfterSuspenseInstance =
	ReactFiberHostConfig.getNextHydratableInstanceAfterSuspenseInstance
local didNotMatchHydratedContainerTextInstance =
	ReactFiberHostConfig.didNotMatchHydratedContainerTextInstance
local didNotMatchHydratedTextInstance =
	ReactFiberHostConfig.didNotMatchHydratedTextInstance
local shouldSetTextContent = ReactFiberHostConfig.shouldSetTextContent

-- local {
--   didNotHydrateContainerInstance,
--   didNotHydrateInstance,
--   didNotFindHydratableContainerInstance,
--   didNotFindHydratableContainerTextInstance,
--   didNotFindHydratableContainerSuspenseInstance,
--   didNotFindHydratableInstance,
--   didNotFindHydratableTextInstance,
--   didNotFindHydratableSuspenseInstance,
-- } = require(Packages../ReactFiberHostConfig'
local enableSuspenseServerRenderer =
	require(Packages.Shared).ReactFeatureFlags.enableSuspenseServerRenderer
local OffscreenLane = require(script.Parent.ReactFiberLane).OffscreenLane

-- The deepest Fiber on the stack involved in a hydration context.
-- This may have been an insertion or a hydration.
local hydrationParentFiber: Fiber? = nil
local nextHydratableInstance: nil | HydratableInstance = nil
local isHydrating: boolean = false

function warnIfHydrating()
	if _G.__DEV__ then
		if isHydrating then
			console.error(
				"We should not be hydrating here. This is a bug in React. Please file a bug."
			)
		end
	end
end

function enterHydrationState(fiber: Fiber): boolean
	if not supportsHydration then
		return false
	end

	local parentInstance = fiber.stateNode.containerInfo
	nextHydratableInstance = getFirstHydratableChild(parentInstance)
	hydrationParentFiber = fiber
	isHydrating = true
	return true
end

function reenterHydrationStateFromDehydratedSuspenseInstance(
	fiber: Fiber,
	suspenseInstance: SuspenseInstance
): boolean
	if not supportsHydration then
		return false
	end

	nextHydratableInstance = getNextHydratableSibling(suspenseInstance)
	popToNextHostParent(fiber)
	isHydrating = true
	return true
end

function deleteHydratableInstance(returnFiber: Fiber?, instance: HydratableInstance)
	unimplemented("deleteHydratableInstance")
	-- if _G.__DEV__ then
	--   switch (returnFiber.tag)
	--     case HostRoot:
	--       didNotHydrateContainerInstance(
	--         returnFiber.stateNode.containerInfo,
	--         instance,
	--       )
	--       break
	--     case HostComponent:
	--       didNotHydrateInstance(
	--         returnFiber.type,
	--         returnFiber.memoizedProps,
	--         returnFiber.stateNode,
	--         instance,
	--       )
	--       break
	-- 		end
	-- 	end

	-- local childToDelete = createFiberFromHostInstanceForDeletion()
	-- childToDelete.stateNode = instance
	-- childToDelete.return = returnFiber

	-- local deletions = returnFiber.deletions
	-- if deletions == nil)
	--   returnFiber.deletions = [childToDelete]
	--   -- TODO (effects) Rename this to better reflect its new usage (e.g. ChildDeletions)
	--   returnFiber.flags |= Deletion
	-- } else {
	--   deletions.push(childToDelete)
	-- }
end

function insertNonHydratedInstance(returnFiber: Fiber?, fiber: Fiber)
	unimplemented("insertNonHydratedInstance")
	fiber.flags = bit32.bor(bit32.band(fiber.flags, bit32.bnot(Hydrating)), Placement)
	if _G.__DEV__ then
		-- switch (returnFiber.tag)
		--   case HostRoot: {
		--     local parentContainer = returnFiber.stateNode.containerInfo
		--     switch (fiber.tag)
		--       case HostComponent:
		--         local type = fiber.type
		--         local props = fiber.pendingProps
		--         didNotFindHydratableContainerInstance(parentContainer, type, props)
		--         break
		--       case HostText:
		--         local text = fiber.pendingProps
		--         didNotFindHydratableContainerTextInstance(parentContainer, text)
		--         break
		--       case SuspenseComponent:
		--         didNotFindHydratableContainerSuspenseInstance(parentContainer)
		--         break
		--     }
		--     break
		--   }
		--   case HostComponent: {
		--     local parentType = returnFiber.type
		--     local parentProps = returnFiber.memoizedProps
		--     local parentInstance = returnFiber.stateNode
		--     switch (fiber.tag)
		--       case HostComponent:
		--         local type = fiber.type
		--         local props = fiber.pendingProps
		--         didNotFindHydratableInstance(
		--           parentType,
		--           parentProps,
		--           parentInstance,
		--           type,
		--           props,
		--         )
		--         break
		--       case HostText:
		--         local text = fiber.pendingProps
		--         didNotFindHydratableTextInstance(
		--           parentType,
		--           parentProps,
		--           parentInstance,
		--           text,
		--         )
		--         break
		--       case SuspenseComponent:
		--         didNotFindHydratableSuspenseInstance(
		--           parentType,
		--           parentProps,
		--           parentInstance,
		--         )
		--         break
		--     }
		--     break
		--   }
		--   default:
		--     return
		-- end
	end
end

function tryHydrate(fiber, nextInstance)
	if fiber.tag == HostComponent then
		local type_ = fiber.type
		local props = fiber.pendingProps
		local instance = canHydrateInstance(nextInstance, type_, props)
		if instance ~= nil then
			fiber.stateNode = instance
			return true
		end
		return false
	elseif fiber.tag == HostText then
		local text = fiber.pendingProps
		local textInstance = canHydrateTextInstance(nextInstance, text)
		if textInstance ~= nil then
			fiber.stateNode = textInstance
			return true
		end
		return false
	elseif fiber.tag == SuspenseComponent then
		if enableSuspenseServerRenderer then
			local suspenseInstance: nil | SuspenseInstance =
				canHydrateSuspenseInstance(nextInstance)
			if suspenseInstance ~= nil then
				local suspenseState: SuspenseState = {
					dehydrated = suspenseInstance,
					retryLane = OffscreenLane,
				}
				fiber.memoizedState = suspenseState
				-- Store the dehydrated fragment as a child fiber.
				-- This simplifies the code for getHostSibling and deleting nodes,
				-- since it doesn't have to consider all Suspense boundaries and
				-- check if they're dehydrated ones or not.
				local dehydratedFragment =
					createFiberFromDehydratedFragment(suspenseInstance)
				dehydratedFragment.return_ = fiber
				fiber.child = dehydratedFragment
				return true
			end
		end
		return false
	else
		return false
	end
end

function tryToClaimNextHydratableInstance(fiber: Fiber)
	if not isHydrating then
		return
	end
	local nextInstance = nextHydratableInstance
	if not nextInstance then
		-- Nothing to hydrate. Make it an insertion.
		insertNonHydratedInstance(hydrationParentFiber, fiber)
		isHydrating = false
		hydrationParentFiber = fiber
		return
	end
	-- ROBLOX FIXME Luau: Luau doesn't narrow based on the guard above
	local firstAttemptedInstance = nextInstance :: HydratableInstance
	if not tryHydrate(fiber, nextInstance) then
		-- If we can't hydrate this instance let's try the next one.
		-- We use this as a heuristic. It's based on intuition and not data so it
		-- might be flawed or unnecessary.
		nextInstance = getNextHydratableSibling(firstAttemptedInstance)
		if not nextInstance or not tryHydrate(fiber, nextInstance) then
			-- Nothing to hydrate. Make it an insertion.
			insertNonHydratedInstance(hydrationParentFiber, fiber)
			isHydrating = false
			hydrationParentFiber = fiber
			return
		end
		-- We matched the next one, we'll now assume that the first one was
		-- superfluous and we'll delete it. Since we can't eagerly delete it
		-- we'll have to schedule a deletion. To do that, this node needs a dummy
		-- fiber associated with it.
		deleteHydratableInstance(hydrationParentFiber, firstAttemptedInstance)
	end
	hydrationParentFiber = fiber
	nextHydratableInstance = getFirstHydratableChild(nextInstance)
end

function prepareToHydrateHostInstance(
	fiber: Fiber,
	rootContainerInstance: Container,
	hostContext: HostContext
): boolean
	if not supportsHydration then
		invariant(
			false,
			"Expected prepareToHydrateHostInstance() to never be called. "
				.. "This error is likely caused by a bug in React. Please file an issue."
		)
	end

	local instance: Instance = fiber.stateNode
	local updatePayload = hydrateInstance(
		instance,
		fiber.type,
		fiber.memoizedProps,
		rootContainerInstance,
		hostContext,
		fiber
	)
	-- TODO: Type this specific to this type of component.
	fiber.updateQueue = updatePayload
	-- If the update payload indicates that there is a change or if there
	-- is a new ref we mark this as an update.
	if updatePayload ~= nil then
		return true
	end
	return false
end

function prepareToHydrateHostTextInstance(fiber: Fiber): boolean
	if not supportsHydration then
		invariant(
			false,
			"Expected prepareToHydrateHostTextInstance() to never be called. "
				.. "This error is likely caused by a bug in React. Please file an issue."
		)
	end

	local textInstance: TextInstance = fiber.stateNode
	local textContent: string = fiber.memoizedProps
	local shouldUpdate = hydrateTextInstance(textInstance, textContent, fiber)
	if _G.__DEV__ then
		if shouldUpdate then
			-- We assume that prepareToHydrateHostTextInstance is called in a context where the
			-- hydration parent is the parent host component of this host text.
			local returnFiber = hydrationParentFiber
			if returnFiber ~= nil then
				if returnFiber.tag == HostRoot then
					local parentContainer = returnFiber.stateNode.containerInfo
					didNotMatchHydratedContainerTextInstance(
						parentContainer,
						textInstance,
						textContent
					)
				elseif returnFiber.tag == HostComponent then
					local parentType = returnFiber.type
					local parentProps = returnFiber.memoizedProps
					local parentInstance = returnFiber.stateNode
					didNotMatchHydratedTextInstance(
						parentType,
						parentProps,
						parentInstance,
						textInstance,
						textContent
					)
				end
			end
		end
	end
	return shouldUpdate
end

function prepareToHydrateHostSuspenseInstance(fiber: Fiber)
	if not supportsHydration then
		invariant(
			false,
			"Expected prepareToHydrateHostSuspenseInstance() to never be called. "
				.. "This error is likely caused by a bug in React. Please file an issue."
		)
	end

	local suspenseState: SuspenseState = fiber.memoizedState
	local suspenseInstance: nil | SuspenseInstance
	if suspenseState ~= nil then
		suspenseInstance = suspenseState.dehydrated
	else
		suspenseInstance = nil
	end

	invariant(
		suspenseInstance,
		"Expected to have a hydrated suspense instance. "
			.. "This error is likely caused by a bug in React. Please file an issue."
	)
	hydrateSuspenseInstance(suspenseInstance, fiber)
end

function skipPastDehydratedSuspenseInstance(fiber: Fiber): nil | HydratableInstance
	if not supportsHydration then
		invariant(
			false,
			"Expected skipPastDehydratedSuspenseInstance() to never be called. "
				.. "This error is likely caused by a bug in React. Please file an issue."
		)
	end
	local suspenseState: SuspenseState = fiber.memoizedState
	local suspenseInstance: nil | SuspenseInstance
	if suspenseState ~= nil then
		suspenseInstance = suspenseState.dehydrated
	else
		suspenseInstance = nil
	end
	invariant(
		suspenseInstance,
		"Expected to have a hydrated suspense instance. "
			.. "This error is likely caused by a bug in React. Please file an issue."
	)
	return getNextHydratableInstanceAfterSuspenseInstance(suspenseInstance)
end

function popToNextHostParent(fiber: Fiber)
	local parent = fiber.return_
	while
		parent ~= nil
		and parent.tag ~= HostComponent
		and parent.tag ~= HostRoot
		and parent.tag ~= SuspenseComponent
	do
		parent = parent.return_
	end
	hydrationParentFiber = parent
end

function popHydrationState(fiber: Fiber): boolean
	if not supportsHydration then
		return false
	end
	if fiber ~= hydrationParentFiber then
		-- We're deeper than the current hydration context, inside an inserted
		-- tree.
		return false
	end
	if not isHydrating then
		-- If we're not currently hydrating but we're in a hydration context, then
		-- we were an insertion and now need to pop up reenter hydration of our
		-- siblings.
		popToNextHostParent(fiber)
		isHydrating = true
		return false
	end

	local type_ = fiber.type

	-- If we have any remaining hydratable nodes, we need to delete them now.
	-- We only do this deeper than head and body since they tend to have random
	-- other nodes in them. We also ignore components with pure text content in
	-- side of them.
	-- TODO: Better heuristic.
	if
		fiber.tag ~= HostComponent
		or (
			type_ ~= "head"
			and type_ ~= "body"
			and not shouldSetTextContent(type_, fiber.memoizedProps)
		)
	then
		local nextInstance = nextHydratableInstance
		while nextInstance do
			deleteHydratableInstance(fiber, nextInstance)
			nextInstance = getNextHydratableSibling(nextInstance)
		end
	end

	popToNextHostParent(fiber)
	if fiber.tag == SuspenseComponent then
		nextHydratableInstance = skipPastDehydratedSuspenseInstance(fiber)
	else
		if hydrationParentFiber then
			nextHydratableInstance = getNextHydratableSibling(fiber.stateNode)
		else
			nextHydratableInstance = nil
		end
	end
	return true
end

function resetHydrationState()
	if not supportsHydration then
		return
	end

	hydrationParentFiber = nil
	nextHydratableInstance = nil
	isHydrating = false
end

function getIsHydrating(): boolean
	return isHydrating
end

return {
	warnIfHydrating = warnIfHydrating,
	enterHydrationState = enterHydrationState,
	getIsHydrating = getIsHydrating,
	reenterHydrationStateFromDehydratedSuspenseInstance = reenterHydrationStateFromDehydratedSuspenseInstance,
	resetHydrationState = resetHydrationState,
	tryToClaimNextHydratableInstance = tryToClaimNextHydratableInstance,
	prepareToHydrateHostInstance = prepareToHydrateHostInstance,
	prepareToHydrateHostTextInstance = prepareToHydrateHostTextInstance,
	prepareToHydrateHostSuspenseInstance = prepareToHydrateHostSuspenseInstance,
	popHydrationState = popHydrationState,
}
