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
local __DEV__ = _G.__DEV__ :: boolean
local CollectionService = game:GetService("CollectionService")
local Packages = script.Parent.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
local Set = LuauPolyfill.Set
local String = LuauPolyfill.String
local inspect = LuauPolyfill.util.inspect

local console = require(Packages.Shared).console

local React = require(Packages.React)
local ReactSymbols = require(Packages.Shared).ReactSymbols
local SingleEventManager = require(script.Parent.SingleEventManager)
type EventManager = SingleEventManager.EventManager
local Type = require(Packages.Shared).Type
local getDefaultInstanceProperty = require(script.Parent.getDefaultInstanceProperty)
local ReactRobloxHostTypes = require(script.Parent.Parent["ReactRobloxHostTypes.roblox"])
type HostInstance = ReactRobloxHostTypes.HostInstance
local Tag = require(Packages.React).Tag

-- ROBLOX deviation: Essentially a placeholder for dom-specific logic, taking the place
-- of ReactDOMComponent. Most of the logic will differ pretty dramatically

type Array<T> = { [number]: T }
type Object = { [any]: any }

-- deviation: Can't assign attributes to Roblox instances, so we use maps to
-- store associated data for host instance features like binding and event
-- management
-- ROBLOX FIXME: Stronger typing for EventManager

local instanceToEventManager: { [HostInstance]: EventManager } = {}
local instanceToBindings: { [HostInstance]: { [string]: any } } = {}

local applyPropsError = [[
Error applying initial props to Roblox Instance '%s' (%s):
  %s
]]

local updatePropsError = [[
Error updating props on Roblox Instance '%s' (%s):
  %s
]]

local updateBindingError = [[
Error updating binding or ref assigned to key %s of '%s' (%s).

Updated value:
  %s

Error:
  %s

%s
]]

local function identity(...)
	return ...
end

local function setRobloxInstanceProperty(hostInstance, key, newValue): ()
	if newValue == nil then
		local hostClass = hostInstance.ClassName
		local _, defaultValue = getDefaultInstanceProperty(hostClass, key)
		newValue = defaultValue
	end

	-- Assign the new value to the object
	hostInstance[key] = newValue
end

local function removeBinding(hostInstance, key)
	local bindings = instanceToBindings[hostInstance]
	if bindings ~= nil then
		local disconnect = bindings[key]
		disconnect()
		bindings[key] = nil
	end
end

local function attachBinding(hostInstance, key, newBinding): ()
	local function updateBoundProperty(newValue)
		local success, errorMessage =
			xpcall(setRobloxInstanceProperty, identity, hostInstance, key, newValue)

		if not success then
			local source = newBinding._source or "<enable DEV mode for stack>"
			local fullMessage = string.format(
				updateBindingError,
				key,
				hostInstance.Name,
				hostInstance.ClassName,
				tostring(newValue),
				errorMessage,
				source
			)
			console.error(fullMessage)
			-- FIXME: Until console.error can be instrumented to send telemetry, we
			-- need to keep the hard error here
			error(fullMessage, 0)
		end
	end

	if instanceToBindings[hostInstance] == nil then
		instanceToBindings[hostInstance] = {}
	end

	instanceToBindings[hostInstance][key] =
		React.__subscribeToBinding(newBinding, updateBoundProperty)

	updateBoundProperty(newBinding:getValue())
end

local function applyTags(hostInstance: Instance, oldTags: string?, newTags: string?)
	if __DEV__ then
		if newTags ~= nil and typeof(newTags) ~= "string" then
			console.error(
				"Type provided for ReactRoblox.Tag is invalid - tags should be "
					.. "specified as a single string, with individual tags delimited "
					.. "by spaces. Instead received:\n%s",
				inspect(newTags)
			)
			return
		end
	end

	local oldTagSet = Set.new(String.split(oldTags or "", " "))
	local newTagSet = Set.new(String.split(newTags or "", " "))

	for _, tag in oldTagSet do
		if not newTagSet:has(tag) then
			CollectionService:RemoveTag(hostInstance, tag)
		end
	end
	for _, tag in newTagSet do
		if not oldTagSet:has(tag) then
			CollectionService:AddTag(hostInstance, tag)
		end
	end
end

local function removeAllTags(hostInstance: Instance)
	for _, tag in CollectionService:GetTags(hostInstance) do
		CollectionService:RemoveTag(hostInstance, tag)
	end
end

