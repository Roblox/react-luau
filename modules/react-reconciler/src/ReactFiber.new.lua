--!strict
-- upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react-reconciler/src/ReactFiber.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
local Array = LuauPolyfill.Array
local inspect = LuauPolyfill.util.inspect

-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactTypes = require(Packages.Shared)
-- ROBLOX deviation: ReactElement is defined at the top level of Shared along
-- with the rest of the ReactTypes
type ReactElement = ReactTypes.ReactElement<any, any>
type ReactFragment = ReactTypes.ReactFragment
type ReactPortal = ReactTypes.ReactPortal
type ReactFundamentalComponent<T, U> = ReactTypes.ReactFundamentalComponent<T, U>
type ReactScope = ReactTypes.ReactScope
local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
export type Fiber = ReactInternalTypes.Fiber

-- ROBLOX deviation: Allow number keys for sparse arrays
type RoactStableKey = ReactInternalTypes.RoactStableKey
local ReactRootTags = require(script.Parent.ReactRootTags)
type RootTag = ReactRootTags.RootTag;
local ReactWorkTags = require(script.Parent.ReactWorkTags)
type WorkTag = ReactWorkTags.WorkTag;
local ReactTypeOfMode = require(script.Parent.ReactTypeOfMode)
type TypeOfMode = ReactTypeOfMode.TypeOfMode;
local ReactFiberLane = require(script.Parent.ReactFiberLane)
type Lanes = ReactFiberLane.Lanes;
local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
type SuspenseInstance = ReactFiberHostConfig.SuspenseInstance;
local ReactFiberOffscreenComponent = require(script.Parent.ReactFiberOffscreenComponent)
type OffscreenProps = ReactFiberOffscreenComponent.OffscreenProps;

local invariant = require(Packages.Shared).invariant
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
local enableProfilerTimer = ReactFeatureFlags.enableProfilerTimer
-- local enableFundamentalAPI = ReactFeatureFlags.enableFundamentalAPI
-- local enableScopeAPI = ReactFeatureFlags.enableScopeAPI
local ReactFiberFlags = require(script.Parent.ReactFiberFlags)
local NoFlags = ReactFiberFlags.NoFlags
local Placement = ReactFiberFlags.Placement
local StaticMask = ReactFiberFlags.StaticMask
local ConcurrentRoot = ReactRootTags.ConcurrentRoot
local BlockingRoot = ReactRootTags.BlockingRoot
local IndeterminateComponent = ReactWorkTags.IndeterminateComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostRoot = ReactWorkTags.HostRoot
local HostComponent = ReactWorkTags.HostComponent
local HostText = ReactWorkTags.HostText
local HostPortal = ReactWorkTags.HostPortal
local ForwardRef = ReactWorkTags.ForwardRef
local Fragment = ReactWorkTags.Fragment
local Mode = ReactWorkTags.Mode
local ContextProvider = ReactWorkTags.ContextProvider
local ContextConsumer = ReactWorkTags.ContextConsumer
local Profiler = ReactWorkTags.Profiler
local SuspenseComponent = ReactWorkTags.SuspenseComponent
local SuspenseListComponent = ReactWorkTags.SuspenseListComponent
local DehydratedFragment = ReactWorkTags.DehydratedFragment
local FunctionComponent = ReactWorkTags.FunctionComponent
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local LazyComponent = ReactWorkTags.LazyComponent
local FundamentalComponent = ReactWorkTags.FundamentalComponent
local ScopeComponent = ReactWorkTags.ScopeComponent
local OffscreenComponent = ReactWorkTags.OffscreenComponent
local LegacyHiddenComponent = ReactWorkTags.LegacyHiddenComponent
local getComponentName = require(Packages.Shared).getComponentName

