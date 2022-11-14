return function()
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	local ReactFiberStack

	describe("ReactFiberStack", function()
		beforeEach(function()
			RobloxJest.resetModules()
			ReactFiberStack = require(script.Parent.Parent["ReactFiberStack.new"])
		end)

		it("creates a cursor with the given default value", function()
			local defaultValue = { foo = 3 }
			jestExpect(ReactFiberStack.createCursor(defaultValue)).toEqual({
				current = defaultValue,
			})
		end)

		it("initializes the stack empty", function()
			jestExpect(ReactFiberStack.isEmpty()).toBe(true)
		end)

		describe("stack manipulations", function()
			local cursor
			local fiber

			beforeEach(function()
				cursor = ReactFiberStack.createCursor(nil)
				fiber = {}
			end)

			it("pushes an element and the stack is not empty", function()
				ReactFiberStack.push(cursor, true, fiber)
				jestExpect(ReactFiberStack.isEmpty()).toBe(false)
			end)

			it("pushes an element and assigns the value to the cursor", function()
				local pushedElement = { foo = 3 }
				ReactFiberStack.push(cursor, pushedElement, fiber)
				jestExpect(cursor.current).toEqual(pushedElement)
			end)

			it("pushes an element, pops it back and the stack is empty", function()
				ReactFiberStack.push(cursor, true, fiber)
				ReactFiberStack.pop(cursor, fiber)
				jestExpect(ReactFiberStack.isEmpty()).toBe(true)
			end)

			it(
				"pushes an element, pops it back and the cursor has its initial value",
				function()
					local initialCursorValue = "foo"
					cursor.current = initialCursorValue

					ReactFiberStack.push(cursor, true, fiber)
					ReactFiberStack.pop(cursor, fiber)
					jestExpect(cursor.current).toBe(initialCursorValue)
				end
			)
		end)
	end)
end
