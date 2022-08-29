-- ROBLOX upstream: https://github.com/Roblox/roact/blob/b2ba9cf4c219c2654e6572219a68d0bf1b541418/src/getDefaultInstanceProperty.lua
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

--[[
	Attempts to get the default value of a given property on a Roblox instance.

	This is used by the reconciler in cases where a prop was previously set on a
	primitive component, but is no longer present in a component's new props.

	Eventually, Roblox might provide a nicer API to query the default property
	of an object without constructing an instance of it.
]]

local Packages = script.Parent.Parent.Parent.Parent
local Symbol = require(Packages.Shared).Symbol

local Nil = Symbol.named("Nil")
local _cachedPropertyValues = {}

local function tryPropertyName(instance, propertyName)
	return instance[propertyName]
end

local function getDefaultInstanceProperty(className, propertyName)
	local classCache = _cachedPropertyValues[className]

	if classCache then
		local propValue = classCache[propertyName]

		-- We have to use a marker here, because Lua doesn't distinguish
		-- between 'nil' and 'not in a table'
		if propValue == Nil then
			return true, nil
		end

		if propValue ~= nil then
			return true, propValue
		end
	else
		classCache = {}
		_cachedPropertyValues[className] = classCache
	end

	local created = Instance.new(className)
	local ok, defaultValue = pcall(tryPropertyName, created, propertyName)

	created:Destroy()

	if ok then
		if defaultValue == nil then
			classCache[propertyName] = Nil
		else
			classCache[propertyName] = defaultValue
		end
	end

	return ok, defaultValue
end

return getDefaultInstanceProperty
