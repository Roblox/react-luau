-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/console-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]
return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local JestGlobals = require(Packages.Dev.JestGlobals)
	local jestExpect = JestGlobals.expect
	local jest = JestGlobals.jest

	-- ROBLOX deviation: Use lua's _G global table
	local global = _G

	-- ROBLOX deviation: Stub for now
	local Console = {
		patch = function(...)
			print("Console.patch", ...)
		end,
		unpatch = function(...)
			print("Console.unpatch", ...)
		end,
		dangerous_setTargetConsoleForTesting = function(...) end,
		registerRenderer = function(...) end,
	}

	-- ROBLOX deviation: require these as relative paths
	local React = require(Packages.React)
	-- ROBLOX deviation: use ReactRoblox instead of ReactDOM
	local ReactRoblox = require(Packages.ReactRoblox)
	local utils = require(script.Parent.utils)

	describe("console", function()
		local act
		local fakeConsole
		local mockError
		local mockInfo
		local mockLog
		local mockWarn
		local patchConsole
		local unpatchConsole

		beforeEach(function()
			RobloxJest.resetModules()

			patchConsole = Console.patch
			unpatchConsole = Console.unpatch

			-- Patch a fake console so we can verify with tests below.
			-- Patching the real console is too complicated,
			-- because Jest itself has hooks into it as does our test env setup.
			mockError = jest:fn()
			mockInfo = jest:fn()
			mockLog = jest:fn()
			mockWarn = jest:fn()
			fakeConsole = {
				error = mockError,
				info = mockInfo,
				log = mockLog,
				warn = mockWarn,
			}

			Console.dangerous_setTargetConsoleForTesting(fakeConsole)

			-- Note the Console module only patches once,
			-- so it's important to patch the test console before injection.
			patchConsole({
				appendComponentStack = true,
				breakOnWarn = false,
			})

			local inject = global.__REACT_DEVTOOLS_GLOBAL_HOOK__.inject
			global.__REACT_DEVTOOLS_GLOBAL_HOOK__.inject = function(internals)
				inject(internals)

				Console.registerRenderer(internals)
			end

			act = utils.act
		end)

		local function normalizeCodeLocInfo(str)
			-- ROBLOX deviation: Lua stack traces won't match JS ones
			-- ROBLOX TODO: verify this
			return str
		end

		xit(
			"should not patch console methods that do not receive component stacks",
			function()
				jestExpect(fakeConsole.error).never.toBe(mockError)
				jestExpect(fakeConsole.info).toBe(mockInfo)
				jestExpect(fakeConsole.log).toBe(mockLog)
				jestExpect(fakeConsole.warn).never.toBe(mockWarn)
			end
		)

		xit("should only patch the console once", function()
			local prevError = fakeConsole.error
			local prevWarn = fakeConsole.warn

			patchConsole({
				appendComponentStack = true,
				breakOnWarn = false,
			})
			jestExpect(fakeConsole.error).toBe(prevError)
			jestExpect(fakeConsole.warn).toBe(prevWarn)
		end)

		xit("should un-patch when requested", function()
			jestExpect(fakeConsole.error).never.toBe(mockError)
			jestExpect(fakeConsole.warn).never.toBe(mockWarn)
			unpatchConsole()
			jestExpect(fakeConsole.error).toBe(mockError)
			jestExpect(fakeConsole.warn).toBe(mockWarn)
		end)

		xit("should pass through logs when there is no current fiber", function()
			jestExpect(mockLog).toHaveBeenCalledTimes(0)
			jestExpect(mockWarn).toHaveBeenCalledTimes(0)
			jestExpect(mockError).toHaveBeenCalledTimes(0)
			fakeConsole.log("log")
			fakeConsole.warn("warn")
			fakeConsole.error("error")
			jestExpect(mockLog).toHaveBeenCalledTimes(1)
			jestExpect(mockLog.mock.calls[0]).toHaveLength(1)
			jestExpect(mockLog.mock.calls[0][0]).toBe("log")
			jestExpect(mockWarn).toHaveBeenCalledTimes(1)
			jestExpect(mockWarn.mock.calls[0]).toHaveLength(1)
			jestExpect(mockWarn.mock.calls[0][0]).toBe("warn")
			jestExpect(mockError).toHaveBeenCalledTimes(1)
			jestExpect(mockError.mock.calls[0]).toHaveLength(1)
			jestExpect(mockError.mock.calls[0][0]).toBe("error")
		end)

		xit("should not append multiple stacks", function()
			local Child = function()
				fakeConsole.warn("warn\n    in Child (at fake.js:123)")
				fakeConsole.error("error", "\n    in Child (at fake.js:123)")
				return nil
			end

			-- ROBLOX deviation: Use createRoot instead of DOM element
			local root = ReactRoblox.createRoot(Instance.new("Frame"))

			act(function()
				return root:render(React.createElement(Child))
			end)
			jestExpect(mockWarn).toHaveBeenCalledTimes(1)
			jestExpect(mockWarn.mock.calls[0]).toHaveLength(1)
			-- ROBLOX TODO: What is printed instead of this?
			jestExpect(mockWarn.mock.calls[0][0]).toBe(
				"warn\n    in Child (at fake.js:123)"
			)
			jestExpect(mockError).toHaveBeenCalledTimes(1)
			jestExpect(mockError.mock.calls[0]).toHaveLength(2)
			jestExpect(mockError.mock.calls[0][0]).toBe("error")
			jestExpect(mockError.mock.calls[0][1]).toBe("\n    in Child (at fake.js:123)")
		end)

		xit(
			"should append component stacks to errors and warnings logged during render",
			function()
				local Intermediate = function(_ref2)
					local children = _ref2.children
					return children
				end
				-- ROBLOX deviation: switched ordering for variable definition order
				local Child = function(_ref4)
					local _children = _ref4.children

					fakeConsole.error("error")
					fakeConsole.log("log")
					fakeConsole.warn("warn")

					return nil
				end
				local Parent = function(_ref3)
					local _children = _ref3.children
					return React.createElement(
						Intermediate,
						nil,
						React.createElement(Child, nil)
					)
				end

				-- ROBLOX deviation: Use createRoot instead of DOM element
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(React.createElement(Parent, nil))
				end)
				jestExpect(mockLog).toHaveBeenCalledTimes(1)
				jestExpect(mockLog.mock.calls[0]).toHaveLength(1)
				jestExpect(mockLog.mock.calls[0][0]).toBe("log")
				jestExpect(mockWarn).toHaveBeenCalledTimes(1)
				jestExpect(mockWarn.mock.calls[0]).toHaveLength(2)
				jestExpect(mockWarn.mock.calls[0][0]).toBe("warn")
				-- ROBLOX TODO: What is printed instead of this?
				jestExpect(normalizeCodeLocInfo(mockWarn.mock.calls[0][1])).toEqual(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
				jestExpect(mockError).toHaveBeenCalledTimes(1)
				jestExpect(mockError.mock.calls[0]).toHaveLength(2)
				jestExpect(mockError.mock.calls[0][0]).toBe("error")
				jestExpect(normalizeCodeLocInfo(mockError.mock.calls[0][1])).toBe(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
			end
		)
		xit(
			"should append component stacks to errors and warnings logged from effects",
			function()
				local Intermediate = function(_ref5)
					local children = _ref5.children
					return children
				end
				-- ROBLOX deviation: switched ordering for variable definition order
				local Child = function(_ref7)
					local _children = _ref7.children

					React.useLayoutEffect(function()
						fakeConsole.error("active error")
						fakeConsole.log("active log")
						fakeConsole.warn("active warn")
					end)
					React.useEffect(function()
						fakeConsole.error("passive error")
						fakeConsole.log("passive log")
						fakeConsole.warn("passive warn")
					end)

					return nil
				end
				local Parent = function(_ref6)
					local _children = _ref6.children

					return React.createElement(
						Intermediate,
						nil,
						React.createElement(Child, nil)
					)
				end

				-- ROBLOX deviation: Use createRoot instead of DOM element
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(React.createElement(Parent, nil))
				end)
				jestExpect(mockLog).toHaveBeenCalledTimes(2)
				jestExpect(mockLog.mock.calls[0]).toHaveLength(1)
				jestExpect(mockLog.mock.calls[0][0]).toBe("active log")
				jestExpect(mockLog.mock.calls[1]).toHaveLength(1)
				jestExpect(mockLog.mock.calls[1][0]).toBe("passive log")
				jestExpect(mockWarn).toHaveBeenCalledTimes(2)
				jestExpect(mockWarn.mock.calls[0]).toHaveLength(2)
				jestExpect(mockWarn.mock.calls[0][0]).toBe("active warn")
				-- ROBLOX TODO: What is printed instead of this?
				jestExpect(normalizeCodeLocInfo(mockWarn.mock.calls[0][1])).toEqual(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
				jestExpect(mockWarn.mock.calls[1]).toHaveLength(2)
				jestExpect(mockWarn.mock.calls[1][0]).toBe("passive warn")
				jestExpect(normalizeCodeLocInfo(mockWarn.mock.calls[1][1])).toEqual(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
				jestExpect(mockError).toHaveBeenCalledTimes(2)
				jestExpect(mockError.mock.calls[0]).toHaveLength(2)
				jestExpect(mockError.mock.calls[0][0]).toBe("active error")
				jestExpect(normalizeCodeLocInfo(mockError.mock.calls[0][1])).toBe(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
				jestExpect(mockError.mock.calls[1]).toHaveLength(2)
				jestExpect(mockError.mock.calls[1][0]).toBe("passive error")
				jestExpect(normalizeCodeLocInfo(mockError.mock.calls[1][1])).toBe(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
			end
		)
		xit(
			"should append component stacks to errors and warnings logged from commit hooks",
			function()
				local Intermediate = function(_ref8)
					local children = _ref8.children

					return children
				end
				-- ROBLOX deviation: switched ordering for variable definition order
				local Child = React.Component:extend("Child")
				local Parent = function(_ref9)
					local _children = _ref9.children

					return React.createElement(
						Intermediate,
						nil,
						React.createElement(Child, nil)
					)
				end

				function Child:componentDidMount()
					fakeConsole.error("didMount error")
					fakeConsole.log("didMount log")
					fakeConsole.warn("didMount warn")
				end
				function Child:componentDidUpdate()
					fakeConsole.error("didUpdate error")
					fakeConsole.log("didUpdate log")
					fakeConsole.warn("didUpdate warn")
				end
				function Child:render()
					return nil
				end

				-- ROBLOX deviation: Use createRoot instead of DOM element
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(React.createElement(Parent, nil))
				end)
				act(function()
					return root:render(React.createElement(Parent, nil))
				end)
				jestExpect(mockLog).toHaveBeenCalledTimes(2)
				jestExpect(mockLog.mock.calls[0]).toHaveLength(1)
				jestExpect(mockLog.mock.calls[0][0]).toBe("didMount log")
				jestExpect(mockLog.mock.calls[1]).toHaveLength(1)
				jestExpect(mockLog.mock.calls[1][0]).toBe("didUpdate log")
				jestExpect(mockWarn).toHaveBeenCalledTimes(2)
				jestExpect(mockWarn.mock.calls[0]).toHaveLength(2)
				jestExpect(mockWarn.mock.calls[0][0]).toBe("didMount warn")
				-- ROBLOX TODO: What is printed instead of this?
				jestExpect(normalizeCodeLocInfo(mockWarn.mock.calls[0][1])).toEqual(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
				jestExpect(mockWarn.mock.calls[1]).toHaveLength(2)
				jestExpect(mockWarn.mock.calls[1][0]).toBe("didUpdate warn")
				jestExpect(normalizeCodeLocInfo(mockWarn.mock.calls[1][1])).toEqual(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
				jestExpect(mockError).toHaveBeenCalledTimes(2)
				jestExpect(mockError.mock.calls[0]).toHaveLength(2)
				jestExpect(mockError.mock.calls[0][0]).toBe("didMount error")
				jestExpect(normalizeCodeLocInfo(mockError.mock.calls[0][1])).toBe(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
				jestExpect(mockError.mock.calls[1]).toHaveLength(2)
				jestExpect(mockError.mock.calls[1][0]).toBe("didUpdate error")
				jestExpect(normalizeCodeLocInfo(mockError.mock.calls[1][1])).toBe(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
			end
		)
		xit(
			"should append component stacks to errors and warnings logged from gDSFP",
			function()
				local Intermediate = function(_ref10)
					local children = _ref10.children
					return children
				end
				-- ROBLOX deviation: switched ordering for variable definition order
				local Child = {}
				local ChildMetatable = { __index = Child }
				local Parent = function(_ref11)
					local _children = _ref11.children
					return React.createElement(
						Intermediate,
						nil,
						React.createElement(Child, nil)
					)
				end

				function Child.new()
					local self = setmetatable({}, ChildMetatable)
					local _temp
					return self
				end
				function Child.getDerivedStateFromProps()
					fakeConsole.error("error")
					fakeConsole.log("log")
					fakeConsole.warn("warn")
					return nil
				end
				function Child:render()
					return nil
				end

				-- ROBLOX deviation: Use createRoot instead of DOM element
				local root = ReactRoblox.createRoot(Instance.new("Frame"))

				act(function()
					return root:render(React.createElement(Parent, nil))
				end)
				jestExpect(mockLog).toHaveBeenCalledTimes(1)
				jestExpect(mockLog.mock.calls[0]).toHaveLength(1)
				jestExpect(mockLog.mock.calls[0][0]).toBe("log")
				jestExpect(mockWarn).toHaveBeenCalledTimes(1)
				jestExpect(mockWarn.mock.calls[0]).toHaveLength(2)
				jestExpect(mockWarn.mock.calls[0][0]).toBe("warn")
				-- ROBLOX TODO: What is printed instead of this?
				jestExpect(normalizeCodeLocInfo(mockWarn.mock.calls[0][1])).toEqual(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
				jestExpect(mockError).toHaveBeenCalledTimes(1)
				jestExpect(mockError.mock.calls[0]).toHaveLength(2)
				jestExpect(mockError.mock.calls[0][0]).toBe("error")
				jestExpect(normalizeCodeLocInfo(mockError.mock.calls[0][1])).toBe(
					"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
				)
			end
		)
		xit("should append stacks after being uninstalled and reinstalled", function()
			local Child = function(_ref12)
				local _children = _ref12.children

				fakeConsole.warn("warn")
				fakeConsole.error("error")

				return nil
			end

			unpatchConsole()

			-- ROBLOX deviation: Use createRoot instead of DOM element
			local root = ReactRoblox.createRoot(Instance.new("Frame"))

			act(function()
				return root:render(React.createElement(Child, nil))
			end)
			jestExpect(mockWarn).toHaveBeenCalledTimes(1)
			jestExpect(mockWarn.mock.calls[0]).toHaveLength(1)
			jestExpect(mockWarn.mock.calls[0][0]).toBe("warn")
			jestExpect(mockError).toHaveBeenCalledTimes(1)
			jestExpect(mockError.mock.calls[0]).toHaveLength(1)
			jestExpect(mockError.mock.calls[0][0]).toBe("error")
			patchConsole({
				appendComponentStack = true,
				breakOnWarn = false,
			})
			act(function()
				return root:render(React.createElement(Child, nil))
			end)
			jestExpect(mockWarn).toHaveBeenCalledTimes(2)
			jestExpect(mockWarn.mock.calls[1]).toHaveLength(2)
			jestExpect(mockWarn.mock.calls[1][0]).toBe("warn")
			-- ROBLOX TODO: What is printed instead of this?
			jestExpect(normalizeCodeLocInfo(mockWarn.mock.calls[1][1])).toEqual(
				"\n    in Child (at **)"
			)
			jestExpect(mockError).toHaveBeenCalledTimes(2)
			jestExpect(mockError.mock.calls[1]).toHaveLength(2)
			jestExpect(mockError.mock.calls[1][0]).toBe("error")
			jestExpect(normalizeCodeLocInfo(mockError.mock.calls[1][1])).toBe(
				"\n    in Child (at **)"
			)
		end)
		xit("should be resilient to prepareStackTrace", function()
			-- ROBLOX TODO: what is a suitable alternative for this?
			-- Error.prepareStackTrace = function(error, callsites)
			-- 	local stack = {
			-- 		'An error occurred:',
			-- 		error.message,
			-- 	}

			-- 	for i=0, callsites.length - 1 do
			-- 		local callsite = callsites[i]

			-- 		stack.push('\t' + callsite.getFunctionName(), '\t\tat ' + callsite.getFileName(), '\t\ton line ' + callsite.getLineNumber())
			-- 	end

			-- 	return stack.join('\n')
			-- end

			local Intermediate = function(_ref13)
				local children = _ref13.children
				return children
			end
			-- ROBLOX deviation: switched ordering for variable definition order
			local Child = function(_ref15)
				fakeConsole.error("error")
				fakeConsole.log("log")
				fakeConsole.warn("warn")

				return nil
			end
			local Parent = function(_ref14)
				local _children = _ref14.children
				return React.createElement(
					Intermediate,
					nil,
					React.createElement(Child, nil)
				)
			end

			-- ROBLOX deviation: Use createRoot instead of DOM element
			local root = ReactRoblox.createRoot(Instance.new("Frame"))

			act(function()
				return root:render(React.createElement(Parent, nil))
			end)
			jestExpect(mockLog).toHaveBeenCalledTimes(1)
			jestExpect(mockLog.mock.calls[0]).toHaveLength(1)
			jestExpect(mockLog.mock.calls[0][0]).toBe("log")
			jestExpect(mockWarn).toHaveBeenCalledTimes(1)
			jestExpect(mockWarn.mock.calls[0]).toHaveLength(2)
			jestExpect(mockWarn.mock.calls[0][0]).toBe("warn")
			-- ROBLOX TODO: What is printed instead of this?
			jestExpect(normalizeCodeLocInfo(mockWarn.mock.calls[0][1])).toEqual(
				"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
			)
			jestExpect(mockError).toHaveBeenCalledTimes(1)
			jestExpect(mockError.mock.calls[0]).toHaveLength(2)
			jestExpect(mockError.mock.calls[0][0]).toBe("error")
			jestExpect(normalizeCodeLocInfo(mockError.mock.calls[0][1])).toBe(
				"\n    in Child (at **)\n    in Intermediate (at **)\n    in Parent (at **)"
			)
		end)
	end)
end
