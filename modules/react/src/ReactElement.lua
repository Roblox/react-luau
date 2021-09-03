-- upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react/src/ReactElement.js
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

local getComponentName = require(Packages.Shared).getComponentName
local invariant = require(Packages.Shared).invariant
local REACT_ELEMENT_TYPE = require(Packages.Shared).ReactSymbols.REACT_ELEMENT_TYPE
local ReactCurrentOwner = require(Packages.Shared).ReactSharedInternals.ReactCurrentOwner
--local hasOwnProperty = Object.prototype.hasOwnProperty
local RESERVED_PROPS = {
	key = true,
	ref = true,
	__self = true,
	__source = true,
}

local specialPropKeyWarningShown, specialPropRefWarningShown, didWarnAboutStringRefs

if _G.__DEV__ then
	didWarnAboutStringRefs = {}
end

local exports = {}

local function hasValidRef(config)
	if _G.__DEV__ then
		if config and config.ref and typeof(config.ref) == "table" then
			local getter = config.ref.get

			if getter and getter.isReactWarning then
				return false
			end
		end
	end

	return config.ref ~= nil
end

local function hasValidKey(config)
	if _G.__DEV__ then
		-- ROBLOX TODO: sort out proper translation of this clause which involves checking for getter methods
		if config.key and typeof(config.key) == "table" then
			local getter = config.key.get

			if getter and getter.isReactWarning then
				return false
			end
		end
	end

	return config.key ~= nil
end

local reactWarning = {isReactWarning = true}

local function defineKeyPropWarningGetter(props, displayName)
	local warnAboutAccessingKey = function()
			if _G.__DEV__ then
				if not specialPropKeyWarningShown then
					specialPropKeyWarningShown = true
					console.error(
						"%s: `key` is not a prop. Trying to access it will result " ..
							"in `nil` being returned. If you need to access the same " ..
							"value within the child component, you should pass it as a different " ..
							"prop. (https://reactjs.org/link/special-props)",
						displayName
					)
				end
			end
		end

	-- ROBLOX deviation: clear key to ensure metamethod is called,
	-- then set key getter to call warnAboutAccessingKey
	props.key = nil
	setmetatable(props, {
		__index = function(t, k)
			if k == "key" then
				warnAboutAccessingKey()
				-- ROBLOX deviation: returns sentinel object that mimics upstream ability to check isReactWarning field
				return reactWarning
			end
			return nil
		end
	})
end

local function defineRefPropWarningGetter(props, displayName)
	-- deviation: Use a __call metamethod here to make this function-like, but
	-- still able to have the `isReactWarning` flag defined on it
	local warnAboutAccessingRef = function()
			if _G.__DEV__ then
				if not specialPropRefWarningShown then
					specialPropRefWarningShown = true
					console.error(
						"%s: `ref` is not a prop. Trying to access it will result " ..
							"in `nil` being returned. If you need to access the same " ..
							"value within the child component, you should pass it as a different " ..
							"prop. (https://reactjs.org/link/special-props)",
						displayName
					)
				end
			end
		end

	-- ROBLOX deviation: clear key to ensure metamethod is called,
	-- then set key getter to call warnAboutAccessingKey
	props.ref = nil
	setmetatable(props, {
		__index = function(t, k)
			if k == "ref" then
				warnAboutAccessingRef()
				-- ROBLOX deviation: returns sentinel object that mimics upstream ability to check isReactWarning field
				return reactWarning
			end
			return nil
		end
	})
end

local function warnIfStringRefCannotBeAutoConverted(config)
	if _G.__DEV__ then
		if
			-- ROBLOX deviation: We removed support for string refs, so all stringrefs cannot be auto-converted regardless
			typeof(config.ref) == "string" and
			ReactCurrentOwner.current
			-- and config.__self
			-- and ReactCurrentOwner.current.stateNode ~= config.__self
		then
			local componentName = getComponentName(ReactCurrentOwner.current.type)

			if not didWarnAboutStringRefs[componentName] then
				console.error(
					'Component "%s" contains the string ref "%s". ' ..
						"Support for string refs has been removed. " ..
						"This case cannot be automatically converted to an arrow function. " ..
						"We ask you to manually fix this case by using useRef() or createRef() instead. " ..
						"Learn more about using refs safely here: " ..
						"https://reactjs.org/link/strict-mode-string-ref",
					componentName,
					config.ref
				)
				didWarnAboutStringRefs[componentName] = true
			end
		end
	end
