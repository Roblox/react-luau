--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-reconciler/src/ReactChildFiber.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local __DEV__ = _G.__DEV__ :: boolean
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
type Array<T> = { [number]: T }
type Set<T> = { [T]: boolean }
type Object = { [any]: any }
type Map<K, V> = { [K]: V }
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console
local describeError = require(Packages.Shared).describeError

local ReactTypes = require(Packages.Shared)
-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes
type ReactElement = ReactTypes.ReactElement<any, any>
type ReactPortal = ReactTypes.ReactPortal

local React = require(Packages.React)
type LazyComponent<T, P> = React.LazyComponent<T, P>

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type RoactStableKey = ReactInternalTypes.RoactStableKey
local ReactFiberLanes = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLanes.Lanes

local getComponentName = require(Packages.Shared).getComponentName
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local Placement = ReactFiberFlags.Placement
local Deletion = ReactFiberFlags.Deletion
local ReactSymbols = require(Packages.Shared).ReactSymbols
local getIteratorFn = ReactSymbols.getIteratorFn
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_PORTAL_TYPE = ReactSymbols.REACT_PORTAL_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
local REACT_BLOCK_TYPE = ReactSymbols.REACT_BLOCK_TYPE
local ReactWorkTags = require(script.Parent.ReactWorkTags)
local FunctionComponent = ReactWorkTags.FunctionComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local Block = ReactWorkTags.Block
local invariant = require(Packages.Shared).invariant
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
-- ROBLOX deviation: we do not support string refs
-- local warnAboutStringRefs = ReactFeatureFlags.warnAboutStringRefs
local enableLazyElements = ReactFeatureFlags.enableLazyElements
local enableBlocksAPI = ReactFeatureFlags.enableBlocksAPI

local ReactFiber = require(script.Parent["ReactFiber.new"])
local createWorkInProgress = ReactFiber.createWorkInProgress
local resetWorkInProgress = ReactFiber.resetWorkInProgress
local createFiberFromElement = ReactFiber.createFiberFromElement
local createFiberFromFragment = ReactFiber.createFiberFromFragment
local createFiberFromText = ReactFiber.createFiberFromText
local createFiberFromPortal = ReactFiber.createFiberFromPortal
-- ROBLOX deviation: we do not support string refs
-- local emptyRefsObject =
-- 	require(script.Parent["ReactFiberClassComponent.new"]).emptyRefsObject
-- local ReactFiberHotReloading = require(script.Parent["ReactFiberHotReloading.new"])
-- local isCompatibleFamilyForHotReloading =
-- 	ReactFiberHotReloading.isCompatibleFamilyForHotReloading
-- ROBLOX deviation: we do not support string refs, which removes our use of StrictMode
-- local StrictMode = require(script.Parent.ReactTypeOfMode).StrictMode

local exports = {}

local didWarnAboutMaps
-- ROBLOX deviation: Lua doesn't have built-in generators
-- local didWarnAboutGenerators
-- ROBLOX deviation: we do not support string refs
-- local didWarnAboutStringRefs
local ownerHasKeyUseWarning
local ownerHasFunctionTypeWarning
local warnForMissingKey = function(child: any, returnFiber: Fiber) end

if __DEV__ then
	didWarnAboutMaps = false
	-- ROBLOX deviation: Lua doesn't have built-in generators
	--   didWarnAboutGenerators = false

	-- ROBLOX deviation: we do not support string refs
	-- didWarnAboutStringRefs = {}

	--[[
	Warn if there's no key explicitly set on dynamic arrays of children or
	object keys are not valid. This allows us to keep track of children between
	updates.
  ]]
	ownerHasKeyUseWarning = {}
	ownerHasFunctionTypeWarning = {}

	-- ROBLOX FIXME: This may need to change depending on how we want children to
	-- be passed. Current Roact accepts a table (keys are built-in) and leaves
	-- ordering up to users via LayoutOrder, but if we accept arrays (and attempt
	-- to somehow map them to LayoutOrder??) we'll need keys for stability
	warnForMissingKey = function(child: any, returnFiber: Fiber)
		if child == nil or type(child) ~= "table" then
			return
		end
		if not child._store or child._store.validated or child.key ~= nil then
			return
		end
		invariant(
			child._store ~= nil and type(child._store) == "table",
			"React Component in warnForMissingKey should have a _store. "
				.. "This error is likely caused by a bug in React. Please file an issue."
		)
		child._store.validated = true

		local componentName = getComponentName(returnFiber.type) or "Component"

		if ownerHasKeyUseWarning[componentName] then
			return
		end
		ownerHasKeyUseWarning[componentName] = true

		console.error(
			"Each child in a list should have a unique "
				.. '"key" prop. See https://reactjs.org/link/warning-keys for '
				.. "more information."
		)
	end
end

local isArray = Array.isArray

