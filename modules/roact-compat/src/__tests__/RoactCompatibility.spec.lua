return function()
	local Packages = script.Parent.Parent.Parent
	local RobloxJest = require(Packages.Dev.RobloxJest)
	local jest = require(Packages.Dev.JestRoblox)
	local jestExpect = jest.Globals.expect
	local Roact
	local RoactCompat

	local UNSUPPORTED = {
		-- Container for features that are unstable in current Roact
		UNSTABLE = true,
		-- Very old aliases for the top-level Roact tree management API
		reify = true,
		reconcile = true,
		teardown = true,
	}

	beforeEach(function()
		RobloxJest.resetModules()
		Roact = require(Packages.Dev.Roact)
		RoactCompat = require(script.Parent.Parent)
	end)

	it("has all interface members that old Roact exposes", function()
		for k, v in pairs(Roact) do
			if UNSUPPORTED[k] then
				-- Skip any API members that are well and truly unsupported
				continue
			end

			jestExpect(RoactCompat).toHaveProperty(k)
			local memberType = typeof(v)
			-- Exports common Roact symbol keys as the reserved key names used
			-- by RoactCompat ("ref" and "children", respectively)
			if k == "Ref" or k == "Children" then
				memberType = "string"
			end
			-- Roact.Portal is replaced by ReactRoblox.createPortal. The
			-- latter is a function that returns a portal object, while the
			-- former is a special component type. By implementing Roact.Portal
			-- as a function component that returns `createPortal`'s result, we
			-- can get similar behavior, but with `Roact.Portal` having a
			-- different type.
			if k == "Portal" then
				memberType = "function"
			end
			jestExpect(typeof(RoactCompat[k])).toBe(memberType)
		end
	end)

	describe("warns about deprecated Roact API features", function()
		it("warns about createFragment", function()
			jestExpect(function()
				RoactCompat.createFragment({ RoactCompat.createElement("div") })
			end).toWarnDev(
				"Warning: The legacy Roact API 'createFragment' is deprecated",
				{ withoutStack = true }
			)
		end)

		-- FIXME: Underlying ReactChildren API not yet ported
		xit("warns about oneChild", function()
			jestExpect(function()
				RoactCompat.oneChild({ RoactCompat.createElement("div") })
			end).toWarnDev(
				"Warning: The legacy Roact API 'oneChild' is deprecated",
				{ withoutStack = true }
			)
		end)

		it("warns about setGlobalConfig", function()
			jestExpect(function()
				RoactCompat.setGlobalConfig({ propValidation = true })
			end).toWarnDev(
				"Warning: The legacy Roact API 'setGlobalConfig' is deprecated",
				{ withoutStack = true }
			)
		end)

		it("warns about Roact.Portal", function()
			local ReactRoblox = require(Packages.ReactRoblox)
			local target = Instance.new("Folder")
			local function withPortal(_props)
				return RoactCompat.createElement(RoactCompat.Portal, {
					target = target,
				}, {
					RoactCompat.createElement("Frame"),
				})
			end
			jestExpect(function()
				local root = ReactRoblox.createLegacyRoot(Instance.new("ScreenGui"))
				root:render(RoactCompat.createElement(withPortal))
			end).toWarnDev(
				"Warning: The legacy Roact API 'Roact.Portal' is deprecated"
			)
		end)

		it("warns about mount", function()
			jestExpect(function()
				RoactCompat.mount(
					RoactCompat.createElement("TextLabel", { Text = "Foo" })
				)
			end).toWarnDev(
				"Warning: The legacy Roact API 'mount' is deprecated",
				{ withoutStack = true }
			)
		end)

		it("warns about update", function()
			local tree = RoactCompat.mount(
				RoactCompat.createElement("TextLabel", { Text = "Foo" })
			)

			jestExpect(function()
				RoactCompat.update(
					tree,
					RoactCompat.createElement("TextLabel", { Text = "Bar" })
				)
			end).toWarnDev(
				"Warning: The legacy Roact API 'update' is deprecated",
				{ withoutStack = true }
			)
		end)

		it("warns about unmount", function()
			local tree = RoactCompat.mount(
				RoactCompat.createElement("TextLabel", { Text = "Foo" })
			)

			jestExpect(function()
				RoactCompat.unmount(tree)
			end).toWarnDev(
				"Warning: The legacy Roact API 'unmount' is deprecated",
				{ withoutStack = true }
			)
		end)
	end)
end
