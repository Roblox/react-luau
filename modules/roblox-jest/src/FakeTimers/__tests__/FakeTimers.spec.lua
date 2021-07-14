local Packages = script.Parent.Parent.Parent.Parent
local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect

return function()
	-- ROBLOX FIXME: remove :: any once CLI understands call metamethods, JIRA ticket CLI-40294
	local FakeTimers = require(script.Parent.Parent) :: any

	beforeEach(function()
		FakeTimers.useFakeTimers()
		FakeTimers.reset()
	end)

	describe("advanceTimersByTime", function()
		it("one timer advances", function()
			local log = {}
			-- add timer
			FakeTimers.delayOverride(0.1, function()
				table.insert(log, "timer callback")
			end)

			-- advance timers but not beyond timer expiry
			FakeTimers.advanceTimersByTime(50)
			jestExpect(FakeTimers.tickOverride()).toEqual(0.05)
			jestExpect(log).toEqual({})

			-- advance timers to exactly timer expiry
			FakeTimers.advanceTimersByTime(50)
			jestExpect(FakeTimers.tickOverride()).toEqual(0.1)
			jestExpect(log).toEqual({ "timer callback" })

			-- reset log
			log = {}

			-- ensure timer isn't triggered again
			FakeTimers.advanceTimersByTime(10000)
			jestExpect(log).toEqual({})
		end)
		it("multiple timers advance", function()
			local log = {}

			-- add timers
			FakeTimers.delayOverride(0.1, function()
				table.insert(log, "timer 1 callback")
			end)
			FakeTimers.delayOverride(0.1, function()
				table.insert(log, "timer 2 callback")
			end)
			FakeTimers.delayOverride(0.104, function()
				table.insert(log, "timer 3 callback")
			end)
			FakeTimers.delayOverride(0.05, function()
				table.insert(log, "timer 4 callback")
			end)
			FakeTimers.delayOverride(0.3, function()
				table.insert(log, "timer 5 callback")
			end)

			jestExpect(FakeTimers.getTimerCount()).toEqual(5)

			-- advance timers passed timer 4 expiry
			FakeTimers.advanceTimersByTime(70)
			jestExpect(log).toEqual({ "timer 4 callback" })

			-- advance timers passed timer 1 and 2 expiry
			FakeTimers.advanceTimersByTime(31)
			jestExpect(log).toEqual({
				"timer 4 callback",
				"timer 1 callback",
				"timer 2 callback",
			})

			-- advance timers passed rest of expiries
			FakeTimers.advanceTimersByTime(1000)
			jestExpect(log).toEqual({
				"timer 4 callback",
				"timer 1 callback",
				"timer 2 callback",
				"timer 3 callback",
				"timer 5 callback",
			})

			jestExpect(FakeTimers.getTimerCount()).toEqual(0)
		end)
	end)
end