function coerceRef(returnFiber: Fiber, current: Fiber | nil, element: ReactElement)
	local mixedRef = element.ref
	if mixedRef ~= nil and type(mixedRef) == "string" then
		-- ROBLOX deviation: we do not support string refs, and will not coerce
		if
			not element._owner
			or not element._self
			or element._owner.stateNode == element._self
		then
			-- ROBLOX performance: don't get component name unless we have to use it
			local componentName
			if __DEV__ then
				componentName = getComponentName(returnFiber.type) or "Component"
			else
				componentName = "<enable __DEV__ mode for component names>"
			end
			error(
				Error.new(
					string.format(
						'Component "%s" contains the string ref "%s". Support for string refs '
							-- ROBLOX deviation: we removed string ref support ahead of upstream schedule
							.. "has been removed. We recommend using "
							.. "useRef() or createRef() instead. "
							.. "Learn more about using refs safely here: "
							.. "https://reactjs.org/link/strict-mode-string-ref",
						componentName,
						tostring(mixedRef)
					)
				)
			)
		end

		if not element._owner then
			error(
				"Expected ref to be a function or an object returned by React.createRef(), or nil."
			)
		end

		-- if __DEV__ then
		-- 	-- TODO: Clean this up once we turn on the string ref warning for
		-- 	-- everyone, because the strict mode case will no longer be relevant
		-- 	if
		-- 		(bit32.band(returnFiber.mode, StrictMode) ~= 0 or warnAboutStringRefs)
		-- 		-- We warn in ReactElement.js if owner and self are equal for string refs
		-- 		-- because these cannot be automatically converted to an arrow function
		-- 		-- using a codemod. Therefore, we don't have to warn about string refs again.
		-- 		and not (
		-- 			element._owner
		-- 			and element._self
		-- 			and element._owner.stateNode ~= element._self
		-- 		)
		-- 	then
		-- 		local componentName = getComponentName(returnFiber.type) or "Component"
		-- 		if not didWarnAboutStringRefs[componentName] then
		-- 			if warnAboutStringRefs then
		-- 				console.error(
		-- 					'Component "%s" contains the string ref "%s". Support for string refs '
		-- 						.. "will be removed in a future major release. We recommend using "
		-- 						.. "useRef() or createRef() instead. "
		-- 						.. "Learn more about using refs safely here: "
		-- 						.. "https://reactjs.org/link/strict-mode-string-ref",
		-- 					componentName,
		-- 					mixedRef
		-- 				)
		-- 			else
		-- 				console.error(
		-- 					'A string ref, "%s", has been found within a strict mode tree. '
		-- 						.. "String refs are a source of potential bugs and should be avoided. "
		-- 						.. "We recommend using useRef() or createRef() instead. "
		-- 						.. "Learn more about using refs safely here: "
		-- 						.. "https://reactjs.org/link/strict-mode-string-ref",
		-- 					mixedRef
		-- 				)
		-- 			end
		-- 			didWarnAboutStringRefs[componentName] = true
		-- 		end
		-- 	end
		-- end

		-- if element._owner then
		-- 	local owner: Fiber? = element._owner
		-- 	local inst
		-- 	if owner then
		-- 		local ownerFiber = owner
		-- 		invariant(
		-- 			ownerFiber.tag == ClassComponent,
		-- 			"Function components cannot have string refs. "
		-- 				.. "We recommend using useRef() instead. "
		-- 				.. "Learn more about using refs safely here: "
		-- 				.. "https://reactjs.org/link/strict-mode-string-ref"
		-- 		)
		-- 		inst = ownerFiber.stateNode
		-- 	end
		-- 	invariant(
		-- 		inst,
		-- 		"Missing owner for string ref %s. This error is likely caused by a "
		-- 			.. "bug in React. Please file an issue.",
		-- 		mixedRef
		-- 	)

		-- 	-- ROBLOX deviation: explicitly convert to string
		-- 	local stringRef = tostring(mixedRef)
		-- 	-- Check if previous string ref matches new string ref
		-- 	if
		-- 		current ~= nil
		-- 		and (current :: Fiber).ref ~= nil
		-- 		-- ROBLOX deviation: Lua doesn't support fields on functions, so invert this check
		-- 		-- typeof((current :: Fiber).ref) == 'function' and
		-- 		and typeof((current :: Fiber).ref) ~= "function"
		-- 		-- ROBLOX deviation: this partially inlines the ref type from Fiber to workaround Luau refinement issues
		-- 		and ((current :: Fiber).ref :: { _stringRef: string? })._stringRef
		-- 			== stringRef
		-- 	then
		-- 		return (current :: Fiber).ref
		-- 	end
		-- 	-- ROBLOX deviation: make ref a callable table rather than a function
		-- 	local callableRef = function(value)
		-- 		local refs = inst.__refs
		-- 		if refs == emptyRefsObject then
		-- 			-- This is a lazy pooled frozen object, so we need to initialize.
		-- 			inst.__refs = {}
		-- 			refs = inst.__refs
		-- 		end
		-- 		if value == nil then
		-- 			refs[stringRef] = nil
		-- 		else
		-- 			refs[stringRef] = value
		-- 		end
		-- 	end
		-- 	local ref = setmetatable({}, { __call = callableRef })
		-- 	ref._stringRef = stringRef
		-- 	return ref
		-- else
		-- 	invariant(
		-- 		typeof(mixedRef) == "string",
		-- 		"Expected ref to be a function, a string, an object returned by React.createRef(), or nil."
		-- 	)
		-- 	invariant(
		-- 		element._owner,
		-- 		"Element ref was specified as a string (%s) but no owner was set. This could happen for one of"
		-- 			.. " the following reasons:\n"
		-- 			.. "1. You may be adding a ref to a function component\n"
		-- 			.. "2. You may be adding a ref to a component that was not created inside a component's render method\n"
		-- 			.. "3. You have multiple copies of React loaded\n"
		-- 			.. "See https://reactjs.org/link/refs-must-have-owner for more information.",
		-- 		mixedRef
		-- 	)
		-- end
	end
	return mixedRef
end

-- ROBLOX performance: all uses commented out
-- local function throwOnInvalidObjectType(returnFiber: Fiber, newChild: { [any]: any })
-- 	if returnFiber.type ~= "textarea" then
-- ROBLOX FIXME: Need to adjust this to check for "table: <address>" instead
-- and print appropriately
-- unimplemented("throwOnInvalidObjectType textarea")

-- ROBLOX TODO: This is likely a bigger deviation; in Roact today, we allow
-- tables and use the keys as equivalents to the `key` prop
-- invariant(
--   false,
--   "Objects are not valid as a React child (found: %s). " ..
--     "If you meant to render a collection of children, use an array " ..
--     "instead.",
--   tostring(newChild) == "[object Object]"
--     ? "object with keys {" + Object.keys(newChild).join(", ") + "}"
--     : newChild,
-- )
-- 	end
-- end

local function warnOnFunctionType(returnFiber: Fiber)
	if __DEV__ then
		local componentName = getComponentName(returnFiber.type) or "Component"

		if ownerHasFunctionTypeWarning[componentName] then
			return
		end
		ownerHasFunctionTypeWarning[componentName] = true

		console.error(
			"Functions are not valid as a React child. This may happen if "
				.. "you return a Component instead of <Component /> from render. "
				.. "Or maybe you meant to call this function rather than return it."
		)
	end
end

-- // We avoid inlining this to avoid potential deopts from using try/catch.
-- /** @noinline */
function resolveLazyType<T, P>(lazyComponent: LazyComponent<T, P>): LazyComponent<T, P> | T
	-- ROBLOX performance: hoist non-throwable lines so we eliminate an anon function for the pcall
	-- If we can, let's peek at the resulting type.
	local payload = lazyComponent._payload
	local init = lazyComponent._init
	local ok, result = xpcall(init, describeError, payload)
	if not ok then
		-- Leave it in place and let it throw again in the begin phase.
		return lazyComponent
	end

	return result
end

