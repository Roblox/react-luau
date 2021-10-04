local React
local ReactTestRenderer
local Scheduler
local act
local useState, useEffect, useReducer

return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)

	local jestExpect = require(Packages.Dev.JestGlobals).expect

	local Promise = require(Packages.Dev.Promise)

	describe("ReactTestRenderer.act()", function()
		beforeEach(function()
			RobloxJest.resetModules()
			RobloxJest.useRealTimers()

			React = require(Packages.React)
			useState, useEffect, useReducer =
				React.useState, React.useEffect, React.useReducer
			ReactTestRenderer = require(Packages.ReactTestRenderer)
			Scheduler = require(Packages.Scheduler)
			act = ReactTestRenderer.act
		end)
		it("can use .act() to flush effects", function()
			local function App(props)
				local ctr, setCtr = useState(0)

				React.useEffect(function()
					props.callback()
					setCtr(1)
				end, {})

				return ctr
			end

			local calledLog = {}
			local root

			act(function()
				root = ReactTestRenderer.create(React.createElement(App, {
					callback = function()
						table.insert(calledLog, #calledLog)
					end,
				}))
			end)
			jestExpect(calledLog).toEqual({ 0 })
			jestExpect(root.toJSON()).toEqual("1")
		end)
		it("warns if you don't use .act", function()
			local ctr, setCtr

			local function App(props)
				ctr, setCtr = useState(0)

				return ctr
			end

			ReactTestRenderer.create(React.createElement(App))

			jestExpect(function()
				setCtr(1)
			end).toErrorDev({
				"An update to App inside a test was not wrapped in act(...).",
			})
		end)
		describe("async", function()
			it("should work with async/await", function()
				local fetch = Promise.promisify(function(url)
					return Promise.resolve({
						details = { 1, 2, 3 },
					})
				end)
				local function App()
					local details, setDetails = React.useState(0)

					React.useEffect(function()
						local fetchDetails = function()
							return fetch():andThen(function(response)
								setDetails(response.details)
							end)
						end

						fetchDetails()
					end, {})

					return details
				end

				local root

				Promise.try(function()
					act(function()
						root = ReactTestRenderer.create(React.createElement(App))
					end)
				end):await()

				jestExpect(root.toJSON()).toEqual({ "1", "2", "3" })
			end)
			it("should not flush effects without also flushing microtasks", function()
				local alreadyResolvedPromise = Promise.resolve()

				local function App()
					-- This component will keep updating itself until step === 3
					local step, proceed = useReducer(function(s)
						if s == 3 then
							return 3
						end

						return s + 1
					end, 1)

					useEffect(function()
						Scheduler.unstable_yieldValue("Effect")
						alreadyResolvedPromise:andThen(function()
							Scheduler.unstable_yieldValue("Microtask")
							proceed()
						end)
					end)

					return step
				end

				local root = ReactTestRenderer.create(nil)

				Promise.try(function()
					act(function()
						root.update(React.createElement(App))
					end)
				end):await()

				jestExpect(Scheduler).toHaveYielded({
					-- Should not flush effects without also flushing microtasks
					-- First render:
					"Effect",
					"Microtask",
					-- Second render:
					"Effect",
					"Microtask",
					-- Final render:
					"Effect",
					"Microtask",
				})

				jestExpect(root).toMatchRenderedOutput("3")
			end)
		end)
	end)
end