local ReactFiberDevToolsHook = require(script.Parent["ReactFiberDevToolsHook.new"])
local isDevToolsPresent = ReactFiberDevToolsHook.isDevToolsPresent
local ReactFiberHotReloading = require(script.Parent["ReactFiberHotReloading.new"])
local resolveClassForHotReloading = ReactFiberHotReloading.resolveClassForHotReloading
local resolveFunctionForHotReloading = ReactFiberHotReloading.resolveFunctionForHotReloading
local resolveForwardRefForHotReloading = ReactFiberHotReloading.resolveForwardRefForHotReloading
local NoLanes = ReactFiberLane.NoLanes
local NoMode = ReactTypeOfMode.NoMode
local ConcurrentMode = ReactTypeOfMode.ConcurrentMode
local DebugTracingMode = ReactTypeOfMode.DebugTracingMode
local ProfileMode = ReactTypeOfMode.ProfileMode
local StrictMode = ReactTypeOfMode.StrictMode
local BlockingMode = ReactTypeOfMode.BlockingMode
local ReactSymbols = require(Packages.Shared).ReactSymbols
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE
local REACT_DEBUG_TRACING_MODE_TYPE = ReactSymbols.REACT_DEBUG_TRACING_MODE_TYPE
local REACT_STRICT_MODE_TYPE = ReactSymbols.REACT_STRICT_MODE_TYPE
local REACT_PROFILER_TYPE = ReactSymbols.REACT_PROFILER_TYPE
local REACT_PROVIDER_TYPE = ReactSymbols.REACT_PROVIDER_TYPE
local REACT_CONTEXT_TYPE = ReactSymbols.REACT_CONTEXT_TYPE
local REACT_SUSPENSE_TYPE = ReactSymbols.REACT_SUSPENSE_TYPE
local REACT_SUSPENSE_LIST_TYPE = ReactSymbols.REACT_SUSPENSE_LIST_TYPE
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_LAZY_TYPE = ReactSymbols.REACT_LAZY_TYPE
-- local REACT_FUNDAMENTAL_TYPE = ReactSymbols.REACT_FUNDAMENTAL_TYPE
-- local REACT_SCOPE_TYPE = ReactSymbols.REACT_SCOPE_TYPE
local REACT_OFFSCREEN_TYPE = ReactSymbols.REACT_OFFSCREEN_TYPE
local REACT_LEGACY_HIDDEN_TYPE = ReactSymbols.REACT_LEGACY_HIDDEN_TYPE

-- deviation: We probably don't have to worry about this scenario, since we use
-- simple tables as maps

-- local hasBadMapPolyfill

-- if _G.__DEV__ then
-- 	hasBadMapPolyfill = false
-- 	try {
-- 		local nonExtensibleObject = Object.preventExtensions({})
-- 		--[[ eslint-disable no-new ]]
-- 		new Map([[nonExtensibleObject, nil]])
-- 		new Set([nonExtensibleObject])
-- 		--[[ eslint-enable no-new ]]
-- 	} catch (e)
-- 		-- TODO: Consider warning about bad polyfills
-- 		hasBadMapPolyfill = true
-- 	end
-- end

local createFiberFromScope, createFiberFromProfiler, createFiberFromFragment,
	createFiberFromFundamental, createFiberFromSuspense, createFiberFromOffscreen,
	createFiberFromLegacyHidden, createFiberFromSuspenseList

local debugCounter = 1

