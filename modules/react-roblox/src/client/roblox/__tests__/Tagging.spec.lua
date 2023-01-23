--!strict
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

local React
local ReactRoblox
local Scheduler
local Tag

local CollectionService = game:GetService("CollectionService")
local Packages = script.Parent.Parent.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local waitForEvents = require(script.Parent.waitForEvents)
local beforeEach = JestGlobals.beforeEach
local afterEach = JestGlobals.afterEach
local it = JestGlobals.it
local describe = JestGlobals.describe

beforeEach(function()
	jest.resetModules()
	React = require(Packages.React)
	ReactRoblox = require(Packages.ReactRoblox)
	Scheduler = require(Packages.Scheduler)
	Tag = require(Packages.React).Tag
end)

describe("adding tags", function()
	local root, parent
	local tag1AddedMock, tag2AddedMock
	local tag1AddedConnection, tag2AddedConnection
	beforeEach(function()
		local tag1Mock, tag1Fn = jest.fn()
		local tag2Mock, tag2Fn = jest.fn()
		tag1AddedConnection = CollectionService:GetInstanceAddedSignal("tag1")
			:Connect(tag1Fn)
		tag2AddedConnection = CollectionService:GetInstanceAddedSignal("tag2")
			:Connect(tag2Fn)

		tag1AddedMock = tag1Mock
		tag2AddedMock = tag2Mock

		parent = Instance.new("Folder")
		parent.Parent = game:GetService("Workspace")
		root = ReactRoblox.createRoot(parent)
	end)

	afterEach(function()
		tag1AddedConnection:Disconnect()
		tag2AddedConnection:Disconnect()

		root:unmount()
		parent:Destroy()
	end)

	it("should add a single tag", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag1",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1AddedMock).toHaveBeenCalledWith(ref.current)
		jestExpect(CollectionService:GetTagged("tag1")).toEqual({ ref.current })
	end)

	it("should add several tags", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag1 tag2",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1AddedMock).toHaveBeenCalledWith(ref.current)
		jestExpect(tag2AddedMock).toHaveBeenCalledWith(ref.current)
		jestExpect(CollectionService:GetTagged("tag1")).toEqual({ ref.current })
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({ ref.current })
	end)

	it("should add tags to several children", function()
		local textLabelRef, textBoxRef = React.createRef(), React.createRef()
		root:render(React.createElement(
			"Frame",
			nil,
			React.createElement("TextLabel", {
				ref = textLabelRef,
				[Tag] = "tag1",
			}),
			React.createElement("TextBox", {
				ref = textBoxRef,
				[Tag] = "tag1",
			})
		))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1AddedMock).toHaveBeenCalledWith(textLabelRef.current)
		jestExpect(tag1AddedMock).toHaveBeenCalledWith(textBoxRef.current)

		-- We don't have any guarantees about order from the engine, so we
		-- just check that both instances are present
		local tags = CollectionService:GetTagged("tag1")
		jestExpect(tags).toHaveLength(2)
		jestExpect(tags).toContain(textLabelRef.current)
		jestExpect(tags).toContain(textBoxRef.current)
	end)

	it("should add no tags when given an empty string", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(CollectionService:GetTags(ref.current)).toEqual({})
	end)

	it("should not change tags that are re-ordered", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag1 tag2",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1AddedMock).toHaveBeenCalledTimes(1)
		jestExpect(tag2AddedMock).toHaveBeenCalledTimes(1)

		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag2 tag1",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1AddedMock).toHaveBeenCalledTimes(1)
		jestExpect(tag2AddedMock).toHaveBeenCalledTimes(1)
	end)
end)

