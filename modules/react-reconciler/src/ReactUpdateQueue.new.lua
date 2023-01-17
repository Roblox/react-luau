--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactUpdateQueue.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- UpdateQueue is a linked list of prioritized updates.
--
-- Like fibers, update queues come in pairs: a current queue, which represents
-- the visible state of the screen, and a work-in-progress queue, which can be
-- mutated and processed asynchronously before it is committed — a form of
-- double buffering. If a work-in-progress render is discarded before finishing,
-- we create a new work-in-progress by cloning the current queue.
--
-- Both queues share a persistent, singly-linked list structure. To schedule an
-- update, we append it to the end of both queues. Each queue maintains a
-- pointer to first update in the persistent list that hasn't been processed.
-- The work-in-progress pointer always has a position equal to or greater than
-- the current queue, since we always work on that one. The current queue's
-- pointer is only updated during the commit phase, when we swap in the
-- work-in-progress.
--
-- For example:
--
--   Current pointer:           A - B - C - D - E - F
--   Work-in-progress pointer:              D - E - F
--                                          ^
--                                          The work-in-progress queue has
--                                          processed more updates than current.
--
-- The reason we append to both queues is because otherwise we might drop
-- updates without ever processing them. For example, if we only add updates to
-- the work-in-progress queue, some updates could be lost whenever a work-in
-- -progress render restarts by cloning from current. Similarly, if we only add
-- updates to the current queue, the updates will be lost whenever an already
-- in-progress queue commits and swaps with the current queue. However, by
-- adding to both queues, we guarantee that the update will be part of the next
-- work-in-progress. (And because the work-in-progress queue becomes the
-- current queue once it commits, there's no danger of applying the same
-- update twice.)
--
-- Prioritization
-- --------------
--
-- Updates are not sorted by priority, but by insertion; new updates are always
-- appended to the end of the list.
--
-- The priority is still important, though. When processing the update queue
-- during the render phase, only the updates with sufficient priority are
-- included in the result. If we skip an update because it has insufficient
-- priority, it remains in the queue to be processed later, during a lower
-- priority render. Crucially, all updates subsequent to a skipped update also
-- remain in the queue *regardless of their priority*. That means high priority
-- updates are sometimes processed twice, at two separate priorities. We also
-- keep track of a base state, that represents the state before the first
-- update in the queue is applied.
--
-- For example:
--
--   Given a base state of '', and the following queue of updates
--
--     A1 - B2 - C1 - D2
--
--   where the number indicates the priority, and the update is applied to the
--   previous state by appending a letter, React will process these updates as
--   two separate renders, one per distinct priority level:
--
--   First render, at priority 1:
--     Base state: ''
--     Updates: [A1, C1]
--     Result state: 'AC'
--
--   Second render, at priority 2:
--     Base state: 'A'            <-  The base state does not include C1,
--                                    because B2 was skipped.
--     Updates: [B2, C1, D2]      <-  C1 was rebased on top of B2
--     Result state: 'ABCD'
--
-- Because we process updates in insertion order, and rebase high priority
-- updates when preceding updates are skipped, the final result is deterministic
-- regardless of priority. Intermediate state may vary according to system
-- resources, but the final state is always the same.

local __DEV__ = _G.__DEV__
local __YOLO__ = _G.__YOLO__

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object

-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type Lane = ReactInternalTypes.Lane
type Lanes = ReactInternalTypes.Lanes

local ReactFiberLane = require(script.Parent.ReactFiberLane)
local NoLane = ReactFiberLane.NoLane
local NoLanes = ReactFiberLane.NoLanes
local isSubsetOfLanes = ReactFiberLane.isSubsetOfLanes
local mergeLanes = ReactFiberLane.mergeLanes

-- ROBLOX deviation: lazy instantiate to avoid circular require
local ReactFiberNewContext --= require(script.Parent["ReactFiberNewContext.new"])
-- local enterDisallowedContextReadInDEV = ReactFiberNewContext.enterDisallowedContextReadInDEV
-- local exitDisallowedContextReadInDEV = ReactFiberNewContext.exitDisallowedContextReadInDEV
local function enterDisallowedContextReadInDEV()
	if not ReactFiberNewContext then
		ReactFiberNewContext = require(script.Parent["ReactFiberNewContext.new"]) :: any
	end
	ReactFiberNewContext.enterDisallowedContextReadInDEV()
