return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestRoblox).Globals.expect
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local ReactFiber = require(script.Parent.Parent["ReactFiber.new"])


	local ReactFiberSuspenseContext

	describe("ReactFiberSuspenseContext", function()
		beforeEach(function()
			RobloxJest.resetModules()
			ReactFiberSuspenseContext = require(script.Parent.Parent["ReactFiberSuspenseContext.new"])
		end)

		describe("suspense context stack", function()
			local someContext
			local fiber
			local suspenseStackCursor

			beforeEach(function()
				someContext = 0b1000
				fiber = ReactFiber.createFiberFromText("", 0, 0)
				suspenseStackCursor = ReactFiberSuspenseContext.suspenseStackCursor
			end)

			it("pushes the context and assigns the value to the cursor", function()
				ReactFiberSuspenseContext.pushSuspenseContext(fiber, someContext)
				jestExpect(suspenseStackCursor).toEqual({current = someContext})
			end)

			it("pushes and pops and sets the cursor to its initial value", function()
				local initialValue = suspenseStackCursor.current

				ReactFiberSuspenseContext.pushSuspenseContext(fiber, someContext)
				ReactFiberSuspenseContext.popSuspenseContext(fiber)
				jestExpect(suspenseStackCursor).toEqual({current = initialValue})
			end)
		end)

		describe("hasSuspenseContext", function()
			it("is true for parent context and its subtree context", function()
				local subtree = 0b1000
				local parent = ReactFiberSuspenseContext.addSubtreeSuspenseContext(10000, subtree)

				jestExpect(
					ReactFiberSuspenseContext.hasSuspenseContext(parent, subtree)
				).toBe(true)
			end)

			it("is false for two different context", function()
				jestExpect(
					ReactFiberSuspenseContext.hasSuspenseContext(0b1000, 0b10000)
				).toBe(false)
			end)
		end)
	end)
end
