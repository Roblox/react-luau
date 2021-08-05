-- upstream: https://github.com/facebook/react/blob/0cf22a56a18790ef34c71bef14f64695c0498619/packages/react/src/ReactBaseClasses.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local invariant = require(Packages.Shared).invariant
local ReactNoopUpdateQueue = require(script.Parent.ReactNoopUpdateQueue)
local emptyObject = {}

if _G.__DEV__ then
  Object.freeze(emptyObject)
end

-- ROBLOX DEVIATION: Initialize state to a singleton that warns on access and errors on assignment
-- initial state singleton
local UninitializedState = require(Packages.Shared).UninitializedState


--[[*
 * Base class helpers for the updating state of a component.
]]
-- FIXME: Due to metatable inheritance, this field will be accessible and true
-- on class component _instances_ as well as class component definitions; this
-- is probably not correct
local componentClassPrototype = {}
componentClassPrototype.isReactComponent = true

-- ROBLOX deviation: logic to support old Roact lifecycle method names
-- ROBLOX FIXME: remove below table and function once we've formally stopped
-- supporting old Roact lifecycle method names.

local function trimPath(path)
  -- ROBLOX TODO: The path splits files by . but file names can
  -- have . in them, so we use best guess heuristics to determine
  -- the file name breaks.
  -- Works for our codebase, but is pretty brittle.

  local pascalFile = string.match(path, "%.%u[%.%w]-$")
  if pascalFile then
    return string.gsub(pascalFile, "^%.", "")
  end

  return path
end

local function warnAboutExistingLifecycle(componentName, newName, existingName)
  console.warn(
    "%s already defined '%s', but it also defining the deprecated Roact method '%s'. %s should only implement one of these methods, preferably using the non-deprecated name.",
    componentName, existingName, newName, componentName)
end

local function warnAboutDeprecatedLifecycleName(componentName, newName, existingName)
  if _G.__DEV__ then
    local path, linenum = debug.info(3, "sln")
    console.warn(
      "%s is using method '%s', which is no longer supported and should be updated to '%s'\nFile: %s:%s",
      componentName, newName, existingName, trimPath(path), tostring(linenum))
  end
end

local lifecycleNames = {
  didMount = 'componentDidMount',
  shouldUpdate = 'shouldComponentUpdate',
  willUpdate = 'UNSAFE_componentWillUpdate',
  didUpdate = 'componentDidUpdate',
  willUnmount = 'componentWillUnmount'
}

local function handleNewLifecycle(self, key, value)
  -- if we're defining a new lifecycle method using old naming convention
  if lifecycleNames[key] ~= nil then
    -- if the method we're defining was already defined under a different name
    if self[lifecycleNames[key]] ~= nil then
      warnAboutExistingLifecycle(self.__componentName, key, lifecycleNames[key])
    -- special case for willUpdate which can be defined properly with 2 different names
    elseif key == 'willUpdate' and self["componentWillUpdate"] then
      warnAboutExistingLifecycle(self.__componentName, key, "UNSAFE_componentWillUpdate")
    -- otherwise if not previously defined, just warn about deprecated name
    else
      warnAboutDeprecatedLifecycleName(self.__componentName, key, lifecycleNames[key])
    end
    -- update key to proper name
    key = lifecycleNames[key]
  end
  rawset(self, key, value)
end

local componentClassMetatable = {
  __newindex = handleNewLifecycle,
  __index = componentClassPrototype,
  __tostring = function(self)
    return self.__componentName
  end,
}

local Component = {}
setmetatable(Component, componentClassMetatable)
Component.__componentName = "Component"

-- ROBLOX deviation: Lua doesn't expose inheritance in a class-syntax way
--[[
  A method called by consumers of Roact to create a new component class.
  Components can not be extended beyond this point, with the exception of
  PureComponent.
]]
function Component:extend(name)
  -- ROBLOX note: legacy Roact will accept nil here and default to empty string
  -- ROBLOX TODO: if name in "" in ReactComponentStack frame, we should try and get the variable name it was assigned to
  if name == nil then
    console.warn("Component:extend() accepting no arguments is deprecated, and will "
        .. "not be supported in a future version of Roact. Please provide an explicit name.")
    name = ""
  end

  assert(typeof(name) == "string", "Component class name must be a string")


  local class = {}

  for key, value in pairs(self) do
    -- Roact opts to make consumers use composition over inheritance, which
    -- lines up with React.
    -- https://reactjs.org/docs/composition-vs-inheritance.html
    if key ~= "extend" then
      class[key] = value
    end
  end

  class.__index = class
  class.__componentName = name

  function class.__ctor(props, context, updater)
    local instance = {}

    instance.props = props
    instance.context = context
    -- ROBLOX DEVIATION: Initialize state to a singleton that warns on attempts
    -- to access this pseudo-uninitialized state and errors on attempts to directly mutate
    -- state.
    instance.state = UninitializedState
    -- If a component has string refs, we will assign a different object later.
    -- ROBLOX deviation: Uses __refs instead of refs to avoid conflicts
    -- instance.refs = emptyObject
    instance.__refs = emptyObject
    -- We initialize the default updater but the real one gets injected by the
    -- renderer.
    instance.__updater = updater or ReactNoopUpdateQueue

    -- ROBLOX TODO: We should consider using a more idiomatic Lua approach for
    -- warning/blocking lifecycle calls during initialization. For now,
    -- ReactNoopUpdateQueue accomplishes this, but we might be able to be more
    -- thorough if we use a dummy metamethod that warns precisely on all sorts
    -- of misbehavior
    instance = setmetatable(instance, class)

    -- deviation: TODO: revisit this; make sure that we properly initialize
    -- things like `state` if its necessary, consider if we want some sort of
    -- alternate naming or syntax for the constructor equivalent
    if typeof(class.init) == 'function' then
      function instance.setState(_, initialState)
        instance.state = initialState
      end

      class.init(instance, props, context)

      instance.setState = (nil :: any)
    end

    return instance
  end


  setmetatable(class, getmetatable(self))

  return class