describe("removing tags", function()
	local root, parent
	local tag1RemovedMock, tag2RemovedMock
	local tag1RemovedConnection, tag2RemovedConnection

	beforeEach(function()
		local tag1Mock, tag1Fn = jest.fn()
		local tag2Mock, tag2Fn = jest.fn()
		tag1RemovedConnection = CollectionService:GetInstanceRemovedSignal("tag1")
			:Connect(tag1Fn)
		tag2RemovedConnection = CollectionService:GetInstanceRemovedSignal("tag2")
			:Connect(tag2Fn)

		tag1RemovedMock = tag1Mock
		tag2RemovedMock = tag2Mock

		parent = Instance.new("Folder")
		parent.Parent = game:GetService("Workspace")
		root = ReactRoblox.createRoot(parent)
	end)

	afterEach(function()
		tag1RemovedConnection:Disconnect()
		tag2RemovedConnection:Disconnect()

		root:unmount()
		parent:Destroy()
	end)

	it("should remove a tag when updated", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag1",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(CollectionService:GetTagged("tag1")).toEqual({ ref.current })
		root:render(React.createElement("TextLabel", {
			ref = ref,
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1RemovedMock).toHaveBeenCalledWith(ref.current)
		jestExpect(CollectionService:GetTagged("tag1")).toEqual({})
	end)

	it("should remove one tag in a list when updated", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag1 tag2",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(CollectionService:GetTagged("tag1")).toEqual({ ref.current })
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({ ref.current })

		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag2",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1RemovedMock).toHaveBeenCalledWith(ref.current)
		jestExpect(tag2RemovedMock).never.toHaveBeenCalled()
		jestExpect(CollectionService:GetTagged("tag1")).toEqual({})
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({ ref.current })
	end)

	it("should remove several tags when updated", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag1 tag2",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(CollectionService:GetTagged("tag1")).toEqual({ ref.current })
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({ ref.current })

		root:render(React.createElement("TextLabel", {
			ref = ref,
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1RemovedMock).toHaveBeenCalledWith(ref.current)
		jestExpect(tag2RemovedMock).toHaveBeenCalledWith(ref.current)
		jestExpect(CollectionService:GetTagged("tag1")).toEqual({})
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({})
	end)

	it("should remove tags on unmount", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag1 tag2",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(CollectionService:GetTagged("tag1")).toEqual({ ref.current })
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({ ref.current })

		root:render(nil)
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1RemovedMock).toHaveBeenCalledTimes(1)
		jestExpect(tag2RemovedMock).toHaveBeenCalledTimes(1)
		jestExpect(CollectionService:GetTagged("tag1")).toEqual({})
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({})
	end)

	it("should remove tags when provided an empty tag string", function()
		local ref = React.createRef()
		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "tag1 tag2",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(CollectionService:GetTagged("tag1")).toEqual({ ref.current })
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({ ref.current })

		root:render(React.createElement("TextLabel", {
			ref = ref,
			[Tag] = "",
		}))
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()

		jestExpect(tag1RemovedMock).toHaveBeenCalledTimes(1)
		jestExpect(tag2RemovedMock).toHaveBeenCalledTimes(1)
		jestExpect(CollectionService:GetTagged("tag1")).toEqual({})
		jestExpect(CollectionService:GetTagged("tag2")).toEqual({})
	end)
end)

it("should warn when assigning tags with an incorrect type", function()
	local parent = Instance.new("Folder")
	parent.Parent = game:GetService("Workspace")
	local root = ReactRoblox.createRoot(parent)
	local ref = React.createRef()
	root:render(React.createElement("TextLabel", {
		key = "My Label",
		ref = ref,
		[Tag] = 42,
	}))
	jestExpect(function()
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()
	end).toErrorDev(
		"Warning: Type provided for ReactRoblox.Tag is invalid - tags "
			.. "should be specified as a single string, with "
			.. "individual tags delimited by spaces. Instead received:"
			.. "\n42"
	)
end)

it("should warn when assigning tags to unrooted instances", function()
	local parent = Instance.new("Folder")
	local orphanedRoot = ReactRoblox.createRoot(parent)
	local ref = React.createRef()
	orphanedRoot:render(React.createElement("TextLabel", {
		key = "My Label",
		ref = ref,
		[Tag] = "tag1",
	}))
	jestExpect(function()
		Scheduler.unstable_flushAllWithoutAsserting()
		waitForEvents()
	end).toWarnDev(
		'Warning: Tags applied to orphaned TextLabel "My Label" cannot'
			.. " be accessed via CollectionService:GetTagged. If you're relying"
			.. " on tag behavior in a unit test, consider mounting your test"
			.. " root into the DataModel."
	)

	-- Despite the warning, the tag should belong to the instance's set of
	-- tags retrieved via `GetTags`
	jestExpect(CollectionService:GetTags(ref.current)).toEqual({ "tag1" })
	-- However, we expect `GetTagged` for the tag itself to be empty; it
	-- only gets populated when the orphaned root is added to the DataModel
	jestExpect(CollectionService:GetTagged("tag1")).toEqual({})
end)
