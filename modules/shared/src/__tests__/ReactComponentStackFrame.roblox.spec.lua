--!strict

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
local String = LuauPolyfill.String

local JestGlobals = require(Packages.Dev.JestGlobals)
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local ReactComponentStackFrame = nil

local function assertStringContains(testString: string, subString)
	assert(
		string.find(testString, subString, 1, true),
		string.format("could not find %q in %q", subString, testString)
	)
end

describe("describeNativeComponentFrame", function()
	local describeNativeComponentFrame

	beforeEach(function()
		jest.resetModules()

		ReactComponentStackFrame = require(script.Parent.Parent.ReactComponentStackFrame)
		describeNativeComponentFrame =
			ReactComponentStackFrame.describeNativeComponentFrame
	end)

	it("finds the appropriate line in the stack trace", function()
		local errorMessage = "some error"

		local function FooComponent()
			error(errorMessage)
		end

		local frame = describeNativeComponentFrame(FooComponent, false)
		jestExpect(frame).toBeDefined()
		local lines = String.trim(frame):split("\n")

		jestExpect(#lines).toBe(1)
		assertStringContains(lines[1], "FooComponent")
	end)
end)

describe("with enableComponentStackLocations to false", function()
	beforeEach(function()
		jest.resetModules()

		local ReactFeatureFlags = require(script.Parent.Parent.ReactFeatureFlags)

		-- ROBLOX FIXME: Calling mock after require won't work
		jest.mock(script.Parent.Parent.ReactFeatureFlags :: any, function()
			return Object.assign({}, ReactFeatureFlags, {
				enableComponentStackLocations = false,
			})
		end)

		ReactComponentStackFrame = require(script.Parent.Parent.ReactComponentStackFrame)
	end)

	describe("describeBuiltInComponentFrame", function()
		it("shows only the component name if there is no source", function()
			local componentName = "SomeComponent"
			local frame =
				ReactComponentStackFrame.describeBuiltInComponentFrame(componentName)
			assertStringContains(frame, componentName)
		end)

		-- deviation: cannot have a field in a function object
		-- if _G.__DEV__ then
		-- 	it("shows the owner name if there is no source", function()
		-- 		local owner = function() end
		--  	owner.displayName = "foo"
		-- 		local frame = ReactComponentStackFrame.describeBuiltInComponentFrame(
		-- 			"FooComponent",
		-- 			nil,
		-- 			owner
		-- 		)
		-- 		assertStringContains(
		-- 			frame
		-- 			"created by " .. owner.displayName,
		-- 		)
		-- 	end)
		-- end

		local fileNames = {
			[""] = "",
			["/"] = "",
			["\\"] = "",
			Foo = "Foo",
			["Bar/Foo"] = "Foo",
			["Bar\\Foo"] = "Foo",
			["Baz/Bar/Foo"] = "Foo",
			["Baz\\Bar\\Foo"] = "Foo",
			["Foo.lua"] = "Foo.lua",
			["/Foo.lua"] = "Foo.lua",
			["\\Foo.lua"] = "Foo.lua",
			["Bar/Foo.lua"] = "Foo.lua",
			["Bar\\Foo.lua"] = "Foo.lua",
			["/Bar/Foo.lua"] = "Foo.lua",
			["\\Bar\\Foo.lua"] = "Foo.lua",
			["Bar/Baz/Foo.lua"] = "Foo.lua",
			["Bar\\Baz\\Foo.lua"] = "Foo.lua",
			["/Bar/Baz/Foo.lua"] = "Foo.lua",
			["\\Bar\\Baz\\Foo.lua"] = "Foo.lua",
			["C:\\funny long (path)/Foo.lua"] = "Foo.lua",
			["init.lua"] = "init.lua",
			["/init.lua"] = "init.lua",
			["\\init.lua"] = "init.lua",
			["Bar/init.lua"] = "Bar/init.lua",
			["Bar\\init.lua"] = "Bar/init.lua",
			["/Bar/init.lua"] = "Bar/init.lua",
			["\\Bar\\init.lua"] = "Bar/init.lua",
			["Bar/Baz/init.lua"] = "Baz/init.lua",
			["Bar\\Baz\\init.lua"] = "Baz/init.lua",
			["/Bar/Baz/init.lua"] = "Baz/init.lua",
			["\\Bar\\Baz\\init.lua"] = "Baz/init.lua",
			["C:\\funny long (path)/init.lua"] = "funny long (path)/init.lua",
		}

		local lineNumber = 0
		-- ROBLOX FIXME Luau: need to fix CLI-56768 to remove any casts
		for fileName, expectedFileName in fileNames :: any do
			lineNumber = lineNumber + 1

			it(string.format("converts the file name %q", fileName), function()
				local owner = nil
				local componentName = "SomeComponent"
				local frame = ReactComponentStackFrame.describeBuiltInComponentFrame(
					componentName,
					{
						fileName = fileName,
						lineNumber = lineNumber,
					},
					owner
				)

				if _G.__DEV__ then
					assertStringContains(
						frame,
						string.format(
							"%s (at %s:%d)",
							componentName,
							expectedFileName,
							lineNumber
						)
					)
				else
					assertStringContains(frame, componentName)
				end
			end)
		end
	end)
end)

describe("with enableComponentStackLocations to true", function()
	local describeBuiltInComponentFrame

	beforeEach(function()
		jest.resetModules()

		local ReactFeatureFlags = require(script.Parent.Parent.ReactFeatureFlags)

		-- ROBLOX FIXME: Calling mock after require won't work
		jest.mock(script.Parent.Parent.ReactFeatureFlags :: any, function()
			return Object.assign({}, ReactFeatureFlags, {
				enableComponentStackLocations = true,
			})
		end)

		ReactComponentStackFrame = require(script.Parent.Parent.ReactComponentStackFrame)
		describeBuiltInComponentFrame =
			ReactComponentStackFrame.describeBuiltInComponentFrame
	end)

	describe("describeBuiltInComponentFrame", function()
		it("has the component name", function()
			local componentName = "foo"
			local frame = describeBuiltInComponentFrame(componentName, {
				fileName = "file name",
				lineNumber = 7,
			})

			assertStringContains(frame, componentName)
		end)
	end)
end)

describe("DEV warning stack trace", function()
	local React
	local describeUnknownElementTypeFrameInDev

	beforeEach(function()
		jest.resetModules()
		React = require(Packages.Dev.React)
		describeUnknownElementTypeFrameInDev = require(
			script.Parent.Parent.ReactComponentStackFrame
		).describeUnknownElementTypeFrameInDEV
	end)

	it("should accept class component to describeUnknownElementTypeFrameInDev", function()
		local TestDevStackComponent = React.Component:extend("TestDevStackComponent")

		function TestDevStackComponent:render()
			return if self.state.isFrame
				then React.createElement("Frame")
				else React.createElement("TextLabel", {
					Text = "Hello!",
				})
		end

		local source = {
			fileName = "TestDev-file.lua",
			lineNumber = 20,
		}

		local function DevParent()
			return React.createElement("Frame")
		end

		local description = describeUnknownElementTypeFrameInDev(
			React.createElement(TestDevStackComponent).type,
			source,
			DevParent
		)

		if _G.__DEV__ then
			jestExpect(description).toEqual(
				"\n    in TestDevStackComponent (at TestDev-file.lua:20)"
			)
		else
			jestExpect(description).toEqual("")
		end
	end)

	it(
		"should accept function component in describeUnknownElementTypeFrameInDev",
		function()
			local function DevStackFunctionComponent()
				error("Thrown Error")
				return React.createElement("Frame")
			end

			local source = {
				fileName = "TestDevFunction-file.lua",
				lineNumber = 15,
			}

			local function DevParent()
				return React.createElement("Frame")
			end

			local description = describeUnknownElementTypeFrameInDev(
				React.createElement(DevStackFunctionComponent).type,
				source,
				DevParent
			)

			if _G.__DEV__ then
				jestExpect(description).toEqual(
					"\n    in DevStackFunctionComponent (at TestDevFunction-file.lua:15)"
				)
			else
				jestExpect(description).toEqual("")
			end
		end
	)
end)
