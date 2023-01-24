-- ROBLOX upstream: https://github.com/facebook/react/blob/9abc2785cb070148d64fae81e523246b90b92016/packages/scheduler/src/Scheduler.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
]]

-- ROBLOX deviation: return an initializer function instead of the module itself
-- for easier dependency injection with unstable_mock
return function(hostConfig)
	local Packages = script.Parent.Parent
	local describeError = require(Packages.Shared).describeError

	local SchedulerFeatureFlags = require(script.Parent.SchedulerFeatureFlags)
	local enableSchedulerDebugging = SchedulerFeatureFlags.enableSchedulerDebugging
	local enableProfiling = SchedulerFeatureFlags.enableProfiling

	local SchedulerHostConfig = hostConfig or require(script.Parent.SchedulerHostConfig)
	local requestHostCallback = SchedulerHostConfig.requestHostCallback
	local requestHostTimeout = SchedulerHostConfig.requestHostTimeout
	local cancelHostTimeout = SchedulerHostConfig.cancelHostTimeout
	local shouldYieldToHost = SchedulerHostConfig.shouldYieldToHost
	local getCurrentTime = SchedulerHostConfig.getCurrentTime
	local forceFrameRate = SchedulerHostConfig.forceFrameRate
	local requestPaint = SchedulerHostConfig.requestPaint

	-- ROBLOX deviation? inline the MinHeap to see if the module-level visibility lets Luau optimize better
	-- local SchedulerMinHeap = require(script.Parent.SchedulerMinHeap)
	-- local push = SchedulerMinHeap.push
	-- local peek = SchedulerMinHeap.peek
	-- local pop = SchedulerMinHeap.pop
	type Heap = { [number]: Node? }
	type Node = {
		id: number,
		sortIndex: number,
	}

	-- ROBLOX deviation: This file contains several workarounds for Luau analysis issues by using the `::` operator
	local compare, siftUp, siftDown

	local push = function(heap: Heap, node: Node): ()
		local index = #heap + 1
		heap[index] = node

		siftUp(heap, node, index)
	end

	local peek = function(heap: Heap): Node?
		return heap[1]
	end

	local pop = function(heap: Heap): Node?
		local first = heap[1]
		if first ~= nil then
			local last = heap[#heap]
			heap[#heap] = nil

			if last :: Node ~= first :: Node then
				heap[1] = last
				siftDown(heap, last :: Node, 1)
			end
			return first
		else
			return nil
		end
	end

	siftUp = function(heap: Heap, node: Node, index: number): ()
		while true do
			local parentIndex = math.floor(index / 2)
			local parent = heap[parentIndex]
			if parent ~= nil and compare(parent :: Node, node :: Node) > 0 then
				-- The parent is larger. Swap positions.
				heap[parentIndex] = node
				heap[index] = parent
				index = parentIndex
			else
				-- The parent is smaller. Exit.
				return
			end
		end
	end

	siftDown = function(heap: Heap, node: Node, index: number): ()
		local length = #heap
		while index < length do
			local leftIndex = index * 2
			local left = heap[leftIndex]
			local rightIndex = leftIndex + 1
			local right = heap[rightIndex]

			-- If the left or right node is smaller, swap with the smaller of those.
			if left ~= nil and compare(left :: Node, node) < 0 then
				if right ~= nil and compare(right :: Node, left :: Node) < 0 then
					heap[index] = right
					heap[rightIndex] = node
					index = rightIndex
				else
					heap[index] = left
					heap[leftIndex] = node
					index = leftIndex
				end
			elseif right ~= nil and compare(right :: Node, node :: Node) < 0 then
				heap[index] = right
				heap[rightIndex] = node
				index = rightIndex
			else
				-- Neither child is smaller. Exit.
				return
			end
		end
	end

	compare = function(a: Node, b: Node): number
		-- Compare sort index first, then task id.
		local diff = a.sortIndex - b.sortIndex

		if diff == 0 then
			return a.id - b.id
		end

		return diff
	end

	-- TODO: Use symbols?
	local SchedulerPriorities = require(script.Parent.SchedulerPriorities)
	local ImmediatePriority = SchedulerPriorities.ImmediatePriority
	local UserBlockingPriority = SchedulerPriorities.UserBlockingPriority
	local NormalPriority = SchedulerPriorities.NormalPriority
	local LowPriority = SchedulerPriorities.LowPriority
	local IdlePriority = SchedulerPriorities.IdlePriority

	local SchedulerProfiling = require(script.Parent.SchedulerProfiling)
	local markTaskRun = SchedulerProfiling.markTaskRun
	local markTaskYield = SchedulerProfiling.markTaskYield
	local markTaskCompleted = SchedulerProfiling.markTaskCompleted
	local markTaskCanceled = SchedulerProfiling.markTaskCanceled
	local markTaskErrored = SchedulerProfiling.markTaskErrored
	local markSchedulerSuspended = SchedulerProfiling.markSchedulerSuspended
	local markSchedulerUnsuspended = SchedulerProfiling.markSchedulerUnsuspended
	local markTaskStart = SchedulerProfiling.markTaskStart
	local stopLoggingProfilingEvents = SchedulerProfiling.stopLoggingProfilingEvents
	local startLoggingProfilingEvents = SchedulerProfiling.startLoggingProfilingEvents

	-- Max 31 bit integer. The max integer size in V8 for 32-bit systems.
	-- Math.pow(2, 30) - 1
	-- 0b111111111111111111111111111111
	local maxSigned31BitInt = 1073741823

	-- Times out immediately
	local IMMEDIATE_PRIORITY_TIMEOUT = -1
	-- Eventually times out
	local USER_BLOCKING_PRIORITY_TIMEOUT = 250
	local NORMAL_PRIORITY_TIMEOUT = 5000
	local LOW_PRIORITY_TIMEOUT = 10000
	-- Never times out
	local IDLE_PRIORITY_TIMEOUT = maxSigned31BitInt

	-- Tasks are stored on a min heap
	local taskQueue = {}
	local timerQueue = {}

	-- Incrementing id counter. Used to maintain insertion order.
	local taskIdCounter = 1

	-- Pausing the scheduler is useful for debugging.
	local isSchedulerPaused = false

	local currentTask = nil
	local currentPriorityLevel = NormalPriority

	-- This is set while performing work, to prevent re-entrancy.
	local isPerformingWork = false

	local isHostCallbackScheduled = false
	local isHostTimeoutScheduled = false

	-- deviation: Preemptively declare these functions so that Lua understands them
	local handleTimeout, flushWork, workLoop

	local function advanceTimers(currentTime)
		-- Check for tasks that are no longer delayed and add them to the queue.
		local timer = peek(timerQueue)

		while timer ~= nil do
			if timer.callback == nil then
				-- Timer was cancelled, remove from queue
				pop(timerQueue)
			elseif timer.startTime <= currentTime then
				-- Timer fired. Transfer to the task queue.
				pop(timerQueue)
				timer.sortIndex = timer.expirationTime
				push(taskQueue, timer)
				if enableProfiling then
					markTaskStart(timer, currentTime)
					timer.isQueued = true
				end
			else
				-- Remaining timers are pending.
				return
			end

			timer = peek(timerQueue)
		end
	end

	handleTimeout = function(currentTime)
		isHostTimeoutScheduled = false
		advanceTimers(currentTime)

		if not isHostCallbackScheduled then
			if peek(taskQueue) ~= nil then
				isHostCallbackScheduled = true
				requestHostCallback(flushWork)
			else
				local firstTimer = peek(timerQueue)
				if firstTimer ~= nil then
					requestHostTimeout(handleTimeout, firstTimer.startTime - currentTime)
				end
			end
		end
	end

	flushWork = function(hasTimeRemaining, initialTime)
		if enableProfiling then
			markSchedulerUnsuspended(initialTime)
		end

		-- We'll need a host callback the next time work is scheduled.
		isHostCallbackScheduled = false
		if isHostTimeoutScheduled then
			-- We scheduled a timeout but it's no longer needed. Cancel it.
			isHostTimeoutScheduled = false
			cancelHostTimeout()
		end

		isPerformingWork = true
		local previousPriorityLevel = currentPriorityLevel

		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not _G.__YOLO__ then
			-- ROBLOX performance: don't nest try/catch here, Lua can do better, and it eliminated an anon function creation
			if enableProfiling then
				ok, result =
					xpcall(workLoop, describeError, hasTimeRemaining, initialTime)

				if not ok then
					if currentTask ~= nil then
						local currentTime = getCurrentTime()
						markTaskErrored(currentTask, currentTime)
						currentTask.isQueued = false
					end
				end
			else
				-- No catch in prod code path.
				ok = true
				result = workLoop(hasTimeRemaining, initialTime)
			end
		else
			ok = true
			result = workLoop(hasTimeRemaining, initialTime)
		end

		-- ROBLOX: finally
		currentTask = nil
		currentPriorityLevel = previousPriorityLevel
		isPerformingWork = false
		if enableProfiling then
			local currentTime = getCurrentTime()
			markSchedulerSuspended(currentTime)
		end

		if not ok then
			error(result)
		end

		return result
	end

	workLoop = function(hasTimeRemaining, initialTime)
		local currentTime = initialTime
		advanceTimers(currentTime)
		currentTask = peek(taskQueue)
		while
			currentTask ~= nil and not (enableSchedulerDebugging and isSchedulerPaused)
		do
			if
				currentTask.expirationTime > currentTime
				and (not hasTimeRemaining or shouldYieldToHost())
			then
				-- This currentTask hasn't expired, and we've reached the deadline.
				break
			end

			local callback = currentTask.callback
			if typeof(callback) == "function" then
				currentTask.callback = nil
				currentPriorityLevel = currentTask.priorityLevel
				local didUserCallbackTimeout = currentTask.expirationTime <= currentTime
				markTaskRun(currentTask, currentTime)
				local continuationCallback = callback(didUserCallbackTimeout)
				currentTime = getCurrentTime()
				if typeof(continuationCallback) == "function" then
					currentTask.callback = continuationCallback
					markTaskYield(currentTask, currentTime)
				else
					if enableProfiling then
						markTaskCompleted(currentTask, currentTime)
						currentTask.isQueued = false
					end

					if currentTask == peek(taskQueue) then
						pop(taskQueue)
					end
				end
				advanceTimers(currentTime)
			else
				pop(taskQueue)
			end

			currentTask = peek(taskQueue)
		end

		-- Return whether there's additional work
		if currentTask ~= nil then
			return true
		else
			local firstTimer = peek(timerQueue)
			if firstTimer ~= nil then
				requestHostTimeout(handleTimeout, firstTimer.startTime - currentTime)
			end

			return false
		end
	end

	local function unstable_runWithPriority(priorityLevel, eventHandler)
		if
			priorityLevel == ImmediatePriority
			or priorityLevel == UserBlockingPriority
			or priorityLevel == NormalPriority
			or priorityLevel == LowPriority
			or priorityLevel == IdlePriority
		then
			-- Leave priority alone if assigned
		else
			priorityLevel = NormalPriority
		end

		local previousPriorityLevel = currentPriorityLevel
		currentPriorityLevel = priorityLevel

		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not _G.__YOLO__ then
			ok, result = xpcall(eventHandler, describeError)
		else
			ok = true
			result = eventHandler()
		end

		-- ROBLOX: finally
		currentPriorityLevel = previousPriorityLevel

		if not ok then
			error(result)
		end

		return result
	end

	local function unstable_next(eventHandler)
		local priorityLevel
		if
			currentPriorityLevel == ImmediatePriority
			or currentPriorityLevel == UserBlockingPriority
			or currentPriorityLevel == NormalPriority
		then
			-- Shift down to normal priority
			priorityLevel = NormalPriority
		else
			-- Anything lower than normal priority should remain at the current level.
			priorityLevel = currentPriorityLevel
		end

		local previousPriorityLevel = currentPriorityLevel
		currentPriorityLevel = priorityLevel

		-- ROBLOX deviation: YOLO flag for disabling pcall
		local ok, result
		if not _G.__YOLO__ then
			ok, result = xpcall(eventHandler, describeError)
		else
			ok = true
			result = eventHandler()
		end

		-- ROBLOX: finally
		currentPriorityLevel = previousPriorityLevel

		if not ok then
			error(result)
		end

		return result
	end

	local function unstable_wrapCallback(callback)
		local parentPriorityLevel = currentPriorityLevel

		return function(...)
			-- This is a fork of runWithPriority, inlined for performance.
			local previousPriorityLevel = currentPriorityLevel
			currentPriorityLevel = parentPriorityLevel

			-- ROBLOX deviation: YOLO flag for disabling pcall
			local ok, result
			if not _G.__YOLO__ then
				ok, result = xpcall(callback, describeError, ...)
			else
				ok = true
				result = callback(...)
			end

			-- ROBLOX: finally
			currentPriorityLevel = previousPriorityLevel

			if not ok then
				error(result)
			end

			return result
		end
	end

	local function unstable_scheduleCallback(priorityLevel, callback, options)
		local currentTime = getCurrentTime()

		local startTime

		if typeof(options) == "table" then
			local delay_ = options.delay
			if typeof(delay_) == "number" and delay_ > 0 then
				startTime = currentTime + delay_
			else
				startTime = currentTime
			end
		else
			startTime = currentTime
		end

		local timeout
		if priorityLevel == ImmediatePriority then
			timeout = IMMEDIATE_PRIORITY_TIMEOUT
		elseif priorityLevel == UserBlockingPriority then
			timeout = USER_BLOCKING_PRIORITY_TIMEOUT
		elseif priorityLevel == IdlePriority then
			timeout = IDLE_PRIORITY_TIMEOUT
		elseif priorityLevel == LowPriority then
			timeout = LOW_PRIORITY_TIMEOUT
		else
			timeout = NORMAL_PRIORITY_TIMEOUT
		end

		local expirationTime = startTime + timeout

		local newTask = {
			id = taskIdCounter,
			callback = callback,
			priorityLevel = priorityLevel,
			startTime = startTime,
			expirationTime = expirationTime,
			sortIndex = -1,
		}
		taskIdCounter += 1

		if enableProfiling then
			newTask.isQueued = false
		end

		if startTime > currentTime then
			-- This is a delayed task.
			newTask.sortIndex = startTime
			push(timerQueue, newTask)
			-- TODO(align): VALIDATE conversion from `peek(taskQueue) === null && newTask === peek(timerQueue)`
			if #taskQueue == 0 and newTask == peek(timerQueue) then
				-- All tasks are delayed, and this is the task with the earliest delay.
				if isHostTimeoutScheduled then
					-- Cancel an existing timeout.
					cancelHostTimeout()
				else
					isHostTimeoutScheduled = true
				end
				-- Schedule a timeout.
				requestHostTimeout(handleTimeout, startTime - currentTime)
			end
		else
			newTask.sortIndex = expirationTime
			push(taskQueue, newTask)
			if enableProfiling then
				markTaskStart(newTask, currentTime)
				newTask.isQueued = true
			end

			-- Schedule a host callback, if needed. If we're already performing work,
			-- wait until the next time we yield.
			if not isHostCallbackScheduled and not isPerformingWork then
				isHostCallbackScheduled = true
				requestHostCallback(flushWork)
			end
		end

		return newTask
	end

	local function unstable_pauseExecution()
		isSchedulerPaused = true
	end

	local function unstable_continueExecution()
		isSchedulerPaused = false
		if not isHostCallbackScheduled and not isPerformingWork then
			isHostCallbackScheduled = true
			requestHostCallback(flushWork)
		end
	end

	local function unstable_getFirstCallbackNode()
		return peek(taskQueue)
	end

	local function unstable_cancelCallback(task)
		if enableProfiling then
			if task.isQueued then
				local currentTime = getCurrentTime()
				markTaskCanceled(task, currentTime)
				task.isQueued = false
			end
		end

		-- Null out the callback to indicate the task has been canceled. (Can't
		-- remove from the queue because you can't remove arbitrary nodes from an
		-- array based heap, only the first one.)
		task.callback = nil
	end

	local function unstable_getCurrentPriorityLevel()
		return currentPriorityLevel
	end

	local unstable_requestPaint = requestPaint

	return {
		unstable_ImmediatePriority = ImmediatePriority,
		unstable_UserBlockingPriority = UserBlockingPriority,
		unstable_NormalPriority = NormalPriority,
		unstable_IdlePriority = IdlePriority,
		unstable_LowPriority = LowPriority,
		unstable_runWithPriority = unstable_runWithPriority,
		unstable_next = unstable_next,
		unstable_scheduleCallback = unstable_scheduleCallback,
		unstable_cancelCallback = unstable_cancelCallback,
		unstable_wrapCallback = unstable_wrapCallback,
		unstable_getCurrentPriorityLevel = unstable_getCurrentPriorityLevel,
		unstable_shouldYield = shouldYieldToHost,
		unstable_requestPaint = unstable_requestPaint,
		unstable_continueExecution = unstable_continueExecution,
		unstable_pauseExecution = unstable_pauseExecution,
		unstable_getFirstCallbackNode = unstable_getFirstCallbackNode,
		unstable_now = getCurrentTime,
		unstable_forceFrameRate = forceFrameRate,
		-- ROBLOX TODO: use if-expressions when all clients are on 503+
		unstable_Profiling = (function()
			if enableProfiling then
				return {
					startLoggingProfilingEvents = startLoggingProfilingEvents,
					stopLoggingProfilingEvents = stopLoggingProfilingEvents,
				}
			end
			return nil
		end)(),
	}
end
