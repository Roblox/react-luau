-- ROBLOX upstream: https://github.com/facebook/react/blob/b87aabdfe1b7461e7331abb3601d9e6bb27544bc/packages/react/src/ReactCreateRef.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 * @flow
*]]

local Packages = script.Parent.Parent
local ReactTypes = require(Packages.Shared)
type RefObject = ReactTypes.RefObject

-- ROBLOX DEVIATION: In Roact, refs are implemented in terms of bindings
--[[
  A ref is nothing more than a binding with a special field 'current'
  that maps to the getValue method of the binding
]]
local Binding = require(script.Parent["ReactBinding.roblox"])

local exports = {}

-- an immutable object with a single mutable value
exports.createRef = function(): RefObject
	local binding, _ = Binding.create(nil)

	local ref = {}

	-- ROBLOX DEVIATION: Since refs are used as bindings, they can often be
	-- assigned to fields of other Instances; we track creation here parallel to
	-- how we do with bindings created via `createBinding` to improve messaging
	-- when something goes wrong
	if _G.__DEV__ then
		-- ROBLOX TODO: LUAFDN-619 - improve debug stacktraces for refs
		binding._source = debug.traceback("Ref created at:", 1)
	end

	--[[
    A ref is just redirected to a binding via its metatable
  ]]
	setmetatable(ref, {
		__index = function(self, key)
			if key == "current" then
				return binding:getValue()
			else
				return (binding :: any)[key]
			end
		end,
		__newindex = function(self, key, value)
			if key == "current" then
				-- ROBLOX FIXME: Bindings - This is not allowed in Roact, but is okay in
				-- React. Lots of discussion at
				-- https://github.com/DefinitelyTyped/DefinitelyTyped/issues/31065
				-- error("Cannot assign to the 'current' property of refs", 2)
				Binding.update(binding, value)
			end

			(binding :: any)[key] = value
		end,
		__tostring = function(self)
			return string.format("Ref(%s)", tostring(binding:getValue()))
		end,
	})

	return (ref :: any) :: RefObject
end

return exports
