-- Mimicking https://github.com/facebook/jest/blob/4453901c0239939cc2c1c8b7c7d121447f6f5f52/packages/jest-fake-timers/src/legacyFakeTimers.ts#L506

type Timer = {
	expiry: number,
	callback: () -> (),
}

local realDelay = delay
local realTick = tick

local timers: { [number]: Timer } = {}
local now = 0

local function reset()
	timers = {}
	now = 0
end

local function runAllTimers()
	for _, timer in pairs(timers) do
		-- Move now to target time, in case the callback reads it via
		-- `tick`
		now = timer.expiry
		timer.callback()
	end

	timers = {}
end

local function mockDelay(_, delayTime, callback)
	local newExpiry = now + delayTime
	local timer = {
		expiry = newExpiry,
		callback = callback,
	}
	local insertIndex = 1
	while insertIndex <= #timers do
		-- Timers are inserted in time order. As soon as we encounter a
		-- expiry that's _after_ our newExpiry, we place ours in the list
		-- immediately before it. This way, timeouts with the exact same time
		-- will be queued up in insertion order to break ties
		if timers[insertIndex].expiry > newExpiry then
			break
		end
		insertIndex += 1
	end

	table.insert(timers, insertIndex, timer)
end

local function mockTick(_)
	return now
end

function round(number, decimals)
    local power = 10 ^ decimals
    return math.floor(number * power) / power
end

local function advanceTimersByTime(msToRun: number): ()
	-- Only run a generous number of timers and then bail.
	-- This is just to help avoid recursive loops
	-- ROBLOX TODO: this needs to match the conversion in the setTimeout polyfill for now
	local secondsToRun = msToRun / 1000
	local i = 0
	while i < 100000 do
		i += 1
		-- If there are no more timers handles, stop!
		if #timers == 0 then
			-- If we run out of timers, we still need to finish advancing the
			-- time the rest of the way
			now += secondsToRun
			break
		end

		local nextTimerExpiry = timers[1].expiry

		if round(now + secondsToRun, 5) < round(nextTimerExpiry, 5) then
			-- There are no timers between now and the target we're running to, so
			-- adjust our time cursor and quit
			now += secondsToRun
			break
		else
			secondsToRun -= nextTimerExpiry - now
			now = nextTimerExpiry
			local callback = timers[1].callback
			table.remove(timers, 1)
			callback()
		end
	end
	if i == 100000 then
		error(
			"Ran 100000"
				.. " timers, and there are still more! "
				.. "Assuming we've hit an infinite recursion and bailing out..."
		)
	end
end

local delayOverride = {}
delayOverride.__call = realDelay

local tickOverride = {}
tickOverride.__call = realTick

local function useFakeTimers()
	reset()
	delayOverride.__call = mockDelay
	tickOverride.__call = mockTick
end

local function useRealTimers()
	delayOverride.__call = realDelay
	tickOverride.__call = realTick
end

local function getTimerCount(): number
	return #timers
end

return {
	delayOverride = setmetatable({}, delayOverride),
	tickOverride = setmetatable({}, tickOverride),
	runAllTimers = runAllTimers,
	useFakeTimers = useFakeTimers,
	useRealTimers = useRealTimers,
	advanceTimersByTime = advanceTimersByTime,
	getTimerCount = getTimerCount,
	reset = reset,
	now = function() return now end
}
