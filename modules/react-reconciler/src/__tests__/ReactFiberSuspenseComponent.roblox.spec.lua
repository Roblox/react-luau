local Reconciler = script.Parent.Parent
local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local it = JestGlobals.it

local ReactFiberSuspenseComponent

describe("ReactFiberSuspenseComponent", function()
	beforeEach(function()
		jest.resetModules()

		ReactFiberSuspenseComponent =
			require(Reconciler["ReactFiberSuspenseComponent.new"])
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

		local function generateTest(expected, hasInvisibleParent)
			if hasInvisibleParent == nil then
				generateTest(expected, true)
				generateTest(expected, false)
			else
				local testName = string.format(
					"is %s if it %s invisible parent",
					tostring(expected),
					hasInvisibleParent and "does not have" or "has"
				)
				it(testName, function()
					jestExpect(shouldCaptureSuspense(fiber, hasInvisibleParent)).toBe(
						expected
					)
				end)
			end
		end

		describe("with a memoizedState", function()
			beforeEach(function()
				fiber.memoizedState = { dehydrated = nil }
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
