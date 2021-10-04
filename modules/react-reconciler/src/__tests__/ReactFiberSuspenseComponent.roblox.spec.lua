return function()
	local Reconciler = script.Parent.Parent
	local Packages = script.Parent.Parent.Parent
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)

	local ReactFiberSuspenseComponent

	describe("ReactFiberSuspenseComponent", function()
		beforeEach(function()
			RobloxJest.resetModules()

			ReactFiberSuspenseComponent = require(Reconciler["ReactFiberSuspenseComponent.new"])
		end)

		describe("shouldCaptureSuspense", function()
			local shouldCaptureSuspense
			local fiber

			beforeEach(function()
				shouldCaptureSuspense = ReactFiberSuspenseComponent.shouldCaptureSuspense
				fiber = {
					memoizedState = nil,
					memoizedProps = {},
				}
			end)

			local function generateTest(expected, hasInvisibleParent, it)
				it = it or getfenv(2).it
				if hasInvisibleParent == nil then
					generateTest(expected, true, it)
					generateTest(expected, false, it)
				else
					local testName = ("is %s if it %s invisible parent"):format(
						tostring(expected),
						hasInvisibleParent and "does not have" or "has"
					)
					it(testName, function()
						jestExpect(
							shouldCaptureSuspense(fiber, hasInvisibleParent)
						).toBe(expected)
					end)
				end
			end

			describe("with a memoizedState", function()
				beforeEach(function()
					fiber.memoizedState = {dehydrated = nil}
				end)
				describe("memoizedState.dehydrated is not null", function()
					beforeEach(function()
						fiber.memoizedState.dehydrated = {}
					end)
					generateTest(true)
				end)

				describe("memoizedState.dehydrated is null", function()
					generateTest(false)
				end)
			end)

			describe("with no memoizedState", function()
				describe("without fallback prop", function()
					generateTest(false)
				end)

				describe("with fallback prop", function()
					beforeEach(function()
						fiber.memoizedProps.fallback = {}
					end)

					describe("without flag unstable_avoidThisFallback", function()
						generateTest(true)
					end)

					describe("with flag unstable_avoidThisFallback", function()
						beforeEach(function()
							fiber.memoizedProps.unstable_avoidThisFallback = true
						end)
						generateTest(false, true)
						generateTest(true, false)
					end)
				end)
			end)
		end)
	end)
end
