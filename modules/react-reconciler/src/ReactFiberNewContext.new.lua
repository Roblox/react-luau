--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/1eaafc9ade46ba708b2361b324dd907d019e3939/packages/react-reconciler/src/ReactFiberNewContext.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Number = LuauPolyfill.Number
local Error = LuauPolyfill.Error

-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactTypes = require(Packages.Shared)
type ReactContext<T> = ReactTypes.ReactContext<T>
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type ContextDependency<T> = ReactInternalTypes.ContextDependency<T>

local ReactFiberStack = require(script.Parent["ReactFiberStack.new"])
type StackCursor<T> = ReactFiberStack.StackCursor<T>
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes
local ReactUpdateQueue = require(script.Parent["ReactUpdateQueue.new"])
type SharedQueue<T> = ReactUpdateQueue.SharedQueue<T>

local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
local isPrimaryRenderer = ReactFiberHostConfig.isPrimaryRenderer
local createCursor = ReactFiberStack.createCursor
local push = ReactFiberStack.push
local pop = ReactFiberStack.pop
local MAX_SIGNED_31_BIT_INT = require(script.Parent.MaxInts).MAX_SIGNED_31_BIT_INT
local ReactWorkTags = require(script.Parent.ReactWorkTags)
local ContextProvider = ReactWorkTags.ContextProvider
local ClassComponent = ReactWorkTags.ClassComponent
-- local DehydratedFragment = ReactWorkTags.DehydratedFragment
local NoLanes = ReactFiberLane.NoLanes
local NoTimestamp = ReactFiberLane.NoTimestamp
local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
local includesSomeLane = ReactFiberLane.includesSomeLane
local mergeLanes = ReactFiberLane.mergeLanes
local pickArbitraryLane = ReactFiberLane.pickArbitraryLane

local is = require(Packages.Shared).objectIs
local createUpdate = ReactUpdateQueue.createUpdate
local ForceUpdate = ReactUpdateQueue.ForceUpdate
-- deviation: passed in as an arg to eliminate cycle
-- local markWorkInProgressReceivedUpdate = require(script.Parent["ReactFiberBeginWork.new"]).markWorkInProgressReceivedUpdate
-- local enableSuspenseServerRenderer = require(Packages.Shared).ReactFeatureFlags.enableSuspenseServerRenderer

local exports = {}

local valueCursor: StackCursor<any> = createCursor(nil)

local rendererSigil
if _G.__DEV__ then
	-- Use this to detect multiple renderers using the same context
	rendererSigil = {}
end

local currentlyRenderingFiber: Fiber | nil = nil
local lastContextDependency: ContextDependency<any> | nil = nil
local lastContextWithAllBitsObserved: ReactContext<any> | nil = nil

local isDisallowedContextReadInDEV: boolean = false

exports.resetContextDependencies = function(): ()
	-- This is called right before React yields execution, to ensure `readContext`
	-- cannot be called outside the render phase.
	currentlyRenderingFiber = nil
	lastContextDependency = nil
	lastContextWithAllBitsObserved = nil
	if _G.__DEV__ then
		isDisallowedContextReadInDEV = false
	end
end

exports.enterDisallowedContextReadInDEV = function(): ()
	if _G.__DEV__ then
		isDisallowedContextReadInDEV = true
	end
end

exports.exitDisallowedContextReadInDEV = function(): ()
	if _G.__DEV__ then
		isDisallowedContextReadInDEV = false
	end
end

exports.pushProvider = function<T>(providerFiber: Fiber, nextValue: T): ()
	local context: ReactContext<T> = providerFiber.type._context

	if isPrimaryRenderer then
		push(valueCursor, context._currentValue, providerFiber)

		context._currentValue = nextValue
		if _G.__DEV__ then
			if
				context._currentRenderer ~= nil
				and context._currentRenderer ~= rendererSigil
			then
				console.error(
					"Detected multiple renderers concurrently rendering the "
						.. "same context provider. This is currently unsupported."
				)
			end
			context._currentRenderer = rendererSigil
		end
	else
		push(valueCursor, context._currentValue2, providerFiber)

		context._currentValue2 = nextValue
		if _G.__DEV__ then
			if
				context._currentRenderer2 ~= nil
				and context._currentRenderer2 ~= rendererSigil
			then
				console.error(
					"Detected multiple renderers concurrently rendering the "
						.. "same context provider. This is currently unsupported."
				)
			end
			context._currentRenderer2 = rendererSigil
		end
	end
end

exports.popProvider = function(providerFiber: Fiber)
	local currentValue = valueCursor.current

	pop(valueCursor, providerFiber)

	local context: ReactContext<any> = providerFiber.type._context
	if isPrimaryRenderer then
		context._currentValue = currentValue
	else
		context._currentValue2 = currentValue
	end
end

