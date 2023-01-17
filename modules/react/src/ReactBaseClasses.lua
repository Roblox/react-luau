--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/0cf22a56a18790ef34c71bef14f64695c0498619/packages/react/src/ReactBaseClasses.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]
local __DEV__ = _G.__DEV__ :: boolean
local __COMPAT_WARNINGS__ = _G.__COMPAT_WARNINGS__ :: boolean
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
type Object = LuauPolyfill.Object
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local SharedModule = require(Packages.Shared)
-- ROBLOX deviation START: we do boolean checks and error() like React 18 does to save functional call in hot path
-- local invariant = SharedModule.invariant
-- ROBLOX deviation END
type React_Component<Props, State = nil> = SharedModule.React_Component<Props, State>
local ReactNoopUpdateQueue = require(script.Parent.ReactNoopUpdateQueue)
local emptyObject = {}

if __DEV__ then
	Object.freeze(emptyObject)
end

-- ROBLOX DEVIATION: Initialize state to a singleton that warns on access and
-- errors on assignment
local UninitializedState = require(Packages.Shared).UninitializedState

--[[*
 * Base class helpers for the updating state of a component.
]]
-- FIXME: Due to metatable inheritance, this field will be accessible and true
-- on class component _instances_ as well as class component definitions; this
-- is probably not correct
local componentClassPrototype = {
	isReactComponent = true,
}

-- ROBLOX deviation: logic to support old Roact lifecycle method names
-- ROBLOX FIXME: remove below table and function once we've formally stopped
-- supporting old Roact lifecycle method names.

-- ROBLOX FIXME Luau: have to annotate this function manually to suppress ReactBaseClasses.lua:55:3-13: (E001) TypeError: Expected to return 2 values, but 1 is returned here
local function trimPath(path: string): string
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
		componentName,
		existingName,
		newName,
		componentName
	)
end

local function warnAboutDeprecatedLifecycleName(componentName, newName, existingName)
	if __DEV__ and __COMPAT_WARNINGS__ then
		local path, linenum = debug.info(3, "sln")
		console.warn(
			"%s is using method '%s', which is no longer supported and should be updated to '%s'\nFile: %s:%s",
			componentName,
			newName,
			existingName,
			trimPath(path),
			tostring(linenum)
		)
	end
end

local lifecycleNames = {
	didMount = "componentDidMount",
	shouldUpdate = "shouldComponentUpdate",
	willUpdate = "UNSAFE_componentWillUpdate",
	didUpdate = "componentDidUpdate",
	willUnmount = "componentWillUnmount",
}

local function handleNewLifecycle(self, key, value)
	-- if we're defining a new lifecycle method using old naming convention
	if lifecycleNames[key] ~= nil then
		-- if the method we're defining was already defined under a different name
		if self[lifecycleNames[key]] ~= nil then
			warnAboutExistingLifecycle(self.__componentName, key, lifecycleNames[key])
		-- special case for willUpdate which can be defined properly with 2 different names
		elseif key == "willUpdate" and self["componentWillUpdate"] then
			warnAboutExistingLifecycle(
				self.__componentName,
				key,
				"UNSAFE_componentWillUpdate"
			)
		-- otherwise if not previously defined, just warn about deprecated name
		else
			warnAboutDeprecatedLifecycleName(
				self.__componentName,
				key,
				lifecycleNames[key]
			)
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

-- ROBLOX deviation: Extend needs to be a table field for our top-level interface
type React_BaseComponent = React_Component<any, any> & {
	extend: (self: React_BaseComponent, name: string) -> React_Component<any, any>,
}

local Component = (
	setmetatable({ __componentName = "Component" }, componentClassMetatable) :: any
) :: React_BaseComponent

-- ROBLOX deviation: Lua doesn't expose inheritance in a class-syntax way
--[[
  A method called by consumers of Roact to create a new component class.
  Components can not be extended beyond this point, with the exception of
  PureComponent.
]]

-- ROBLOX performance: pool size tuned for benchmarks
local InstancePoolSize = if not _G.__TESTEZ_RUNNING_TEST__ then 900 else 0
local InstancePoolIndex = 1
local InstancePool = table.create(InstancePoolSize)
for i = 1, InstancePoolSize do
	table.insert(InstancePool, {
		-- pre-initialize instance fields with known static values
		props = nil,
		context = nil,
		state = UninitializedState,
		__refs = emptyObject,
		__updater = ReactNoopUpdateQueue,
	})