end

--[[*
 * Factory method to create a new React element. This no longer adheres to
 * the class pattern, so do not use new to call it. Also, instanceof check
 * will not work. Instead test $$typeof field against Symbol.for('react.element') to check
 * if something is a React Element.
 *
 * @param *} type
 * @param *} props
 * @param *} key
 * @param string|object} ref
 * @param *} owner
 * @param *} self A *temporary* helper to detect places where `this` is
 * different from the `owner` when React.createElement is called, so that we
 * can warn. We want to get rid of owner and replace string `ref`s with arrow
 * functions, and as long as `this` and owner are the same, there will be no
 * change in behavior.
 * @param *} source An annotation object (added by a transpiler or otherwise)
 * indicating filename, line number, and/or other information.
 * @internal
 ]]

local function ReactElement(type_, key, ref, self, source, owner, props)
	local element = {
		-- Built-in properties that belong on the element
		type = type_,
		key = key,
		ref = ref,
		props = props,
		-- Record the component responsible for creating this element.
		_owner = owner,
	}

	-- This tag allows us to uniquely identify this as a React Element
	element["$$typeof"] = REACT_ELEMENT_TYPE

	if _G.__DEV__ then
		-- The validation flag is currently mutative. We put it on
		-- an external backing store so that we can freeze the whole object.
		-- This can be replaced with a WeakMap once they are implemented in
		-- commonly used development environments.
		element._store = setmetatable({}, {
			-- To make comparing ReactElements easier for testing purposes, we make
			-- the validation flag non-enumerable (where possible, which should
			-- include every environment we run tests in), so the test framework
			-- ignores it.
			__index = {
				validated = false
			}
		})
		-- self and source are DEV only properties.
		element._self = self
		-- Two elements created in two different places should be considered
		-- equal for testing purposes and therefore we hide it from enumeration.
		element._source = source
	end

	return element
end

-- deviation: skipping JSX for now, as it may never apply to Roblox
----[[*
-- * https://github.com/reactjs/rfcs/pull/107
-- * @param *} type
-- * @param object} props
-- * @param string} key
-- ]]
--
--
exports.jsx = function(type, config, maybeKey)
	error("JSX is currently unsupported")
--  local propName; -- Reserved names are extracted
--
--  local props = }
--  local key = nil
--  local ref = nil; -- Currently, key can be spread in as a prop. This causes a potential
--  -- issue if key is also explicitly declared (ie. <div ...props} key="Hi" />
--  -- or <div key="Hi" ...props} /> ). We want to deprecate key spread,
--  -- but as an intermediary step, we will use jsxDEV for everything except
--  -- <div ...props} key="Hi" />, because we aren't currently able to tell if
--  -- key is explicitly declared to be nil or not.
--
--  if maybeKey ~= nil)
--    key = '' .. maybeKey
--  end
--
--  if hasValidKey(config))
--    key = '' .. config.key
--  end
--
--  if hasValidRef(config))
--    ref = config.ref
--  } -- Remaining properties are added to a new props object
--
--
--  for (propName in config)
--    if hasOwnProperty.call(config, propName) and !RESERVED_PROPS.hasOwnProperty(propName))
--      props[propName] = config[propName]
--    end
--  } -- Resolve default props
--
--
--  if type and type.defaultProps)
--    local defaultProps = type.defaultProps
--
--    for (propName in defaultProps)
--      if props[propName] == nil)
--        props[propName] = defaultProps[propName]
--      end
--    end
end
--
--  return ReactElement(type, key, ref, nil, nil, ReactCurrentOwner.current, props)
--end
----[[*
-- * https://github.com/reactjs/rfcs/pull/107
-- * @param *} type
-- * @param object} props
-- * @param string} key
-- ]]
--
exports.jsxDEV = function(type, config, maybeKey, source, self)
	error("JSX is currently unsupported")