function FiberNode(
	tag: WorkTag,
	pendingProps: any,
	key: RoactStableKey?,
	mode: TypeOfMode
): Fiber
	local node = {}

	-- Instance
	node.tag = tag
	node.key = key
	node.elementType = nil
	node.type = nil
	node.stateNode = nil

	-- Fiber
	-- deviation: Lua doesn't allow `return` keyword as key
	node.return_ = nil
	node.child = nil
	node.sibling = nil
	node.index = 1

	node.ref = nil

	node.pendingProps = pendingProps
	node.memoizedProps = nil
	node.updateQueue = nil
	node.memoizedState = nil
	node.dependencies = nil

	node.mode = mode

	-- Effects
	node.flags = NoFlags
	node.subtreeFlags = NoFlags
	node.deletions = nil

	node.lanes = NoLanes
	node.childLanes = NoLanes

	node.alternate = nil

	if enableProfilerTimer then
		-- deviation: Unlikely that we have this same performance problem
		--[[
			-- Note: The following is done to avoid a v8 performance cliff.
			--
			-- Initializing the fields below to smis and later updating them with
			-- double values will cause Fibers to end up having separate shapes.
			-- This behavior/bug has something to do with Object.preventExtension().
			-- Fortunately this only impacts DEV builds.
			-- Unfortunately it makes React unusably slow for some applications.
			-- To work around this, initialize the fields below with doubles.
			--
			-- Learn more about this here:
			-- https://github.com/facebook/react/issues/14365
			-- https://bugs.chromium.org/p/v8/issues/detail?id=8538
			node.actualDuration = Number.NaN
			node.actualStartTime = Number.NaN
			node.selfBaseDuration = Number.NaN
			node.treeBaseDuration = Number.NaN

			-- It's okay to replace the initial doubles with smis after initialization.
			-- This won't trigger the performance cliff mentioned above,
			-- and it simplifies other profiler code (including DevTools).
		]]
		node.actualDuration = 0
		node.actualStartTime = -1
		node.selfBaseDuration = 0
		node.treeBaseDuration = 0
	end

	if _G.__DEV__ then
		-- This isn't directly used but is handy for debugging internals:
		node._debugID = debugCounter
		debugCounter += 1
		node._debugSource = nil
		node._debugOwner = nil
		node._debugNeedsRemount = false
		node._debugHookTypes = nil
		-- deviation: We can just make sure this is always valid
		-- if not hasBadMapPolyfill and typeof(Object.preventExtensions) == "function"

		-- deviation: FIXME - we can't actually distinguish between 'nil' and
		-- absent, so if we do this here, we won't be able to initialize fields
		-- that start out as 'nil'
		-- Object.preventExtensions(node)

		-- end
	end

	return node
end

-- This is a constructor function, rather than a POJO constructor, still
-- please ensure we do the following:
-- 1) Nobody should add any instance methods on this. Instance methods can be
--    more difficult to predict when they get optimized and they are almost
--    never inlined properly in static compilers.
-- 2) Nobody should rely on `instanceof Fiber` for type testing. We should
--    always know when it is a fiber.
-- 3) We might want to experiment with using numeric keys since they are easier
--    to optimize in a non-JIT environment.
-- 4) We can easily go from a constructor to a createFiber object literal if that
--    is faster.
-- 5) It should be easy to port this to a C struct and keep a C implementation
--    compatible.
local function createFiber(
	tag: WorkTag,
	pendingProps: any,
	key: RoactStableKey?,
	mode: TypeOfMode
): Fiber
	-- $FlowFixMe: the shapes are exact here but Flow doesn't like constructors
	return FiberNode(tag, pendingProps, key, mode)
end

-- deviation: FIXME: `Component: Function` - need to lock down component def
function shouldConstruct(Component)
	-- deviation: With Lua metatables, members of the "prototype" can be
	-- accessed directly. so we don't need to check for a prototype separately
	return typeof(Component) ~= "function" and (not not Component.isReactComponent)
end

local function isSimpleFunctionComponent(type: any)
	return
		typeof(type) == "function" and
		not shouldConstruct(type)
		-- deviation: function components don't support this anyway
		-- type.defaultProps == undefined
end

local function resolveLazyComponentTag(Component: any): WorkTag
	if typeof(Component) == "function"
		-- ROBLOX deviation: upstream is a function with method on, we use a table and need an alternate route
		 or (typeof(Component) == "table" and Component.isReactComponent) then
		if shouldConstruct(Component) then
			return ClassComponent
		end

		return FunctionComponent
	-- ROBLOX deviation: we can only index ["$$typeof"] on a table
	elseif Component ~= nil and typeof(Component) == 'table' then
		local __typeof = Component["$$typeof"]
		if __typeof == REACT_FORWARD_REF_TYPE then
			return ForwardRef
		end
		if __typeof == REACT_MEMO_TYPE then
			return MemoComponent
		end
	end
	return IndeterminateComponent
end