end

--[[*
 * Sets a subset of the state. Always use this to mutate
 * state. You should treat `self.state` as immutable.
 *
 * There is no guarantee that `self.state` will be immediately updated, so
 * accessing `self.state` after calling this method may return the old value.
 *
 * There is no guarantee that calls to `setState` will run synchronously,
 * as they may eventually be batched together.  You can provide an optional
 * callback that will be executed when the call to setState is actually
 * completed.
 *
 * When a function is provided to setState, it will be called at some point in
 * the future (not synchronously). It will be called with the up to date
 * component arguments (state, props, context). These values can be different
 * from self.* because your function may be called after receiveProps but before
 * shouldComponentUpdate, and this new state, props, and context will not yet be
 * assigned to self.
 *
 * @param {object|function} partialState Next partial state or function to
 *        produce next partial state to be merged with current state.
 * @param {?function} callback Called after state is updated.
 * @final
 * @protected
 ]]
function Component:setState(partialState, callback)
  invariant(
    typeof(partialState) == 'table' or typeof(partialState) == 'function' or partialState == nil,
    'setState(...): takes an object of state variables to update or a ' .. 'function which returns an object of state variables.'
  )
  self.__updater.enqueueSetState(self, partialState, callback, 'setState')
end

--[[*
 * Forces an update. This should only be invoked when it is known with
 * certainty that we are **not** in a DOM transaction.
 *
 * You may want to call this when you know that some deeper aspect of the
 * component's state has changed but `setState` was not called.
 *
 * This will not invoke `shouldComponentUpdate`, but it will invoke
 * `componentWillUpdate` and `componentDidUpdate`.
 *
 * @param {?function} callback Called after update is complete.
 * @final
 * @protected
 ]]


function Component:forceUpdate(callback)
  self.__updater.enqueueForceUpdate(self, callback, 'forceUpdate')
end
--[[*
 * Deprecated APIs. These APIs used to exist on classic React classes but since
 * we would like to deprecate them, we're not going to move them over to this
 * modern base class. Instead, we define a getter that warns if it's accessed.
 ]]


if _G.__DEV__ then
  local deprecatedAPIs = {
    isMounted = {'isMounted', 'Instead, make sure to clean up subscriptions and pending requests in ' .. 'componentWillUnmount to prevent memory leaks.'},
    replaceState = {'replaceState', 'Refactor your code to use setState instead (see ' .. 'https:--github.com/facebook/react/issues/3236).'}
  }

  local defineDeprecationWarning = function (methodName, info)
    Component[methodName] =
      function()
        console.warn('%s(...) is deprecated in plain JavaScript React classes. %s', info[1], info[2])
        return nil
      end
  end

  for fnName, _ in pairs(deprecatedAPIs) do
    if deprecatedAPIs[fnName] ~= nil then
      defineDeprecationWarning(fnName, deprecatedAPIs[fnName])
    end
  end
end

--[[*
 * Convenience component with default shallow equality check for sCU.
 ]]
-- deviation: work within the `extend` framework defined above to emulate JS's
-- class inheritance
local PureComponent = Component:extend("PureComponent")

-- When extend()ing a component, you don't get an extend method.
-- This is to promote composition over inheritance.
-- PureComponent is an exception to this rule.
PureComponent.extend = Component.extend

-- deviation: We copy members directly from the Component prototype above; we
-- don't need to redefine the constructor or do dummy function trickery to apply
-- it without jumping around
local pureComponentClassPrototype = {}
Object.assign(pureComponentClassPrototype, componentClassPrototype)
pureComponentClassPrototype.isPureReactComponent = true

-- ROBLOX: FIXME: we should clean this up and align the implementations of
-- Component and PureComponent more clearly and explicitly
setmetatable(PureComponent, {
  __newindex = handleNewLifecycle,
  __index = pureComponentClassPrototype,
  __tostring = function(self)
    return self.__componentName
  end,
})

return {
  Component = Component,
  PureComponent = PureComponent,
}