exports.calculateChangedBits =
	function<T>(context: ReactContext<T>, newValue: T, oldValue: T)
		if is(oldValue, newValue) then
			-- No change
			return 0
		else
			-- deviation: unravel ternary that's unsafe to translate
			local changedBits = MAX_SIGNED_31_BIT_INT
			if typeof(context._calculateChangedBits) == "function" then
				changedBits = context._calculateChangedBits(oldValue, newValue)
			end

			-- ROBLOX performance: eliminate nice-to-have compare in hot path that's removed in React 18
			-- if _G.__DEV__ then
			--   if bit32.band(changedBits, MAX_SIGNED_31_BIT_INT) ~= changedBits then
			--     console.error(
			--       "calculateChangedBits: Expected the return value to be a " ..
			--         "31-bit integer. Instead received: %s",
			--       changedBits
			--     )
			--   end
			-- end
			-- deviation: JS does a bitwise OR with 0 presumably to floor the value and
			-- coerce to an int; we just use math.floor
			return math.floor(changedBits)
		end
	end

exports.scheduleWorkOnParentPath = function(parent: Fiber | nil, renderLanes: Lanes)
	-- Update the child lanes of all the ancestors, including the alternates.
	local node = parent
	while node ~= nil do
		local alternate = node.alternate
		if not isSubsetOfLanes(node.childLanes, renderLanes) then
			node.childLanes = mergeLanes(node.childLanes, renderLanes)
			if alternate ~= nil then
				alternate.childLanes = mergeLanes(alternate.childLanes, renderLanes)
			end
		elseif
			alternate ~= nil and not isSubsetOfLanes(alternate.childLanes, renderLanes)
		then
			alternate.childLanes = mergeLanes(alternate.childLanes, renderLanes)
		else
			-- Neither alternate was updated, which means the rest of the
			-- ancestor path already has sufficient priority.
			break
		end
		node = node.return_
	end
end

exports.propagateContextChange = function<T>(
	workInProgress: Fiber,
	context: ReactContext<T>,
	changedBits: number,
	renderLanes: Lanes
): ()
	local fiber = workInProgress.child
	if fiber ~= nil then
		-- Set the return pointer of the child to the work-in-progress fiber.
		fiber.return_ = workInProgress
	end
	while fiber ~= nil do
		local nextFiber

		-- Visit this fiber.
		local list = fiber.dependencies
		if list ~= nil then
			nextFiber = fiber.child

			local dependency = list.firstContext
			while dependency ~= nil do
				-- Check if the context matches.
				if
					dependency.context == context
					-- ROBLOX performance: unstable observedBits is removed in React 18
					and bit32.band(dependency.observedBits, changedBits) ~= 0
				then
					-- Match! Schedule an update on this fiber.

					if fiber.tag == ClassComponent then
						-- Schedule a force update on the work-in-progress.
						local update =
							createUpdate(NoTimestamp, pickArbitraryLane(renderLanes))
						update.tag = ForceUpdate
						-- TODO: Because we don't have a work-in-progress, this will add the
						-- update to the current fiber, too, which means it will persist even if
						-- this render is thrown away. Since it's a race condition, not sure it's
						-- worth fixing.

						-- Inlined `enqueueUpdate` to remove interleaved update check
						local updateQueue = fiber.updateQueue
						if updateQueue == nil then
						-- Only occurs if the fiber has been unmounted.
						else
							local sharedQueue: SharedQueue<any> = (updateQueue :: any).shared
							local pending = sharedQueue.pending
							if pending == nil then
								-- This is the first update. Create a circular list.
								update.next = update
							else
								update.next = pending.next
								pending.next = update
							end
							sharedQueue.pending = update
						end
					end

					-- ROBLOX performance: inline mergeLanes(fiber.lanes, renderLanes)
					fiber.lanes = bit32.bor(fiber.lanes, renderLanes)
					local alternate = fiber.alternate
					if alternate ~= nil then
						-- ROBLOX performance: inline mergeLanes(alternate.lanes, renderLanes)
						alternate.lanes = bit32.bor(alternate.lanes, renderLanes)
					end
					exports.scheduleWorkOnParentPath(fiber.return_, renderLanes)

					-- Mark the updated lanes on the list, too.
					-- ROBLOX performance: inline mergeLanes(list.lanes, renderLanes)
					list.lanes = bit32.bor(list.lanes, renderLanes)

					-- Since we already found a match, we can stop traversing the
					-- dependency list.
					break
				end
				dependency = dependency.next
			end
		elseif fiber.tag == ContextProvider then
			-- Don't scan deeper if this is a matching provider
			if fiber.type == workInProgress.type then
				nextFiber = nil
			else
				nextFiber = fiber.child
			end
		-- ROBLOX performance: eliminate always-false compare in tab switching hot path
		-- elseif
		--   enableSuspenseServerRenderer and
		--   fiber.tag == DehydratedFragment
		-- then
		--   -- If a dehydrated suspense boundary is in this subtree, we don't know
		--   -- if it will have any context consumers in it. The best we can do is
		--   -- mark it as having updates.
		--   local parentSuspense = fiber.return_
		--   if parentSuspense == nil then
		--     error("We just came from a parent so we must have had a parent. This is a bug in React.")
		--   end
		--   parentSuspense.lanes = mergeLanes(parentSuspense.lanes, renderLanes)
		--   local alternate = parentSuspense.alternate
		--   if alternate ~= nil then
		--     alternate.lanes = mergeLanes(alternate.lanes, renderLanes)
		--   end
		--   -- This is intentionally passing this fiber as the parent
		--   -- because we want to schedule this fiber as having work
		--   -- on its children. We'll use the childLanes on
		--   -- this fiber to indicate that a context has changed.
		--   exports.scheduleWorkOnParentPath(parentSuspense, renderLanes)
		--   nextFiber = fiber.sibling
		else
			-- Traverse down.
			nextFiber = fiber.child
		end

		if nextFiber ~= nil then
			-- Set the return pointer of the child to the work-in-progress fiber.
			nextFiber.return_ = fiber
		else
			-- No child. Traverse to next sibling.
			nextFiber = fiber
			while nextFiber ~= nil do
				if nextFiber == workInProgress then
					-- We're back to the root of this subtree. Exit.
					nextFiber = nil
					break
				end
				local sibling = nextFiber.sibling
				if sibling ~= nil then
					-- Set the return pointer of the sibling to the work-in-progress fiber.
					sibling.return_ = nextFiber.return_
					nextFiber = sibling
					break
				end
				-- No more siblings. Traverse up.
				nextFiber = nextFiber.return_
			end
		end
		fiber = nextFiber
	end