-- This is used to create an alternate fiber to do work on.
local function createWorkInProgress(current: Fiber, pendingProps: any): Fiber
	-- ROBLOX FIXME Luau: Luau doesn't understand if nil then create pattern
	local workInProgress = current.alternate :: Fiber
	if workInProgress == nil then
		-- We use a double buffering pooling technique because we know that we'll
		-- only ever need at most two versions of a tree. We pool the "other" unused
		-- node that we're free to reuse. This is lazily created to avoid allocating
		-- extra objects for things that are never updated. It also allow us to
		-- reclaim the extra memory if needed.
		workInProgress = createFiber(
			current.tag,
			pendingProps,
			current.key,
			current.mode
		)
		workInProgress.elementType = current.elementType
		workInProgress.type = current.type
		workInProgress.stateNode = current.stateNode

		if _G.__DEV__ then
			-- DEV-only fields
			workInProgress._debugID = current._debugID
			workInProgress._debugSource = current._debugSource
			workInProgress._debugOwner = current._debugOwner
			workInProgress._debugHookTypes = current._debugHookTypes
		end

		workInProgress.alternate = current
		current.alternate = workInProgress
	else
		workInProgress.pendingProps = pendingProps
		-- Needed because Blocks store data on type.
		workInProgress.type = current.type

		-- We already have an alternate.
		-- Reset the effect tag.
		workInProgress.flags = NoFlags

		-- The current effects are no longer valid
		workInProgress.subtreeFlags = NoFlags
		workInProgress.deletions = nil

		if enableProfilerTimer then
			-- We intentionally reset, rather than copy, actualDuration & actualStartTime.
			-- This prevents time from endlessly accumulating in new commits.
			-- This has the downside of resetting values for different priority renders,
			-- But works for yielding (the common case) and should support resuming.
			workInProgress.actualDuration = 0
			workInProgress.actualStartTime = -1
		end
	end

	-- Reset all effects except static ones.
	-- Static effects are not specific to a render.
	workInProgress.flags = bit32.band(current.flags, StaticMask)
	workInProgress.childLanes = current.childLanes
	workInProgress.lanes = current.lanes

	workInProgress.child = current.child
	workInProgress.memoizedProps = current.memoizedProps
	workInProgress.memoizedState = current.memoizedState
	workInProgress.updateQueue = current.updateQueue

	-- Clone the dependencies object. This is mutated during the render phase, so
	-- it cannot be shared with the current fiber.
	local currentDependencies = current.dependencies
	if currentDependencies == nil then
		workInProgress.dependencies = nil
	else
		workInProgress.dependencies = {
			lanes = currentDependencies.lanes,
			firstContext = currentDependencies.firstContext,
		}
	end

	-- These will be overridden during the parent's reconciliation
	workInProgress.sibling = current.sibling
	workInProgress.index = current.index
	workInProgress.ref = current.ref

	if enableProfilerTimer then
		workInProgress.selfBaseDuration = current.selfBaseDuration
		workInProgress.treeBaseDuration = current.treeBaseDuration
	end

	if _G.__DEV__ then
		workInProgress._debugNeedsRemount = current._debugNeedsRemount
		if
			workInProgress.tag == IndeterminateComponent or
			workInProgress.tag == FunctionComponent or
			workInProgress.tag == SimpleMemoComponent
		then
			workInProgress.type = resolveFunctionForHotReloading(current.type)
		elseif workInProgress.tag == ClassComponent then
			workInProgress.type = resolveClassForHotReloading(current.type)
		elseif workInProgress.tag == ForwardRef then
			workInProgress.type = resolveForwardRefForHotReloading(current.type)
		end
	end

	return workInProgress
end

