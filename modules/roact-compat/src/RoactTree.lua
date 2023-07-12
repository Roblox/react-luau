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
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local inspect = LuauPolyfill.util.inspect
local ReactRoblox = require(Packages.ReactRoblox)
type RootType = ReactRoblox.RootType

local warnOnce = require(script.Parent.warnOnce)

type RoactHandle = {
	root: RootType,
	key: string | number,
	parent: any, -- ROBLOX TODO: Instance?
}

local function mount(element: any, parent: any, key: string?): RoactHandle
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
		warnOnce("mount", "Please use the createRoot API in ReactRoblox")
	end

	if parent ~= nil and typeof(parent) ~= "Instance" then
		error(
			string.format(
				"Cannot mount element (`%s`) into a parent that is not a Roblox Instance (got type `%s`) \n%s",
				(function()
					if element then
						return tostring(element.type)
					end
					return "<unknown>"
				end)(),
				typeof(parent),
				(function()
					if parent ~= nil then
						return inspect(parent)
					end
					return ""
				end)()
			)
		)
	end

	-- Since we use portals to actually parent to the provided parent argument,
	-- the container instance that we provide to createRoot is just a
	-- dummy instance.
	local root
	if _G.__ROACT_17_COMPAT_LEGACY_ROOT__ then
		root = ReactRoblox.createLegacyRoot(Instance.new("Folder"))
	else
		root = ReactRoblox.createRoot(Instance.new("Folder"))
	end
	if parent == nil then
		local newParent = Instance.new("Folder")
		newParent.Name = "Target"
		parent = newParent
	end
	if key == nil then
		if _G.__ROACT_17_COMPAT_LEGACY_ROOT__ then
			key = "ReactLegacyRoot"
		else
			key = "ReactRoot"
		end
	end

	-- ROBLOX TODO: remove INLINE_ACT flag when all tests are updated to use
	-- `act` explicitly
	if _G.__ROACT_17_INLINE_ACT__ then
		ReactRoblox.act(function()
			root:render(ReactRoblox.createPortal({ [key] = element }, parent))
		end)
	else
		root:render(ReactRoblox.createPortal({ [key] = element }, parent))
	end

	return {
		root = root,
		-- To preserve the same key and portal to the same parent on update, we
		-- need to stash them in the opaque "tree" reference returned by `mount`
		parent = parent,
		key = key :: string,
	}
end

local function update(roactHandle: RoactHandle, element)
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
		warnOnce("update", "Please use the createRoot API in ReactRoblox")
	end

	local key = roactHandle.key
	local parent = roactHandle.parent
	-- ROBLOX TODO: remove INLINE_ACT flag when all tests are updated to use
	-- `act` explicitly
	if _G.__ROACT_17_INLINE_ACT__ then
		ReactRoblox.act(function()
			roactHandle.root:render(
				ReactRoblox.createPortal({ [key :: string] = element }, parent)
			)
		end)
	else
		roactHandle.root:render(
			ReactRoblox.createPortal({ [key :: string] = element }, parent)
		)
	end

	return roactHandle
end

local function unmount(roactHandle: RoactHandle)
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
		warnOnce("unmount", "Please use the createRoot API in ReactRoblox")
	end

	-- ROBLOX TODO: remove INLINE_ACT flag when all tests are updated to use
	-- `act` explicitly
	if _G.__ROACT_17_INLINE_ACT__ then
		ReactRoblox.act(function()
			roactHandle.root:unmount()
		end)
	else
		roactHandle.root:unmount()
	end
end

return {
	mount = mount,
	update = update,
	unmount = unmount,
}