--  local propName; -- Reserved names are extracted
--
--  local props = }
--  local key = nil
--  local ref = nil; -- Currently, key can be spread in as a prop. This causes a potential
--  -- issue if key is also explicitly declared (ie. <div ...props} key="Hi" />
--  -- or <div key="Hi" ...props} /> ). We want to deprecate key spread,
--  -- but as an intermediary step, we will use jsxDEV for everything except
--  -- <div ...props} key="Hi" />, because we aren't currently able to tell if
--  -- key is explicitly declared to be nil or not.
--
--  if maybeKey ~= nil)
--    key = '' .. maybeKey
--  end
--
--  if hasValidKey(config))
--    key = '' .. config.key
--  end
--
--  if hasValidRef(config))
--    ref = config.ref
--    warnIfStringRefCannotBeAutoConverted(config)
--  } -- Remaining properties are added to a new props object
--
--
--  for (propName in config)
--    if hasOwnProperty.call(config, propName) and !RESERVED_PROPS.hasOwnProperty(propName))
--      props[propName] = config[propName]
--    end
--  } -- Resolve default props
--
--
--  if type and type.defaultProps)
--    local defaultProps = type.defaultProps
--
--    for (propName in defaultProps)
--      if props[propName] == nil)
--        props[propName] = defaultProps[propName]
--      end
--    end
--  end
--
--  if key or ref)
--    local displayName = function ()
--      if typeof type == 'function')
--        return type.displayName or type.name or 'Unknown'
--      end
--
--      return type
--    }()
--
--    if key)
--      defineKeyPropWarningGetter(props, displayName)
--    end
--
--    if ref)
--      defineRefPropWarningGetter(props, displayName)
--    end
end
--
--  return ReactElement(type, key, ref, self, source, ReactCurrentOwner.current, props)
--end
--[[*
 * Create and return a new ReactElement of the given type.
 * See https://reactjs.org/docs/react-api.html#createelement
 ]]

exports.createElement = function(type_, config, ...)
	local props = {}
	local key = nil
	local ref = nil
	local self = nil
	local source = nil

	if config ~= nil then
		if hasValidRef(config) then
			ref = config.ref

			if _G.__DEV__ then
				warnIfStringRefCannotBeAutoConverted(config)
			end
		end

		if hasValidKey(config) then
			-- ROBLOX deviation: call tostring instead of concatenating with an
			-- empty string, which can throw in luau. If the string is a number,
			-- then do not use tostring
			if typeof(config.key) == "number" then
				key = config.key
			else
				key = tostring(config.key)
			end
		end

		if config.__self == nil then
			self = nil
		else
			self = config.__self
		end

		if config.__source == nil then
			source = nil
		else
			source = config.__source
		end
		-- Remaining properties are added to a new props object
		for propName, _ in pairs(config) do
			if config[propName] ~= nil and not RESERVED_PROPS[propName] then
				props[propName] = config[propName]
			end
		end
	end

	-- Children can be more than one argument, and those are transferred onto
	-- the newly allocated props object.
	local childrenLength = select("#", ...)

	if childrenLength == 1 then
		props.children = select(1, ...)
	end

	local childArray = {}
	if childrenLength > 1 then
		for i = 1, childrenLength do
			local toInsert = select(i, ...)
			table.insert(childArray, toInsert)
		end

		if _G.__DEV__ then
			if Object.freeze then
				Object.freeze(childArray)
			end
		end

		props.children = childArray
	end

	-- Resolve default props
	-- deviation: Lua can't index defaultProps on a function
	if typeof(type_) == "table" and type_.defaultProps then
		local defaultProps = type_.defaultProps

		for propName, _ in pairs(defaultProps) do
			if props[propName] == nil then
				props[propName] = defaultProps[propName]
			end
		end
	end

	if _G.__DEV__ then
		if key or ref then
			local displayName

			if typeof(type_) == "function" then
				-- deviation: Can't get displayName for functions
				-- displayName = (type_.displayName or type_.name) or "Unknown"
				displayName = "<function>"
			else
				displayName = type_
			end

			if key then
				defineKeyPropWarningGetter(props, displayName)
			end

			if ref then
				defineRefPropWarningGetter(props, displayName)
			end
		end
	end

	return ReactElement(type_, key, ref, self, source, ReactCurrentOwner.current, props)
