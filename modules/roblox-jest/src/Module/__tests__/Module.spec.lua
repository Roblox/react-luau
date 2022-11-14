return function()
	local Module = require(script.Parent.Parent)
	local Packages = script.Parent.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect

	beforeEach(function()
		Module.resetModules()
	end)

	afterEach(function()
		Module.unmock(script.Parent.TestScripts.add)
	end)

	it("should always use the real require for itself", function()
		local Module1 = Module.requireOverride(script.Parent.Parent)
		Module.resetModules()
		local Module2 = Module.requireOverride(script.Parent.Parent)
		jestExpect(Module1).toBe(Module2)
	end)

	describe("Module Cache", function()
		it("should return a cached module when nothing has been reset", function()
			local add1 = Module.requireOverride(script.Parent.TestScripts.add)
			local add2 = Module.requireOverride(script.Parent.TestScripts.add)
			jestExpect(add1).toBe(add2)
		end)

		it("should clear any top-level module state", function()
			local Incrementor =
				Module.requireOverride(script.Parent.TestScripts.Incrementor)
			jestExpect(Incrementor.get()).toBe(0)
			Incrementor.increment()
			jestExpect(Incrementor.get()).toBe(1)

			Module.resetModules()
			Incrementor = Module.requireOverride(script.Parent.TestScripts.Incrementor)

			jestExpect(Incrementor.get()).toBe(0)
		end)

		it("should clear transitive module requirements", function()
			local Incrementor =
				Module.requireOverride(script.Parent.TestScripts.Incrementor)
			local getIncrementorValue =
				Module.requireOverride(script.Parent.TestScripts.getIncrementorValue)
			jestExpect(getIncrementorValue()).toBe(0)
			Incrementor.increment()
			Incrementor.increment()
			jestExpect(getIncrementorValue()).toBe(2)

			-- Reset will reset the Incrementor's state before the
			-- getIncrementorValue script requires it again
			Module.resetModules()
			getIncrementorValue =
				Module.requireOverride(script.Parent.TestScripts.getIncrementorValue)

			jestExpect(getIncrementorValue()).toBe(0)
		end)

		it("should not clear mocks when resetting modules", function()
			Module.mock(script.Parent.TestScripts.add, function()
				return math.min
			end)
			local addMocked = Module.requireOverride(script.Parent.TestScripts.add)

			Module.resetModules()
			local addAfterReset = Module.requireOverride(script.Parent.TestScripts.add)

			jestExpect(addMocked).toBe(addAfterReset)
		end)
	end)

	describe("Mock behavior", function()
		it("should be replace an existing module with a mock", function()
			local addUnmocked = Module.requireOverride(script.Parent.TestScripts.add)

			local mockValue = function(_a, _b)
				-- print(a, b)
			end
			Module.mock(script.Parent.TestScripts.add, function()
				return mockValue
			end)
			local addMocked = Module.requireOverride(script.Parent.TestScripts.add)

			jestExpect(addUnmocked).never.toBe(addMocked)
			jestExpect(addMocked).toBe(mockValue)
		end)

		it("should allow a mock implementation to replace a real one", function()
			local addUnmocked = Module.requireOverride(script.Parent.TestScripts.add)
			jestExpect(addUnmocked(10, 4)).toBe(14)

			Module.mock(script.Parent.TestScripts.add, function()
				return function(a, b)
					-- replace functionality with subtraction!
					return a - b
				end
			end)
			local addMocked = Module.requireOverride(script.Parent.TestScripts.add)

			jestExpect(addMocked(10, 4)).toBe(6)
		end)

		it("should work with mocking transitive requires", function()
			Module.mock(script.Parent.TestScripts.add, function()
				return function(a, b)
					-- replace functionality with multiplication!
					return a * b
				end
			end)
			-- addFour requires add, which we did not required directly
			-- ourselves
			local addFourMocked =
				Module.requireOverride(script.Parent.TestScripts.addFour)

			jestExpect(addFourMocked(10)).toBe(40)
		end)

		it("should restore the original module if requiring after unmocking", function()
			Module.mock(script.Parent.TestScripts.add, function()
				return function(a, b)
					-- replace functionality with division!
					return a / b
				end
			end)
			local add = Module.requireOverride(script.Parent.TestScripts.add)

			jestExpect(add(10, 4)).toBe(2.5)

			Module.unmock(script.Parent.TestScripts.add)
			add = Module.requireOverride(script.Parent.TestScripts.add)
			jestExpect(add(10, 4)).toBe(14)
		end)
	end)
end