end

-- deviation: third argument added to eliminate cycle
exports.prepareToReadContext = function(
	workInProgress: Fiber,
	renderLanes: Lanes,
	markWorkInProgressReceivedUpdate: () -> ()
): ()
	currentlyRenderingFiber = workInProgress
	lastContextDependency = nil
	lastContextWithAllBitsObserved = nil

	local dependencies = workInProgress.dependencies
	if dependencies ~= nil then
		local firstContext = dependencies.firstContext
		if firstContext ~= nil then
			if includesSomeLane(dependencies.lanes, renderLanes) then
				-- Context list has a pending update. Mark that this fiber performed work.
				markWorkInProgressReceivedUpdate()
			end
			-- Reset the work-in-progress list
			dependencies.firstContext = nil
		end
	end
end

exports.readContext =
	function<T>(context: ReactContext<T>, observedBits: nil | number | boolean): T
		if _G.__DEV__ then
			-- This warning would fire if you read context inside a Hook like useMemo.
			-- Unlike the class check below, it's not enforced in production for perf.
			if isDisallowedContextReadInDEV then
				console.error(
					"Context can only be read while React is rendering. "
						.. "In classes, you can read it in the render method or getDerivedStateFromProps. "
						.. "In function components, you can read it directly in the function body, but not "
						.. "inside Hooks like useReducer() or useMemo()."
				)
			end
		end

		if lastContextWithAllBitsObserved == context then
		-- Nothing to do. We already observe everything in this context.
		elseif observedBits == false or observedBits == 0 then
		-- Do not observe any updates.
		else
			local resolvedObservedBits -- Avoid deopting on observable arguments or heterogeneous types.
			if
				typeof(observedBits) ~= "number"
				or observedBits == Number.MAX_SAFE_INTEGER
			then
				-- Observe all updates.
				-- lastContextWithAllBitsObserved = ((context: any): ReactContext<mixed>)
				lastContextWithAllBitsObserved = context
				resolvedObservedBits = Number.MAX_SAFE_INTEGER
			else
				resolvedObservedBits = observedBits
			end

			local contextItem = {
				-- context: ((context: any): ReactContext<mixed>),
				context = context,
				observedBits = resolvedObservedBits,
				next = nil,
			}

			if lastContextDependency == nil then
				if currentlyRenderingFiber == nil then
					error(
						Error.new(
							"Context can only be read while React is rendering. "
								.. "In classes, you can read it in the render method or getDerivedStateFromProps. "
								.. "In function components, you can read it directly in the function body, but not "
								.. "inside Hooks like useReducer() or useMemo()."
						)
					)
				end

				-- This is the first dependency for this component. Create a new list.
				lastContextDependency = contextItem;
				(currentlyRenderingFiber :: Fiber).dependencies = {
					lanes = NoLanes,
					firstContext = contextItem,
					responders = nil,
				}
			else
				-- Append a new context item.
				(lastContextDependency :: any).next = contextItem
				lastContextDependency = contextItem
			end
		end
		return if isPrimaryRenderer then context._currentValue else context._currentValue2
	end

return exports