local function applyProp(hostInstance: Instance, key, newValue, oldValue): ()
	-- ROBLOX performance: gets checked in applyProps so we can assume the key is valid
	-- if key == "ref" or key == "children" then
	--   return
	-- end

	local internalKeyType = Type.of(key)

	if internalKeyType == Type.HostEvent or internalKeyType == Type.HostChangeEvent then
		local eventManager = instanceToEventManager[hostInstance]
		if eventManager == nil then
			eventManager = (SingleEventManager.new(hostInstance) :: any) :: EventManager
			instanceToEventManager[hostInstance] = eventManager
		end

		local eventName = key.name

		if internalKeyType == Type.HostChangeEvent then
			eventManager:connectPropertyChange(eventName, newValue)
		else
			eventManager:connectEvent(eventName, newValue)
		end

		return
	end

	-- Handle bindings
	local newIsBinding = typeof(newValue) == "table"
		and newValue["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE
	local oldIsBinding = oldValue ~= nil
		and typeof(oldValue) == "table"
		and oldValue["$$typeof"] == ReactSymbols.REACT_BINDING_TYPE
	if oldIsBinding then
		removeBinding(hostInstance, key)
	end

	if newIsBinding then
		attachBinding(hostInstance, key, newValue)
	elseif key == Tag then
		applyTags(hostInstance, oldValue, newValue)
	else
		setRobloxInstanceProperty(hostInstance, key, newValue)
	end
end

local function applyProps(hostInstance: Instance, props: Object): ()
	for propKey, value in props do
		-- ROBLOX performance: avoid the function call by inlining check here
		if propKey == "ref" or propKey == "children" then
			continue
		end

		applyProp(hostInstance, propKey, value)
	end
end

local function setInitialProperties(
	domElement: HostInstance,
	_tag: string,
	rawProps: Object,
	_rootContainerElement: HostInstance
): ()
	-- deviation: Use Roact's prop application logic
	local success, errorMessage = xpcall(applyProps, identity, domElement, rawProps)
	-- ROBLOX deviation: Roblox renderer doesn't currently track where instances
	-- were created the way that legacy Roact did, but DEV mode should include
	-- component stack traces as a separate warning
	if not success then
		local fullMessage = string.format(
			applyPropsError,
			domElement.Name,
			domElement.ClassName,
			errorMessage
		)
		console.error(fullMessage)
		-- FIXME: Until console.error can be instrumented to send telemetry, we need
		-- to keep the hard error here
		error(fullMessage, 0)
	end

	if instanceToEventManager[domElement] ~= nil then
		instanceToEventManager[domElement]:resume()
	end
end

local function safelyApplyProperties(
	domElement: HostInstance,
	updatePayload: Array<any>,
	lastProps: Object
): ()
	local updatePayloadCount = #updatePayload
	for i = 1, updatePayloadCount, 2 do
		local propKey = updatePayload[i]
		local value = updatePayload[i + 1]
		if value == Object.None then
			value = nil
		end
		-- ROBLOX performance: avoid the function call by inlining check here
		if propKey ~= "ref" and propKey ~= "children" then
			applyProp(domElement, propKey, value, lastProps[propKey])
		end
	end
end

local function updateProperties(
	domElement: HostInstance,
	updatePayload: Array<any>,
	lastProps: Object
): ()
	-- deviation: Use Roact's prop application logic
	if instanceToEventManager[domElement] ~= nil then
		instanceToEventManager[domElement]:suspend()
	end

	local success, errorMessage =
		xpcall(safelyApplyProperties, identity, domElement, updatePayload, lastProps)

	if not success then
		-- ROBLOX deviation: Roblox renderer doesn't currently track where instances
		-- were created the way that legacy Roact did, but DEV mode should include
		-- component stack traces as a separate warning
		local fullMessage = string.format(
			updatePropsError,
			domElement.Name,
			domElement.ClassName,
			errorMessage
		)
		console.error(fullMessage)
		-- FIXME: Until console.error can be instrumented to send telemetry, we need
		-- to keep the hard error here
		error(fullMessage, 0)
	end

	if instanceToEventManager[domElement] ~= nil then
		instanceToEventManager[domElement]:resume()
	end
end

-- ROBLOX deviation: Clear out references to components when they unmount so we
-- avoid leaking memory when they're removed
local function cleanupHostComponent(domElement: HostInstance)
	if instanceToEventManager[domElement] ~= nil then
		instanceToEventManager[domElement] = nil
	end
	if instanceToBindings[domElement] ~= nil then
		instanceToBindings[domElement] = nil
	end

	-- ROBLOX https://jira.rbx.com/browse/LUAFDN-718: Tables are somehow ending up
	-- in this function that expects Instances. In that case, we won't be able to
	-- iterate through its descendants.
	if typeof(domElement :: any) ~= "Instance" then
		return
	end

	removeAllTags(domElement)
	for _, descElement in domElement:GetDescendants() do
		if instanceToEventManager[descElement] ~= nil then
			instanceToEventManager[descElement] = nil
		end
		if instanceToBindings[descElement] ~= nil then
			instanceToBindings[descElement] = nil
		end
		removeAllTags(domElement)
	end
end

return {
	setInitialProperties = setInitialProperties,
	updateProperties = updateProperties,
	cleanupHostComponent = cleanupHostComponent,

	-- ROBLOX deviation: expose maps to test for Instance cleanups
	_instanceToEventManager = instanceToEventManager,
	_instanceToBindings = instanceToBindings,
}