end
local function exitDisallowedContextReadInDEV()
	if not ReactFiberNewContext then
		ReactFiberNewContext = require(script.Parent["ReactFiberNewContext.new"]) :: any
	end
	ReactFiberNewContext.exitDisallowedContextReadInDEV()
end
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local Callback = ReactFiberFlags.Callback
local ShouldCapture = ReactFiberFlags.ShouldCapture
local DidCapture = ReactFiberFlags.DidCapture

local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local debugRenderPhaseSideEffectsForStrictMode =
	ReactFeatureFlags.debugRenderPhaseSideEffectsForStrictMode

local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
local StrictMode = ReactTypeOfMode.StrictMode
-- local ReactFiberWorkLoop = require(script.Parent["ReactFiberWorkLoop.new"])
local markSkippedUpdateLanes =
	require(script.Parent.ReactFiberWorkInProgress).markSkippedUpdateLanes

-- ROBLOX deviation START: use if-then-error, which avoid string format and function call overhead, as in React 18
-- local invariant = require(Packages.Shared).invariant
-- ROBLOX deviation END
local describeError = require(Packages.Shared).describeError

local ConsolePatchingDev = require(Packages.Shared).ConsolePatchingDev
local disableLogs = ConsolePatchingDev.disableLogs
local reenableLogs = ConsolePatchingDev.reenableLogs

-- deviation: Common types
type Array<T> = { [number]: T }

-- ROBLOX deviation: transplants UpdateQueue<> and SharedState<> types to ReactInternalTypes for export to createReactNoop
type Update<T> = ReactInternalTypes.Update<T>
type UpdateQueue<T> = ReactInternalTypes.UpdateQueue<T>
export type SharedQueue<T> = ReactInternalTypes.SharedQueue<T>

local exports = {}

local UpdateState = 0
exports.UpdateState = UpdateState
local ReplaceState = 1
exports.ReplaceState = ReplaceState
local ForceUpdate = 2
exports.ForceUpdate = ForceUpdate
local CaptureUpdate = 3
exports.CaptureUpdate = CaptureUpdate

-- Global state that is reset at the beginning of calling `processUpdateQueue`.
-- It should only be read right after calling `processUpdateQueue`, via
-- `checkHasForceUpdateAfterProcessing`.
local hasForceUpdate = false

local didWarnUpdateInsideUpdate
local currentlyProcessingQueue: SharedQueue<any>?
-- export local resetCurrentlyProcessingQueue
if __DEV__ then
	didWarnUpdateInsideUpdate = false
	currentlyProcessingQueue = nil
	exports.resetCurrentlyProcessingQueue = function()
		currentlyProcessingQueue = nil
	end
end

-- ROBLOX performance: use a recycle pool for update tables
local poolInitSize = 210 -- TODO: Tune to LuaApps
-- local poolAdditionalSize = 0
local updatePool = table.create(poolInitSize)
local updatePoolIndex = poolInitSize
for i = 1, poolInitSize do
	updatePool[i] = {
		eventTime = -1,
		lane = -1,
		tag = -1,
		payload = nil,
		callback = nil,
		next = nil,
	}
end

local function initializeUpdateQueue<State>(fiber: Fiber): ()
	local queue: UpdateQueue<State> = {
		baseState = fiber.memoizedState,
		firstBaseUpdate = nil,
		lastBaseUpdate = nil,
		shared = {
			pending = nil,
		},
		effects = nil,
	}
	fiber.updateQueue = queue
end
exports.initializeUpdateQueue = initializeUpdateQueue

