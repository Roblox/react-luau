-- ROBLOX upstream: https://github.com/Roblox/roact/blob/b2ba9cf4c219c2654e6572219a68d0bf1b541418/src/SingleEventManager.spec.lua
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the Apache License, Version 2.0 (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     http://www.apache.org/licenses/LICENSE-2.0
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

local Packages = script.Parent.Parent.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local it = JestGlobals.it
local describe = JestGlobals.describe
-- ROBLOX FIXME
-- local Logging = require(script.Parent.Parent.Logging)

local SingleEventManager = require(script.Parent.Parent.SingleEventManager)
local waitForEvents = require(script.Parent.waitForEvents)

describe("new", function()
	it("should create a SingleEventManager", function()
		local instance = Instance.new("BindableEvent")
		local manager = SingleEventManager.new(instance)

		jestExpect(manager).never.toBeNil()
	end)
end)

describe("connectEvent", function()
	it("should connect to events", function()
		local instance = Instance.new("BindableEvent")
		local manager = SingleEventManager.new(instance)
		local eventSpy = jest.fn()

		manager:connectEvent("Event", function(...)
			eventSpy(...)
		end)
		manager:resume()

		instance:Fire("foo")
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(1)
		jestExpect(eventSpy).toBeCalledWith(instance, "foo")

		instance:Fire("bar")
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(2)
		jestExpect(eventSpy).toBeCalledWith(instance, "bar")

		manager:connectEvent("Event")

		instance:Fire("baz")
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(2)
	end)

	it("should drop events until resumed initially", function()
		local instance = Instance.new("BindableEvent")
		local manager = SingleEventManager.new(instance)
		local eventSpy = jest.fn()

		manager:connectEvent("Event", function(...)
			eventSpy(...)
		end)

		instance:Fire("foo")
		waitForEvents()

		jestExpect(eventSpy).never.toBeCalled()

		manager:resume()

		instance:Fire("bar")
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(1)
		jestExpect(eventSpy).toBeCalledWith(instance, "bar")
	end)

	it("should invoke suspended events when resumed", function()
		local instance = Instance.new("BindableEvent")
		local manager = SingleEventManager.new(instance)
		local eventSpy = jest.fn()

		manager:connectEvent("Event", function(...)
			eventSpy(...)
		end)
		manager:resume()

		instance:Fire("foo")
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(1)
		jestExpect(eventSpy).toBeCalledWith(instance, "foo")

		manager:suspend()

		instance:Fire("bar")
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(1)

		manager:resume()
		jestExpect(eventSpy).toBeCalledTimes(2)
		jestExpect(eventSpy).toBeCalledWith(instance, "bar")
	end)

	it("should invoke events triggered during resumption in the correct order", function()
		local instance = Instance.new("BindableEvent")
		local manager = SingleEventManager.new(instance)

		local recordedValues = {}
		local eventSpy = jest.fn(function(_, value)
			table.insert(recordedValues, value)

			if value == 2 then
				instance:Fire(3)
			elseif value == 3 then
				instance:Fire(4)
			end
		end)

		manager:connectEvent("Event", function(...)
			eventSpy(...)
		end)
		manager:suspend()

		instance:Fire(1)
		instance:Fire(2)
		waitForEvents()

		manager:resume()
		waitForEvents()
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(4)
		jestExpect(recordedValues).toEqual({ 1, 2, 3, 4 })
	end)

	it(
		"should not invoke events fired during suspension but disconnected before resumption",
		function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)
			local eventSpy = jest.fn()

			manager:connectEvent("Event", function(...)
				eventSpy(...)
			end)
			manager:suspend()

			instance:Fire(1)
			waitForEvents()

			manager:connectEvent("Event")

			manager:resume()
			jestExpect(eventSpy).never.toBeCalled()
		end
	)

	it("should not yield events through the SingleEventManager when resuming", function()
		local instance = Instance.new("BindableEvent")
		local manager = SingleEventManager.new(instance)

		manager:connectEvent("Event", function()
			coroutine.yield()
		end)

		manager:resume()

		local co = coroutine.create(function()
			instance:Fire(5)
			waitForEvents()
		end)

		assert(coroutine.resume(co))
		waitForEvents()

		jestExpect(coroutine.status(co)).toBe("dead")

		manager:suspend()
		instance:Fire(5)
		waitForEvents()

		co = coroutine.create(function()
			manager:resume()
		end)

		assert(coroutine.resume(co))
		jestExpect(coroutine.status(co)).toBe("dead")
	end)

	it("should not throw errors through SingleEventManager when resuming", function()
		local errorText = "Error from SingleEventManager test"

		local instance = Instance.new("BindableEvent")
		local manager = SingleEventManager.new(instance)

		manager:connectEvent("Event", function()
			error(errorText)
		end)

		manager:resume()

		-- If we call instance:Fire() here, the error message will leak to
		-- the console since the thread's resumption will be handled by
		-- Roblox's scheduler.

		manager:suspend()
		instance:Fire(5)

		-- local logInfo = Logging.capture(function()
		-- 	manager:resume()
		-- end)

		-- jestExpect(#logInfo.errors).to.equal(0)
		-- jestExpect(#logInfo.warnings).to.equal(1)
		-- jestExpect(#logInfo.infos).to.equal(0)

		-- jestExpect(logInfo.warnings[1]:find(errorText)).to.be.ok()
	end)

	it(
		"should not overflow with events if manager:resume() is invoked when resuming a suspended event",
		function()
			local instance = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(instance)

			-- This connection emulates what happens if reconciliation is
			-- triggered again in response to reconciliation. Without
			-- appropriate guards, the inner resume() call will process the
			-- Fire(1) event again, causing a nasty stack overflow.
			local eventSpy = jest.fn(function(_, value)
				if value == 1 then
					manager:suspend()
					instance:Fire(2)
					manager:resume()
				end
			end)

			manager:connectEvent("Event", function(...)
				eventSpy(...)
			end)

			manager:suspend()
			instance:Fire(1)
			manager:resume()
			waitForEvents()
			waitForEvents()

			jestExpect(eventSpy).toBeCalledTimes(2)
		end
	)
end)

describe("connectPropertyChange", function()
	-- Since property changes utilize the same mechanisms as other events,
	-- the tests here are slimmed down to reduce redundancy.

	it("should connect to property changes", function()
		local instance = Instance.new("Folder")
		local manager = SingleEventManager.new(instance)
		local eventSpy = jest.fn()

		manager:connectPropertyChange("Name", function(...)
			eventSpy(...)
		end)
		manager:resume()

		instance.Name = "foo"
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(1)
		jestExpect(eventSpy).toBeCalledWith(instance)

		instance.Name = "bar"
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(2)
		jestExpect(eventSpy).toBeCalledWith(instance)

		manager:connectPropertyChange("Name")

		instance.Name = "baz"
		waitForEvents()

		jestExpect(eventSpy).toBeCalledTimes(2)
	end)

	it("should throw an error if the property is invalid", function()
		local instance = Instance.new("Folder")
		local manager = SingleEventManager.new(instance)

		jestExpect(function()
			manager:connectPropertyChange("foo", function() end)
		end).toThrow()
	end)
end)
