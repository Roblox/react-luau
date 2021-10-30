--[[*
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	local RobloxJest = require(Packages.Dev.RobloxJest)
	local React = require(Packages.React)

	local ReactUpdateQueue, Fiber, FiberLane
	local fundamentalFiber, component, update, lane, setStateCallbackWasCalled, workInProgress

	local updateTime = 0
	local nextProps = { userName = 'Dan' }
	local updatePayload = { myVariable = 90210 }

	beforeEach(function()
		RobloxJest.resetModules()

		ReactUpdateQueue = require(script.Parent.Parent["ReactUpdateQueue.new"])
		Fiber = require(script.Parent.Parent["ReactFiber.new"])
		FiberLane = require(script.Parent.Parent.ReactFiberLane)

		component = React.Component:extend("fundamental")
		fundamentalFiber = Fiber.createFiberFromFundamental(component)

		lane = FiberLane.NoLane
		update = ReactUpdateQueue.createUpdate(updateTime, lane)
		setStateCallbackWasCalled = false
		update.payload = updatePayload
		update.callback = function()
		  setStateCallbackWasCalled = true
		end
		update.lane = lane
	end)

	describe("new ReactUpdateQueue", function()
		it("does not have force update", function()
			jestExpect(
				ReactUpdateQueue.checkHasForceUpdateAfterProcessing()
			).toEqual(false)
		end)

		it("enqueue before initialize is a no-op", function()
			workInProgress = Fiber.createWorkInProgress(fundamentalFiber, {})
			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			jestExpect(workInProgress.updateQueue).toEqual(nil)
		end)
	end)

	describe("initialized ReactUpdateQueue", function()
		beforeEach(function()
			ReactUpdateQueue.initializeUpdateQueue(workInProgress)
		end)

		it("initializes fiber", function()
			jestExpect(workInProgress.updateQueue).toBeDefined()
		end)

		it("enqueues first update", function()
			jestExpect(update.tag).toBe(0)

			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			jestExpect(update.next).toBe(update)
			jestExpect(workInProgress.updateQueue.shared.pending).toBe(update)
		end)

		it("enqueues same update twice", function()
			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			ReactUpdateQueue.enqueueUpdate(workInProgress, update)

			jestExpect(update.next).toBe(update)
			jestExpect(update.next.next).toBe(update)
			jestExpect(workInProgress.updateQueue.shared.pending).toBe(update)
		end)
	end)

	describe("processUpdateQueue", function()
		beforeEach(function()
			ReactUpdateQueue.initializeUpdateQueue(fundamentalFiber)
			workInProgress = Fiber.createWorkInProgress(fundamentalFiber, nextProps)
		end)

		it("with empty queue", function()
			ReactUpdateQueue.processUpdateQueue(
				workInProgress,
				nextProps,
				component,
				FiberLane.NoLanes
			  )

			jestExpect(workInProgress.memoizedState).toBe(nil)
		end)

		it("with non-empty queue", function()
			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			jestExpect(workInProgress.memoizedState).toBe(nil)

			ReactUpdateQueue.processUpdateQueue(
			  workInProgress,
			  nextProps,
			  component,
			  FiberLane.NoLanes
			)

			jestExpect(setStateCallbackWasCalled).toBe(false)
			jestExpect(workInProgress.memoizedState).toEqual(updatePayload)
		end)
	end)

	describe("commitUpdateQueue", function()
		beforeEach(function()
			lane = FiberLane.SomeRetryLane
			update = ReactUpdateQueue.createUpdate(updateTime, lane)
			setStateCallbackWasCalled = false
			update.payload = updatePayload
			update.callback = function()
			  setStateCallbackWasCalled = true
			end
			update.lane = lane
			ReactUpdateQueue.initializeUpdateQueue(fundamentalFiber)
			workInProgress = Fiber.createWorkInProgress(fundamentalFiber, nextProps)
		end)

		it("with non-empty queue", function()
			-- our update is Retry, since NoLane means the callback was already committed
			ReactUpdateQueue.enqueueUpdate(workInProgress, update)
			jestExpect(workInProgress.memoizedState).toBe(nil)

			-- we use RetryLanes here because the update lane needs to be a subset of that
			ReactUpdateQueue.processUpdateQueue(
			  workInProgress,
			  nextProps,
			  component,
			  FiberLane.RetryLanes
			)
			jestExpect(fundamentalFiber.updateQueue.effects).never.toBe(nil)

			ReactUpdateQueue.commitUpdateQueue(
			  workInProgress,
			  fundamentalFiber.updateQueue,
			  component
			)

			jestExpect(setStateCallbackWasCalled).toBe(true)
		end)
	end)

	describe("enqueueCapturedUpdate", function()
		beforeEach(function()
			lane = FiberLane.NoLane
			update = ReactUpdateQueue.createUpdate(updateTime, lane)
			update.tag = ReactUpdateQueue.CaptureUpdate
			update.lane = lane
			ReactUpdateQueue.initializeUpdateQueue(fundamentalFiber)
			workInProgress = Fiber.createWorkInProgress(fundamentalFiber, nextProps)
			local ReactFiberFlags = require(script.Parent.Parent.ReactFiberFlags)
			workInProgress.flags = bit32.bor(0, ReactFiberFlags.ShouldCapture)
		end)

		it("sets lastBaseUpdate", function()
			ReactUpdateQueue.enqueueCapturedUpdate(workInProgress, update)

			jestExpect(workInProgress.updateQueue.lastBaseUpdate).toEqual(update)
		end)
	end)

end
