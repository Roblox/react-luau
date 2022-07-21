local Packages = script.Parent.Parent.Parent

local RobloxComponentProps
local setInitialTags
local updateTags
local removeTags
local getInstancesForTag
local Tag
local RobloxJest

return function()
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	RobloxJest = require(Packages.Dev.RobloxJest)

	describe("TestRenderer Tag Support", function()
		beforeEach(function()
			RobloxJest.resetModules()
			RobloxComponentProps = require(script.Parent.Parent.roblox.RobloxComponentProps)
			setInitialTags = RobloxComponentProps.setInitialTags
			updateTags = RobloxComponentProps.updateTags
			removeTags = RobloxComponentProps.removeTags
			getInstancesForTag = RobloxComponentProps.getInstancesForTag
			Tag = require(Packages.Shared).Tag
		end)

		it("should set initial tags for an instance", function()
			local rootContainer = "rootContainer1"
			local hostInstances = {
				{
					props = { [Tag] = "foo" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "bar" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "foo,bar" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "bar" },
					rootContainerInstance = rootContainer,
				},
			}

			for _, inst in hostInstances do
				setInitialTags(inst, "Instance", inst.props, inst.rootContainerInstance)
			end

			local fooTags = getInstancesForTag(rootContainer, "foo")
			jestExpect(#fooTags).toEqual(2)
			jestExpect(fooTags).toEqual({
				hostInstances[1],
				hostInstances[3],
			})

			local barTags = getInstancesForTag(rootContainer, "bar")
			jestExpect(#barTags).toEqual(3)
			jestExpect(barTags).toEqual({
				hostInstances[2],
				hostInstances[3],
				hostInstances[4],
			})
		end)

		it("should update tags", function()
			local rootContainer = "rootContainer1"
			local hostInstances = {
				{
					props = { [Tag] = "foo" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "bar" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "foo,bar" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "bar" },
					rootContainerInstance = rootContainer,
				},
			}

			for _, inst in hostInstances do
				setInitialTags(inst, "Instance", inst.props, inst.rootContainerInstance)
			end

			local newProps = {
				{ [Tag] = "foo,bar" },
				{ [Tag] = "baz" },
				{ [Tag] = "baz"},
				{ [Tag] = "bar"}
			}

			for i, inst in hostInstances do
				updateTags(inst, newProps[i], inst.props)
			end

			local fooTags = getInstancesForTag(rootContainer, "foo")
			jestExpect(#fooTags).toEqual(1)
			jestExpect(fooTags).toEqual({
				hostInstances[1],
			})

			local barTags = getInstancesForTag(rootContainer, "bar")
			jestExpect(#barTags).toEqual(2)
			jestExpect(barTags).toEqual({
				hostInstances[4],
				hostInstances[1],
			})

			local bazTags = getInstancesForTag(rootContainer, "baz")
			jestExpect(#bazTags).toEqual(2)
			jestExpect(bazTags).toEqual({
				hostInstances[2],
				hostInstances[3],
			})
		end)

		it("should remove tags", function()
			local rootContainer = "rootContainer1"
			local hostInstances = {
				{
					props = { [Tag] = "foo" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "bar" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "foo,bar" },
					rootContainerInstance = rootContainer,
				},
				{
					props = { [Tag] = "bar" },
					rootContainerInstance = rootContainer,
				},
			}

			for _, inst in hostInstances do
				setInitialTags(inst, "Instance", inst.props, inst.rootContainerInstance)
			end

			-- Children should have tags removed as well
			hostInstances[1]["children"] = {
				[2] = hostInstances[2],
				[3] = hostInstances[3]
			}

			removeTags(hostInstances[1])

			local fooTags = getInstancesForTag(rootContainer, "foo")
			jestExpect(#fooTags).toEqual(0)

			local barTags = getInstancesForTag(rootContainer, "bar")
			jestExpect(#barTags).toEqual(1)
			jestExpect(barTags).toEqual({
				hostInstances[4],
			})
		end)
	end)
end