-- Used to reuse a Fiber for a second pass.
local function resetWorkInProgress(workInProgress: Fiber, renderLanes: Lanes)
	-- This resets the Fiber to what createFiber or createWorkInProgress would
	-- have set the values to before during the first pass. Ideally this wouldn't
	-- be necessary but unfortunately many code paths reads from the workInProgress
	-- when they should be reading from current and writing to workInProgress.

	-- We assume pendingProps, index, key, ref, return are still untouched to
	-- avoid doing another reconciliation.

	-- Reset the effect tag but keep any Placement tags, since that's something
	-- that child fiber is setting, not the reconciliation.
	workInProgress.flags = bit32.band(workInProgress.flags, bit32.bor(StaticMask, Placement))

	-- The effects are no longer valid

	local current = workInProgress.alternate
	if current == nil then
		-- Reset to createFiber's initial values.
		workInProgress.childLanes = NoLanes
		workInProgress.lanes = renderLanes

		workInProgress.child = nil
		workInProgress.subtreeFlags = NoFlags
		workInProgress.memoizedProps = nil
		workInProgress.memoizedState = nil
		workInProgress.updateQueue = nil

		workInProgress.dependencies = nil

		workInProgress.stateNode = nil

		if enableProfilerTimer then
			-- Note: We don't reset the actualTime counts. It's useful to accumulate
			-- actual time across multiple render passes.
			workInProgress.selfBaseDuration = 0
			workInProgress.treeBaseDuration = 0
		end
	else
		-- Reset to the cloned values that createWorkInProgress would've.
		workInProgress.childLanes = current.childLanes
		workInProgress.lanes = current.lanes

		workInProgress.child = current.child
		workInProgress.subtreeFlags = current.subtreeFlags
		workInProgress.deletions = nil
		workInProgress.memoizedProps = current.memoizedProps
		workInProgress.memoizedState = current.memoizedState
		workInProgress.updateQueue = current.updateQueue
		-- Needed because Blocks store data on type.
		workInProgress.type = current.type

		-- Clone the dependencies object. This is mutated during the render phase, so
		-- it cannot be shared with the current fiber.
		local currentDependencies = current.dependencies
		if currentDependencies == nil then
			workInProgress.dependencies = nil
		else
			workInProgress.dependencies = {
				lanes = currentDependencies.lanes,
				firstContext = currentDependencies.firstContext,
			}
		end

		if enableProfilerTimer then
			-- Note: We don't reset the actualTime counts. It's useful to accumulate
			-- actual time across multiple render passes.
			workInProgress.selfBaseDuration = current.selfBaseDuration
			workInProgress.treeBaseDuration = current.treeBaseDuration
		end
	end

	return workInProgress
end

local function createHostRootFiber(tag: RootTag): Fiber
	local mode
	if tag == ConcurrentRoot then
		mode = bit32.bor(ConcurrentMode, BlockingMode, StrictMode)
	elseif tag == BlockingRoot then
		mode = bit32.bor(BlockingMode, StrictMode)
	else
		mode = NoMode
	end

	if enableProfilerTimer and isDevToolsPresent then
		-- Always collect profile timings when DevTools are present.
		-- This enables DevTools to start capturing timing at any point–
		-- Without some nodes in the tree having empty base times.
		mode = bit32.bor(mode, ProfileMode)
	end

	return createFiber(HostRoot, nil, nil, mode)
end

