-- Upstream: https://github.com/facebook/react/blob/faa697f4f9afe9f1c98e315b2a9e70f5a74a7a74/packages/react-cache/src/__tests__/ReactCacheOld-test.internal.js

-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @emails react-core
--  */

-- !strict

local ReactCache
local createResource
local React
local ReactFeatureFlags
local ReactTestRenderer
local Scheduler
local Suspense
local TextResource
local textResourceShouldFail

return function()
	local Packages = script.Parent.Parent.Parent
	local LuauPolyfill = require(Packages.LuauPolyfill)
	local Promise = require(Packages.Dev.Promise)
	local setTimeout = LuauPolyfill.setTimeout
	local jest = require(Packages.Dev.JestRoblox)
	local jestExpect = jest.Globals.expect
	local RobloxJest = require(Packages.Dev.RobloxJest)
	describe("ReactCache", function()
		beforeEach(function()
			RobloxJest.resetModules()
			RobloxJest.useFakeTimers()

			ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags

			ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
			React = require(Packages.React)
			Suspense = React.Suspense
			ReactCache = require(script.Parent.Parent)
			createResource = ReactCache.unstable_createResource
			ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
			Scheduler = require(Packages.Scheduler)

			TextResource = createResource(function(input)
				local text = input[1]
				local ms = input[2] or 0
				local listeners = nil
				local status = "pending"
				local value = nil
				return {
					andThen = function(self, resolve, reject)
						if status == "pending" then
							if listeners == nil then
								listeners = { { resolve = resolve, reject = reject } }
								LuauPolyfill.setTimeout(function()
									if textResourceShouldFail then
										Scheduler.unstable_yieldValue(
											string.format("Promise rejected [%s]", text)
										)
										status = "rejected"
										value = LuauPolyfill.Error.new(
											"Failed to load: " .. text
										)
										for _, listener in ipairs(listeners) do
											listener.reject(value)
										end
									else
										Scheduler.unstable_yieldValue(
											string.format("Promise resolved [%s]", text)
										)
										status = "resolved"
										value = text
										for _, listener in ipairs(listeners) do
											listener.resolve(value)
										end
									end
								end, ms)
							else
								table.insert(
									listeners,
									{ resolve = resolve, reject = reject }
								)
							end
						elseif status == "resolved" then
							resolve(value)
						elseif status == "rejected" then
							reject(value)
						end
					end,
				}
			end, function(input)
				return input[1]
			end)

			textResourceShouldFail = false
		end)

		local function Text(props)
			Scheduler.unstable_yieldValue(props.text)
			return props.text
		end

		local function AsyncText(props)
			local text = props.text
			local ok, result = pcall(function()
				TextResource.read({ props.text, props.ms })
				Scheduler.unstable_yieldValue(text)
				return text
			end)
			if not ok then
				if typeof(result.andThen) == "function" then
					Scheduler.unstable_yieldValue(string.format("Suspend! [%s]", text))
				else
					Scheduler.unstable_yieldValue(string.format("Error! [%s]", text))
				end
				error(result)
			end
			return result
		end

		it("throws a promise if the requested value is not in the cache", function()
			local function App()
				return (
						React.createElement(Suspense, {
							fallback = React.createElement(Text, { text = "Loading..." }),
						}, React.createElement(
							AsyncText,
							{ ms = 100, text = "Hi" }
						))
					)
			end

			ReactTestRenderer.create(React.createElement(App), {
				unstable_isConcurrent = true,
			})
			-- Promise.delay(0):await()

			-- ROBLOX TODO: currently fails here with ReactCacheOld:178: attempt to index nil with 'status'
			-- return value from accessResult is nil
			jestExpect(Scheduler).toFlushAndYield({ "Suspend! [Hi]", "Loading..." })

			RobloxJest.advanceTimersByTime(100)
			jestExpect(Scheduler).toHaveYielded({ "Promise resolved [Hi]" })
			jestExpect(Scheduler).toFlushAndYield({ "Hi" })
		end)

		it("throws an error on the subsequent read if the promise is rejected", function()
			local function App()
				return (
						React.createElement(Suspense, {
							fallback = React.createElement(Text, { text = "Loading..." }),
						}, React.createElement(
							AsyncText,
							{ ms = 100, text = "Hi" }
						))
					)
			end

			local root = ReactTestRenderer.create(React.createElement(App), {
				unstable_isConcurrent = true,
			})

			jestExpect(Scheduler).toFlushAndYield({ "Suspend! [Hi]", "Loading..." })

			textResourceShouldFail = true
			RobloxJest.advanceTimersByTime(100)
			jestExpect(Scheduler).toHaveYielded({ "Promise rejected [Hi]" })

			jestExpect(Scheduler).toFlushAndThrow("Failed to load: Hi")
			jestExpect(Scheduler).toHaveYielded({ "Error! [Hi]", "Error! [Hi]" })

			-- Should throw again on a subsequent read
			root.update(React.createElement(App))
			jestExpect(Scheduler).toFlushAndThrow("Failed to load: Hi")
			jestExpect(Scheduler).toHaveYielded({ "Error! [Hi]", "Error! [Hi]" })
		end)

		it(
			"warns if non-primitive key is passed to a resource without a hash function",
			function()
				local BadTextResource = createResource(function(input)
					local text = input[1]
					local ms = input[2] or 0
					return Promise.new(function(resolve, _reject)
						setTimeout(function()
							resolve(text)
						end, ms)
					end)
				end)

				local function App()
					Scheduler.unstable_yieldValue("App")
					return BadTextResource.read({ "Hi", 100 })
				end

				ReactTestRenderer.create(
					React.createElement(
						Suspense,
						{ fallback = React.createElement(Text, { text = "Loading..." }) },
						{ React.createElement(App) }
					),
					{ unstable_isConcurrent = true }
				)

				if _G.__DEV__ then
					jestExpect(function()
						jestExpect(Scheduler).toFlushAndYield({ "App", "Loading..." })
					end).toErrorDev(
						"Warning: " -- ROBLOX FIXME: remove the Warning: prefix in consoleWithStackDev
							.. "Invalid key type. Expected a string, number, symbol, or "
							-- ROBLOX TODO: make console polyfill format arrays the same as JS
							.. 'boolean, but instead received: { "Hi", 100 }\n\n'
							.. "To use non-primitive values as keys, you must pass a hash "
							.. "function as the second argument to createResource()."
					)
				else
					jestExpect(Scheduler).toFlushAndYield({ "App", "Loading..." })
				end
			end
		)

		it("evicts least recently used values", function()
			ReactCache.unstable_setGlobalCacheLimit(3)

			-- Render 1, 2, and 3
			local root = ReactTestRenderer.create(
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					{
						React.createElement(AsyncText, { ms = 100, text = 1 }),
						React.createElement(AsyncText, { ms = 100, text = 2 }),
						React.createElement(AsyncText, { ms = 100, text = 3 }),
					}
				),
				{ unstable_isConcurrent = true }
			)
			jestExpect(Scheduler).toFlushAndYield({
				"Suspend! [1]",
				"Suspend! [2]",
				"Suspend! [3]",
				"Loading...",
			})
			RobloxJest.advanceTimersByTime(100)
			jestExpect(Scheduler).toHaveYielded({
				"Promise resolved [1]",
				"Promise resolved [2]",
				"Promise resolved [3]",
			})
			jestExpect(Scheduler).toFlushAndYield({ 1, 2, 3 })
			jestExpect(root).toMatchRenderedOutput("123")

			-- Render 1, 4, 5
			root.update(
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					{
						React.createElement(AsyncText, { ms = 100, text = 1 }),
						React.createElement(AsyncText, { ms = 100, text = 4 }),
						React.createElement(AsyncText, { ms = 100, text = 5 }),
					}
				)
			)

			jestExpect(Scheduler).toFlushAndYield({
				1,
				"Suspend! [4]",
				"Suspend! [5]",
				"Loading...",
			})
			RobloxJest.advanceTimersByTime(100)
			jestExpect(Scheduler).toHaveYielded({
				"Promise resolved [4]",
				"Promise resolved [5]",
			})
			jestExpect(Scheduler).toFlushAndYield({ 1, 4, 5 })
			jestExpect(root).toMatchRenderedOutput("145")

			-- We've now rendered values 1, 2, 3, 4, 5, over our limit of 3. The least
			-- recently used values are 2 and 3. They should have been evicted.

			root.update(
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					{
						React.createElement(AsyncText, { ms = 100, text = 1 }),
						React.createElement(AsyncText, { ms = 100, text = 2 }),
						React.createElement(AsyncText, { ms = 100, text = 3 }),
					}
				)
			)

			jestExpect(Scheduler).toFlushAndYield({
				-- 1 is still cached
				1,
				-- 2 and 3 suspend because they were evicted from the cache
				"Suspend! [2]",
				"Suspend! [3]",
				"Loading...",
			})
			RobloxJest.advanceTimersByTime(100)
			jestExpect(Scheduler).toHaveYielded({
				"Promise resolved [2]",
				"Promise resolved [3]",
			})
			jestExpect(Scheduler).toFlushAndYield({ 1, 2, 3 })
			jestExpect(root).toMatchRenderedOutput("123")
		end)

		it("preloads during the render phase", function()
			local function App()
				TextResource.preload({ "B", 1000 })
				TextResource.read({ "A", 1000 })
				TextResource.read({ "B", 1000 })
				return React.createElement(Text, { text = "Result" })
			end

			local root = ReactTestRenderer.create(
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					{ React.createElement(App) }
				),
				{ unstable_isConcurrent = true }
			)

			jestExpect(Scheduler).toFlushAndYield({ "Loading..." })

			RobloxJest.advanceTimersByTime(1000)
			jestExpect(Scheduler).toHaveYielded({
				"Promise resolved [B]",
				"Promise resolved [A]",
			})
			jestExpect(Scheduler).toFlushAndYield({ "Result" })
			jestExpect(root).toMatchRenderedOutput("Result")
		end)

		it(
			"if a thenable resolves multiple times, does not update the first cached value",
			function()
				local resolveThenable
				local BadTextResource = createResource(function(props)
					local _text = props.text
					local _ms = props.ms or 0
					local listeners = nil
					local value = nil
					return {
						andThen = function(self, resolve, reject)
							if value ~= nil then
								resolve(value)
							else
								if listeners == nil then
									listeners = { resolve }
									resolveThenable = function(v)
										for _, listener in pairs(listeners) do
											listener(v)
										end
									end
								else
									table.insert(listeners, resolve)
								end
							end
						end,
					}
				end, function(input)
					return input[1]
				end)

				local function BadAsyncText(props)
					local text = props.text
					local ok, result = pcall(function()
						local actualText = BadTextResource.read({ props.text, props.ms })
						Scheduler.unstable_yieldValue(actualText)
						return actualText
					end)

					if not ok then
						if typeof(result.andThen) == "function" then
							Scheduler.unstable_yieldValue(
								string.format("Suspend! [%s]", text)
							)
						else
							Scheduler.unstable_yieldValue(
								string.format("Error! [%s]", text)
							)
						end
						error(result)
					end
					return result
				end

				local root = ReactTestRenderer.create(
					React.createElement(
						Suspense,
						{ fallback = React.createElement(Text, { text = "Loading..." }) },
						{ React.createElement(BadAsyncText, { text = "Hi" }) }
					),
					{
						unstable_isConcurrent = true,
					}
				)

				jestExpect(Scheduler).toFlushAndYield({ "Suspend! [Hi]", "Loading..." })

				resolveThenable("Hi")
				-- This thenable improperly resolves twice. We should not update the
				-- cached value.
				resolveThenable("Hi muahahaha I am different")

				root.update(
					React.createElement(
						Suspense,
						{ fallback = React.createElement(Text, { text = "Loading..." }) },
						{ React.createElement(BadAsyncText, { text = "Hi" }) }
					),
					{
						unstable_isConcurrent = true,
					}
				)

				jestExpect(Scheduler).toHaveYielded({})
				jestExpect(Scheduler).toFlushAndYield({ "Hi" })
				jestExpect(root).toMatchRenderedOutput("Hi")
			end
		)

		it("throws if read is called outside render", function()
			jestExpect(function()
				TextResource.read({ "A", 1000 })
			end).toThrow(
				"read and preload may only be called from within a component's render"
			)
		end)

		it("throws if preload is called outside render", function()
			jestExpect(function()
				TextResource.preload({ "A", 1000 })
			end).toThrow(
				"read and preload may only be called from within a component's render"
			)
		end)
	end)
end
