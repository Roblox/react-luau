--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]

local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local afterEach = JestGlobals.afterEach
local beforeEach = JestGlobals.beforeEach
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local jest = JestGlobals.jest
local Roact
local RoactCompat

local prevCompatWarnings
beforeEach(function()
	prevCompatWarnings = _G.__COMPAT_WARNINGS__
	-- Silence warnings; we're intersted in functionality in these tests
	_G.__COMPAT_WARNINGS__ = false
end)

afterEach(function()
	_G.__COMPAT_WARNINGS__ = prevCompatWarnings
end)

describe("Concurrent root (default behavior)", function()
	local prevInlineAct, prevMockScheduler
	beforeEach(function()
		prevInlineAct = _G.__ROACT_17_INLINE_ACT__
		prevMockScheduler = _G.__ROACT_17_MOCK_SCHEDULER__
		_G.__ROACT_17_INLINE_ACT__ = true
		_G.__ROACT_17_MOCK_SCHEDULER__ = true
		jest.resetModules()
		Roact = require(Packages.Dev.Roact)
		RoactCompat = require(script.Parent.Parent)
	end)

	afterEach(function()
		_G.__ROACT_17_INLINE_ACT__ = prevInlineAct
		_G.__ROACT_17_MOCK_SCHEDULER__ = prevMockScheduler
	end)

	it("should create an orphaned instance to mount under if none is provided", function()
		local ref = RoactCompat.createRef()
		local tree = RoactCompat.mount(RoactCompat.createElement("Frame", { ref = ref }))

		jestExpect(ref.current).never.toBeNil()
		jestExpect(ref.current.Parent).never.toBeNil()
		jestExpect(ref.current.Parent.ClassName).toBe("Folder")

		jestExpect(ref.current.Name).toBe("ReactRoot")

		RoactCompat.unmount(tree)
	end)

	it("should name children using the key", function()
		local legacyTarget = Instance.new("Folder")
		local legacyTree =
			Roact.mount(Roact.createElement("Frame"), legacyTarget, "SameNameTree")

		local compatTarget = Instance.new("Folder")
		local compatTree = RoactCompat.mount(
			RoactCompat.createElement("Frame"),
			compatTarget,
			"SameNameTree"
		)

		local legacyRootInstance = legacyTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(legacyRootInstance).never.toBeNil()
		local compatRootInstance = compatTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(compatRootInstance).never.toBeNil()

		jestExpect(legacyRootInstance.Name).toEqual(compatRootInstance.Name)
		jestExpect(compatRootInstance.Name).toBe("SameNameTree")

		Roact.unmount(legacyTree)
		RoactCompat.unmount(compatTree)
	end)

	it("keeps the same root name on update", function()
		local legacyTarget = Instance.new("Folder")
		local legacyTree =
			Roact.mount(Roact.createElement("Frame"), legacyTarget, "SameNameTree")

		local compatTarget = Instance.new("Folder")
		local compatTree = RoactCompat.mount(
			RoactCompat.createElement("Frame"),
			compatTarget,
			"SameNameTree"
		)

		local legacyRootInstance = legacyTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(legacyRootInstance.Name).toBe("SameNameTree")
		local compatRootInstance = compatTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(compatRootInstance.Name).toBe("SameNameTree")

		Roact.update(legacyTree, Roact.createElement("TextLabel"))
		RoactCompat.update(compatTree, RoactCompat.createElement("TextLabel"))

		legacyRootInstance = legacyTarget:FindFirstChildWhichIsA("TextLabel")
		jestExpect(legacyRootInstance.Name).toBe("SameNameTree")
		compatRootInstance = compatTarget:FindFirstChildWhichIsA("TextLabel")
		jestExpect(compatRootInstance.Name).toBe("SameNameTree")

		Roact.unmount(legacyTree)
		RoactCompat.unmount(compatTree)
	end)

	it("should not clear out other children of the target", function()
		local compatTarget = Instance.new("Folder")

		local preexistingChild = Instance.new("Frame")
		preexistingChild.Name = "PreexistingChild"
		preexistingChild.Parent = compatTarget

		local compatTree = RoactCompat.mount(
			RoactCompat.createElement("TextLabel"),
			compatTarget,
			"RoactTree"
		)

		local compatRootInstance = compatTarget:FindFirstChildWhichIsA("TextLabel")
		jestExpect(compatRootInstance.Name).toBe("RoactTree")

		local existingChild = compatTarget:FindFirstChildWhichIsA("Frame")
		jestExpect(existingChild.Name).toBe("PreexistingChild")

		RoactCompat.unmount(compatTree)
	end)
end)

describe("Legacy root", function()
	local previousGlobalValue
	beforeEach(function()
		previousGlobalValue = _G.__ROACT_17_COMPAT_LEGACY_ROOT__
		_G.__ROACT_17_COMPAT_LEGACY_ROOT__ = true
		jest.resetModules()
		Roact = require(Packages.Dev.Roact)
		RoactCompat = require(script.Parent.Parent)
	end)

	afterEach(function()
		_G.__ROACT_17_COMPAT_LEGACY_ROOT__ = previousGlobalValue
	end)

	it("should create an orphaned instance to mount under if none is provided", function()
		local ref = RoactCompat.createRef()
		local tree = RoactCompat.mount(RoactCompat.createElement("Frame", { ref = ref }))

		jestExpect(ref.current).never.toBeNil()
		jestExpect(ref.current.Parent).never.toBeNil()
		jestExpect(ref.current.Parent.ClassName).toBe("Folder")

		jestExpect(ref.current.Name).toBe("ReactLegacyRoot")

		RoactCompat.unmount(tree)
	end)
end)