local function createFiberFromTypeAndProps(
	type_: any, -- React$ElementType
	key: string?,
	pendingProps: any,
	owner: nil | Fiber,
	mode: TypeOfMode,
	lanes: Lanes
): Fiber
	local fiberTag = IndeterminateComponent
	-- The resolved type is set if we know what the final type will be. I.e. it's not lazy.
	-- deviation: FIXME: Account for deviated class v. function component type logic
	local resolvedType = type_
	-- deviation: since our class components aren't functions, we have to look
	-- for them more explicitly (inlines logic from `shouldConstruct`)
	if typeof(type_) == "function" then
		if _G.__DEV__ then
			resolvedType = resolveFunctionForHotReloading(resolvedType)
		end
	elseif typeof(type_) == "table" and (not not type_.isReactComponent) then
		fiberTag = ClassComponent
		if _G.__DEV__ then
			resolvedType = resolveClassForHotReloading(resolvedType)
		end
	elseif typeof(type_) == "string" then
		fiberTag = HostComponent
	else
		if type_ == REACT_FRAGMENT_TYPE then
			return createFiberFromFragment(pendingProps.children, mode, lanes, key)
		elseif type_ == REACT_DEBUG_TRACING_MODE_TYPE then
			fiberTag = Mode
			mode = bit32.bor(mode, DebugTracingMode)
		elseif type_ == REACT_STRICT_MODE_TYPE then
			fiberTag = Mode
			mode = bit32.bor(mode, StrictMode)
		elseif type_ == REACT_PROFILER_TYPE then
			return createFiberFromProfiler(pendingProps, mode, lanes, key)
		elseif type_ == REACT_SUSPENSE_TYPE then
			return createFiberFromSuspense(pendingProps, mode, lanes, key)
		-- elseif type_ == REACT_SUSPENSE_LIST_TYPE then
		-- 	return createFiberFromSuspenseList(pendingProps, mode, lanes, key)
		elseif type_ == REACT_OFFSCREEN_TYPE then
			return createFiberFromOffscreen(pendingProps, mode, lanes, key)
		elseif type_ == REACT_LEGACY_HIDDEN_TYPE then
			return createFiberFromLegacyHidden(pendingProps, mode, lanes, key)
		-- elseif type_ == REACT_SCOPE_TYPE then
		-- 	if enableScopeAPI then
		-- 		return createFiberFromScope(type_, pendingProps, mode, lanes, key)
		-- 	end
		else
			local shouldBreak = false;
			if typeof(type_) == "table" then
				if type_["$$typeof"] == REACT_PROVIDER_TYPE then
					fiberTag = ContextProvider
					shouldBreak = true
				elseif type_["$$typeof"] == REACT_CONTEXT_TYPE then
					-- This is a consumer
					fiberTag = ContextConsumer
					shouldBreak = true
				elseif type_["$$typeof"] == REACT_FORWARD_REF_TYPE then
					fiberTag = ForwardRef
					if _G.__DEV__ then
						resolvedType = resolveForwardRefForHotReloading(resolvedType)
					end
					shouldBreak = true
				elseif type_["$$typeof"] == REACT_MEMO_TYPE then
					fiberTag = MemoComponent
					shouldBreak = true
				elseif type_["$$typeof"] == REACT_LAZY_TYPE then
					fiberTag = LazyComponent
					resolvedType = nil
					shouldBreak = true
				-- elseif type_["$$typeof"] == REACT_FUNDAMENTAL_TYPE then
				-- 	if enableFundamentalAPI then
				-- 		return createFiberFromFundamental(
				-- 			type_,
				-- 			pendingProps,
				-- 			mode,
				-- 			lanes,
				-- 			key
				-- 		)
				-- 	end
				end
			end
			if not shouldBreak then
				local info = ""
				if _G.__DEV__ then
					if
						type_ == nil or
						(typeof(type_) == "table" and
							#Object.keys(type_) == 0)
					then
						info ..=
							" You likely forgot to export your component from the file " ..
							"it's defined in, or you might have mixed up default and " ..
							"named imports."
					elseif type_ ~= nil and typeof(type_) == "table" then
						-- ROBLOX deviation: print the table/string in readable form to give a clue, if no other info was gathered
						info ..= "\n" .. inspect(type_)
					end
					local ownerName
					if owner then
						ownerName = getComponentName(owner.type)
					end
					if ownerName ~= nil and ownerName ~= "" then
						info ..= "\n\nCheck the render method of `" .. ownerName .. "`."
					elseif owner then
						-- ROBLOX deviation: print the raw table in readable
						-- form to give a clue, if no other info was gathered
						info ..= "\n" .. inspect(owner)
					end
				end

				-- ROBLOX deviation: make output logic consistent across ReactFiber, ElementValidator, Memo, Context, and Lazy
				local typeString
				if type_ == nil then
					typeString = "nil"
				elseif Array.isArray(type_) then
					typeString = "array"
				elseif typeof(type_) == "table" and type_["$$typeof"] == REACT_ELEMENT_TYPE then
					typeString = string.format("<%s />", getComponentName(type_.type) or "Unknown")
					info = " Did you accidentally export a JSX literal or Element instead of a component?"
				else
					typeString = typeof(type_)
				end

				invariant(
					false,
					"Element type is invalid: expected a string (for built-in " ..
						"components) or a class/function (for composite components) " ..
						"but got: %s.%s",
					typeString,
					info
				)
			end
		end
	end

	local fiber = createFiber(fiberTag, pendingProps, key, mode)
	fiber.elementType = type_
	fiber.type = resolvedType
	fiber.lanes = lanes

	if _G.__DEV__ then
		fiber._debugOwner = owner
	end

	return fiber
end

local function createFiberFromElement(
	element: ReactElement,
	mode: TypeOfMode,
	lanes: Lanes
): Fiber
	local owner = nil
	if _G.__DEV__ then
		owner = element._owner
	end
	local type = element.type
	local key = element.key
	local pendingProps = element.props
	local fiber = createFiberFromTypeAndProps(
		type,
		-- ROBLOX FIXME: according to upstream types, key can only be string?, but RoactStableKey deviation also says number
		key :: string,
		pendingProps,
		owner,
		mode,
		lanes
	)
	if _G.__DEV__ then
		fiber._debugSource = element._source
		fiber._debugOwner = element._owner
	end
	return fiber
end

function createFiberFromFragment(
	elements: ReactFragment,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	local fiber = createFiber(Fragment, elements, key, mode)
	fiber.lanes = lanes
	return fiber
end

function createFiberFromFundamental(
	fundamentalComponent: ReactFundamentalComponent<any, any>,
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	local fiber = createFiber(FundamentalComponent, pendingProps, key, mode)
	fiber.elementType = fundamentalComponent
	fiber.type = fundamentalComponent
	fiber.lanes = lanes
	return fiber
end

function createFiberFromScope(
	scope: ReactScope,
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	local fiber = createFiber(ScopeComponent, pendingProps, key, mode)
	fiber.type = scope
	fiber.elementType = scope
	fiber.lanes = lanes
	return fiber
end

function createFiberFromProfiler(
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	if _G.__DEV__ then
		if typeof(pendingProps.id) ~= "string" then
			console.error("Profiler must specify an \"id\" as a prop")
		end
	end

	local fiber = createFiber(Profiler, pendingProps, key, bit32.bor(mode, ProfileMode))
	-- TODO: The Profiler fiber shouldn't have a type. It has a tag.
	fiber.elementType = REACT_PROFILER_TYPE
	fiber.type = REACT_PROFILER_TYPE
	fiber.lanes = lanes

	if enableProfilerTimer then
		fiber.stateNode = {
			effectDuration = 0,
			passiveEffectDuration = 0,
		}
	end

	return fiber
end

function createFiberFromSuspense(
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	local fiber = createFiber(SuspenseComponent, pendingProps, key, mode)

	-- TODO: The SuspenseComponent fiber shouldn't have a type. It has a tag.
	-- This needs to be fixed in getComponentName so that it relies on the tag
	-- instead.
	fiber.type = REACT_SUSPENSE_TYPE
	fiber.elementType = REACT_SUSPENSE_TYPE

	fiber.lanes = lanes
	return fiber
end

function createFiberFromSuspenseList(
	pendingProps: any,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	local fiber = createFiber(SuspenseListComponent, pendingProps, key, mode)
	if _G.__DEV__ then
		-- TODO: The SuspenseListComponent fiber shouldn't have a type. It has a tag.
		-- This needs to be fixed in getComponentName so that it relies on the tag
		-- instead.
		fiber.type = REACT_SUSPENSE_LIST_TYPE
	end
	fiber.elementType = REACT_SUSPENSE_LIST_TYPE
	fiber.lanes = lanes
	return fiber
end

function createFiberFromOffscreen(
	pendingProps: OffscreenProps,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	local fiber = createFiber(OffscreenComponent, pendingProps, key, mode)
	-- TODO: The OffscreenComponent fiber shouldn't have a type. It has a tag.
	-- This needs to be fixed in getComponentName so that it relies on the tag
	-- instead.
	if _G.__DEV__ then
		fiber.type = REACT_OFFSCREEN_TYPE
	end
	fiber.elementType = REACT_OFFSCREEN_TYPE
	fiber.lanes = lanes
	return fiber
end

function createFiberFromLegacyHidden(
	pendingProps: OffscreenProps,
	mode: TypeOfMode,
	lanes: Lanes,
	key: string?
): Fiber
	local fiber = createFiber(LegacyHiddenComponent, pendingProps, key, mode)
	-- TODO: The LegacyHidden fiber shouldn't have a type. It has a tag.
	-- This needs to be fixed in getComponentName so that it relies on the tag
	-- instead.
	if _G.__DEV__ then
		fiber.type = REACT_LEGACY_HIDDEN_TYPE
	end
	fiber.elementType = REACT_LEGACY_HIDDEN_TYPE
	fiber.lanes = lanes
	return fiber
end

local function createFiberFromText(
	content: string,
	mode: TypeOfMode,
	lanes: Lanes
): Fiber
	local fiber = createFiber(HostText, content, nil, mode)
	fiber.lanes = lanes
	return fiber
end

local function createFiberFromHostInstanceForDeletion(): Fiber
	local fiber = createFiber(HostComponent, nil, nil, NoMode)
	-- TODO: These should not need a type.
	fiber.elementType = "DELETED"
	fiber.type = "DELETED"
	return fiber
end

local function createFiberFromDehydratedFragment(
	dehydratedNode: SuspenseInstance
): Fiber
	local fiber = createFiber(DehydratedFragment, nil, nil, NoMode)
	fiber.stateNode = dehydratedNode
	return fiber
end

local function createFiberFromPortal(
	portal: ReactPortal,
	mode: TypeOfMode,
	lanes: Lanes
): Fiber
	local pendingProps
	if portal.children ~= nil then
		pendingProps = portal.children
	else
		pendingProps = {}
	end
	local fiber = createFiber(HostPortal, pendingProps, portal.key, mode)
	fiber.lanes = lanes
	fiber.stateNode = {
		containerInfo = portal.containerInfo,
		pendingChildren = nil, -- Used by persistent updates
		implementation = portal.implementation,
	}
	return fiber
end

-- Used for stashing WIP properties to replay failed work in DEV.
-- ROBLOX FIXME: `target: Fiber | nil` - Narrowing doesn't work even with nil check
local function assignFiberPropertiesInDEV(
	target: Fiber,
	source: Fiber
): Fiber
	if target == nil then
		-- This Fiber's initial properties will always be overwritten.
		-- We only use a Fiber to ensure the same hidden class so DEV isn't slow.
		target = createFiber(IndeterminateComponent, nil, nil, NoMode)
	end

	-- This is intentionally written as a list of all properties.
	-- We tried to use Object.assign() instead but this is called in
	-- the hottest path, and Object.assign() was too slow:
	-- https://github.com/facebook/react/issues/12502
	-- This code is DEV-only so size is not a concern.

	target.tag = source.tag
	target.key = source.key
	target.elementType = source.elementType
	target.type = source.type
	target.stateNode = source.stateNode
	target.return_ = source.return_
	target.child = source.child
	target.sibling = source.sibling
	target.index = source.index
	target.ref = source.ref
	target.pendingProps = source.pendingProps
	target.memoizedProps = source.memoizedProps
	target.updateQueue = source.updateQueue
	target.memoizedState = source.memoizedState
	target.dependencies = source.dependencies
	target.mode = source.mode
	target.flags = source.flags
	target.subtreeFlags = source.subtreeFlags
	target.deletions = source.deletions
	target.lanes = source.lanes
	target.childLanes = source.childLanes
	target.alternate = source.alternate
	if enableProfilerTimer then
		target.actualDuration = source.actualDuration
		target.actualStartTime = source.actualStartTime
		target.selfBaseDuration = source.selfBaseDuration
		target.treeBaseDuration = source.treeBaseDuration
	end
	target._debugID = source._debugID
	target._debugSource = source._debugSource
	target._debugOwner = source._debugOwner
	target._debugNeedsRemount = source._debugNeedsRemount
	target._debugHookTypes = source._debugHookTypes
	return target
end

-- deviation: more convenient to export entire interface at the end
return {
	isSimpleFunctionComponent = isSimpleFunctionComponent,
	resolveLazyComponentTag = resolveLazyComponentTag,
	createWorkInProgress = createWorkInProgress,
	resetWorkInProgress = resetWorkInProgress,
	createHostRootFiber = createHostRootFiber,
	createFiberFromTypeAndProps = createFiberFromTypeAndProps,
	createFiberFromElement = createFiberFromElement,
	createFiberFromFragment = createFiberFromFragment,
	createFiberFromFundamental = createFiberFromFundamental,
	createFiberFromSuspense = createFiberFromSuspense,
	createFiberFromSuspenseList = createFiberFromSuspenseList,
	createFiberFromOffscreen = createFiberFromOffscreen,
	createFiberFromLegacyHidden = createFiberFromLegacyHidden,
	createFiberFromText = createFiberFromText,
	createFiberFromHostInstanceForDeletion = createFiberFromHostInstanceForDeletion,
	createFiberFromDehydratedFragment = createFiberFromDehydratedFragment,
	createFiberFromPortal = createFiberFromPortal,
	assignFiberPropertiesInDEV = assignFiberPropertiesInDEV,
}