end

----[[*
-- * Return a function that produces ReactElements of a given type.
-- * See https://reactjs.org/docs/react-api.html#createfactory
-- ]]
--
--export function createFactory(type)
--  local factory = createElement.bind(null, type); -- Expose the type on the factory and the prototype so that it can be
--  -- easily accessed on elements. E.g. `<Foo />.type == Foo`.
--  -- This should not be named `constructor` since this may not be the function
--  -- that created the element, and it may not even be a constructor.
--  -- Legacy hook: remove it
--
--  factory.type = type
--  return factory
--end
--export function cloneAndReplaceKey(oldElement, newKey)
--  local newElement = ReactElement(oldElement.type, newKey, oldElement.ref, oldElement._self, oldElement._source, oldElement._owner, oldElement.props)
--  return newElement
--end

--[[*
* Clone and return a new ReactElement using element as the starting point.
* See https://reactjs.org/docs/react-api.html#cloneelement
]]

exports.cloneElement = function(element, config, ...)
	invariant(not (element == nil), "React.cloneElement(...): The argument must be a React element, but you passed " .. tostring(element))

	-- Original props are copied
	local props = Object.assign({}, element.props)

	-- Reserved names are extracted
	local key = element.key
	local ref = element.ref

	-- Self is preserved since the owner is preserved.
	local self = element._self

	-- Source is preserved since cloneElement is unlikely to be targeted by a
	-- transpiler, and the original source is probably a better indicator of the
	-- true owner.
	local source = element._source;

	-- Owner will be preserved, unless ref is overridden
	local owner = element._owner

	if config ~= nil then
		if hasValidRef(config) then
			-- Silently steal the ref from the parent.
			ref = config.ref
			owner = ReactCurrentOwner.current
		end

		if hasValidKey(config) then
			key = "" .. config.key
		end
	end

	-- Remaining properties override existing props
	local defaultProps

	-- ROBLOX deviation: make sure type is a table (and not a function component)
	-- if element.type and element.type.defaultProps then
	if typeof(element.type) == "table" and element.type.defaultProps then
		defaultProps = element.type.defaultProps
	end

	-- ROBLOX deviation: cannot call pairs on nil the way you can use `for...in`
	-- on nil in JS, so we check for nil before iterating
	if config ~= nil then
		for propName, _ in pairs(config) do
			if config[propName] and not RESERVED_PROPS[propName] then
				if config[propName] == nil and defaultProps ~= nil then
					-- Resolve default props
					props[propName] = defaultProps[propName]
				else
					props[propName] = config[propName]
				end
			end
		end
	end

	-- Children can be more than one argument, and those are transferred onto
	-- the newly allocated props object.
	local childrenLength = select("#", ...)

	if childrenLength == 1 then
		props.children = select(1, ...)
	elseif childrenLength > 1 then
		local childArray = {}
		for i = 1, childrenLength do
			local toInsert = select(i, ...)
			table.insert(childArray, toInsert)
		end
		props.children = childArray
	end

	return ReactElement(element.type, key, ref, self, source, owner, props)
end
--[[*
 * Verifies the object is a ReactElement.
 * See https://reactjs.org/docs/react-api.html#isvalidelement
 * @param ?object} object
 * @return boolean} True if `object` is a ReactElement.
 * @final
 ]]

exports.isValidElement = function(object)
	return typeof(object) == "table" and object["$$typeof"] == REACT_ELEMENT_TYPE
end

return exports
