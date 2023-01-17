-- ROBLOX upstream: https://github.com/facebook/react/blob/2ba43edc2675380a0f2222f351475bf9d750c6a9/packages/shared/ReactInstanceMap.js
--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

--[[*
 * `ReactInstanceMap` maintains a mapping from a public facing stateful
 * instance (key) and the internal representation (value). This allows public
 * methods to accept the user facing instance as an argument and map them back
 * to internal methods.
 *
 * Note that this module is currently shared and assumed to be stateless.
 * If this becomes an actual Map, that will break.
 ]]

--[[*
 * This API should be called `delete` but we'd have to make sure to always
 * transform these to strings for IE support. When this transform is fully
 * supported we can rename it.
 ]]

local Shared = script.Parent
local Packages = Shared.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Error = LuauPolyfill.Error
local inspect = LuauPolyfill.util.inspect
local getComponentName = require(script.Parent.getComponentName)

local exports = {}

local function isValidFiber(fiber): boolean
	return fiber.tag ~= nil
		and fiber.subtreeFlags ~= nil
		and fiber.lanes ~= nil
		and fiber.childLanes ~= nil
end

exports.remove = function(key)
	key._reactInternals = nil
end

exports.get = function(key)
	local value = key._reactInternals

	-- ROBLOX deviation: we have a crash in production this will help catch
	-- ROBLOX TODO: wrap this in __DEV__
	if not isValidFiber(value) then
		error(
			Error.new(
				"invalid fiber in "
					.. (getComponentName(key) or "UNNAMED Component")
					.. " during get from ReactInstanceMap! "
					.. inspect(value)
			)
		)
	elseif value.alternate ~= nil and not isValidFiber(value.alternate) then
		error(
			Error.new(
				"invalid alternate fiber ("
					.. (getComponentName(key) or "UNNAMED alternate")
					.. ") in "
					.. (getComponentName(key) or "UNNAMED Component")
					.. " during get from ReactInstanceMap! "
					.. inspect(value.alternate)
			)
		)
	end

	return value
end

exports.has = function(key)
	return key._reactInternals ~= nil
end

exports.set = function(key, value)
	-- ROBLOX deviation: we have a crash in production this will help catch
	-- ROBLOX TODO: wrap this in __DEV__
	local parent = value
	local message
	while parent ~= nil do
		if not isValidFiber(parent) then
			message = "invalid fiber in "
				.. (getComponentName(key) or "UNNAMED Component")
				.. " being set in ReactInstanceMap! "
				.. inspect(parent)
				.. "\n"

			if value ~= parent then
				message ..= " (from original fiber " .. (getComponentName(key) or "UNNAMED Component") .. ")"
			end
			error(Error.new(message))
		elseif
			(parent :: any).alternate ~= nil
			and not isValidFiber((parent :: any).alternate)
		then
			message = "invalid alternate fiber ("
				.. (getComponentName(key) or "UNNAMED alternate")
				.. ") in "
				.. (getComponentName(key) or "UNNAMED Component")
				.. " being set in ReactInstanceMap! "
				.. inspect((parent :: any).alternate)
				.. "\n"

			if value ~= parent then
				message ..= " (from original fiber " .. (getComponentName(key) or "UNNAMED Component") .. ")"
			end
			error(Error.new(message))
		end
		parent = (parent :: any).return_
	end

	(key :: any)._reactInternals = value
end

return exports