local function cloneUpdateQueue<State>(current: Fiber, workInProgress: Fiber): ()
	-- Clone the update queue from current. Unless it's already a clone.
	local queue: UpdateQueue<State> = workInProgress.updateQueue :: any
	local currentQueue: UpdateQueue<State> = current.updateQueue :: any
	if queue == currentQueue then
		-- ROBLOX deviation START: use our queue method for hot path optimizations
		local clone: UpdateQueue<State> = table.clone(currentQueue)
		-- ROBLOX deviation END
		workInProgress.updateQueue = clone
	end
end
exports.cloneUpdateQueue = cloneUpdateQueue

-- ROBLOX deviation START: add extra parameters here so updates can be create in single table ctor
local function createUpdate(
	eventTime: number,
	lane: Lane,
	payload: any?,
	callback: (() -> ...any)?
): Update<any>
	-- ROBLOX performance: Use pooled update object when available
	if updatePoolIndex > 0 then
		local update = updatePool[updatePoolIndex]
		updatePool[updatePoolIndex] = nil
		updatePoolIndex -= 1

		update.eventTime = eventTime
		update.lane = lane
		update.tag = UpdateState
		update.payload = payload
		update.callback = callback :: any

		return update :: Update<any>
	end
	-- ROBLOX deviation END

	-- ROBLOX performance FIXME: This warning is very noisy in practice and not
	-- actionable by Roact developers in any way. We should re-establish the
	-- warning once we've done some tuning and thought more about what messaging
	-- we want to convey to Roact users

	-- if __DEV__ then
	-- 	poolAdditionalSize += 1
	-- 	console.warn(
	-- 		"ReactUpdateQueue createUpdate's object pool exhausted, allocating fresh table."
	-- 			.. "\nConsider setting poolInitSize to " .. poolInitSize + poolAdditionalSize
	-- 			.. " to avoid this occurring in the future."
	-- 	)
	-- end

	local update = {
		eventTime = eventTime,
		lane = lane,

		tag = UpdateState,
		payload = payload,
		callback = callback :: any,

		next = nil,
	}
	return update :: Update<any>
end
exports.createUpdate = createUpdate

local function enqueueUpdate<State>(fiber: Fiber, update: Update<State>)
	local updateQueue = fiber.updateQueue
	if updateQueue == nil then
		-- Only occurs if the fiber has been unmounted.
		return
	end

	local sharedQueue: SharedQueue<State> = (updateQueue :: any).shared
	local pending = sharedQueue.pending
	if pending == nil then
		-- This is the first update. Create a circular list.
		update.next = update
	else
		update.next = pending.next
		pending.next = update
	end
	sharedQueue.pending = update

	if __DEV__ then
		if currentlyProcessingQueue == sharedQueue and not didWarnUpdateInsideUpdate then
			console.error(
				"An update (setState, replaceState, or forceUpdate) was scheduled "
					.. "from inside an update function. Update functions should be pure, "
					.. "with zero side-effects. Consider using componentDidUpdate or a "
					.. "callback."
			)
			didWarnUpdateInsideUpdate = true
		end
	end
end
exports.enqueueUpdate = enqueueUpdate

