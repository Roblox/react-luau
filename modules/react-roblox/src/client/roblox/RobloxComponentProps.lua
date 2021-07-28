local Packages = script.Parent.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object

local Binding = require(script.Parent.Binding)
local SingleEventManager = require(script.Parent.SingleEventManager)
local Type = require(script.Parent.Type)
local getDefaultInstanceProperty = require(script.Parent.getDefaultInstanceProperty)
local ReactRobloxHostTypes = require(script.Parent.Parent["ReactRobloxHostTypes.roblox"])
type HostInstance = ReactRobloxHostTypes.HostInstance;

-- ROBLOX deviation: Essentially a placeholder for dom-specific logic, taking the place
-- of ReactDOMComponent. Most of the logic will differ pretty dramatically

type Array<T> = { [number]: T }
type Object = { [any]: any }

-- deviation: Can't assign attributes to Roblox instances, so we use maps to
-- store associated data for host instance features like binding and event
-- management
-- ROBLOX FIXME: Stronger typing for EventManager
type EventManager = Object;
local instanceToEventManager: { [HostInstance]: EventManager } = {}
local instanceToBindings: { [HostInstance]: { [string]: any } } = {}

local applyPropsError = [[
Error applying initial props:
  %s
In element:
  %s
]]

local updatePropsError = [[
Error updating props:
  %s
In element:
  %s
]]

local function identity(...)
  return ...
end

local function setRobloxInstanceProperty(hostInstance, key, newValue)
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

local function attachBinding(hostInstance, key, newBinding)
  local function updateBoundProperty(newValue)
    local success, errorMessage = xpcall(function()
      setRobloxInstanceProperty(hostInstance, key, newValue)
    end, identity)

    if not success then
      -- ROBLOX FIXME: Binding update error messages
      error(errorMessage, 0)
    end
  end

  if instanceToBindings[hostInstance] == nil then
    instanceToBindings[hostInstance] = {}
  end

  instanceToBindings[hostInstance][key] = Binding.subscribe(newBinding, updateBoundProperty)

  updateBoundProperty(newBinding:getValue())
end

-- local function detachAllBindings(virtualNode)
--   if virtualNode.bindings ~= nil then
--     for _, disconnect in pairs(virtualNode.bindings) do
--       disconnect()
--     end
--   end
-- end

local function applyProp(hostInstance, key, newValue, oldValue)
  if key == "ref" or key == "children" then
    return
  end

  local internalKeyType = Type.of(key)

  if internalKeyType == Type.HostEvent or internalKeyType == Type.HostChangeEvent then
    local eventManager = instanceToEventManager[hostInstance]
    if eventManager == nil then
      eventManager = SingleEventManager.new(hostInstance)
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
  local newIsBinding = Type.of(newValue) == Type.Binding
  local oldIsBinding = Type.of(oldValue) == Type.Binding

  if oldIsBinding then
    removeBinding(hostInstance, key)
  end

  if newIsBinding then
    attachBinding(hostInstance, key, newValue)
  else
    setRobloxInstanceProperty(hostInstance, key, newValue)
  end
end

local function applyProps(hostInstance, props)
  for propKey, value in pairs(props) do
    applyProp(hostInstance, propKey, value, nil)
  end
end


local function setInitialProperties(
  domElement: HostInstance,
  _tag: string,
  rawProps: Object,
  _rootContainerElement: HostInstance
)
  -- deviation: Use Roact's prop application logic
  local success, errorMessage = xpcall(function()
    applyProps(domElement, rawProps)
  end, identity)

  -- ROBLOX deviation: Roblox renderer doesn't currently track where instances were created
  if not success then
  --   local source = domElement.source

    -- if source == nil then
    local source = "<enable element tracebacks>"
    -- end

    -- ROBLOX FIXME: Does this error messaging play nicely with the error logic
    -- in the reconciler?
    local fullMessage = applyPropsError:format(errorMessage, source)
    error(fullMessage, 0)
  end

  if instanceToEventManager[domElement] ~= nil then
    instanceToEventManager[domElement]:resume()
  end
end

local function updateProperties(
  domElement: HostInstance,
  updatePayload: Array<any>,
  lastProps: Object
)
  -- deviation: Use Roact's prop application logic
  if instanceToEventManager[domElement] ~= nil then
    instanceToEventManager[domElement]:suspend()
  end

  local success, errorMessage = xpcall(function()
    local i = 1
    while i <= #updatePayload do
      local propKey = updatePayload[i]
      local value = updatePayload[i+1]
      if value == Object.None then
        value = nil
      end
      applyProp(domElement, propKey, value, lastProps[propKey])
      i += 2
    end
  end, identity)

  if not success then
    -- ROBLOX deviation: Roblox renderer doesn't currently track where instances were created
    -- local source = domElement.source

    -- if source == nil then
    local source = "<enable element tracebacks>"
    -- end

    -- ROBLOX FIXME: Does this error messaging play nicely with the error logic
    -- in the reconciler?
    local fullMessage = updatePropsError:format(errorMessage, source)
    error(fullMessage, 0)
  end

  if instanceToEventManager[domElement] ~= nil then
    instanceToEventManager[domElement]:resume()
  end
end

return {
  setInitialProperties = setInitialProperties,
  updateProperties = updateProperties,
}