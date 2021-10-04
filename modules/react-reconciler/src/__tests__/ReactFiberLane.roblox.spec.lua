-- awaiting pull request: https://github.com/facebook/react/pull/20155
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
]]

return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Object = LuauPolyfill.Object

	local RobloxJest = require(Packages.Dev.RobloxJest)

	local ReactFiberSchedulerPriorities = require(script.Parent.Parent["ReactFiberSchedulerPriorities.roblox"])
	local ImmediatePriority = ReactFiberSchedulerPriorities.ImmediatePriority
	local NormalPriority = ReactFiberSchedulerPriorities.NormalPriority
	local NoPriority = ReactFiberSchedulerPriorities.NoPriority
	local UserBlockingPriority = ReactFiberSchedulerPriorities.UserBlockingPriority

	local ReactFiberLane

	beforeEach(function()
		RobloxJest.resetModules()
		ReactFiberLane = require(script.Parent.Parent.ReactFiberLane)
	end)

	describe("lanePriorityToSchedulerPriority", function()
		local INVALID_PRIORITY_LANE = 999

		local expectedPriorities = {
			SyncLanePriority = ImmediatePriority,
			SyncBatchedLanePriority = ImmediatePriority,
			InputDiscreteLanePriority = UserBlockingPriority,
			InputContinuousLanePriority = UserBlockingPriority,
			DefaultLanePriority = NormalPriority,
			TransitionPriority = NormalPriority,
			NoLanePriority = NoPriority,
		}

		for priorityName, priority in pairs(expectedPriorities) do
			it(("returns the expected priority (%d) for lane %s"):format(priority, priorityName), function()
				local lane = ReactFiberLane[priorityName]
				jestExpect(lane).toBeDefined()
				jestExpect(ReactFiberLane.lanePriorityToSchedulerPriority(lane)).toBe(
					priority
				)
			end)
		end

		it("throws when giving an invalid lane priority", function()
			jestExpect(function()
				ReactFiberLane.lanePriorityToSchedulerPriority(INVALID_PRIORITY_LANE)
			end).toThrow(
				("Invalid update priority: %s. This is a bug in React"):format(tostring(INVALID_PRIORITY_LANE))
			)
		end)
	end)

	describe("getHighestPriorityPendingLanes", function()
		it("returns the Sync lane and sets the sync lane priority", function()
			local root = { pendingLanes = ReactFiberLane.SyncLane }
			local lane = ReactFiberLane.getHighestPriorityPendingLanes(root)

			jestExpect(lane).toBe(ReactFiberLane.SyncLane)
			local nextLanesPriority = ReactFiberLane.returnNextLanesPriority()
			jestExpect(nextLanesPriority).toBe(ReactFiberLane.SyncLanePriority)
		end)
	end)

	describe('getNextLanes', function()
		describe('given no pending lanes', function()
			local root

			beforeEach(function()
				root = {pendingLanes = ReactFiberLane.NoLanes}
			end)

			it('returns no lanes', function()
				jestExpect(
					ReactFiberLane.getNextLanes(root, ReactFiberLane.NoLanes)
				).toBe(ReactFiberLane.NoLanes)
			end)

			it('sets the highest lane priority to no lane', function()
				ReactFiberLane.getNextLanes(root, ReactFiberLane.NoLanes)
				jestExpect(ReactFiberLane.returnNextLanesPriority()).toBe(
					ReactFiberLane.NoLanePriority
				)
			end)
		end)
		describe('given expired lanes', function()
			local root

			beforeEach(function()
				root = {
					pendingLanes = ReactFiberLane.SyncLane,
					expiredLanes = ReactFiberLane.SyncLane,
					suspendedLanes = ReactFiberLane.NoLanes,
					pingedLanes = ReactFiberLane.NoLanes,
					entangledLanes = ReactFiberLane.NoLanes,
				}
			end)

			describe('no entangled lanes', function()
				describe('pending lanes with higher priority than expired lanes', function()
					beforeEach(function()
						root = Object.assign(root, {
							pendingLanes = ReactFiberLane.mergeLanes(
								ReactFiberLane.SomeRetryLane,
								ReactFiberLane.DefaultHydrationLane
							),
							expiredLanes = ReactFiberLane.DefaultLanes,
						})
					end)

					it('returns the lanes above or equal to the priority of the expired lanes', function()
						local result = ReactFiberLane.getNextLanes(
							root,
							ReactFiberLane.NoLanes
						)
						jestExpect(result).toBe(ReactFiberLane.DefaultHydrationLane)
					end)

					it('sets the highest lane priority to sync lane', function()
						ReactFiberLane.getNextLanes(root, ReactFiberLane.NoLanes)
						jestExpect(ReactFiberLane.returnNextLanesPriority()).toBe(ReactFiberLane.SyncLanePriority)
					end)
				end)

				describe('pending lanes with lower priority than expired lanes', function()
					beforeEach(function()
						root = Object.assign(root, {
							pendingLanes = ReactFiberLane.SyncBatchedLane,
							expiredLanes = ReactFiberLane.SyncLane,
						})
					end)

					it('returns no lanes', function()
						local result = ReactFiberLane.getNextLanes(
							root,
							ReactFiberLane.NoLanes
						)
						jestExpect(result).toBe(ReactFiberLane.NoLanes)
					end)

					it('sets the highest lane priority to sync lane', function()
						ReactFiberLane.getNextLanes(root, ReactFiberLane.NoLanes)
						jestExpect(ReactFiberLane.returnNextLanesPriority()).toBe(
							ReactFiberLane.SyncLanePriority
						)
					end)
				end)
			end)

			it('sets the highest lane priority to sync lane', function()
				local result = ReactFiberLane.getNextLanes(
					root,
					ReactFiberLane.NoLanes
				)
				jestExpect(result).toBe(ReactFiberLane.SyncLane)
				jestExpect(ReactFiberLane.returnNextLanesPriority()).toBe(
					ReactFiberLane.SyncLanePriority
				)
			end)

			it('sets the highest lane priority to sync lane 2', function()
				root = Object.assign(root, {
					expiredLanes = ReactFiberLane.SyncBatchedLane,
				})
				local result = ReactFiberLane.getNextLanes(
					root,
					ReactFiberLane.NoLanes
				)

				jestExpect(result).toBe(ReactFiberLane.SyncLane)
				jestExpect(ReactFiberLane.returnNextLanesPriority()).toBe(
					ReactFiberLane.SyncLanePriority
				)
			end)
		end)
	end)

	describe("includesNonIdleWork", function()
		local nonIdleLaneNames = {
			"SyncLane",
			"SyncBatchedLane",
			"InputDiscreteHydrationLane",
			"DefaultHydrationLane",
			"SomeRetryLane",
			"SelectiveHydrationLane",
		}

		for _, laneName in ipairs(nonIdleLaneNames) do
			it(("is true for %s"):format(laneName), function()
				local lane = ReactFiberLane[laneName]

				jestExpect(lane).toBeDefined()
				jestExpect(ReactFiberLane.includesNonIdleWork(lane)).toBe(true)
			end)
		end

		local idleLaneNames = {
			"NoLane",
			"OffscreenLane",
			"IdleHydrationLane",
		}

		for _, laneName in ipairs(idleLaneNames) do
			it(("is false for %s"):format(laneName), function()
				local lane = ReactFiberLane[laneName]

				jestExpect(lane).toBeDefined()
				jestExpect(ReactFiberLane.includesNonIdleWork(lane)).toBe(false)
			end)
		end
	end)

	describe("includesOnlyRetries", function()
		it("is true for a retry lane", function()
			jestExpect(
				ReactFiberLane.includesOnlyRetries(ReactFiberLane.SomeRetryLane
			)).toBe(true)
		end)

		it("is false for the sync lane", function()
			jestExpect(
				ReactFiberLane.includesOnlyRetries(ReactFiberLane.SyncLane
			)).toBe(false)
		end)

		it("is false for a retry lane merged with another lane", function()
			local mergedLanes = ReactFiberLane.mergeLanes(
				ReactFiberLane.SyncLane,
				ReactFiberLane.SomeRetryLane
			)
			jestExpect(ReactFiberLane.includesOnlyRetries(mergedLanes)).toBe(false)
		end)
	end)

	describe("includesSomeLane", function()
		it("is true given the same lane", function()
			local lane = ReactFiberLane.SyncLane
			jestExpect(ReactFiberLane.includesSomeLane(lane, lane)).toBe(true)
		end)

		it("is true given lanes that includes the other", function()
			local lane = ReactFiberLane.SyncLane
			local mergedLanes = ReactFiberLane.mergeLanes(
				lane,
				ReactFiberLane.DefaultHydrationLane
			)

			jestExpect(ReactFiberLane.includesSomeLane(mergedLanes, lane)).toBe(true)
		end)

		it("is false for two seperate lanes", function()
			jestExpect(
				ReactFiberLane.includesSomeLane(
					ReactFiberLane.SyncLane,
					ReactFiberLane.DefaultHydrationLane
				)
			).toBe(false)
		end)
	end)

	describe("isSubsetOfLanes", function()
		it("is true given the same lane", function()
			local lane = ReactFiberLane.SyncLane

			jestExpect(ReactFiberLane.isSubsetOfLanes(lane, lane)).toBe(true)
		end)

		it("is true given lanes that includes the other", function()
			local subset = ReactFiberLane.mergeLanes(
				ReactFiberLane.SyncLane,
				ReactFiberLane.DefaultHydrationLane
			)
			local mergedLanes = ReactFiberLane.mergeLanes(
				subset,
				ReactFiberLane.SyncBatchedLane
			)

			jestExpect(ReactFiberLane.includesSomeLane(mergedLanes, subset)).toBe(true)
		end)

		it("is false for two seperate lanes", function()
			jestExpect(
				ReactFiberLane.includesSomeLane(
					ReactFiberLane.SyncLane,
					ReactFiberLane.DefaultHydrationLane
				)
			).toBe(false)
		end)
	end)

	describe("mergeLanes", function()
		it("returns a lane that includes both inputs", function()
			local laneA = ReactFiberLane.SyncLane
			local laneB = ReactFiberLane.DefaultHydrationLane
			local mergedLanes = ReactFiberLane.mergeLanes(laneA, laneB)

			jestExpect(ReactFiberLane.includesSomeLane(mergedLanes, laneA)).toBe(true)
			jestExpect(ReactFiberLane.includesSomeLane(mergedLanes, laneB)).toBe(true)
		end)

		it("returns the same lane given two identical lanes", function()
			local lane = ReactFiberLane.SyncLane
			jestExpect(ReactFiberLane.mergeLanes(lane, lane)).toBe(lane)
		end)
	end)

	describe("removeLanes", function()
		it("returns the lanes without the given lane", function()
			local laneA = ReactFiberLane.SyncLane
			local laneB = ReactFiberLane.DefaultHydrationLane
			local mergedLanes = ReactFiberLane.mergeLanes(laneA, laneB)

			jestExpect(ReactFiberLane.removeLanes(mergedLanes, laneA)).toBe(laneB)
			jestExpect(ReactFiberLane.removeLanes(mergedLanes, laneB)).toBe(laneA)
		end)

		it("returns the same lane when removing a lane not included", function()
			local lanes = ReactFiberLane.mergeLanes(
				ReactFiberLane.SyncLane,
				ReactFiberLane.DefaultHydrationLane
			)
			jestExpect(ReactFiberLane.removeLanes(lanes, ReactFiberLane.SyncBatchedLane)).toBe(lanes)
		end)
	end)

	describe("higherPriorityLane", function()
		it("returns the other lane if one is NoLane", function()
			local lane = ReactFiberLane.SyncLane

			jestExpect(
				ReactFiberLane.higherPriorityLane(ReactFiberLane.NoLane, lane)
			).toBe(lane)
			jestExpect(
				ReactFiberLane.higherPriorityLane(lane, ReactFiberLane.NoLane)
			).toBe(lane)
		end)

		it("returns the higher priority lane", function()
			local higherLane = ReactFiberLane.SyncLane
			local otherLane = ReactFiberLane.OffscreenLane
			jestExpect(
				ReactFiberLane.higherPriorityLane(higherLane, otherLane)
			).toBe(higherLane)
			jestExpect(
				ReactFiberLane.higherPriorityLane(otherLane, higherLane)
			).toBe(higherLane)
		end)
	end)

	describe("higherLanePriority", function()
		it("returns the other priority if one is NoLanePriority", function()
			local priority = ReactFiberLane.DefaultLanePriority
			jestExpect(
				ReactFiberLane.higherLanePriority(ReactFiberLane.NoLanePriority, priority)
			).toBe(priority)
			jestExpect(
				ReactFiberLane.higherLanePriority(priority, ReactFiberLane.NoLanePriority)
			).toBe(priority)
		end)

		it("returns the higher lane priority", function()
			local higherPriority = ReactFiberLane.SyncLanePriority
			local otherPriority = ReactFiberLane.TransitionPriority
			jestExpect(
				ReactFiberLane.higherLanePriority(higherPriority, otherPriority)
			).toBe(higherPriority)
			jestExpect(
				ReactFiberLane.higherLanePriority(otherPriority, higherPriority)
			).toBe(higherPriority)
		end)
	end)
end