-- This wrapper function exists because I expect to clone the code in each path
-- to be able to optimize each path individually by branching early. This needs
-- a compiler or we can do it manually. Helpers that don't need this branching
-- live outside of this function.
local function ChildReconciler(shouldTrackSideEffects)
	local function deleteChild(returnFiber: Fiber, childToDelete: Fiber)
		if not shouldTrackSideEffects then
			-- Noop.
			return
		end
		local deletions = returnFiber.deletions
		if deletions == nil then
			returnFiber.deletions = { childToDelete }
			returnFiber.flags = bit32.bor(returnFiber.flags, Deletion)
		else
			table.insert(deletions, childToDelete)
		end
	end

	local function deleteRemainingChildren(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil
	)
		if not shouldTrackSideEffects then
			-- Noop.
			return nil
		end

		-- TODO: For the shouldClone case, this could be micro-optimized a bit by
		-- assuming that after the first child we've already added everything.
		local childToDelete = currentFirstChild
		while childToDelete ~= nil do
			deleteChild(returnFiber, childToDelete)
			childToDelete = childToDelete.sibling
		end
		return nil
	end

	local function mapRemainingChildren(
		returnFiber: Fiber,
		currentFirstChild: Fiber
	): { [string | number]: Fiber }
		-- Add the remaining children to a temporary map so that we can find them by
		-- keys quickly. Implicit (null) keys get added to this set with their index
		-- instead.
		local existingChildren: { [string | number]: Fiber } = {}

		-- ROBLOX FIXME Luau: Luau doesn't correctly infer in repeat until nil scenarios
		local existingChild: Fiber? = currentFirstChild
		while existingChild ~= nil do
			if existingChild.key ~= nil then
				existingChildren[existingChild.key] = existingChild
			else
				existingChildren[existingChild.index] = existingChild
			end
			existingChild = existingChild.sibling
		end
		return existingChildren
	end

	local function useFiber(fiber: Fiber, pendingProps: any): Fiber
		-- We currently set sibling to nil and index to 0 here because it is easy
		-- to forget to do before returning it. E.g. for the single child case.
		local clone = createWorkInProgress(fiber, pendingProps)
		-- ROBLOX deviation: set index to 1 for 1-indexing
		clone.index = 1
		clone.sibling = nil
		return clone
	end

	local function placeChild(
		newFiber: Fiber,
		lastPlacedIndex: number,
		newIndex: number
	): number
		newFiber.index = newIndex
		if not shouldTrackSideEffects then
			-- Noop.
			return lastPlacedIndex
		end
		local current = newFiber.alternate
		if current ~= nil then
			local oldIndex = current.index
			if oldIndex < lastPlacedIndex then
				-- This is a move.
				newFiber.flags = bit32.bor(newFiber.flags, Placement)
				return lastPlacedIndex
			else
				-- This item can stay in place.
				return oldIndex
			end
		else
			-- This is an insertion.
			newFiber.flags = bit32.bor(newFiber.flags, Placement)
			return lastPlacedIndex
		end
	end

	local function placeSingleChild(newFiber: Fiber): Fiber
		-- This is simpler for the single child case. We only need to do a
		-- placement for inserting new children.
		if shouldTrackSideEffects and newFiber.alternate == nil then
			newFiber.flags = bit32.bor(newFiber.flags, Placement)
		end
		return newFiber
	end

	local function updateTextNode(
		returnFiber: Fiber,
		current: Fiber | nil,
		textContent: string,
		lanes: Lanes
	)
		-- ROBLOX FIXME: Luau narrowing issue
		if current == nil or (current :: Fiber).tag ~= HostText then
			-- Insert
			local created = createFiberFromText(textContent, returnFiber.mode, lanes)
			created.return_ = returnFiber
			return created
		else
			-- Update
			local existing = useFiber(current :: Fiber, textContent)
			existing.return_ = returnFiber
			return existing
		end
	end

	local function updateElement(
		returnFiber: Fiber,
		current: Fiber | nil,
		element: ReactElement,
		lanes: Lanes
	): Fiber
		if current ~= nil then
			if
				(current :: Fiber).elementType == element.type
				-- ROBLOX performance: avoid always-false cmp, hot reloading isn't enabled in Roblox yet
				-- Keep this check inline so it only runs on the false path:
				-- or (__DEV__ and isCompatibleFamilyForHotReloading(current, element))
			then
				-- Move based on index
				local existing = useFiber(current :: Fiber, element.props)
				existing.ref = coerceRef(returnFiber, current, element)
				existing.return_ = returnFiber
				if __DEV__ then
					existing._debugSource = element._source
					existing._debugOwner = element._owner
				end
				return existing
			elseif enableBlocksAPI and (current :: Fiber).tag == Block then
				-- The new Block might not be initialized yet. We need to initialize
				-- it in case initializing it turns out it would match.
				-- ROBLOX FIXME Luau: Luau should analyze closure and create union of assignments
				local type_: any = element.type
				if type(type_) == "table" and type_["$$typeof"] == REACT_LAZY_TYPE then
					type_ = resolveLazyType(type_) :: LazyComponent<any, any>
				end
				if
					type_["$$typeof"] == REACT_BLOCK_TYPE
					and type_._render == (current :: Fiber).type._render
				then
					-- Same as above but also update the .type field.
					local existing = useFiber(current :: Fiber, element.props)
					existing.return_ = returnFiber
					existing.type = type_
					if __DEV__ then
						existing._debugSource = element._source
						existing._debugOwner = element._owner
					end
					return existing
				end
			end
		end
		-- Insert
		local created = createFiberFromElement(element, returnFiber.mode, lanes)
		created.ref = coerceRef(returnFiber, current, element)
		created.return_ = returnFiber
		return created
	end

	local function updatePortal(
		returnFiber: Fiber,
		current: Fiber | nil,
		portal: ReactPortal,
		lanes: Lanes
	): Fiber
		-- ROBLOX FIXME: type narrowing.
		if
			current == nil
			or (current :: Fiber).tag ~= HostPortal
			or (current :: Fiber).stateNode.containerInfo ~= portal.containerInfo
			or (current :: Fiber).stateNode.implementation ~= portal.implementation
		then
			-- Insert
			local created = createFiberFromPortal(portal, returnFiber.mode, lanes)
			created.return_ = returnFiber
			return created
		else
			-- Update
			local existing = useFiber(current :: Fiber, portal.children or {})
			existing.return_ = returnFiber
			return existing
		end
	end

	local function updateFragment(
		returnFiber: Fiber,
		current: Fiber | nil,
		-- ROBLOX TODO: figure out how we should define our Iterable type
		--   fragment: Iterable<*>,
		fragment: any,
		lanes: Lanes,
		key: nil | string
	): Fiber
		if current == nil or (current :: Fiber).tag ~= Fragment then
			-- Insert
			local created =
				createFiberFromFragment(fragment, returnFiber.mode, lanes, key)
			created.return_ = returnFiber
			return created
		else
			-- Update
			local existing = useFiber(current :: Fiber, fragment)
			existing.return_ = returnFiber
			return existing
		end
	end

	-- ROBLOX deviation: Roact stable keys - Support Roact's implementation of
	-- stable keys, wherein the key used in the `children` table is used as if it
	-- were a `key` prop. Child order doesn't matter in Roblox, so a vast majority
	-- of existing Roact code used table keys in this way.
	local function assignStableKey(tableKey: any?, newChild: Object): ()
		-- If there's no assigned key in the element, and the table key is valid,
		-- assign it as the element's key.
		-- If the key is a table, convert it to a string.

		-- ROBLOX TODO: Investigate if this is safe; maybe we need to shallow-copy
		-- the object if we have a new key, to preserve immutability, but that cost
		-- may be severe
		if newChild.key == nil then
			-- ROBLOX performance? only call typeof once, and only if first condition is true
			local typeOfTableKey = type(tableKey)
			if typeOfTableKey == "string" or typeOfTableKey == "number" then
				newChild.key = tableKey
			elseif typeOfTableKey == "table" then
				newChild.key = tostring(tableKey)
			end
		end
	end

	local function createChild(
		returnFiber: Fiber,
		newChild: any,
		lanes: Lanes,
		-- ROBLOX deviation: children table key for compat with Roact's stable keys
		tableKey: any?
	): Fiber | nil
		-- ROBLOX performance: early exit for nil newChild since no actions will be taken
		if newChild == nil then
			return nil
		end

		-- ROBLOX performance: avoid repeated calls to typeof, since Luau doesn't optimize
		local typeOfNewChild = type(newChild)

		-- ROBLOX performance: hoist more common ROblox case (non-string/number) first to reduce cmp in hot path
		if typeOfNewChild == "table" then
			-- ROBLOX deviation: Roact stable keys - forward children table key to
			-- child if applicable
			assignStableKey(tableKey, newChild)
			-- ROBLOX performance: avoid repeated indexing to $$typeof
			local newChildTypeof = newChild["$$typeof"]
			if newChildTypeof == REACT_ELEMENT_TYPE then
				local created = createFiberFromElement(newChild, returnFiber.mode, lanes)
				created.ref = coerceRef(returnFiber, nil, newChild)
				created.return_ = returnFiber
				return created
			elseif newChildTypeof == REACT_PORTAL_TYPE then
				local created = createFiberFromPortal(newChild, returnFiber.mode, lanes)
				created.return_ = returnFiber
				return created
			elseif newChildTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = newChild._payload
					local init = newChild._init
					-- ROBLOX deviation: Roact stable keys - Since the table key was
					-- already applied to `newChild` above, we don't need to pass it along
					return createChild(returnFiber, init(payload), lanes)
				end
			end

			-- ROBLOX deviation peformance: this is the equiv of checking for a table, and we already know typeof(newChild) is a table in this branch
			-- if isArray(newChild) or getIteratorFn(newChild) then
			local created =
				createFiberFromFragment(newChild, returnFiber.mode, lanes, nil)
			created.return_ = returnFiber
			return created

			-- ROBLOX performance deviation: unreachable with the above table check
			-- throwOnInvalidObjectType(returnFiber, newChild)
		end

		if typeOfNewChild == "string" or typeOfNewChild == "number" then
			-- Text nodes don't have keys. If the previous node is implicitly keyed
			-- we can continue to replace it without aborting even if it is not a text
			-- node.
			local created =
				createFiberFromText(tostring(newChild), returnFiber.mode, lanes)
			created.return_ = returnFiber
			return created
		end

		if __DEV__ then
			if typeOfNewChild == "function" then
				warnOnFunctionType(returnFiber)
			end
		end

		return nil
	end

	local function updateSlot(
		returnFiber: Fiber,
		oldFiber: Fiber | nil,
		newChild: any,
		lanes: Lanes,
		-- ROBLOX deviation: children table key for compat with Roact's stable keys
		tableKey: any?
	): Fiber | nil
		-- ROBLOX performance: early exit for nil newChild since no actions will be taken
		if newChild == nil then
			return nil
		end

		-- Update the fiber if the keys match, otherwise return nil.

		local key = if oldFiber ~= nil then oldFiber.key else nil
		-- ROBLOX performance: avoid repeated calls to typeof since Luau doesn't cache
		local typeOfNewChild = type(newChild)

		if typeOfNewChild == "table" then
			-- ROBLOX deviation: Roact stable keys - forward children table key to
			-- child if applicable
			assignStableKey(tableKey, newChild)
			-- ROBLOX performance: avoid repeated indexing to $$typeof
			local newChildTypeof = newChild["$$typeof"]
			if newChildTypeof == REACT_ELEMENT_TYPE then
				if newChild.key == key then
					if newChild.type == REACT_FRAGMENT_TYPE then
						return updateFragment(
							returnFiber,
							oldFiber,
							newChild.props.children,
							lanes,
							key :: string?
						)
					end
					return updateElement(returnFiber, oldFiber, newChild, lanes)
				else
					return nil
				end
			elseif newChildTypeof == REACT_PORTAL_TYPE then
				if newChild.key == key then
					return updatePortal(returnFiber, oldFiber, newChild, lanes)
				else
					return nil
				end
			elseif newChildTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = newChild._payload
					local init = newChild._init
					-- ROBLOX deviation: Roact stable keys - Since the table key was
					-- already applied to `newChild` above, we don't need to pass it along
					return updateSlot(returnFiber, oldFiber, init(payload), lanes)
				end
			end

			-- ROBLOX deviation peformance: this is the equiv of checking for a table, and we already know typeof(newChild) is a table in this branch
			-- if isArray(newChild) or getIteratorFn(newChild) then
			if key ~= nil then
				return nil
			end

			return updateFragment(returnFiber, oldFiber, newChild, lanes)

			-- ROBLOX performance deviation: unreachable with the above table check
			-- throwOnInvalidObjectType(returnFiber, newChild)
		end

		-- ROBLOX performance: do this compare last to save 2 string cmp in typical Roblox hot path
		if typeOfNewChild == "string" or typeOfNewChild == "number" then
			-- Text nodes don't have keys. If the previous node is implicitly keyed
			-- we can continue to replace it without aborting even if it is not a text
			-- node.
			if key ~= nil then
				return nil
			end
			return updateTextNode(returnFiber, oldFiber, tostring(newChild), lanes)
		end

		if __DEV__ then
			if typeOfNewChild == "function" then
				warnOnFunctionType(returnFiber)
			end
		end

		return nil
	end

	local function updateFromMap(
		existingChildren: Map<string | number, Fiber>,
		returnFiber: Fiber,
		newIdx: number,
		newChild: any,
		lanes: Lanes,
		-- ROBLOX deviation: children table key for compat with Roact's stable keys
		tableKey: any?
	): Fiber | nil
		-- ROBLOX performance: early exit for nil newChild since no actions will be taken
		if newChild == nil then
			return nil
		end

		-- ROBLOX performance: avoid repeated calls to typeof since Luau doesn't cache
		local typeOfNewChild = type(newChild)

		if typeOfNewChild == "table" then
			-- ROBLOX deviation: Roact stable keys - forward children table key to
			-- child if applicable
			assignStableKey(tableKey, newChild)
			local existingChildrenKey
			-- ROBLOX performance: avoid repeated indexing to $$typeof
			local newChildTypeof = newChild["$$typeof"]
			if newChildTypeof == REACT_ELEMENT_TYPE then
				if newChild.key == nil then
					existingChildrenKey = newIdx
				else
					existingChildrenKey = newChild.key
				end
				local matchedFiber = existingChildren[existingChildrenKey]
				if newChild.type == REACT_FRAGMENT_TYPE then
					return updateFragment(
						returnFiber,
						matchedFiber,
						newChild.props.children,
						lanes,
						newChild.key
					)
				end
				return updateElement(returnFiber, matchedFiber, newChild, lanes)
			elseif newChildTypeof == REACT_PORTAL_TYPE then
				if newChild.key == nil then
					existingChildrenKey = newIdx
				else
					existingChildrenKey = newChild.key
				end
				local matchedFiber = existingChildren[existingChildrenKey]
				return updatePortal(returnFiber, matchedFiber, newChild, lanes)
			elseif newChildTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = newChild._payload
					local init = newChild._init
					-- ROBLOX deviation: Roact stable keys - Since the table key was
					-- already applied to `newChild` above, we don't need to pass it along
					return updateFromMap(
						existingChildren,
						returnFiber,
						newIdx,
						init(payload),
						lanes
					)
				end
			end

			-- ROBLOX deviation peformance: this is the equiv of checking for a table, and we already know typeof(newChild) is a table in this branch
			-- if isArray(newChild) or getIteratorFn(newChild) then
			local matchedFiber = existingChildren[newIdx]
			return updateFragment(returnFiber, matchedFiber, newChild, lanes)

			-- ROBLOX performance deviation: unreachable with the above table check
			-- throwOnInvalidObjectType(returnFiber, newChild)
		end

		-- ROBLOX performance: do this compare last, as Roblox won't really support text nodes directly
		if typeOfNewChild == "string" or typeOfNewChild == "number" then
			-- Text nodes don't have keys, so we neither have to check the old nor
			-- new node for the key. If both are text nodes, they match.
			local matchedFiber = existingChildren[newIdx] or nil
			return updateTextNode(returnFiber, matchedFiber, tostring(newChild), lanes)
		end

		if __DEV__ then
			if typeOfNewChild == "function" then
				warnOnFunctionType(returnFiber)
			end
		end

		return nil
	end

	--[[
	Warns if there is a duplicate or missing key
  ]]
	local function warnOnInvalidKey(
		child: any,
		knownKeys: Set<string> | nil,
		returnFiber: Fiber
	): Set<string> | nil
		if __DEV__ then
			if child == nil or type(child) ~= "table" then
				return knownKeys
			end
			-- ROBLOX performance: avoid repeated indexing to $$typeof
			local childTypeof = child["$$typeof"]
			if childTypeof == REACT_ELEMENT_TYPE or childTypeof == REACT_PORTAL_TYPE then
				warnForMissingKey(child, returnFiber)
				local key = child.key
				if type(key) ~= "string" then
					-- break
				elseif knownKeys == nil then
					knownKeys = {};
					(knownKeys :: Set<string>)[key] = true
				elseif not (knownKeys :: Set<string>)[key] then
					(knownKeys :: Set<string>)[key] = true
				else
					console.error(
						"Encountered two children with the same key, `%s`. "
							.. "Keys should be unique so that components maintain their identity "
							.. "across updates. Non-unique keys may cause children to be "
							.. "duplicated and/or omitted — the behavior is unsupported and "
							.. "could change in a future version.",
						key
					)
				end
			elseif childTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = child._payload
					local init = child._init
					warnOnInvalidKey(init(payload), knownKeys, returnFiber)
				end
			end
		end
		return knownKeys
	end

	local function reconcileChildrenArray(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		newChildren: Array<any>,
		lanes: Lanes
	): Fiber | nil
		-- This algorithm can't optimize by searching from both ends since we
		-- don't have backpointers on fibers. I'm trying to see how far we can get
		-- with that model. If it ends up not being worth the tradeoffs, we can
		-- add it later.

		-- Even with a two ended optimization, we'd want to optimize for the case
		-- where there are few changes and brute force the comparison instead of
		-- going for the Map. It'd like to explore hitting that path first in
		-- forward-only mode and only go for the Map once we notice that we need
		-- lots of look ahead. This doesn't handle reversal as well as two ended
		-- search but that's unusual. Besides, for the two ended optimization to
		-- work on Iterables, we'd need to copy the whole set.

		-- In this first iteration, we'll just live with hitting the bad case
		-- (adding everything to a Map) in for every insert/move.

		-- If you change this code, also update reconcileChildrenIterator() which
		-- uses the same algorithm.

		if __DEV__ then
			-- First, validate keys.
			local knownKeys = nil
			for i, child in newChildren do
				knownKeys = warnOnInvalidKey(child, knownKeys, returnFiber)
			end
		end

		local resultingFirstChild: Fiber | nil = nil
		local previousNewFiber: Fiber | nil = nil

		local oldFiber: Fiber | nil = currentFirstChild
		local lastPlacedIndex = 1
		local newIdx = 1
		local nextOldFiber: Fiber | nil = nil
		-- ROBLOX performance: don't re-evaluate length of newChildren on each iteration through the loop
		local newChildrenCount = #newChildren
		-- ROBLOX deviation: use while loop in place of modified for loop
		while oldFiber ~= nil and newIdx <= newChildrenCount do
			if oldFiber.index > newIdx then
				nextOldFiber = oldFiber
				oldFiber = nil
			else
				nextOldFiber = oldFiber.sibling
			end
			--[[
				ROBLOX DEVIATION: We pass newIdx to createChild to ensure that children are
				assigned a key, assuming the child is not an array itself. We only need to
				pass newIdx if the child is actually a React element. If the child is a
				string or number, a key is never assigned, so we do not pass newIdx as a key.
			]]
			local newFiber
			-- ROBLOX performance: avoid repeated indexing of newChildren to newIdx
			local newChildNewIdx = newChildren[newIdx]
			if
				newChildNewIdx ~= nil
				and type(newChildNewIdx) == "table"
				and newChildNewIdx["$$typeof"] ~= nil
			then
				newFiber =
					updateSlot(returnFiber, oldFiber, newChildNewIdx, lanes, newIdx)
			else
				newFiber = updateSlot(returnFiber, oldFiber, newChildNewIdx, lanes)
			end
			if newFiber == nil then
				-- TODO: This breaks on empty slots like nil children. That's
				-- unfortunate because it triggers the slow path all the time. We need
				-- a better way to communicate whether this was a miss or nil,
				-- boolean, undefined, etc.
				if oldFiber == nil then
					oldFiber = nextOldFiber
				end
				break
			end
			if shouldTrackSideEffects then
				-- ROBLOX FIXME Luau: needs type states to understand the continue above
				if oldFiber and (newFiber :: Fiber).alternate == nil then
					-- We matched the slot, but we didn't reuse the existing fiber, so we
					-- need to delete the existing child.
					-- ROBLOX FIXME Luau: needs type states to understand the break above
					deleteChild(returnFiber, oldFiber :: Fiber)
				end
			end
			lastPlacedIndex = placeChild(newFiber :: Fiber, lastPlacedIndex, newIdx)
			if previousNewFiber == nil then
				-- TODO: Move out of the loop. This only happens for the first run.
				resultingFirstChild = newFiber
			else
				-- TODO: Defer siblings if we're not at the right index for this slot.
				-- I.e. if we had nil values before, then we want to defer this
				-- for each nil value. However, we also don't want to call updateSlot
				-- with the previous one.
				(previousNewFiber :: Fiber).sibling = newFiber
			end
			previousNewFiber = newFiber
			oldFiber = nextOldFiber
			-- deviation: increment manually since we're not using a modified for loop
			newIdx += 1
		end

		if newIdx > newChildrenCount then
			-- We've reached the end of the new children. We can delete the rest.
			deleteRemainingChildren(returnFiber, oldFiber)
			return resultingFirstChild
		end

		if oldFiber == nil then
			-- If we don't have any more existing children we can choose a fast path
			-- since the rest will all be insertions.
			-- deviation: use while loop in place of modified for loop
			while newIdx <= newChildrenCount do
				--[[
					ROBLOX DEVIATION: We pass newIdx to createChild to ensure that children are
					assigned a key, assuming the child is not an array itself. We only need to
					pass newIdx if the child is actually a React element. If the child is a
					string or number, a key is never assigned, so we do not pass newIdx as a key.
				]]
				local newFiber
				-- ROBLOX performance: avoid repeated indexing of newChildren to newIdx
				local newChildNewIdx = newChildren[newIdx]
				if
					newChildNewIdx ~= nil
					and type(newChildNewIdx) == "table"
					and newChildNewIdx["$$typeof"] ~= nil
				then
					newFiber = createChild(returnFiber, newChildNewIdx, lanes, newIdx)
				else
					newFiber = createChild(returnFiber, newChildNewIdx, lanes)
				end
				if newFiber == nil then
					-- ROBLOX deviation: increment manually since we're not using a modified for loop
					newIdx += 1
					continue
				end
				-- ROBLOX FIXME Luau: needs type state to understand the continue above
				lastPlacedIndex = placeChild(newFiber :: Fiber, lastPlacedIndex, newIdx)
				if previousNewFiber == nil then
					-- TODO: Move out of the loop. This only happens for the first run.
					resultingFirstChild = newFiber
				else
					(previousNewFiber :: Fiber).sibling = newFiber
				end
				previousNewFiber = newFiber
				-- deviation: increment manually since we're not using a modified for loop
				newIdx += 1
			end
			return resultingFirstChild
		end

		-- Add all children to a key map for quick lookups.
		-- ROBLOX FIXME Luau: need type state to understand the if/return above
		local existingChildren = mapRemainingChildren(returnFiber, oldFiber :: Fiber)

		-- Keep scanning and use the map to restore deleted items as moves.
		-- ROBLOX deviation: use while loop in place of modified for loop
		while newIdx <= newChildrenCount do
			local newFiber = updateFromMap(
				existingChildren,
				returnFiber,
				newIdx,
				newChildren[newIdx],
				lanes,
				-- ROBLOX deviation: pass newIdx to be used as the key of the element
				newIdx
			)
			if newFiber ~= nil then
				if shouldTrackSideEffects then
					if newFiber.alternate ~= nil then
						-- The new fiber is a work in progress, but if there exists a
						-- current, that means that we reused the fiber. We need to delete
						-- it from the child list so that we don't add it to the deletion
						-- list.
						existingChildren[if newFiber.key == nil
							then newIdx
							else newFiber.key] =
							nil
					end
				end
				lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
				if previousNewFiber == nil then
					resultingFirstChild = newFiber
				else
					(previousNewFiber :: Fiber).sibling = newFiber
				end
				previousNewFiber = newFiber
			end
			-- deviation: increment manually since we're not using a modified for loop
			newIdx += 1
		end

		if shouldTrackSideEffects then
			-- Any existing children that weren't consumed above were deleted. We need
			-- to add them to the deletion list.
			for _, child in existingChildren do
				deleteChild(returnFiber, child)
			end
		end

		return resultingFirstChild
	end

	-- ROBLOX TODO: LUAFDN-254
	local function reconcileChildrenIterator(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		-- ROBLOX TODO: figure out our Iterable<> interface
		--   newChildrenIterable: Iterable<*>,
		newChildrenIterable: any,
		lanes: Lanes,
		-- ROBLOX performance? pass in iteratorFn to avoid two calls to getIteratorFn
		iteratorFn: (...any) -> any
	): Fiber | nil
		-- This is the same implementation as reconcileChildrenArray(),
		-- but using the iterator instead.

		-- local iteratorFn = getIteratorFn(newChildrenIterable)
		-- ROBLOX performance? eliminate 'nice to have' strcmp in hot path
		-- invariant(
		-- 	typeof(iteratorFn) == "function",
		-- 	"An object is not an iterable. This error is likely caused by a bug in "
		-- 		.. "React. Please file an issue."
		-- )

		if __DEV__ then
			-- We don't support rendering Generators because it's a mutation.
			-- See https://github.com/facebook/react/issues/12995
			-- ROBLOX deviation: Lua doesn't have built-in generators
			-- if
			--   typeof(Symbol) == 'function' and
			--   -- $FlowFixMe Flow doesn't know about toStringTag
			--   newChildrenIterable[Symbol.toStringTag] == 'Generator'
			-- then
			--   if not didWarnAboutGenerators then
			--     console.error(
			--       'Using Generators as children is unsupported and will likely yield ' ..
			--         'unexpected results because enumerating a generator mutates it. ' ..
			--         'You may convert it to an array with `Array.from()` or the ' ..
			--         '`[...spread]` operator before rendering. Keep in mind ' ..
			--         'you might need to polyfill these features for older browsers.'
			--     )
			--   end
			--   didWarnAboutGenerators = true
			-- end

			-- Warn about using Maps as children
			if newChildrenIterable.entries == iteratorFn then
				if not didWarnAboutMaps then
					console.error(
						"Using Maps as children is not supported. "
							.. "Use an array of keyed ReactElements instead."
					)
				end
				didWarnAboutMaps = true
			end

			-- First, validate keys.
			-- We'll get a different iterator later for the main pass.
			local newChildren = iteratorFn(newChildrenIterable)
			if newChildren then
				local knownKeys = nil
				local step = newChildren.next()
				while not step.done do
					step = newChildren.next()
					local child = step.value
					knownKeys = warnOnInvalidKey(child, knownKeys, returnFiber)
				end
			end
		end

		local newChildren = iteratorFn(newChildrenIterable)
		-- ROBLOX performance? eliminate 'nice to have' cmp in hot path
		-- invariant(newChildren ~= nil, "An iterable object provided no iterator.")

		local resultingFirstChild: Fiber | nil = nil
		local previousNewFiber: Fiber = nil

		local oldFiber = currentFirstChild
		local lastPlacedIndex = 1
		local newIdx = 1
		local nextOldFiber: Fiber | nil = nil

		local step = newChildren.next()
		while oldFiber ~= nil and not step.done do
			if oldFiber.index > newIdx then
				nextOldFiber = oldFiber
				oldFiber = nil
			else
				nextOldFiber = oldFiber.sibling
			end
			local newFiber =
				updateSlot(returnFiber, oldFiber, step.value, lanes, step.key)
			if newFiber == nil then
				-- TODO: This breaks on empty slots like nil children. That's
				-- unfortunate because it triggers the slow path all the time. We need
				-- a better way to communicate whether this was a miss or nil,
				-- boolean, undefined, etc.
				if oldFiber == nil then
					oldFiber = nextOldFiber
				end
				break
			end
			if shouldTrackSideEffects then
				-- ROBLOX FIXME Luau: need type states to understand the break above
				if oldFiber and (newFiber :: Fiber).alternate == nil then
					-- We matched the slot, but we didn't reuse the existing fiber, so we
					-- need to delete the existing child.
					deleteChild(returnFiber, oldFiber)
				end
			end
			lastPlacedIndex = placeChild(newFiber :: Fiber, lastPlacedIndex, newIdx)
			if previousNewFiber == nil then
				-- TODO: Move out of the loop. This only happens for the first run.
				resultingFirstChild = newFiber
			else
				-- TODO: Defer siblings if we're not at the right index for this slot.
				-- I.e. if we had nil values before, then we want to defer this
				-- for each nil value. However, we also don't want to call updateSlot
				-- with the previous one.
				previousNewFiber.sibling = newFiber :: Fiber
			end
			previousNewFiber = newFiber :: Fiber
			oldFiber = nextOldFiber

			newIdx += 1
			step = newChildren.next()
		end

		if step.done then
			-- We've reached the end of the new children. We can delete the rest.
			deleteRemainingChildren(returnFiber, oldFiber)
			return resultingFirstChild
		end

		if oldFiber == nil then
			-- If we don't have any more existing children we can choose a fast path
			-- since the rest will all be insertions.
			while not step.done do
				local newFiber = createChild(returnFiber, step.value, lanes, step.key)
				if newFiber == nil then
					newIdx += 1
					step = newChildren.next()
					continue
				end
				-- ROBLOX FIXME Luau: need type states to understand the continue above
				lastPlacedIndex = placeChild(newFiber :: Fiber, lastPlacedIndex, newIdx)
				if previousNewFiber == nil then
					-- TODO: Move out of the loop. This only happens for the first run.
					resultingFirstChild = newFiber
				else
					previousNewFiber.sibling = newFiber
				end
				previousNewFiber = newFiber :: Fiber

				newIdx += 1
				step = newChildren.next()
			end
			return resultingFirstChild
		end

		-- Add all children to a key map for quick lookups.
		-- ROBLOX performance? defer initialization into the loop. extra cmp per loop iter, but avoid call if no loop iter
		local existingChildren

		-- Keep scanning and use the map to restore deleted items as moves.
		while not step.done do
			if not existingChildren then
				-- ROBLOX FIXME LUau: need type states to understand the guard+return above
				existingChildren = mapRemainingChildren(returnFiber, oldFiber :: Fiber)
			end
			local newFiber = updateFromMap(
				existingChildren,
				returnFiber,
				newIdx,
				step.value,
				lanes,
				step.key
			)
			if newFiber ~= nil then
				if shouldTrackSideEffects then
					if newFiber.alternate ~= nil then
						-- The new fiber is a work in progress, but if there exists a
						-- current, that means that we reused the fiber. We need to delete
						-- it from the child list so that we don't add it to the deletion
						-- list.
						if newFiber.key == nil then
							existingChildren[newIdx] = nil
						else
							existingChildren[newFiber.key] = nil
						end
					end
				end
				lastPlacedIndex = placeChild(newFiber, lastPlacedIndex, newIdx)
				if previousNewFiber == nil then
					resultingFirstChild = newFiber
				else
					previousNewFiber.sibling = newFiber
				end
				previousNewFiber = newFiber
			end

			newIdx += 1
			step = newChildren.next()
		end

		if shouldTrackSideEffects then
			-- Any existing children that weren't consumed above were deleted. We need
			-- to add them to the deletion list.
			for _, child in existingChildren do
				deleteChild(returnFiber, child)
			end
		end

		return resultingFirstChild
	end

	local function reconcileSingleTextNode(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		textContent: string,
		lanes: Lanes
	): Fiber
		-- There's no need to check for keys on text nodes since we don't have a
		-- way to define them.
		-- ROBLOX FIXME: Luau narrowing issue
		if currentFirstChild ~= nil and (currentFirstChild :: Fiber).tag == HostText then
			-- We already have an existing node so let's just update it and delete
			-- the rest.
			deleteRemainingChildren(returnFiber, (currentFirstChild :: Fiber).sibling)
			local existing = useFiber(currentFirstChild :: Fiber, textContent)
			existing.return_ = returnFiber
			return existing
		end
		-- The existing first child is not a text node so we need to create one
		-- and delete the existing ones.
		deleteRemainingChildren(returnFiber, currentFirstChild)
		local created = createFiberFromText(textContent, returnFiber.mode, lanes)
		created.return_ = returnFiber
		return created
	end

	local function reconcileSingleElement(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		element: ReactElement,
		lanes: Lanes
	): Fiber
		local key = element.key
		local child = currentFirstChild
		while child ~= nil do
			-- TODO: If key == nil and child.key == nil, then this only applies to
			-- the first item in the list.
			if child.key == key then
				if child.tag == Fragment then
					if element.type == REACT_FRAGMENT_TYPE then
						deleteRemainingChildren(returnFiber, child.sibling)
						local existing = useFiber(child, element.props.children)
						existing.return_ = returnFiber
						if __DEV__ then
							existing._debugSource = element._source
							existing._debugOwner = element._owner
						end
						return existing
					end
					-- ROBLOX performance: avoid always-false cmp in hot path
					-- elseif child.tag == Block then
					-- 	unimplemented("reconcileSingleElement: Block")
					-- if (enableBlocksAPI) {
					--   let type = element.type;
					--   if (type.$$typeof === REACT_LAZY_TYPE) {
					--     type = resolveLazyType(type);
					--   }
					--   if (type.$$typeof === REACT_BLOCK_TYPE) {
					--     // The new Block might not be initialized yet. We need to initialize
					--     // it in case initializing it turns out it would match.
					--     if (
					--       ((type: any): BlockComponent<any, any>)._render ===
					--       (child.type: BlockComponent<any, any>)._render
					--     ) {
					--       deleteRemainingChildren(returnFiber, child.sibling);
					--       const existing = useFiber(child, element.props);
					--       existing.type = type;
					--       existing.return = returnFiber;
					--       if (__DEV__) {
					--         existing._debugSource = element._source;
					--         existing._debugOwner = element._owner;
					--       }
					--       return existing;
					--     }
					--   }
					-- }
					-- // We intentionally fallthrough here if enableBlocksAPI is not on.
					-- // eslint-disable-next-lined no-fallthrough
				else
					if
						child.elementType == element.type
						-- ROBLOX performance: avoid always-false cmp, hot reloading isn't enabled in Roblox yet
						-- Keep this check inline so it only runs on the false path:
						-- or (
						-- 	__DEV__
						-- 	and isCompatibleFamilyForHotReloading(child, element)
						-- )
					then
						deleteRemainingChildren(returnFiber, child.sibling)
						local existing = useFiber(child, element.props)
						existing.ref = coerceRef(returnFiber, child, element)
						existing.return_ = returnFiber
						if __DEV__ then
							existing._debugSource = element._source
							existing._debugOwner = element._owner
						end
						return existing
					end
				end
				-- Didn't match.
				deleteRemainingChildren(returnFiber, child)
				break
			else
				deleteChild(returnFiber, child)
			end
			child = child.sibling
		end

		if element.type == REACT_FRAGMENT_TYPE then
			local created = createFiberFromFragment(
				element.props.children,
				returnFiber.mode,
				lanes,
				-- ROBLOX FIXME Luau: needs normalization: TypeError: Type '(number | string)?' could not be converted into 'string?'
				element.key :: string
			)
			created.return_ = returnFiber
			return created
		else
			local created = createFiberFromElement(element, returnFiber.mode, lanes)
			created.ref = coerceRef(returnFiber, currentFirstChild, element)
			created.return_ = returnFiber
			return created
		end
	end

	local function reconcileSinglePortal(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		portal: ReactPortal,
		lanes: Lanes
	): Fiber
		local key = portal.key
		local child = currentFirstChild
		while child ~= nil do
			-- TODO: If key == nil and child.key == nil, then this only applies to
			-- the first item in the list.
			if child.key == key then
				if
					child.tag == HostPortal
					and child.stateNode.containerInfo == portal.containerInfo
					and child.stateNode.implementation == portal.implementation
				then
					deleteRemainingChildren(returnFiber, child.sibling)
					local existing = useFiber(child, portal.children or {})
					existing.return_ = returnFiber
					return existing
				else
					deleteRemainingChildren(returnFiber, child)
					break
				end
			else
				deleteChild(returnFiber, child)
			end
			child = child.sibling
		end

		local created = createFiberFromPortal(portal, returnFiber.mode, lanes)
		created.return_ = returnFiber
		return created
	end

	-- This API will tag the children with the side-effect of the reconciliation
	-- itself. They will be added to the side-effect list as we pass through the
	-- children and the parent.
	local function reconcileChildFibers(
		returnFiber: Fiber,
		currentFirstChild: Fiber | nil,
		newChild: any,
		lanes: Lanes
	): Fiber | nil
		-- This function is not recursive.
		-- If the top level item is an array, we treat it as a set of children,
		-- not as a fragment. Nested arrays on the other hand will be treated as
		-- fragment nodes. Recursion happens at the normal flow.

		-- ROBLOX performance: avoid repeated calls to typeof since Luau doesn't cache
		local typeOfNewChild = type(newChild)

		-- Handle top level unkeyed fragments as if they were arrays.
		-- This leads to an ambiguity between <>{[...]}</> and <>...</>.
		-- We treat the ambiguous cases above the same.
		local isUnkeyedTopLevelFragment = newChild ~= nil
			and typeOfNewChild == "table"
			and newChild.type == REACT_FRAGMENT_TYPE
			and newChild.key == nil
		if isUnkeyedTopLevelFragment then
			newChild = newChild.props.children
			typeOfNewChild = type(newChild)
		end
		local newChildIsArray = isArray(newChild)

		-- Handle object types
		-- ROBLOX deviation: upstream checks for `object`, but we need to manually exclude array
		local isObject = newChild ~= nil
			and typeOfNewChild == "table"
			and not newChildIsArray

		if isObject then
			-- ROBLOX performance: avoid repeated indexing of $$typeof
			local newChildTypeof = newChild["$$typeof"]
			if newChildTypeof == REACT_ELEMENT_TYPE then
				return placeSingleChild(
					reconcileSingleElement(
						returnFiber,
						currentFirstChild,
						newChild,
						lanes
					)
				)
			elseif newChildTypeof == REACT_PORTAL_TYPE then
				return placeSingleChild(
					reconcileSinglePortal(returnFiber, currentFirstChild, newChild, lanes)
				)
			elseif newChildTypeof == REACT_LAZY_TYPE then
				if enableLazyElements then
					local payload = newChild._payload
					local init = newChild._init
					-- TODO: This function is supposed to be non-recursive.
					return reconcileChildFibers(
						returnFiber,
						currentFirstChild,
						init(payload),
						lanes
					)
				end
			end
		-- ROBLOX performance: make these next blocks `elseif`, as they're mutually exclusive to `isObject` above
		elseif newChildIsArray then
			return reconcileChildrenArray(returnFiber, currentFirstChild, newChild, lanes)
		elseif typeOfNewChild == "string" or typeOfNewChild == "number" then
			return placeSingleChild(
				reconcileSingleTextNode(
					returnFiber,
					currentFirstChild,
					tostring(newChild),
					lanes
				)
			)
		end

		-- ROBLOX performance? only call getIteratorFn once, pass in the value
		local newChildIteratorFn = getIteratorFn(newChild)
		if newChildIteratorFn then
			return reconcileChildrenIterator(
				returnFiber,
				currentFirstChild,
				newChild,
				lanes,
				newChildIteratorFn
			)
		end

		-- ROBLOX performance? eliminate a cmp in hot path for something unimplemented anyway
		-- if isObject then
		-- 	unimplemented("throwOnInvalidObjectType")
		-- 	-- throwOnInvalidObjectType(returnFiber, newChild)
		-- end

		if __DEV__ then
			if typeOfNewChild == "function" then
				warnOnFunctionType(returnFiber)
			end
		end
		if newChild == nil and not isUnkeyedTopLevelFragment then
			-- deviation: need a flag here to simulate switch/case fallthrough + break
			local shouldFallThrough = false
			-- If the new child is undefined, and the return fiber is a composite
			-- component, throw an error. If Fiber return types are disabled,
			-- we already threw above.
			-- ROBLOX deviation: With coercion of no returns to `nil`, it
			-- if returnFiber.tag == ClassComponent then
			--   if __DEV__ then
			-- isn't necessary to special case this scenario
			-- local instance = returnFiber.stateNode
			-- if instance.render._isMockFunction then
			--   -- We allow auto-mocks to proceed as if they're returning nil.
			--   shouldFallThrough = true
			-- end
			--   end
			-- end
			-- Intentionally fall through to the next case, which handles both
			-- functions and classes
			-- eslint-disable-next-lined no-fallthrough
			if
				shouldFallThrough
				and (
					returnFiber.tag == ClassComponent
					or returnFiber.tag == FunctionComponent
					or returnFiber.tag == ForwardRef
					or returnFiber.tag == SimpleMemoComponent
				)
			then
				invariant(
					false,
					"%s(...): Nothing was returned from render. This usually means a "
						.. "return statement is missing. Or, to render nothing, "
						.. "return nil.",
					getComponentName(returnFiber.type) or "Component"
				)
			end
		end

		-- Remaining cases are all treated as empty.
		return deleteRemainingChildren(returnFiber, currentFirstChild)
	end

	return reconcileChildFibers
