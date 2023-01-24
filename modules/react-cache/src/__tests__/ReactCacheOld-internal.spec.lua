-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.2/packages/react-cache/src/__tests__/ReactCacheOld-test.internal.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]
local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
-- ROBLOX deviation START: unused imports
-- local Array = LuauPolyfill.Array
-- local Boolean = LuauPolyfill.Boolean
-- local Error = LuauPolyfill.Error
-- ROBLOX deviation END
-- ROBLOX deviation START: add additional types
type Error = LuauPolyfill.Error
-- ROBLOX deviation END
local setTimeout = LuauPolyfill.setTimeout
-- ROBLOX deviation START: import promise from dev dependencies
-- local Promise = require(Packages.Promise)
local Promise = require(Packages.Dev.Promise)
-- ROBLOX deviation END
local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it
local jest = JestGlobals.jest

local ReactCache
local createResource
local React
local ReactFeatureFlags
local ReactTestRenderer
local Scheduler
local Suspense
local TextResource
local textResourceShouldFail
describe("ReactCache", function()
	beforeEach(function()
		jest.resetModules()
		-- ROBLOX deviation START: add useFakeTimers call
		jest.useFakeTimers()
		-- ROBLOX deviation END
		-- ROBLOX deviation START: fix require
		-- ReactFeatureFlags = require_("shared/ReactFeatureFlags")
		ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		-- ROBLOX deviation END
		ReactFeatureFlags.replayFailedUnitOfWorkWithInvokeGuardedCallback = false
		-- ROBLOX deviation START: fix require
		-- React = require_("react")
		React = require(Packages.React)
		-- ROBLOX deviation END
		Suspense = React.Suspense
		-- ROBLOX deviation START: fix require
		-- ReactCache = require_("react-cache")
		ReactCache = require(script.Parent.Parent)
		-- ROBLOX deviation END
		createResource = ReactCache.unstable_createResource
		-- ROBLOX deviation START: fix requires
		-- ReactTestRenderer = require_("react-test-renderer")
		-- Scheduler = require_("scheduler")
		ReactTestRenderer = require(Packages.Dev.ReactTestRenderer)
		Scheduler = require(Packages.Scheduler)
		-- ROBLOX deviation END
		-- ROBLOX deviation START: explicit type
		-- TextResource = createResource(function(ref0)
		-- 	local text = ref0[1]
		TextResource = createResource(function(ref0: { string | number })
			local text = ref0[1] :: string
			-- ROBLOX deviation END
			-- ROBLOX deviation START: simplify
			-- local ms = (function()
			-- 	local element = table.unpack(ref0, 2, 2)
			-- 	if element == nil then
			-- 		return 0
			-- 	else
			-- 		return element
			-- 	end
			-- end)()
			local ms = ref0[2] or 0
			-- ROBLOX deviation END
			local listeners = nil
			local status = "pending"
			-- ROBLOX deviation START: explicit type
			-- local value = nil
			local value = nil :: string | Error | nil
			-- ROBLOX deviation END
			return {
				-- ROBLOX deviation START: use andThen
				-- ["then"] = function(self, resolve, reject)
				andThen = function(self, resolve, reject)
					-- ROBLOX deviation END
					-- ROBLOX deviation START: simplify switch statement conversion
					-- repeat --[[ ROBLOX comment: switch statement conversion ]]
					-- 	local condition_ = status
					-- 	if condition_ == "pending" then
					-- 		do
					-- 			if listeners == nil then
					-- 				listeners = { { resolve = resolve, reject = reject } }
					-- 				setTimeout(function()
					-- 					if
					-- 						Boolean.toJSBoolean(textResourceShouldFail)
					-- 					then
					-- 						Scheduler:unstable_yieldValue(
					-- 							("Promise rejected [%s]"):format(
					-- 								tostring(text)
					-- 							)
					-- 						)
					-- 						status = "rejected"
					-- 						value = Error.new(
					-- 							"Failed to load: " .. tostring(text)
					-- 						)
					-- 						Array.forEach(listeners, function(listener)
					-- 							return listener:reject(value)
					-- 						end) --[[ ROBLOX CHECK: check if 'listeners' is an Array ]]
					-- 					else
					-- 						Scheduler:unstable_yieldValue(
					-- 							("Promise resolved [%s]"):format(
					-- 								tostring(text)
					-- 							)
					-- 						)
					-- 						status = "resolved"
					-- 						value = text
					-- 						Array.forEach(listeners, function(listener)
					-- 							return listener:resolve(value)
					-- 						end) --[[ ROBLOX CHECK: check if 'listeners' is an Array ]]
					-- 					end
					-- 				end, ms)
					-- 			else
					-- 				table.insert(
					-- 					listeners,
					-- 					{ resolve = resolve, reject = reject }
					-- 				) --[[ ROBLOX CHECK: check if 'listeners' is an Array ]]
					-- 			end
					-- 			break
					-- 		end
					-- 	elseif condition_ == "resolved" then
					-- 		do
					-- 			resolve(value)
					-- 			break
					-- 		end
					-- 	elseif condition_ == "rejected" then
					-- 		do
					-- 			reject(value)
					-- 			break
					-- 		end
					-- 	end
					-- until true
					if status == "pending" then
						if listeners == nil then
							listeners = { { resolve = resolve, reject = reject } }
							LuauPolyfill.setTimeout(function()
								if textResourceShouldFail then
									Scheduler.unstable_yieldValue(
										string.format("Promise rejected [%s]", text)
									)
									status = "rejected"
									value =
										LuauPolyfill.Error.new("Failed to load: " .. text)
									for _, listener in listeners do
										listener.reject(value)
									end
								else
									Scheduler.unstable_yieldValue(
										string.format("Promise resolved [%s]", text)
									)
									status = "resolved"
									value = text
									for _, listener in listeners do
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
					-- ROBLOX deviation END
				end,
			}
		end, function(ref0)
			-- ROBLOX deviation START: ms not used
			-- local text, ms = table.unpack(ref0, 1, 2)
			-- return text
			return ref0[1]
			-- ROBLOX deviation END
		end)
		textResourceShouldFail = false
	end)
	local function Text(props)
		-- ROBLOX deviation START: use dot notation
		-- Scheduler:unstable_yieldValue(props.text)
		Scheduler.unstable_yieldValue(props.text)
		-- ROBLOX deviation END
		return props.text
	end
	-- ROBLOX deviation START: explicit type
	-- local function AsyncText(props)
	local function AsyncText(props: { ms: number, text: string | number })
		-- ROBLOX deviation END
		local text = props.text
		do --[[ ROBLOX COMMENT: try-catch block conversion ]]
			-- ROBLOX deviation START: use pcall
			-- local ok, result, hasReturned = xpcall(function()
			local ok, result = pcall(function()
				-- ROBLOX deviation END
				-- ROBLOX deviation START: use dot notation
				-- TextResource:read({ props.text, props.ms })
				-- Scheduler:unstable_yieldValue(text)
				TextResource.read({ props.text :: string | number, props.ms })
				Scheduler.unstable_yieldValue(text)
				-- ROBLOX deviation END
				-- ROBLOX deviation START: using pcall
				-- 	return text, true
				-- end, function(promise)
				return text
			end)
			if not ok then
				local promise = result
				-- ROBLOX deviation END
				-- ROBLOX deviation START: use andThen
				-- if typeof(promise["then"]) == "function" then
				if typeof(promise.andThen) == "function" then
					-- ROBLOX deviation END
					-- ROBLOX deviation START: use dot notation
					-- Scheduler:unstable_yieldValue(
					Scheduler.unstable_yieldValue(
						-- ROBLOX deviation END
						("Suspend! [%s]"):format(tostring(text))
					)
				else
					-- ROBLOX deviation START: use dot notation
					-- Scheduler:unstable_yieldValue(("Error! [%s]"):format(tostring(text)))
					Scheduler.unstable_yieldValue(("Error! [%s]"):format(tostring(text)))
					-- ROBLOX deviation END
				end
				error(promise)
				-- ROBLOX deviation START: using pcall
				-- end)
				-- if hasReturned then
				-- 	return result
				-- end
			end
			return result
			-- ROBLOX deviation END
		end
	end
	it("throws a promise if the requested value is not in the cache", function()
		local function App()
			return React.createElement(
				Suspense,
				{ fallback = React.createElement(Text, { text = "Loading..." }) },
				React.createElement(AsyncText, { ms = 100, text = "Hi" })
			)
		end
		ReactTestRenderer.create(
			React.createElement(App, nil),
			{ unstable_isConcurrent = true }
		)
		expect(Scheduler).toFlushAndYield({ "Suspend! [Hi]", "Loading..." })
		jest.advanceTimersByTime(100)
		expect(Scheduler).toHaveYielded({ "Promise resolved [Hi]" })
		expect(Scheduler).toFlushAndYield({ "Hi" })
	end)
	it("throws an error on the subsequent read if the promise is rejected", function()
		return Promise.resolve():andThen(function()
			local function App()
				return React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(AsyncText, { ms = 100, text = "Hi" })
				)
			end
			local root = ReactTestRenderer.create(
				React.createElement(App, nil),
				{ unstable_isConcurrent = true }
			)
			expect(Scheduler).toFlushAndYield({ "Suspend! [Hi]", "Loading..." })
			textResourceShouldFail = true
			jest.advanceTimersByTime(100)
			expect(Scheduler).toHaveYielded({ "Promise rejected [Hi]" })
			expect(Scheduler).toFlushAndThrow("Failed to load: Hi")
			expect(Scheduler).toHaveYielded({ "Error! [Hi]", "Error! [Hi]" }) -- Should throw again on a subsequent read
			-- ROBLOX deviation START: use dot notation
			-- root:update(React.createElement(App, nil))
			root.update(React.createElement(App, nil))
			-- ROBLOX deviation END
			expect(Scheduler).toFlushAndThrow("Failed to load: Hi")
			expect(Scheduler).toHaveYielded({ "Error! [Hi]", "Error! [Hi]" })
		end)
	end)
	it(
		"warns if non-primitive key is passed to a resource without a hash function",
		function()
			-- ROBLOX deviation START: explicit type
			-- local BadTextResource = createResource(function(ref0)
			-- 	local text = ref0[1]
			local BadTextResource = createResource(function(ref0: { string | number })
				local text = ref0[1] :: string
				-- ROBLOX deviation END
				-- ROBLOX deviation START: simplify
				-- local ms = (function()
				-- 	local element = table.unpack(ref0, 2, 2)
				-- 	if element == nil then
				-- 		return 0
				-- 	else
				-- 		return element
				-- 	end
				-- end)()
				local ms = ref0[2] or 0
				-- ROBLOX deviation END
				return Promise.new(function(resolve, reject)
					return setTimeout(function()
						resolve(text)
					end, ms)
				end)
			end)
			local function App()
				-- ROBLOX deviation START: use dot notation and cast type because luau doesn't support mixed arrays
				-- Scheduler:unstable_yieldValue("App")
				-- return BadTextResource:read({ "Hi", 100 })
				Scheduler.unstable_yieldValue("App")
				return BadTextResource.read({ "Hi" :: string | number, 100 })
				-- ROBLOX deviation END
			end
			ReactTestRenderer.create(
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(App, nil)
				),
				{ unstable_isConcurrent = true }
			)
			-- ROBLOX deviation START: remove toJSBoolean and use _G
			-- if Boolean.toJSBoolean(__DEV__) then
			if _G.__DEV__ then
				-- ROBLOX deviation END
				expect(function()
					expect(Scheduler).toFlushAndYield({ "App", "Loading..." })
				end).toErrorDev({
					"Invalid key type. Expected a string, number, symbol, or "
						-- ROBLOX deviation START: FIXME - make console polyfill format arrays the same as JS
						-- .. "boolean, but instead received: Hi,100\n\n"
						.. 'boolean, but instead received: ["Hi", 100]\n\n'
						-- ROBLOX deviation END
						.. "To use non-primitive values as keys, you must pass a hash "
						.. "function as the second argument to createResource().",
				})
			else
				expect(Scheduler).toFlushAndYield({ "App", "Loading..." })
			end
		end
	)
	it("evicts least recently used values", function()
		return Promise.resolve():andThen(function()
			-- ROBLOX deviation START: use dot notation
			-- ReactCache:unstable_setGlobalCacheLimit(3) -- Render 1, 2, and 3
			ReactCache.unstable_setGlobalCacheLimit(3)
			-- ROBLOX deviation END
			local root = ReactTestRenderer.create(
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(AsyncText, { ms = 100, text = 1 }),
					React.createElement(AsyncText, { ms = 100, text = 2 }),
					React.createElement(AsyncText, { ms = 100, text = 3 })
				),
				{ unstable_isConcurrent = true }
			)
			expect(Scheduler).toFlushAndYield({
				"Suspend! [1]",
				"Suspend! [2]",
				"Suspend! [3]",
				"Loading...",
			})
			jest.advanceTimersByTime(100)
			expect(Scheduler).toHaveYielded({
				"Promise resolved [1]",
				"Promise resolved [2]",
				"Promise resolved [3]",
			})
			expect(Scheduler).toFlushAndYield({ 1, 2, 3 })
			expect(root).toMatchRenderedOutput("123") -- Render 1, 4, 5
			-- ROBLOX deviation START: use dot notation
			-- root:update(
			root.update(
				-- ROBLOX deviation END
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(AsyncText, { ms = 100, text = 1 }),
					React.createElement(AsyncText, { ms = 100, text = 4 }),
					React.createElement(AsyncText, { ms = 100, text = 5 })
				)
			)
			expect(Scheduler).toFlushAndYield({
				-- ROBLOX deviation START: Luau doesn't support mixed arrays
				-- 1,
				1 :: number | string,
				-- ROBLOX deviation END
				"Suspend! [4]",
				"Suspend! [5]",
				"Loading...",
			})
			jest.advanceTimersByTime(100)
			expect(Scheduler).toHaveYielded({
				"Promise resolved [4]",
				"Promise resolved [5]",
			})
			expect(Scheduler).toFlushAndYield({ 1, 4, 5 })
			expect(root).toMatchRenderedOutput("145") -- We've now rendered values 1, 2, 3, 4, 5, over our limit of 3. The least
			-- recently used values are 2 and 3. They should have been evicted.
			-- ROBLOX deviation START: use dot notation
			-- root:update(
			root.update(
				-- ROBLOX deviation END
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(AsyncText, { ms = 100, text = 1 }),
					React.createElement(AsyncText, { ms = 100, text = 2 }),
					React.createElement(AsyncText, { ms = 100, text = 3 })
				)
			)
			expect(Scheduler).toFlushAndYield({
				-- 1 is still cached
				-- ROBLOX deviation START: Luau doesn't support mixed arrays
				-- 1,
				1 :: number | string,
				-- ROBLOX deviation END
				-- 2 and 3 suspend because they were evicted from the cache
				"Suspend! [2]",
				"Suspend! [3]",
				"Loading...",
			})
			jest.advanceTimersByTime(100)
			expect(Scheduler).toHaveYielded({
				"Promise resolved [2]",
				"Promise resolved [3]",
			})
			expect(Scheduler).toFlushAndYield({ 1, 2, 3 })
			expect(root).toMatchRenderedOutput("123")
		end)
	end, 9999999999)
	it("preloads during the render phase", function()
		return Promise.resolve():andThen(function()
			local function App()
				-- ROBLOX deviation START: use dot notation
				-- TextResource:preload({ "B", 1000 })
				-- TextResource:read({ "A", 1000 })
				-- TextResource:read({ "B", 1000 })
				TextResource.preload({ "B", 1000 })
				TextResource.read({ "A", 1000 })
				TextResource.read({ "B", 1000 })
				-- ROBLOX deviation END
				return React.createElement(Text, { text = "Result" })
			end
			local root = ReactTestRenderer.create(
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(App, nil)
				),
				{ unstable_isConcurrent = true }
			)
			expect(Scheduler).toFlushAndYield({ "Loading..." })
			jest.advanceTimersByTime(1000)
			expect(Scheduler).toHaveYielded({
				"Promise resolved [B]",
				"Promise resolved [A]",
			})
			expect(Scheduler).toFlushAndYield({ "Result" })
			expect(root).toMatchRenderedOutput("Result")
		end)
	end)
	it(
		"if a thenable resolves multiple times, does not update the first cached value",
		function()
			local resolveThenable
			local BadTextResource = createResource(function(ref0)
				-- ROBLOX deviation START: unused
				-- local text = ref0[1]
				-- local ms = (function()
				-- 	local element = table.unpack(ref0, 2, 2)
				-- 	if element == nil then
				-- 		return 0
				-- 	else
				-- 		return element
				-- 	end
				-- end)()
				-- ROBLOX deviation END
				local listeners = nil
				local value = nil
				return {
					-- ROBLOX deviation START: use andThen
					-- ["then"] = function(self, resolve, reject)
					andThen = function(self, resolve, reject)
						-- ROBLOX deviation END
						if value ~= nil then
							resolve(value)
						else
							if listeners == nil then
								listeners = { resolve }
								resolveThenable = function(v)
									-- ROBLOX deviation START: use for..in loop instead
									-- Array.forEach(listeners, function(listener)
									-- 	return listener(v)
									-- end) --[[ ROBLOX CHECK: check if 'listeners' is an Array ]]
									for _, listener in listeners do
										listener(v)
									end
									-- ROBLOX deviation END
								end
							else
								table.insert(listeners, resolve) --[[ ROBLOX CHECK: check if 'listeners' is an Array ]]
							end
						end
					end,
				}
				-- ROBLOX deviation START: explicit type
				-- end, function(ref0)
			end, function(ref0: { any })
				-- ROBLOX deviation END
				-- ROBLOX deviation START: ms not used
				-- local text, ms = table.unpack(ref0, 1, 2)
				-- return text
				return ref0[1]
				-- ROBLOX deviation END
			end)
			local function BadAsyncText(props)
				local text = props.text
				do --[[ ROBLOX COMMENT: try-catch block conversion ]]
					-- ROBLOX deviation START: use pcall
					-- local ok, result, hasReturned = xpcall(function()
					local ok, result = pcall(function()
						-- ROBLOX deviation END
						-- ROBLOX deviation START: use dot notation
						-- local actualText = BadTextResource:read({ props.text, props.ms })
						-- Scheduler:unstable_yieldValue(actualText)
						local actualText = BadTextResource.read({ props.text, props.ms })
						Scheduler.unstable_yieldValue(actualText)
						-- ROBLOX deviation END
						-- ROBLOX deviation START: using pcall
						-- 	return actualText, true
						-- end, function(promise)
						return actualText
					end)
					if not ok then
						local promise = result
						-- ROBLOX deviation END
						-- ROBLOX deviation START: use andThen
						-- if typeof(promise["then"]) == "function" then
						if typeof(promise.andThen) == "function" then
							-- ROBLOX deviation END
							-- ROBLOX deviation START: use dot notation
							-- Scheduler:unstable_yieldValue(
							Scheduler.unstable_yieldValue(
								-- ROBLOX deviation END
								("Suspend! [%s]"):format(tostring(text))
							)
						else
							-- ROBLOX deviation START: use dot notation
							-- Scheduler:unstable_yieldValue(
							Scheduler.unstable_yieldValue(
								-- ROBLOX deviation END
								("Error! [%s]"):format(tostring(text))
							)
						end
						error(promise)
						-- ROBLOX deviation START: using pcall
						-- end)
						-- if hasReturned then
						-- 	return result
						-- end
					end
					return result
					-- ROBLOX deviation END
				end
			end
			local root = ReactTestRenderer.create(
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(BadAsyncText, { text = "Hi" })
				),
				{ unstable_isConcurrent = true }
			)
			expect(Scheduler).toFlushAndYield({ "Suspend! [Hi]", "Loading..." })
			resolveThenable("Hi") -- This thenable improperly resolves twice. We should not update the
			-- cached value.
			resolveThenable("Hi muahahaha I am different")
			-- ROBLOX deviation START: use dot notation
			-- root:update(
			root.update(
				-- ROBLOX deviation END
				React.createElement(
					Suspense,
					{ fallback = React.createElement(Text, { text = "Loading..." }) },
					React.createElement(BadAsyncText, { text = "Hi" })
				),
				{ unstable_isConcurrent = true }
			)
			expect(Scheduler).toHaveYielded({})
			expect(Scheduler).toFlushAndYield({ "Hi" })
			expect(root).toMatchRenderedOutput("Hi")
		end
	)
	it("throws if read is called outside render", function()
		expect(function()
			-- ROBLOX deviation START: use dot notation
			-- return TextResource:read({ "A", 1000 })
			TextResource.read({ "A", 1000 })
			-- ROBLOX deviation END
		end).toThrow(
			"read and preload may only be called from within a component's render"
		)
	end)
	it("throws if preload is called outside render", function()
		expect(function()
			-- ROBLOX deviation START: use dot notation
			-- return TextResource:preload({ "A", 1000 })
			TextResource.preload({ "A", 1000 })
			-- ROBLOX deviation END
		end).toThrow(
			"read and preload may only be called from within a component's render"
		)
	end)
end)
