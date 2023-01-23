-- ROBLOX upstream: https://github.com/facebook/react/blob/3e94bce765d355d74f6a60feb4addb6d196e3482/packages/shared/__tests__/ReactErrorUtils-test.internal.js
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
local Error = LuauPolyfill.Error
local JestGlobals = require(Packages.Dev.JestGlobals)
local afterEach = JestGlobals.afterEach
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local it = JestGlobals.it
local jest = JestGlobals.jest
local ReactErrorUtils

beforeEach(function()
	-- TODO: can we express this test with only public API?
	jest.resetModules()
	ReactErrorUtils = require(script.Parent.Parent.ReactErrorUtils)
end)

afterEach(function()
	jest.unmock(script.Parent.Parent.invokeGuardedCallbackImpl)
end)

it("it should rethrow caught errors", function()
	local err = Error("foo")
	local callback = function()
		error(err)
	end
	ReactErrorUtils.invokeGuardedCallbackAndCatchFirstError("foo", callback, nil)
	jestExpect(ReactErrorUtils.hasCaughtError()).toBe(false)
	jestExpect(function()
		ReactErrorUtils.rethrowCaughtError()
	end).toThrow(err)
end)

it("should call the callback the passed arguments", function()
	-- ROBLOX deviation: In Lua, calling a function with `self` (which is the
	-- equivalent of the `context` argument used in
	-- invokeGuardedCallbackImpl) is explicit; if the context argument is
	-- nil, the function is presumed to not rely on `self` and is called
	-- without the `context` argument. For this test, we validate both
	-- cases.
	local callback = jest.fn()
	ReactErrorUtils.invokeGuardedCallback("foo", callback, nil, "arg1", "arg2")
	jestExpect(callback).toBeCalledWith("arg1", "arg2")
end)

it("should call the callback with the provided context", function()
	local context = { didCall = false }
	ReactErrorUtils.invokeGuardedCallback("foo", function(self)
		self.didCall = true
	end, context)
	jestExpect(context.didCall).toBe(true)
end)

it("should catch errors", function()
	local error_ = Error()
	local returnValue = ReactErrorUtils.invokeGuardedCallback("foo", function()
		error(error_)
	end, nil, "arg1", "arg2")
	jestExpect(returnValue).toBe(nil)
	jestExpect(ReactErrorUtils.hasCaughtError()).toBe(true)
	jestExpect(ReactErrorUtils.clearCaughtError()).toBe(error_)
end)

it("should return false from clearCaughtError if no error was thrown", function()
	local callback = jest.fn()
	ReactErrorUtils.invokeGuardedCallback("foo", callback, nil)
	jestExpect(ReactErrorUtils.hasCaughtError()).toBe(false)
	jestExpect(ReactErrorUtils.clearCaughtError).toThrow("no error was captured")
end)

it("can nest with same debug name", function()
	local err1 = Error()
	local err2
	local err3 = Error()
	ReactErrorUtils.invokeGuardedCallback("foo", function()
		ReactErrorUtils.invokeGuardedCallback("foo", function()
			error(err1)
		end, nil)
		err2 = ReactErrorUtils.clearCaughtError()
		error(err3)
	end, nil)
	local err4 = ReactErrorUtils.clearCaughtError()

	jestExpect(err2).toBe(err1)
	jestExpect(err4).toBe(err3)
end)

it("handles nested errors", function()
	local err1 = Error()
	local err2
	ReactErrorUtils.invokeGuardedCallback("foo", function()
		ReactErrorUtils.invokeGuardedCallback("foo", function()
			error(err1)
		end, nil)
		err2 = ReactErrorUtils.clearCaughtError()
	end, nil)
	-- Returns nil because inner error was already captured
	jestExpect(ReactErrorUtils.hasCaughtError()).toBe(false)

	jestExpect(err2).toBe(err1)
end)

it("handles nested errors in separate renderers", function()
	local ReactErrorUtils1 = require(script.Parent.Parent.ReactErrorUtils)
	jest.resetModules()
	local ReactErrorUtils2 = require(script.Parent.Parent.ReactErrorUtils)
	jestExpect(ReactErrorUtils1).never.toEqual(ReactErrorUtils2)

	local ops = {}

	ReactErrorUtils1.invokeGuardedCallback(nil, function()
		ReactErrorUtils2.invokeGuardedCallback(nil, function()
			error(Error("nested error"))
		end)
		-- ReactErrorUtils2 should catch the error
		table.insert(ops, ReactErrorUtils2.hasCaughtError())
		-- ROBLOX TODO: this is a missing assert/cast in upstream
		table.insert(ops, (ReactErrorUtils2.clearCaughtError() :: any).message)
	end, nil)

	-- ReactErrorUtils1 should not catch the error
	table.insert(ops, ReactErrorUtils1.hasCaughtError())

	jestExpect(ops).toEqual({ true, "nested error", false })
end)

if not _G.__DEV__ then
	-- jsdom doesn't handle this properly, but Chrome and Firefox should. Test
	-- this with a fixture.
	it("catches nil values", function()
		ReactErrorUtils.invokeGuardedCallback(nil, function()
			error(nil) -- eslint-disable-line no-throw-literal
		end, nil)
		jestExpect(ReactErrorUtils.hasCaughtError()).toBe(true)
		jestExpect(ReactErrorUtils.clearCaughtError()).toBe(nil)
	end)
end

it("can be shimmed", function()
	local ops = {}
	jest.resetModules()
	jest.mock(script.Parent.Parent.invokeGuardedCallbackImpl, function()
		return function(reporter, name, func, context, a)
			table.insert(ops, a)
			local ok, result = pcall(func, context, a)

			if not ok then
				reporter.onError(result)
			end
		end
	end)
	ReactErrorUtils = require(script.Parent.Parent.ReactErrorUtils)

	-- deviation: no need to wrap in try/finally since we don't need to
	-- undo the mock like we would with jest
	local err = Error("foo")
	local callback = function()
		error(err)
	end
	ReactErrorUtils.invokeGuardedCallbackAndCatchFirstError(
		"foo",
		callback,
		nil,
		"somearg"
	)

	jestExpect(function()
		ReactErrorUtils.rethrowCaughtError()
	end).toThrow(err)
	jestExpect(ops).toEqual({ "somearg" })
end)
