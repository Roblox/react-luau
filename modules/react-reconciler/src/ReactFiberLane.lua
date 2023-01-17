-- ROBLOX upstream: https://github.com/facebook/react/blob/6f62abb58ae46d9c88525635f1790487285666e6/packages/react-reconciler/src/ReactFiberLane.js
--!strict
--[[
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local Packages = script.Parent.Parent
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type FiberRoot = ReactInternalTypes.FiberRoot
type ReactPriorityLevel = ReactInternalTypes.ReactPriorityLevel
local console = require(Packages.Shared).console

local ReactFiberSchedulerPriorities =
	require(script.Parent["ReactFiberSchedulerPriorities.roblox"])

-- deviation: Instead of defining these here, and and re-exporting in
-- `ReactInternalTypes`, we depend on and re-export them here to avoid cyclical
-- require issues
export type LanePriority = ReactInternalTypes.LanePriority
export type Lane = ReactInternalTypes.Lane
export type Lanes = ReactInternalTypes.Lanes
export type LaneMap<T> = ReactInternalTypes.LaneMap<T>

local invariant = require(Packages.Shared).invariant

local ImmediateSchedulerPriority = ReactFiberSchedulerPriorities.ImmediatePriority
local UserBlockingSchedulerPriority = ReactFiberSchedulerPriorities.UserBlockingPriority
local NormalSchedulerPriority = ReactFiberSchedulerPriorities.NormalPriority
local LowSchedulerPriority = ReactFiberSchedulerPriorities.LowPriority
local IdleSchedulerPriority = ReactFiberSchedulerPriorities.IdlePriority
local NoSchedulerPriority = ReactFiberSchedulerPriorities.NoPriority

local exports = {}

local SyncLanePriority: LanePriority = 15
exports.SyncLanePriority = SyncLanePriority
local SyncBatchedLanePriority: LanePriority = 14
exports.SyncBatchedLanePriority = SyncBatchedLanePriority

local InputDiscreteHydrationLanePriority: LanePriority = 13
local InputDiscreteLanePriority: LanePriority = 12
exports.InputDiscreteLanePriority = InputDiscreteLanePriority

local InputContinuousHydrationLanePriority: LanePriority = 11
local InputContinuousLanePriority: LanePriority = 10
exports.InputContinuousLanePriority = InputContinuousLanePriority

local DefaultHydrationLanePriority: LanePriority = 9
local DefaultLanePriority: LanePriority = 8
exports.DefaultLanePriority = DefaultLanePriority

local TransitionHydrationPriority: LanePriority = 7
local TransitionPriority: LanePriority = 6
exports.TransitionPriority = TransitionPriority

local RetryLanePriority: LanePriority = 5

local SelectiveHydrationLanePriority: LanePriority = 4

local IdleHydrationLanePriority: LanePriority = 3
local IdleLanePriority: LanePriority = 2

local OffscreenLanePriority: LanePriority = 1

local NoLanePriority: LanePriority = 0
exports.NoLanePriority = NoLanePriority

-- ROBLOX performance: only use was for loop that was manually unrolled
-- local TotalLanes = 31

local NoLanes: Lanes = --[[                             ]]
	0b0000000000000000000000000000000
exports.NoLanes = NoLanes
local NoLane: Lane = --[[                               ]]
	0b0000000000000000000000000000000
exports.NoLane = NoLane

local SyncLane: Lane = --[[                             ]]
	0b0000000000000000000000000000001
exports.SyncLane = SyncLane
local SyncBatchedLane: Lanes = --[[                     ]]
	0b0000000000000000000000000000010
exports.SyncBatchedLane = SyncBatchedLane

local InputDiscreteHydrationLane: Lane = --[[           ]]
	0b0000000000000000000000000000100
exports.InputDiscreteHydrationLane = InputDiscreteHydrationLane
local InputDiscreteLanes: Lanes = --[[                  ]]
	0b0000000000000000000000000011000

local InputContinuousHydrationLane: Lane = --[[         ]]
	0b0000000000000000000000000100000
local InputContinuousLanes: Lanes = --[[                ]]
	0b0000000000000000000000011000000

local DefaultHydrationLane: Lane = --[[                 ]]
	0b0000000000000000000000100000000
exports.DefaultHydrationLane = DefaultHydrationLane
local DefaultLanes: Lanes = --[[                        ]]
	0b0000000000000000000111000000000
exports.DefaultLanes = DefaultLanes

local TransitionHydrationLane: Lane = --[[              ]]
	0b0000000000000000001000000000000
local TransitionLanes: Lanes = --[[                     ]]
	0b0000000001111111110000000000000

local RetryLanes: Lanes = --[[                          ]]
	0b0000011110000000000000000000000
-- ROBLOX deviation: we expose this symbol from the module for ReactUpdateQueue.roblox tests, we don't re-export outside the package
exports.RetryLanes = RetryLanes
local SomeRetryLane: Lanes = --[[                       ]]
	0b0000010000000000000000000000000
exports.SomeRetryLane = SomeRetryLane

local SelectiveHydrationLane: Lane = --[[               ]]
	0b0000100000000000000000000000000
exports.SelectiveHydrationLane = SelectiveHydrationLane

local NonIdleLanes = --[[                               ]]
	0b0000111111111111111111111111111

local IdleHydrationLane: Lane = --[[                    ]]
	0b0001000000000000000000000000000
exports.IdleHydrationLane = IdleHydrationLane
local IdleLanes: Lanes = --[[                           ]]
	0b0110000000000000000000000000000

local OffscreenLane: Lane = --[[                        ]]
	0b1000000000000000000000000000000
exports.OffscreenLane = OffscreenLane

local NoTimestamp = -1
exports.NoTimestamp = NoTimestamp

local currentUpdateLanePriority: LanePriority = exports.NoLanePriority

exports.getCurrentUpdateLanePriority = function(): LanePriority
	return currentUpdateLanePriority
end

exports.setCurrentUpdateLanePriority = function(newLanePriority: LanePriority)
	currentUpdateLanePriority = newLanePriority
end

-- // "Registers" used to "return" multiple values
-- // Used by getHighestPriorityLanes and getNextLanes:
local return_highestLanePriority: LanePriority = exports.DefaultLanePriority

local function getHighestPriorityLanes(lanes: Lanes | Lane): Lanes
	if bit32.band(SyncLane, lanes) ~= NoLanes then
		return_highestLanePriority = SyncLanePriority
		return SyncLane
	end
	if bit32.band(SyncBatchedLane, lanes) ~= NoLanes then
		return_highestLanePriority = SyncBatchedLanePriority
		return SyncBatchedLane
	end
	if bit32.band(InputDiscreteHydrationLane, lanes) ~= NoLanes then
		return_highestLanePriority = InputDiscreteHydrationLanePriority
		return InputDiscreteHydrationLane
	end
	local inputDiscreteLanes = bit32.band(InputDiscreteLanes, lanes)
	if inputDiscreteLanes ~= NoLanes then
		return_highestLanePriority = InputDiscreteLanePriority
		return inputDiscreteLanes
	end
	if bit32.band(lanes, InputContinuousHydrationLane) ~= NoLanes then
		return_highestLanePriority = InputContinuousHydrationLanePriority
		return InputContinuousHydrationLane
	end
	local inputContinuousLanes = bit32.band(InputContinuousLanes, lanes)
	if inputContinuousLanes ~= NoLanes then
		return_highestLanePriority = InputContinuousLanePriority
		return inputContinuousLanes
	end
	if bit32.band(lanes, DefaultHydrationLane) ~= NoLanes then
		return_highestLanePriority = DefaultHydrationLanePriority
		return DefaultHydrationLane
	end
	local defaultLanes = bit32.band(DefaultLanes, lanes)
	if defaultLanes ~= NoLanes then
		return_highestLanePriority = DefaultLanePriority
		return defaultLanes
	end
	if bit32.band(lanes, TransitionHydrationLane) ~= NoLanes then
		return_highestLanePriority = TransitionHydrationPriority
		return TransitionHydrationLane
	end
	local transitionLanes = bit32.band(TransitionLanes, lanes)
	if transitionLanes ~= NoLanes then
		return_highestLanePriority = TransitionPriority
		return transitionLanes
	end
	local retryLanes = bit32.band(RetryLanes, lanes)
	if retryLanes ~= NoLanes then
		return_highestLanePriority = RetryLanePriority
		return retryLanes
	end
	if bit32.band(lanes, SelectiveHydrationLane) ~= 0 then
		return_highestLanePriority = SelectiveHydrationLanePriority
		return SelectiveHydrationLane
	end
	if bit32.band(lanes, IdleHydrationLane) ~= NoLanes then
		return_highestLanePriority = IdleHydrationLanePriority
		return IdleHydrationLane
	end
	local idleLanes = bit32.band(IdleLanes, lanes)
	if idleLanes ~= NoLanes then
		return_highestLanePriority = IdleLanePriority
		return idleLanes
	end
	if bit32.band(OffscreenLane, lanes) ~= NoLanes then
		return_highestLanePriority = OffscreenLanePriority
		return OffscreenLane
	end
	if _G.__DEV__ then
		console.error("Should have found matching lanes. This is a bug in React.")
	end
	-- // This shouldn't be reachable, but as a fallback, return the entire bitmask.
	return_highestLanePriority = DefaultLanePriority
	return lanes
end

local function schedulerPriorityToLanePriority(
	schedulerPriorityLevel: ReactPriorityLevel
): LanePriority
	if schedulerPriorityLevel == ImmediateSchedulerPriority then
		return SyncLanePriority
	elseif schedulerPriorityLevel == UserBlockingSchedulerPriority then
		return InputContinuousLanePriority
	elseif
		schedulerPriorityLevel == NormalSchedulerPriority
		or schedulerPriorityLevel == LowSchedulerPriority
	then
		-- // TODO: Handle LowSchedulerPriority, somehow. Maybe the same lane as hydration.
		return DefaultLanePriority
	elseif schedulerPriorityLevel == IdleSchedulerPriority then
		return IdleLanePriority
	else
		return NoLanePriority
	end
end
exports.schedulerPriorityToLanePriority = schedulerPriorityToLanePriority

local function lanePriorityToSchedulerPriority(
	lanePriority: LanePriority
): ReactPriorityLevel
	if lanePriority == SyncLanePriority or lanePriority == SyncBatchedLanePriority then
		return ImmediateSchedulerPriority
	elseif
		lanePriority == InputDiscreteHydrationLanePriority
		or lanePriority == InputDiscreteLanePriority
		or lanePriority == InputContinuousHydrationLanePriority
		or lanePriority == InputContinuousLanePriority
	then
		return UserBlockingSchedulerPriority
	elseif
		lanePriority == DefaultHydrationLanePriority
		or lanePriority == DefaultLanePriority
		or lanePriority == TransitionHydrationPriority
		or lanePriority == TransitionPriority
		or lanePriority == SelectiveHydrationLanePriority
		or lanePriority == RetryLanePriority
	then
		return NormalSchedulerPriority
	elseif
		lanePriority == IdleHydrationLanePriority
		or lanePriority == IdleLanePriority
		or lanePriority == OffscreenLanePriority
	then
		return IdleSchedulerPriority
	elseif lanePriority == NoLanePriority then
		return NoSchedulerPriority
	else
		invariant(
			false,
			"Invalid update priority: %s. This is a bug in React.",
			lanePriority
		)
		-- deviation: luau doesn't know that invariant throws, so we error
		error("unreachable")
	end
end
exports.lanePriorityToSchedulerPriority = lanePriorityToSchedulerPriority

-- deviation: pre-declare pickArbitraryLaneIndex to keep ordering
local pickArbitraryLaneIndex, getLowestPriorityLane, getEqualOrHigherPriorityLanes

local function getNextLanes(root: FiberRoot, wipLanes: Lanes): Lanes
	-- // Early bailout if there's no pending work left.
	local pendingLanes = root.pendingLanes
	if pendingLanes == NoLanes then
		return_highestLanePriority = NoLanePriority
		return NoLanes
	end

	local nextLanes = NoLanes
	local nextLanePriority = NoLanePriority

	local expiredLanes = root.expiredLanes
	local suspendedLanes = root.suspendedLanes
	local pingedLanes = root.pingedLanes

	-- // Check if any work has expired.
	if expiredLanes ~= NoLanes then
		nextLanes = expiredLanes
		return_highestLanePriority = SyncLanePriority
		nextLanePriority = SyncLanePriority
	else
		-- // Do not work on any idle work until all the non-idle work has finished,
		-- // even if the work is suspended.
		local nonIdlePendingLanes = bit32.band(pendingLanes, NonIdleLanes)
		if nonIdlePendingLanes ~= NoLanes then
			local nonIdleUnblockedLanes =
				bit32.band(nonIdlePendingLanes, bit32.bnot(suspendedLanes))
			if nonIdleUnblockedLanes ~= NoLanes then
				nextLanes = getHighestPriorityLanes(nonIdleUnblockedLanes)
				nextLanePriority = return_highestLanePriority
			else
				local nonIdlePingedLanes = bit32.band(nonIdlePendingLanes, pingedLanes)
				if nonIdlePingedLanes ~= NoLanes then
					nextLanes = getHighestPriorityLanes(nonIdlePingedLanes)
					nextLanePriority = return_highestLanePriority
				end
			end
		else
			-- // The only remaining work is Idle.
			local unblockedLanes = bit32.band(pendingLanes, bit32.bnot(suspendedLanes))
			if unblockedLanes ~= NoLanes then
				nextLanes = getHighestPriorityLanes(unblockedLanes)
				nextLanePriority = return_highestLanePriority
			else
				if pingedLanes ~= NoLanes then
					nextLanes = getHighestPriorityLanes(pingedLanes)
					nextLanePriority = return_highestLanePriority
				end
			end
		end
	end

	if nextLanes == NoLanes then
		-- // This should only be reachable if we're suspended
		-- // TODO: Consider warning in this path if a fallback timer is not scheduled.
		return NoLanes
	end

	-- // If there are higher priority lanes, we'll include them even if they
	-- // are suspended.
	-- ROBLOX performance: inline getEqualOrHigherPriorityLanes to avoid function call overhead in hot path
	-- nextLanes = bit32.band(pendingLanes, getEqualOrHigherPriorityLanes(nextLanes))
	nextLanes =
		bit32.band(pendingLanes, bit32.lshift(getLowestPriorityLane(nextLanes), 1) - 1)

	-- // If we're already in the middle of a render, switching lanes will interrupt
	-- // it and we'll lose our progress. We should only do this if the new lanes are
	-- // higher priority.
	if
		wipLanes ~= NoLanes
		and wipLanes ~= nextLanes
		-- // If we already suspended with a delay, then interrupting is fine. Don't
		-- // bother waiting until the root is complocale.
		and bit32.band(wipLanes, suspendedLanes) == NoLanes
	then
		getHighestPriorityLanes(wipLanes)
		local wipLanePriority = return_highestLanePriority
		if nextLanePriority <= wipLanePriority then
			return wipLanes
		else
			return_highestLanePriority = nextLanePriority
		end
	end

	-- // Check for entangled lanes and add them to the batch.
	-- //
	-- // A lane is said to be entangled with another when it's not allowed to render
	-- // in a batch that does not also include the other lane. Typically we do this
	-- // when multiple updates have the same source, and we only want to respond to
	-- // the most recent event from that source.
	-- //
	-- // Note that we apply entanglements *after* checking for partial work above.
	-- // This means that if a lane is entangled during an interleaved event while
	-- // it's already rendering, we won't interrupt it. This is intentional, since
	-- // entanglement is usually "best effort": we'll try our best to render the
	-- // lanes in the same batch, but it's not worth throwing out partially
	-- // complocaled work in order to do it.
	-- //
	-- // For those exceptions where entanglement is semantically important, like
	-- // useMutableSource, we should ensure that there is no partial work at the
	-- // time we apply the entanglement.
	local entangledLanes = root.entangledLanes
	if entangledLanes ~= NoLanes then
		local entanglements = root.entanglements
		local lanes = bit32.band(nextLanes, entangledLanes)
		while lanes > 0 do
			local index = pickArbitraryLaneIndex(lanes)
			local lane = bit32.lshift(1, index)

			nextLanes = bit32.bor(nextLanes, entanglements[index])

			lanes = bit32.band(lanes, bit32.bnot(lane))
		end
	end

	return nextLanes
end
exports.getNextLanes = getNextLanes

local function getMostRecentEventTime(root: FiberRoot, lanes: Lanes): number
	local eventTimes = root.eventTimes

	local mostRecentEventTime = NoTimestamp
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		local eventTime = eventTimes[index]
		if eventTime > mostRecentEventTime then
			mostRecentEventTime = eventTime
		end

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end

	return mostRecentEventTime
end
exports.getMostRecentEventTime = getMostRecentEventTime

local function computeExpirationTime(lane: Lane, currentTime: number)
	-- // TODO: Expiration heuristic is constant per lane, so could use a map.
	getHighestPriorityLanes(lane)
	local priority = return_highestLanePriority
	if priority >= InputContinuousLanePriority then
		-- // User interactions should expire slightly more quickly.
		-- //
		-- // NOTE: This is set to the corresponding constant as in Scheduler.js. When
		-- // we made it larger, a product metric in www regressed, suggesting there's
		-- // a user interaction that's being starved by a series of synchronous
		-- // updates. If that theory is correct, the proper solution is to fix the
		-- // starvation. However, this scenario supports the idea that expiration
		-- // times are an important safeguard when starvation does happen.
		-- //
		-- // Also note that, in the case of user input specifically, this will soon no
		-- // longer be an issue because we plan to make user input synchronous by
		-- // default (until you enter `startTransition`, of course.)
		-- //
		-- // If weren't planning to make these updates synchronous soon anyway, I
		-- // would probably make this number a configurable parameter.
		return currentTime + 250
	elseif priority >= TransitionPriority then
		return currentTime + 5000
	else
		-- // Anything idle priority or lower should never expire.
		return NoTimestamp
	end
end
exports.computeExpirationTime = computeExpirationTime

local function markStarvedLanesAsExpired(root: FiberRoot, currentTime: number)
	-- // TODO: This gets called every time we yield. We can optimize by storing
	-- // the earliest expiration time on the root. Then use that to quickly bail out
	-- // of this function.

	local pendingLanes = root.pendingLanes
	local suspendedLanes = root.suspendedLanes
	local pingedLanes = root.pingedLanes
	local expirationTimes = root.expirationTimes

	-- // Iterate through the pending lanes and check if we've reached their
	-- // expiration time. If so, we'll assume the update is being starved and mark
	-- // it as expired to force it to finish.
	local lanes = pendingLanes
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		local expirationTime = expirationTimes[index]
		if expirationTime == NoTimestamp then
			-- // Found a pending lane with no expiration time. If it's not suspended, or
			-- // if it's pinged, assume it's CPU-bound. Compute a new expiration time
			-- // using the current time.
			if
				bit32.band(lane, suspendedLanes) == NoLanes
				or bit32.band(lane, pingedLanes) ~= NoLanes
			then
				-- // Assumes timestamps are monotonically increasing.
				expirationTimes[index] = computeExpirationTime(lane, currentTime)
			end
		elseif expirationTime <= currentTime then
			-- // This lane expired
			root.expiredLanes = bit32.bor(root.expiredLanes, lane)
		end

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end
end
exports.markStarvedLanesAsExpired = markStarvedLanesAsExpired

-- // This returns the highest priority pending lanes regardless of whether they
-- // are suspended.
local function getHighestPriorityPendingLanes(root: FiberRoot)
	return getHighestPriorityLanes(root.pendingLanes)
end
exports.getHighestPriorityPendingLanes = getHighestPriorityPendingLanes

local function getLanesToRetrySynchronouslyOnError(root: FiberRoot): Lanes
	local everythingButOffscreen =
		bit32.band(root.pendingLanes, bit32.bnot(OffscreenLane))
	if everythingButOffscreen ~= NoLanes then
		return everythingButOffscreen
	end
	if bit32.band(everythingButOffscreen, OffscreenLane) ~= 0 then
		return OffscreenLane
	end
	return NoLanes
end
exports.getLanesToRetrySynchronouslyOnError = getLanesToRetrySynchronouslyOnError

local function returnNextLanesPriority()
	return return_highestLanePriority
end
exports.returnNextLanesPriority = returnNextLanesPriority

local function includesNonIdleWork(lanes: Lanes)
	return bit32.band(lanes, NonIdleLanes) ~= NoLanes
end
exports.includesNonIdleWork = includesNonIdleWork

local function includesOnlyRetries(lanes: Lanes)
	return bit32.band(lanes, RetryLanes) == lanes
end
exports.includesOnlyRetries = includesOnlyRetries

local function includesOnlyTransitions(lanes: Lanes)
	return bit32.band(lanes, TransitionLanes) == lanes
end
exports.includesOnlyTransitions = includesOnlyTransitions

-- deviation: pre-declare pickArbitraryLane to keep ordering
local pickArbitraryLane

-- // To ensure consistency across multiple updates in the same event, this should
-- // be a pure function, so that it always returns the same lane for given inputs.
local function findUpdateLane(lanePriority: LanePriority, wipLanes: Lanes): Lane
	if lanePriority == NoLanePriority then
		-- break
	elseif lanePriority == SyncLanePriority then
		return SyncLane
	elseif lanePriority == SyncBatchedLanePriority then
		return SyncBatchedLane
	elseif lanePriority == InputDiscreteLanePriority then
		local lane =
			pickArbitraryLane(bit32.band(InputDiscreteLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			-- // Shift to the next priority level
			return findUpdateLane(InputContinuousLanePriority, wipLanes)
		end
		return lane
	elseif lanePriority == InputContinuousLanePriority then
		local lane =
			pickArbitraryLane(bit32.band(InputContinuousLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			-- // Shift to the next priority level
			return findUpdateLane(DefaultLanePriority, wipLanes)
		end
		return lane
	elseif lanePriority == DefaultLanePriority then
		local lane = pickArbitraryLane(bit32.band(DefaultLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			-- // If all the default lanes are already being worked on, look for a
			-- // lane in the transition range.
			lane = pickArbitraryLane(bit32.band(TransitionLanes, bit32.bnot(wipLanes)))
			if lane == NoLane then
				-- // All the transition lanes are taken, too. This should be very
				-- // rare, but as a last resort, pick a default lane. This will have
				-- // the effect of interrupting the current work-in-progress render.
				lane = pickArbitraryLane(DefaultLanes)
			end
		end
		return lane
	elseif
		lanePriority == TransitionPriority -- // Should be handled by findTransitionLane instead
		or lanePriority == RetryLanePriority -- // Should be handled by findRetryLane instead
	then
		-- break
	elseif lanePriority == IdleLanePriority then
		local lane = pickArbitraryLane(bit32.band(IdleLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			lane = pickArbitraryLane(IdleLanes)
		end
		return lane
	else
		-- // The remaining priorities are not valid for updates
	end
	invariant(false, "Invalid update priority: %s. This is a bug in React.", lanePriority)
	-- deviation: luau doesn't know that invariant throws, so we error
	error("unreachable")
end
exports.findUpdateLane = findUpdateLane

-- // To ensure consistency across multiple updates in the same event, this should
-- // be pure function, so that it always returns the same lane for given inputs.
local function findTransitionLane(wipLanes: Lanes, pendingLanes: Lanes): Lane
	-- // First look for lanes that are completely unclaimed, i.e. have no
	-- // pending work.
	local lane = pickArbitraryLane(bit32.band(TransitionLanes, bit32.bnot(pendingLanes)))
	if lane == NoLane then
		-- // If all lanes have pending work, look for a lane that isn't currently
		-- // being worked on.
		lane = pickArbitraryLane(bit32.band(TransitionLanes, bit32.bnot(wipLanes)))
		if lane == NoLane then
			-- // If everything is being worked on, pick any lane. This has the
			-- // effect of interrupting the current work-in-progress.
			lane = pickArbitraryLane(TransitionLanes)
		end
	end
	return lane
end
exports.findTransitionLane = findTransitionLane

-- // To ensure consistency across multiple updates in the same event, this should
-- // be pure function, so that it always returns the same lane for given inputs.
local function findRetryLane(wipLanes: Lanes): Lane
	-- // This is a fork of `findUpdateLane` designed specifically for Suspense
	-- // "retries" — a special update that attempts to flip a Suspense boundary
	-- // from its placeholder state to its primary/resolved state.
	local lane = pickArbitraryLane(bit32.band(RetryLanes, bit32.bnot(wipLanes)))
	if lane == NoLane then
		lane = pickArbitraryLane(RetryLanes)
	end
	return lane
end
exports.findRetryLane = findRetryLane

local function getHighestPriorityLane(lanes: Lanes)
	return bit32.band(lanes, -lanes)
end

function getLowestPriorityLane(lanes: Lanes): Lane
	-- // This finds the most significant non-zero bit.
	local index = 31 - bit32.countlz(lanes)
	if index < 0 then
		return NoLanes
	else
		return bit32.lshift(1, index)
	end
end

function getEqualOrHigherPriorityLanes(lanes: Lanes | Lane): Lanes
	return bit32.lshift(getLowestPriorityLane(lanes), 1) - 1
end

function pickArbitraryLane(lanes: Lanes): Lane
	-- // This wrapper function gets inlined. Only exists so to communicate that it
	-- // doesn't matter which bit is selected; you can pick any bit without
	-- // affecting the algorithms where its used. Here I'm using
	-- // getHighestPriorityLane because it requires the fewest operations.
	return getHighestPriorityLane(lanes)
end
exports.pickArbitraryLane = pickArbitraryLane

function pickArbitraryLaneIndex(lanes: Lanes)
	return 31 - bit32.countlz(lanes)
end

-- ROBLOX performance: all uses have been inlined
-- local function laneToIndex(lane: Lane)
-- 	return pickArbitraryLaneIndex(lane)
-- end

local function includesSomeLane(a: Lanes | Lane, b: Lanes | Lane)
	return bit32.band(a, b) ~= NoLanes
end
exports.includesSomeLane = includesSomeLane

local function isSubsetOfLanes(set: Lanes, subset: Lanes | Lane)
	return bit32.band(set, subset) == subset
end
exports.isSubsetOfLanes = isSubsetOfLanes

local function mergeLanes(a: Lanes | Lane, b: Lanes | Lane): Lanes
	return bit32.bor(a, b)
end
exports.mergeLanes = mergeLanes

local function removeLanes(set: Lanes, subset: Lanes | Lane): Lanes
	return bit32.band(set, bit32.bnot(subset))
end
exports.removeLanes = removeLanes

-- // Seems redundant, but it changes the type from a single lane (used for
-- // updates) to a group of lanes (used for flushing work).
local function laneToLanes(lane: Lane): Lanes
	return lane
end
exports.laneToLanes = laneToLanes

local function higherPriorityLane(a: Lane, b: Lane)
	-- // This works because the bit ranges decrease in priority as you go left.
	if a ~= NoLane and b ~= NoLane then
		if a < b then
			return a
		end
		return b
	else
		if a ~= NoLane then
			return a
		end
		return b
	end
end
exports.higherPriorityLane = higherPriorityLane

local function higherLanePriority(a: LanePriority, b: LanePriority): LanePriority
	if a ~= NoLanePriority and a > b then
		return a
	else
		return b
	end
end
exports.higherLanePriority = higherLanePriority

-- deviation: luau does not support generic functions yet
-- local function createLaneMap<T>(initial: T): LaneMap<T>
local function createLaneMap(initial): LaneMap<any>
	-- // Intentionally pushing one by one.
	-- // https://v8.dev/blog/elements-kinds#avoid-creating-holes
	-- ROBLOX performance: manually unroll this loop so the table creation is a one-shot
	--for i = 0, TotalLanes do
	local laneMap = {
		[0] = initial,
		[1] = initial,
		[2] = initial,
		[3] = initial,
		[4] = initial,
		[5] = initial,
		[6] = initial,
		[7] = initial,
		[8] = initial,
		[9] = initial,
		[10] = initial,
		[11] = initial,
		[12] = initial,
		[13] = initial,
		[14] = initial,
		[15] = initial,
		[16] = initial,
		[17] = initial,
		[18] = initial,
		[19] = initial,
		[20] = initial,
		[21] = initial,
		[22] = initial,
		[23] = initial,
		[24] = initial,
		[25] = initial,
		[26] = initial,
		[27] = initial,
		[28] = initial,
		[29] = initial,
		[30] = initial,
		[31] = initial,
		-- ROBLOX TODO: must be updated when TotalLanes is updated!
	}
	return laneMap
end
exports.createLaneMap = createLaneMap

local function markRootUpdated(root: FiberRoot, updateLane: Lane, eventTime: number)
	root.pendingLanes = bit32.bor(root.pendingLanes, updateLane)

	-- // TODO: Theoretically, any update to any lane can unblock any other lane. But
	-- // it's not practical to try every single possible combination. We need a
	-- // heuristic to decide which lanes to attempt to render, and in which batches.
	-- // For now, we use the same heuristic as in the old ExpirationTimes model:
	-- // retry any lane at equal or lower priority, but don't try updates at higher
	-- // priority without also including the lower priority updates. This works well
	-- // when considering updates across different priority levels, but isn't
	-- // sufficient for updates within the same priority, since we want to treat
	-- // those updates as parallel.

	-- // Unsuspend any update at equal or lower priority.
	local higherPriorityLanes = updateLane - 1 -- // Turns 0b1000 into 0b0111

	root.suspendedLanes = bit32.band(root.suspendedLanes, higherPriorityLanes)
	root.pingedLanes = bit32.band(root.pingedLanes, higherPriorityLanes)

	local eventTimes = root.eventTimes
	-- ROBLOX performance: inline laneToIndex in hot path
	-- local index = laneToIndex(updateLane)
	local index = 31 - bit32.countlz(updateLane)
	-- // We can always overwrite an existing timestamp because we prefer the most
	-- // recent event, and we assume time is monotonically increasing.
	eventTimes[index] = eventTime
end
exports.markRootUpdated = markRootUpdated

local function markRootSuspended(root: FiberRoot, suspendedLanes: Lanes)
	root.suspendedLanes = bit32.bor(root.suspendedLanes, suspendedLanes)
	root.pingedLanes = bit32.band(root.pingedLanes, bit32.bnot(suspendedLanes))

	-- // The suspended lanes are no longer CPU-bound. Clear their expiration times.
	local expirationTimes = root.expirationTimes
	local lanes = suspendedLanes
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		expirationTimes[index] = NoTimestamp

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end
end
exports.markRootSuspended = markRootSuspended

local function markRootPinged(root: FiberRoot, pingedLanes: Lanes, eventTime: number)
	root.pingedLanes =
		bit32.bor(root.pingedLanes, bit32.band(root.suspendedLanes, pingedLanes))
end
exports.markRootPinged = markRootPinged

local function markRootExpired(root: FiberRoot, expiredLanes: Lanes)
	root.expiredLanes =
		bit32.bor(root.expiredLanes, bit32.band(expiredLanes, root.pendingLanes))
end
exports.markRootExpired = markRootExpired

local function markDiscreteUpdatesExpired(root: FiberRoot)
	root.expiredLanes =
		bit32.bor(root.expiredLanes, bit32.band(InputDiscreteLanes, root.pendingLanes))
end
exports.markDiscreteUpdatesExpired = markDiscreteUpdatesExpired

local function hasDiscreteLanes(lanes: Lanes)
	return bit32.band(lanes, InputDiscreteLanes) ~= NoLanes
end
exports.hasDiscreteLanes = hasDiscreteLanes

local function markRootMutableRead(root: FiberRoot, updateLane: Lane)
	root.mutableReadLanes =
		bit32.bor(root.mutableReadLanes, bit32.band(updateLane, root.pendingLanes))
end
exports.markRootMutableRead = markRootMutableRead

local function markRootFinished(root: FiberRoot, remainingLanes: Lanes)
	local noLongerPendingLanes = bit32.band(root.pendingLanes, bit32.bnot(remainingLanes))

	root.pendingLanes = remainingLanes

	-- // Let's try everything again
	root.suspendedLanes = 0
	root.pingedLanes = 0

	root.expiredLanes = bit32.band(root.expiredLanes, remainingLanes)
	root.mutableReadLanes = bit32.band(root.mutableReadLanes, remainingLanes)

	root.entangledLanes = bit32.band(root.entangledLanes, remainingLanes)

	local entanglements = root.entanglements
	local eventTimes = root.eventTimes
	local expirationTimes = root.expirationTimes

	-- // Clear the lanes that no longer have pending work
	local lanes = noLongerPendingLanes
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		entanglements[index] = NoLanes
		eventTimes[index] = NoTimestamp
		expirationTimes[index] = NoTimestamp

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end
end
exports.markRootFinished = markRootFinished

local function markRootEntangled(root: FiberRoot, entangledLanes: Lanes)
	root.entangledLanes = bit32.bor(root.entangledLanes, entangledLanes)

	local entanglements = root.entanglements
	local lanes = entangledLanes
	while lanes > 0 do
		local index = pickArbitraryLaneIndex(lanes)
		local lane = bit32.lshift(1, index)

		entanglements[index] = bit32.bor(entanglements[index], entangledLanes)

		lanes = bit32.band(lanes, bit32.bnot(lane))
	end
end
exports.markRootEntangled = markRootEntangled

local function getBumpedLaneForHydration(root: FiberRoot, renderLanes: Lanes): Lane
	getHighestPriorityLanes(renderLanes)
	local highestLanePriority = return_highestLanePriority

	local lane

	if
		highestLanePriority == SyncLanePriority
		or highestLanePriority == SyncBatchedLanePriority
	then
		lane = NoLane
	elseif
		highestLanePriority == InputDiscreteHydrationLanePriority
		or highestLanePriority == InputDiscreteLanePriority
	then
		lane = InputDiscreteHydrationLane
	elseif
		highestLanePriority == InputContinuousHydrationLanePriority
		or highestLanePriority == InputContinuousLanePriority
	then
		lane = InputContinuousHydrationLane
	elseif
		highestLanePriority == DefaultHydrationLanePriority
		or highestLanePriority == DefaultLanePriority
	then
		lane = DefaultHydrationLane
	elseif
		highestLanePriority == TransitionHydrationPriority
		or highestLanePriority == TransitionPriority
	then
		lane = TransitionHydrationLane
	elseif highestLanePriority == RetryLanePriority then
		-- // Shouldn't be reachable under normal circumstances, so there's no
		-- // dedicated lane for retry priority. Use the one for long transitions.
		lane = TransitionHydrationLane
	elseif highestLanePriority == SelectiveHydrationLanePriority then
		lane = SelectiveHydrationLane
	elseif
		highestLanePriority == IdleHydrationLanePriority
		or highestLanePriority == IdleLanePriority
	then
		lane = IdleHydrationLane
	elseif
		highestLanePriority == OffscreenLanePriority
		or highestLanePriority == NoLanePriority
	then
		lane = NoLane
	else
		invariant(false, "Invalid lane: %s. This is a bug in React.", tostring(lane))
	end

	-- // Check if the lane we chose is suspended. If so, that indicates that we
	-- // already attempted and failed to hydrate at that level. Also check if we're
	-- // already rendering that lane, which is rare but could happen.
	if bit32.band(lane, bit32.bor(root.suspendedLanes, renderLanes)) ~= NoLane then
		-- // Give up trying to hydrate and fall back to client render.
		return NoLane
	end

	return lane
end
exports.getBumpedLaneForHydration = getBumpedLaneForHydration

return exports