local function enqueueCapturedUpdate<State>(workInProgress: Fiber, capturedUpdate: Update<State>)
	-- Captured updates are updates that are thrown by a child during the render
	-- phase. They should be discarded if the render is aborted. Therefore,
	-- we should only put them on the work-in-progress queue, not the current one.
	local queue: UpdateQueue<State> = workInProgress.updateQueue :: any

	-- Check if the work-in-progress queue is a clone.
	local current = workInProgress.alternate
	if current ~= nil then
		local currentQueue: UpdateQueue<State> = current.updateQueue :: any
		if queue == currentQueue then
			-- The work-in-progress queue is the same as current. This happens when
			-- we bail out on a parent fiber that then captures an error thrown by
			-- a child. Since we want to append the update only to the work-in
			-- -progress queue, we need to clone the updates. We usually clone during
			-- processUpdateQueue, but that didn't happen in this case because we
			-- skipped over the parent when we bailed out.
			local newFirst = nil
			local newLast = nil
			local firstBaseUpdate = queue.firstBaseUpdate
			if firstBaseUpdate ~= nil then
				-- Loop through the updates and clone them.
				local update = firstBaseUpdate
				repeat
					local clone: Update<State> = {
						eventTime = update.eventTime,
						lane = update.lane,

						tag = update.tag,
						payload = update.payload,
						callback = update.callback,

						next = nil,
					}
					if newLast == nil then
						newLast = clone
						newFirst = clone
					else
						newLast.next = clone
						newLast = clone
					end
					-- ROBLOX FIXME Luau: Luau needs to support repeat until nil pattern
					update = update.next :: Update<State>
				until update == nil

				-- Append the captured update the end of the cloned list.
				if newLast == nil then
					newLast = capturedUpdate
					newFirst = capturedUpdate
				else
					newLast.next = capturedUpdate
					newLast = capturedUpdate
				end
			else
				-- There are no base updates.
				newLast = capturedUpdate
				newFirst = capturedUpdate
			end
			queue = {
				baseState = currentQueue.baseState,
				firstBaseUpdate = newFirst,
				lastBaseUpdate = newLast,
				shared = currentQueue.shared,
				effects = currentQueue.effects,
			}
			workInProgress.updateQueue = queue
			return
		end
	end

	-- Append the update to the end of the list.
	local lastBaseUpdate = queue.lastBaseUpdate
	if lastBaseUpdate == nil then
		queue.firstBaseUpdate = capturedUpdate
	else
		lastBaseUpdate.next = capturedUpdate
	end
	queue.lastBaseUpdate = capturedUpdate
end
exports.enqueueCapturedUpdate = enqueueCapturedUpdate

local function getStateFromUpdate<State>(
	workInProgress: Fiber,
	queue: UpdateQueue<State>,
	update: Update<State>,
	prevState: State,
	nextProps: any,
	instance: any
): any
	local updateTag = update.tag
	if updateTag == ReplaceState then
		local payload = update.payload
		if type(payload) == "function" then
			-- Updater function
			if __DEV__ then
				enterDisallowedContextReadInDEV()
			end
			-- ROBLOX deviation: Upstream binds this callback to the instance;
			-- in order for us to get the same behavior, we'd need to change the
			-- signature of the updater, which doesn't make sense for our case
			local nextState = payload(prevState, nextProps)
			if __DEV__ then
				if
					debugRenderPhaseSideEffectsForStrictMode
					and bit32.band(workInProgress.mode, StrictMode) ~= 0
				then
					disableLogs()
					-- ROBLOX deviation: YOLO flag for disabling pcall
					local ok, result
					if not __YOLO__ then
						ok, result = xpcall(payload, describeError, prevState, nextProps)
					else
						ok = true
						payload(prevState, nextProps)
					end
					-- finally
					reenableLogs()

					if not ok then
						error(result)
					end
				end
				exitDisallowedContextReadInDEV()
			end
			return nextState
		end
		-- State object
		return payload
	elseif updateTag == CaptureUpdate or updateTag == UpdateState then
		if updateTag == CaptureUpdate then
			workInProgress.flags = bit32.bor(
				bit32.band(workInProgress.flags, bit32.bnot(ShouldCapture)),
				DidCapture
			)
		end
		-- Intentional fallthrough
		local payload = update.payload
		local partialState
		if type(payload) == "function" then
			-- Updater function
			if __DEV__ then
				enterDisallowedContextReadInDEV()
			end
			-- ROBLOX deviation: Upstream binds this callback to the instance;
			-- in order for us to get the same behavior, we'd need to change the
			-- signature of the updater, which doesn't make sense for our case
			partialState = payload(prevState, nextProps)
			if __DEV__ then
				if
					debugRenderPhaseSideEffectsForStrictMode
					and bit32.band(workInProgress.mode, StrictMode) ~= 0
				then
					disableLogs()
					-- ROBLOX deviation: YOLO flag for disabling pcall
					local ok, result
					if not __YOLO__ then
						ok, result = xpcall(payload, describeError, prevState, nextProps)
					else
						ok = true
						payload(prevState, nextProps)
					end
					-- finally
					reenableLogs()

					if not ok then
						error(result)
					end
				end
				exitDisallowedContextReadInDEV()
			end
		else
			-- Partial state object
			partialState = payload
		end
		if partialState == nil then
			-- Null and undefined are treated as no-ops.
			return prevState
		end
		-- Merge the partial state and the previous state.
		-- ROBLOX TODO: the below optimziation doesn't work because: invalid argument #1 to 'clone' (table has a protected metatable)
		-- local newState = if prevState ~= nil then table.clone(prevState :: any) else {}
		return Object.assign({}, prevState, partialState)
	elseif updateTag == ForceUpdate then
		hasForceUpdate = true
		return prevState
	end
	return prevState
