-- ROBLOX upstream: https://github.com/Roblox/roact/blob/b2ba9cf4c219c2654e6572219a68d0bf1b541418/src/getDefaultInstanceProperty.spec.lua
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
local it = JestGlobals.it
local getDefaultInstanceProperty =
	require(script.Parent.Parent.getDefaultInstanceProperty)

it("should get default name string values", function()
	local _, defaultName = getDefaultInstanceProperty("StringValue", "Name")

	jestExpect(defaultName).toBe("Value")
end)

it("should get default empty string values", function()
	local _, defaultValue = getDefaultInstanceProperty("StringValue", "Value")

	jestExpect(defaultValue).toBe("")
end)

it("should get default number values", function()
	local _, defaultValue = getDefaultInstanceProperty("IntValue", "Value")

	jestExpect(defaultValue).toBe(0)
end)

it("should get nil default values", function()
	local _, defaultValue = getDefaultInstanceProperty("ObjectValue", "Value")

	jestExpect(defaultValue).toBe(nil)
end)

it("should get bool default values", function()
	local _, defaultValue = getDefaultInstanceProperty("BoolValue", "Value")

	jestExpect(defaultValue).toBe(false)
end)