end

local function setStateInInit(
	componentInstance: React_Component<any, any>,
	statePayload: any,
	callback: nil
): ()
	if __DEV__ and (callback :: any) ~= nil then
		console.warn(
			"Received a `callback` argument to `setState` during initialization of "
				.. '"%s". The callback behavior is not supported when using `setState` '
				.. "in `init`.\n\nConsider defining similar behavior in a "
				.. "`compontentDidMount` method instead.",
			componentInstance.__componentName
		)
	end

	-- Use the same warning as in the "real" `setState` below
	local typeStatePayload = statePayload and type(statePayload)
	if
		statePayload == nil
		or (typeStatePayload ~= "table" and typeStatePayload ~= "function")
	then
		error(
			"setState(...): takes an object of state variables to update or a "
				.. "function which returns an object of state variables."
		)
	end
	local prevState = componentInstance.state
	local partialState
	if typeStatePayload == "function" then
		-- Updater function
		partialState = statePayload(prevState, componentInstance.props)
	else
		-- Partial state object
		partialState = statePayload
	end
	-- ROBLOX TODO: can't use table.clone optimization here: invalid argument #1 to 'clone' (table has a protected metatable)
	-- local newState = if prevState then table.clone(prevState) else {}
	componentInstance.state = Object.assign({}, prevState, partialState)
end

function Component:extend(name): React_Component<any, any>
	-- ROBLOX note: legacy Roact will accept nil here and default to empty string
	-- ROBLOX TODO: if name in "" in ReactComponentStack frame, we should try and get the variable name it was assigned to
	if name == nil then
		if __COMPAT_WARNINGS__ then
			console.warn(
				"Component:extend() accepting no arguments is deprecated, and will "
					.. "not be supported in a future version of Roact. Please provide an explicit name."
			)
		end
		name = ""
	elseif type(name) ~= "string" then
		error("Component class name must be a string")
	end

	-- ROBLOX performance? do table literal in one shot instead a field at a time in a pairs() loop
	local class = {
		__componentName = name,
		setState = self.setState,
		forceUpdate = self.forceUpdate,
		init = nil, -- ROBLOX note: required to make Luau analyze happy, should be removed by bytecode compiler
	}
	-- for key, value in self do
	--   -- Roact opts to make consumers use composition over inheritance, which
	--   -- lines up with React.
	--   -- https://reactjs.org/docs/composition-vs-inheritance.html
	--   if key ~= "extend" then
	--     class[key] = value
	--   end
	-- end

	class.__index = class
	-- class.__componentName = name

	function class.__ctor<P>(props: P, context, updater): React_Component<P, any>
		local instance
		-- ROBLOX performance: use a pooled object
		if InstancePoolIndex <= InstancePoolSize then
			instance = InstancePool[InstancePoolIndex]
			-- fill in the dynamic fields
			-- ROBLOX FIXME Luau: TypeError: Type 'P' could not be converted into 'nil'
			instance.props = props :: any
			instance.context = context
			-- release the premade object from the pool -- we aren't recycling objects right now
			InstancePool[InstancePoolIndex] = nil
			InstancePoolIndex += 1
		else
			-- ROBLOX note: uncomment to tune pool size for lua-apps
			-- print("!!!!! hit ReactBaseClass instance pool limit")
			instance = {
				-- ROBLOX FIXME Luau: TypeError: Type 'P' could not be converted into 'nil'
				props = props :: any,
				context = context,
				state = UninitializedState,
				__refs = emptyObject,
				__updater = updater or ReactNoopUpdateQueue,
			}

			-- instance.props = props
			-- instance.context = context
			-- ROBLOX DEVIATION: Initialize state to a singleton that warns on attempts
			-- to access this pseudo-uninitialized state and errors on attempts to directly mutate
			-- state.
			-- instance.state = UninitializedState
			-- If a component has string refs, we will assign a different object later.
			-- ROBLOX deviation: Uses __refs instead of refs to avoid conflicts
			-- instance.refs = emptyObject
			-- instance.__refs = emptyObject
			-- We initialize the default updater but the real one gets injected by the
			-- renderer.
			-- instance.__updater = updater or ReactNoopUpdateQueue
		end

		-- ROBLOX TODO: We should consider using a more idiomatic Lua approach for
		-- warning/blocking lifecycle calls during initialization. For now,
		-- ReactNoopUpdateQueue accomplishes this, but we might be able to be more
		-- thorough if we use a dummy metamethod that warns precisely on all sorts
		-- of misbehavior
		instance = setmetatable(instance, class)

		-- ROBLOX performance: only do typeof if it's non-nil to begin with
		if class.init and type(class.init) == "function" then
			-- ROBLOX deviation: Override setState to allow it to be used in init.
			-- This maintains legacy Roact behavior and allows more consistent
			-- adherance to the "never assign directly to state" rule
			instance.setState = setStateInInit

			class.init(instance, props, context)

			-- ROBLOX devition: Unbind specialized version of setState used in init
			instance.setState = nil :: any
		end

		return (instance :: any) :: React_Component<P, any>
	end

	setmetatable(class, getmetatable(self :: any))

	return (class :: any) :: React_Component<any, any>
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
	if
		partialState ~= nil
		and type(partialState) ~= "table"
		and type(partialState) ~= "function"
	then
		error(
			"setState(...): takes an object of state variables to update or a "
				.. "function which returns an object of state variables."
		)
	end
	self.__updater.enqueueSetState(self, partialState, callback, "setState")
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
	self.__updater.enqueueForceUpdate(self, callback, "forceUpdate")