end
exports.getStateFromUpdate = getStateFromUpdate

local function processUpdateQueue<State>(
	workInProgress: Fiber,
	props: any,
	instance: any,
	renderLanes: Lanes
): ()
	-- This is always non-null on a ClassComponent or HostRoot
	local queue: UpdateQueue<State> = workInProgress.updateQueue :: any

	hasForceUpdate = false

	if __DEV__ then
		currentlyProcessingQueue = queue.shared
	end

	local firstBaseUpdate = queue.firstBaseUpdate
	local lastBaseUpdate = queue.lastBaseUpdate

	-- Check if there are pending updates. If so, transfer them to the base queue.
	local pendingQueue = queue.shared.pending
	if pendingQueue ~= nil then
		queue.shared.pending = nil

		-- The pending queue is circular. Disconnect the pointer between first
		-- and last so that it's non-circular.
		local lastPendingUpdate = pendingQueue
		local firstPendingUpdate = lastPendingUpdate.next
		lastPendingUpdate.next = nil
		-- Append pending updates to base queue
		if lastBaseUpdate == nil then
			firstBaseUpdate = firstPendingUpdate
		else
			lastBaseUpdate.next = firstPendingUpdate
		end
		lastBaseUpdate = lastPendingUpdate

		-- If there's a current queue, and it's different from the base queue, then
		-- we need to transfer the updates to that queue, too. Because the base
		-- queue is a singly-linked list with no cycles, we can append to both
		-- lists and take advantage of structural sharing.
		-- TODO: Pass `current` as argument
		local current = workInProgress.alternate
		if current ~= nil then
			-- This is always non-null on a ClassComponent or HostRoot
			local currentQueue: UpdateQueue<State> = current.updateQueue :: any
			local currentLastBaseUpdate = currentQueue.lastBaseUpdate
			if currentLastBaseUpdate ~= lastBaseUpdate then
				if currentLastBaseUpdate == nil then
					currentQueue.firstBaseUpdate = firstPendingUpdate
				else
					currentLastBaseUpdate.next = firstPendingUpdate
				end
				currentQueue.lastBaseUpdate = lastPendingUpdate
			end
		end
	end

	-- These values may change as we process the queue.
	if firstBaseUpdate ~= nil then
		-- Iterate through the list of updates to compute the result.
		local newState = queue.baseState
		-- TODO: Don't need to accumulate this. Instead, we can remove renderLanes
		-- from the original lanes.
		local newLanes = NoLanes

		local newBaseState = nil
		local newFirstBaseUpdate = nil
		local newLastBaseUpdate = nil

		local update = firstBaseUpdate
		while true do
			local updateLane = update.lane
			local updateEventTime = update.eventTime
			if not isSubsetOfLanes(renderLanes, updateLane) then
				-- Priority is insufficient. Skip this update. If this is the first
				-- skipped update, the previous update/state is the new base
				-- update/state.
				local clone: Update<State> = {
					eventTime = updateEventTime,
					lane = updateLane,

					tag = update.tag,
					payload = update.payload,
					callback = update.callback,

					next = nil,
				}
				if newLastBaseUpdate == nil then
					newFirstBaseUpdate = clone
					newLastBaseUpdate = clone
					newBaseState = newState
				else
					newLastBaseUpdate.next = clone
					newLastBaseUpdate = clone
				end
				-- Update the remaining priority in the queue.
				newLanes = mergeLanes(newLanes, updateLane)
			else
				-- This update does have sufficient priority.

				if newLastBaseUpdate ~= nil then
					local clone: Update<State> = {
						eventTime = updateEventTime,
						-- This update is going to be committed so we never want uncommit
						-- it. Using NoLane works because 0 is a subset of all bitmasks, so
						-- this will never be skipped by the check above.
						lane = NoLane,

						tag = update.tag,
						payload = update.payload,
						callback = update.callback,

						next = nil,
					}
					newLastBaseUpdate.next = clone
					newLastBaseUpdate = clone
				end

				-- Process this update.
				newState = getStateFromUpdate(
					workInProgress,
					queue,
					update,
					newState,
					props,
					instance
				)
				local callback = update.callback
				if
					callback ~= nil
					-- If the update was already committed, we should not queue its
					-- callback again.
					and update.lane ~= NoLane
				then
					workInProgress.flags = bit32.bor(workInProgress.flags, Callback)
					local effects = queue.effects
					if effects == nil then
						queue.effects = { update }
					else
						table.insert(effects, update)
					end
				end
			end
			-- ROBLOX FIXME Luau: Luau needs to support repeat until nil pattern
			update = update.next :: Update<State>
			if update == nil then
				pendingQueue = queue.shared.pending
				if pendingQueue == nil then
					break
				else
					-- An update was scheduled from inside a reducer. Add the new
					-- pending updates to the end of the list and keep processing.
					local lastPendingUpdate = pendingQueue
					-- Intentionally unsound. Pending updates form a circular list, but we
					-- unravel them when transferring them to the base queue.
					local firstPendingUpdate = (
						lastPendingUpdate.next :: any
					) :: Update<State>
					lastPendingUpdate.next = nil
					update = firstPendingUpdate
					queue.lastBaseUpdate = lastPendingUpdate
					queue.shared.pending = nil
				end
			end
		end

		if newLastBaseUpdate == nil then
			newBaseState = newState
		end

		queue.baseState = (newBaseState :: any) :: State
		queue.firstBaseUpdate = newFirstBaseUpdate
		queue.lastBaseUpdate = newLastBaseUpdate

		-- Set the remaining expiration time to be whatever is remaining in the queue.
		-- This should be fine because the only two other things that contribute to
		-- expiration time are props and context. We're already in the middle of the
		-- begin phase by the time we start processing the queue, so we've already
		-- dealt with the props. Context in components that specify
		-- shouldComponentUpdate is tricky; but we'll have to account for
		-- that regardless.
		markSkippedUpdateLanes(newLanes)
		workInProgress.lanes = newLanes
		workInProgress.memoizedState = newState
	end

	if __DEV__ then
		currentlyProcessingQueue = nil
	end
end
exports.processUpdateQueue = processUpdateQueue

local function callCallback(callback, context)
	-- ROBLOX deviation START: use if-then-error, which avoid string format and function call overhead, as in React 18
	if type(callback) ~= "function" then
		error(
			string.format(
				"Invalid argument passed as callback. Expected a function. Instead "
					.. "received: %s",
				tostring(callback)
			)
		)
		-- ROBLOX deviation END
	end
	callback(context)
end

exports.resetHasForceUpdateBeforeProcessing = function()
	hasForceUpdate = false
end

exports.checkHasForceUpdateAfterProcessing = function(): boolean
	return hasForceUpdate
end

local function commitUpdateQueue<State>(
	finishedWork: Fiber,
	finishedQueue: UpdateQueue<State>,
	instance: any
): ()
	-- Commit the effects
	local effects = finishedQueue.effects
	finishedQueue.effects = nil
	if effects ~= nil then
		for _, effect in effects do
			local callback = effect.callback
			if callback ~= nil then
				callCallback(callback, instance)
			end

			-- ROBLOX performance: return this object to the pool
			table.clear(effect)
			table.insert(updatePool, effect :: any)
			updatePoolIndex += 1
		end
	end
end
exports.commitUpdateQueue = commitUpdateQueue

return exports