end

exports.reconcileChildFibers = ChildReconciler(true)
exports.mountChildFibers = ChildReconciler(false)

exports.cloneChildFibers = function(current: Fiber | nil, workInProgress: Fiber)
	-- ROBLOX deviation: This message isn't tested upstream, remove for hot path optimization
	-- invariant(
	-- 	current == nil or workInProgress.child == (current :: Fiber).child,
	-- 	"Resuming work not yet implemented."
	-- )

	if workInProgress.child == nil then
		return
	end

	local currentChild = workInProgress.child :: Fiber
	local newChild = createWorkInProgress(currentChild, currentChild.pendingProps)
	workInProgress.child = newChild

	newChild.return_ = workInProgress
	while currentChild.sibling ~= nil do
		currentChild = currentChild.sibling
		newChild.sibling = createWorkInProgress(currentChild, currentChild.pendingProps)
		-- ROBLOX FIXME Luau: luau doesn't track/narrow the direct assignment on the line above
		newChild = newChild.sibling :: Fiber
		newChild.return_ = workInProgress
	end
	newChild.sibling = nil
end

-- Reset a workInProgress child set to prepare it for a second pass.
exports.resetChildFibers = function(workInProgress: Fiber, lanes: Lanes): ()
	local child = workInProgress.child
	while child ~= nil do
		resetWorkInProgress(child, lanes)
		child = child.sibling
	end
end

return exports