end
--[[*
 * Deprecated APIs. These APIs used to exist on classic React classes but since
 * we would like to deprecate them, we're not going to move them over to this
 * modern base class. Instead, we define a getter that warns if it's accessed.
 ]]

if __DEV__ then
	-- ROBLOX FIXME Luau: need CLI-53569 to remove the any cast
	local deprecatedAPIs = {
		isMounted = {
			"isMounted",
			"Instead, make sure to clean up subscriptions and pending requests in "
				.. "componentWillUnmount to prevent memory leaks.",
		},
		replaceState = {
			"replaceState",
			"Refactor your code to use setState instead (see "
				.. "https://github.com/facebook/react/issues/3236).",
		},
	} :: any

	local defineDeprecationWarning = function(methodName, info)
		(Component :: any)[methodName] = function()
			console.warn(
				"%s(...) is deprecated in plain JavaScript React classes. %s",
				info[1],
				info[2]
			)
			return nil
		end
	end

	for fnName, _ in deprecatedAPIs do
		if deprecatedAPIs[fnName] ~= nil then
			defineDeprecationWarning(fnName, deprecatedAPIs[fnName])
		end
	end
end

--[[*
 * Convenience component with default shallow equality check for sCU.
 ]]
-- ROBLOX deviation START: work within the `extend` framework defined above to emulate JS's
-- class inheritance

-- ROBLOX FIXME Luau: this is so we get *some* type checking despite the FIXME Luau above
local PureComponent = Component:extend("PureComponent") :: React_BaseComponent;

-- When extend()ing a component, you don't get an extend method.
-- This is to promote composition over inheritance.
-- PureComponent is an exception to this rule.
-- ROBLOX FIXME Luau: this is so we get *some* type checking despite the FIXME Luau above
(PureComponent :: any).extend = Component.extend

-- ROBLOX note: We copy members directly from the Component prototype above; we
-- don't need to redefine the constructor or do dummy function trickery to apply
-- it without jumping around
-- ROBLOX performance? inline (duplicate) explicit assignments to avoid loop overhead in hot path
-- Object.assign(pureComponentClassPrototype, componentClassPrototype)
local pureComponentClassPrototype = {
	isReactComponent = true,
	isPureReactComponent = true,
}

-- ROBLOX: FIXME: we should clean this up and align the implementations of
-- Component and PureComponent more clearly and explicitly
setmetatable(PureComponent, {
	__newindex = handleNewLifecycle,
	__index = pureComponentClassPrototype,
	__tostring = function(self)
		return self.__componentName
	end,
})
-- ROBLOX deviation END

return {
	Component = Component,
	PureComponent = PureComponent :: typeof(Component),
}
