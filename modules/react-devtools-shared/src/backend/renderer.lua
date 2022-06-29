-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/renderer.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Shared = require(Packages.Shared)
local console = Shared.console
local Set = LuauPolyfill.Set
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local Number = LuauPolyfill.Number

type Array<K> = { [number]: K }
type Map<K, V> = { [K]: V }
type Set<T> = LuauPolyfill.Set<T>
type Object = { [string]: any }

function Array.new()
	return {}
end
-- ROBLOX deviation: Use _G as a catch all for global for now
-- ROBLOX TODO: Work out a better capability-based solution
local window = _G
local exports = {}

local invariant = require(Packages.Shared).invariant

-- ROBLOX deviation: we don't currently need semver, as we only support one version of React
-- local semver = require(semver)
-- local gte = semver.gte
local types = require(script.Parent.Parent.types)
local ComponentFilterDisplayName = types.ComponentFilterDisplayName
local ComponentFilterElementType = types.ComponentFilterElementType
local ComponentFilterHOC = types.ComponentFilterHOC
local ComponentFilterLocation = types.ComponentFilterLocation
local ElementTypeClass = types.ElementTypeClass
local ElementTypeContext = types.ElementTypeContext
local ElementTypeFunction = types.ElementTypeFunction
local ElementTypeForwardRef = types.ElementTypeForwardRef
local ElementTypeHostComponent = types.ElementTypeHostComponent
local ElementTypeMemo = types.ElementTypeMemo
local ElementTypeOtherOrUnknown = types.ElementTypeOtherOrUnknown
local ElementTypeProfiler = types.ElementTypeProfiler
local ElementTypeRoot = types.ElementTypeRoot
local ElementTypeSuspense = types.ElementTypeSuspense
local ElementTypeSuspenseList = types.ElementTypeSuspenseList
local utils = require(script.Parent.Parent.utils)
local deletePathInObject = utils.deletePathInObject
local getDisplayName = utils.getDisplayName
local getDefaultComponentFilters = utils.getDefaultComponentFilters
local getInObject = utils.getInObject
local getUID = utils.getUID
local renamePathInObject = utils.renamePathInObject
local setInObject = utils.setInObject
-- ROBLOX deviation: Don't encode strings
-- local utfEncodeString = utils.utfEncodeString
local storage = require(script.Parent.Parent.storage)
local sessionStorageGetItem = storage.sessionStorageGetItem
local backendUtils = require(script.Parent.utils)
local cleanForBridge = backendUtils.cleanForBridge
local copyToClipboard = backendUtils.copyToClipboard
local copyWithDelete = backendUtils.copyWithDelete
local copyWithRename = backendUtils.copyWithRename
local copyWithSet = backendUtils.copyWithSet
local constants = require(script.Parent.Parent.constants)
local __DEBUG__ = constants.__DEBUG__
local SESSION_STORAGE_RELOAD_AND_PROFILE_KEY =
	constants.SESSION_STORAGE_RELOAD_AND_PROFILE_KEY
local SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY =
	constants.SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY
local TREE_OPERATION_ADD = constants.TREE_OPERATION_ADD
local TREE_OPERATION_REMOVE = constants.TREE_OPERATION_REMOVE
local TREE_OPERATION_REORDER_CHILDREN = constants.TREE_OPERATION_REORDER_CHILDREN
local TREE_OPERATION_UPDATE_TREE_BASE_DURATION =
	constants.TREE_OPERATION_UPDATE_TREE_BASE_DURATION
local ReactDebugTools = require(Packages.ReactDebugTools)
local inspectHooksOfFiber = ReactDebugTools.inspectHooksOfFiber
local Console = require(script.Parent.console)
local patchConsole = Console.patch
local registerRendererWithConsole = Console.registerRenderer
local ReactSymbols = require(script.Parent.ReactSymbols)
local CONCURRENT_MODE_NUMBER = ReactSymbols.CONCURRENT_MODE_NUMBER
local CONCURRENT_MODE_SYMBOL_STRING = ReactSymbols.CONCURRENT_MODE_SYMBOL_STRING
local DEPRECATED_ASYNC_MODE_SYMBOL_STRING =
	ReactSymbols.DEPRECATED_ASYNC_MODE_SYMBOL_STRING
local PROVIDER_NUMBER = ReactSymbols.PROVIDER_NUMBER
local PROVIDER_SYMBOL_STRING = ReactSymbols.PROVIDER_SYMBOL_STRING
local CONTEXT_NUMBER = ReactSymbols.CONTEXT_NUMBER
local CONTEXT_SYMBOL_STRING = ReactSymbols.CONTEXT_SYMBOL_STRING
local STRICT_MODE_NUMBER = ReactSymbols.STRICT_MODE_NUMBER
local STRICT_MODE_SYMBOL_STRING = ReactSymbols.STRICT_MODE_SYMBOL_STRING
local PROFILER_NUMBER = ReactSymbols.PROFILER_NUMBER
local PROFILER_SYMBOL_STRING = ReactSymbols.PROFILER_SYMBOL_STRING
local SCOPE_NUMBER = ReactSymbols.SCOPE_NUMBER
local SCOPE_SYMBOL_STRING = ReactSymbols.SCOPE_SYMBOL_STRING
local FORWARD_REF_NUMBER = ReactSymbols.FORWARD_REF_NUMBER
local FORWARD_REF_SYMBOL_STRING = ReactSymbols.FORWARD_REF_SYMBOL_STRING
local MEMO_NUMBER = ReactSymbols.MEMO_NUMBER
local MEMO_SYMBOL_STRING = ReactSymbols.MEMO_SYMBOL_STRING
local is = Shared.objectIs
-- ROBLOX FIXME: pass in a real host config, or make this able to use basic enums without initializing
local ReactReconciler = require(Packages.ReactReconciler)({})

-- ROBLOX deviation: Require shared functionality rather than copying and pasting it inline
local getNearestMountedFiber = ReactReconciler.getNearestMountedFiber

-- ROBLOX deviation: ReactInternalTypes is re-exported from top-level reconciler to respect the module encapsulation boundary
local ReactInternalTypes = require(Packages.ReactReconciler)
type Fiber = ReactInternalTypes.Fiber
local BackendTypes = require(script.Parent.types)
type ChangeDescription = BackendTypes.ChangeDescription
type CommitDataBackend = BackendTypes.CommitDataBackend
type DevToolsHook = BackendTypes.DevToolsHook
type InspectedElement = BackendTypes.InspectedElement
type InspectedElementPayload = BackendTypes.InspectedElementPayload
type InstanceAndStyle = BackendTypes.InstanceAndStyle
type NativeType = BackendTypes.NativeType
type Owner = BackendTypes.Owner
type PathFrame = BackendTypes.PathFrame
type PathMatch = BackendTypes.PathMatch
type ProfilingDataBackend = BackendTypes.ProfilingDataBackend
type ProfilingDataForRootBackend = BackendTypes.ProfilingDataForRootBackend
type ReactRenderer = BackendTypes.ReactRenderer
type RendererInterface = BackendTypes.RendererInterface
type WorkTagMap = BackendTypes.WorkTagMap

local ProfilerTypes = require(script.Parent.Parent.devtools.views.Profiler.types)
type Interaction = ProfilerTypes.Interaction
local TypesModules = require(script.Parent.Parent.types)
type ComponentFilter = TypesModules.ComponentFilter
type ElementType = TypesModules.ElementType

type RegExpComponentFilter = TypesModules.RegExpComponentFilter
type ElementTypeComponentFilter = TypesModules.ElementTypeComponentFilter

type getDisplayNameForFiberType = (fiber: Fiber) -> string | nil
type getTypeSymbolType = (type: any) -> any | number

type ReactPriorityLevelsType = {
	ImmediatePriority: number,
	UserBlockingPriority: number,
	NormalPriority: number,
	LowPriority: number,
	IdlePriority: number,
	NoPriority: number,
}

type ReactTypeOfSideEffectType = {
	NoFlags: number,
	PerformedWork: number,
	Placement: number,
}

local function getFiberFlags(fiber: Fiber): number
	-- The name of this field changed from "effectTag" to "flags"
	if fiber.flags ~= nil then
		return fiber.flags
	else
		return (fiber :: any).effectTag
	end
end

local getCurrentTime = function()
	-- ROBLOX deviation: use os.clock not performance
	return os.clock()
end

exports.getInternalReactConstants = function(
	version: string
): {
	getDisplayNameForFiber: getDisplayNameForFiberType,
	getTypeSymbol: getTypeSymbolType,
	ReactPriorityLevels: ReactPriorityLevelsType,
	ReactTypeOfSideEffect: ReactTypeOfSideEffectType,
	ReactTypeOfWork: WorkTagMap,
}
	local ReactTypeOfSideEffect = {
		NoFlags = 0,
		PerformedWork = 1,
		Placement = 2,
	}

	-- **********************************************************
	-- The section below is copied from files in React repo.
	-- Keep it in sync, and add version guards if it changes.
	--
	-- Technically these priority levels are invalid for versions before 16.9,
	-- but 16.9 is the first version to report priority level to DevTools,
	-- so we can avoid checking for earlier versions and support pre-16.9 canary releases in the process.
	local ReactPriorityLevels = {
		ImmediatePriority = 99,
		UserBlockingPriority = 98,
		NormalPriority = 97,
		LowPriority = 96,
		IdlePriority = 95,
		NoPriority = 90,
	}

	-- ROBLOX deviation: we don't need to support older versions
	-- if gte(version, '17.0.0-alpha') then
	local ReactTypeOfWork: WorkTagMap = {
		Block = 22,
		ClassComponent = 1,
		ContextConsumer = 9,
		ContextProvider = 10,
		CoroutineComponent = -1,
		CoroutineHandlerPhase = -1,
		DehydratedSuspenseComponent = 18,
		ForwardRef = 11,
		Fragment = 7,
		FunctionComponent = 0,
		HostComponent = 5,
		HostPortal = 4,
		HostRoot = 3,
		HostText = 6,
		IncompleteClassComponent = 17,
		IndeterminateComponent = 2,
		LazyComponent = 16,
		MemoComponent = 14,
		Mode = 8,
		OffscreenComponent = 23,
		Profiler = 12,
		SimpleMemoComponent = 15,
		SuspenseComponent = 13,
		SuspenseListComponent = 19,
		YieldComponent = -1,
	}
	-- elseif gte(version, '16.6.0-beta.0') then
	--     ReactTypeOfWork = {
	--         Block = 22,
	--         ClassComponent = 1,
	--         ContextConsumer = 9,
	--         ContextProvider = 10,
	--         CoroutineComponent = -1,
	--         CoroutineHandlerPhase = -1,
	--         DehydratedSuspenseComponent = 18,
	--         ForwardRef = 11,
	--         Fragment = 7,
	--         FunctionComponent = 0,
	--         HostComponent = 5,
	--         HostPortal = 4,
	--         HostRoot = 3,
	--         HostText = 6,
	--         IncompleteClassComponent = 17,
	--         IndeterminateComponent = 2,
	--         LazyComponent = 16,
	--         MemoComponent = 14,
	--         Mode = 8,
	--         OffscreenComponent = -1,
	--         Profiler = 12,
	--         SimpleMemoComponent = 15,
	--         SuspenseComponent = 13,
	--         SuspenseListComponent = 19,
	--         YieldComponent = -1,
	--     }
	-- elseif gte(version, '16.4.3-alpha') then
	--     ReactTypeOfWork = {
	--         Block = -1,
	--         ClassComponent = 2,
	--         ContextConsumer = 11,
	--         ContextProvider = 12,
	--         CoroutineComponent = -1,
	--         CoroutineHandlerPhase = -1,
	--         DehydratedSuspenseComponent = -1,
	--         ForwardRef = 13,
	--         Fragment = 9,
	--         FunctionComponent = 0,
	--         HostComponent = 7,
	--         HostPortal = 6,
	--         HostRoot = 5,
	--         HostText = 8,
	--         IncompleteClassComponent = -1,
	--         IndeterminateComponent = 4,
	--         LazyComponent = -1,
	--         MemoComponent = -1,
	--         Mode = 10,
	--         OffscreenComponent = -1,
	--         Profiler = 15,
	--         SimpleMemoComponent = -1,
	--         SuspenseComponent = 16,
	--         SuspenseListComponent = -1,
	--         YieldComponent = -1,
	--     }
	-- else
	--     ReactTypeOfWork = {
	--         Block = -1,
	--         ClassComponent = 2,
	--         ContextConsumer = 12,
	--         ContextProvider = 13,
	--         CoroutineComponent = 7,
	--         CoroutineHandlerPhase = 8,
	--         DehydratedSuspenseComponent = -1,
	--         ForwardRef = 14,
	--         Fragment = 10,
	--         FunctionComponent = 1,
	--         HostComponent = 5,
	--         HostPortal = 4,
	--         HostRoot = 3,
	--         HostText = 6,
	--         IncompleteClassComponent = -1,
	--         IndeterminateComponent = 0,
	--         LazyComponent = -1,
	--         MemoComponent = -1,
	--         Mode = 11,
	--         OffscreenComponent = -1,
	--         Profiler = 15,
	--         SimpleMemoComponent = -1,
	--         SuspenseComponent = 16,
	--         SuspenseListComponent = -1,
	--         YieldComponent = 9,
	--     }
	-- end

	-- 	// **********************************************************
	--    // End of copied code.
	--    // **********************************************************

	local function getTypeSymbol(type_)
		local symbolOrNumber = (function()
			if typeof(type_) == "table" and type_ ~= nil then
				return type_["$$typeof"]
			else
				return type_
			end
		end)()
		return (function()
			-- ROBLOX deviation: symbol is not a native Luau type
			if typeof(symbolOrNumber) == "table" then
				return tostring(symbolOrNumber)
			else
				return symbolOrNumber
			end
		end)()
	end

	local ClassComponent, IncompleteClassComponent, FunctionComponent, IndeterminateComponent, ForwardRef, HostRoot, HostComponent, HostPortal, HostText, Fragment, MemoComponent, SimpleMemoComponent, SuspenseComponent, SuspenseListComponent =
		ReactTypeOfWork.ClassComponent,
		ReactTypeOfWork.IncompleteClassComponent,
		ReactTypeOfWork.FunctionComponent,
		ReactTypeOfWork.IndeterminateComponent,
		ReactTypeOfWork.ForwardRef,
		ReactTypeOfWork.HostRoot,
		ReactTypeOfWork.HostComponent,
		ReactTypeOfWork.HostPortal,
		ReactTypeOfWork.HostText,
		ReactTypeOfWork.Fragment,
		ReactTypeOfWork.MemoComponent,
		ReactTypeOfWork.SimpleMemoComponent,
		ReactTypeOfWork.SuspenseComponent,
		ReactTypeOfWork.SuspenseListComponent

	local function resolveFiberType(type_: any)
		local typeSymbol = getTypeSymbol(type_)
		if typeSymbol == MEMO_NUMBER or typeSymbol == MEMO_SYMBOL_STRING then
			-- recursively resolving memo type in case of memo(forwardRef(Component))
			return resolveFiberType(type_.type)
		elseif
			typeSymbol == FORWARD_REF_NUMBER
			or typeSymbol == FORWARD_REF_SYMBOL_STRING
		then
			return type_.render
		else
			return type_
		end
	end

	-- NOTICE Keep in sync with shouldFilterFiber() and other get*ForFiber methods
	local function getDisplayNameForFiber(fiber: Fiber): string | nil
		local type_, tag = fiber.type, fiber.tag
		local resolvedType = type_

		if typeof(type_) == "table" and type_ ~= nil then
			resolvedType = resolveFiberType(type_)
		end

		local resolvedContext = nil
		if tag == ClassComponent or tag == IncompleteClassComponent then
			return getDisplayName(resolvedType)
		elseif tag == FunctionComponent or tag == IndeterminateComponent then
			return getDisplayName(resolvedType)
		elseif tag == ForwardRef then
			-- Mirror https://github.com/facebook/react/blob/7c21bf72ace77094fd1910cc350a548287ef8350/packages/shared/getComponentName.js#L27-L37
			return (type_ and type_.displayName)
				or getDisplayName(resolvedType, "Anonymous")
		elseif tag == HostRoot then
			return nil
		elseif tag == HostComponent then
			return type_
		elseif tag == HostPortal or tag == HostText or tag == Fragment then
			return nil
		elseif tag == MemoComponent or tag == SimpleMemoComponent then
			return getDisplayName(resolvedType, "Anonymous")
		elseif tag == SuspenseComponent then
			return "Suspense"
		elseif tag == SuspenseListComponent then
			return "SuspenseList"
		else
			local typeSymbol = getTypeSymbol(type_)
			if
				typeSymbol == CONCURRENT_MODE_NUMBER
				or typeSymbol == CONCURRENT_MODE_SYMBOL_STRING
				or typeSymbol == DEPRECATED_ASYNC_MODE_SYMBOL_STRING
			then
				return nil
			elseif
				typeSymbol == PROVIDER_NUMBER or typeSymbol == PROVIDER_SYMBOL_STRING
			then
				-- 16.3.0 exposed the context object as "context"
				-- PR #12501 changed it to "_context" for 16.3.1+
				-- NOTE Keep in sync with inspectElementRaw()
				resolvedContext = fiber.type._context or fiber.type.context
				return ("%s.Provider"):format(resolvedContext.displayName or "Context")
			elseif
				typeSymbol == CONTEXT_NUMBER or typeSymbol == CONTEXT_SYMBOL_STRING
			then
				-- 16.3-16.5 read from "type" because the Consumer is the actual context object.
				-- 16.6+ should read from "type._context" because Consumer can be different (in DEV).
				-- NOTE Keep in sync with inspectElementRaw()
				resolvedContext = fiber.type._context or fiber.type

				-- NOTE: TraceUpdatesBackendManager depends on the name ending in '.Consumer'
				-- If you change the name, figure out a more resilient way to detect it.
				return ("%s.Consumer"):format(resolvedContext.displayName or "Context")
			elseif
				typeSymbol == STRICT_MODE_NUMBER
				or typeSymbol == STRICT_MODE_SYMBOL_STRING
			then
				return nil
			elseif
				typeSymbol == PROFILER_NUMBER or typeSymbol == PROFILER_SYMBOL_STRING
			then
				return ("Profiler(%s)"):format(fiber.memoizedProps.id)
			elseif typeSymbol == SCOPE_NUMBER or typeSymbol == SCOPE_SYMBOL_STRING then
				return "Scope"
			else
				-- Unknown element type.
				-- This may mean a new element type that has not yet been added to DevTools.
				return nil
			end
		end
	end

	return {
		getDisplayNameForFiber = getDisplayNameForFiber,
		getTypeSymbol = getTypeSymbol,
		ReactPriorityLevels = ReactPriorityLevels,
		ReactTypeOfWork = ReactTypeOfWork,
		ReactTypeOfSideEffect = ReactTypeOfSideEffect,
	}
end

exports.attach = function(
	hook: DevToolsHook,
	rendererID: number,
	renderer: ReactRenderer,
	global: Object
): RendererInterface
	-- ROBLOX deviation: these definitions have been hoisted to top of function for earlier use
	local fiberToIDMap = {}
	local idToFiberMap = {}
	local primaryFibers = Set.new()

	-- When profiling is supported, we store the latest tree base durations for each Fiber.
	-- This is so that we can quickly capture a snapshot of those values if profiling starts.
	-- If we didn't store these values, we'd have to crawl the tree when profiling started,
	-- and use a slow path to find each of the current Fibers.
	local idToTreeBaseDurationMap: Map<number, number> = {}

	-- When profiling is supported, we store the latest tree base durations for each Fiber.
	-- This map enables us to filter these times by root when sending them to the frontend.
	local idToRootMap: Map<number, number> = {}

	-- When a mount or update is in progress, this value tracks the root that is being operated on.
	local currentRootID = -1

	local function getFiberID(primaryFiber)
		if not fiberToIDMap[primaryFiber] then
			local id = getUID()
			fiberToIDMap[primaryFiber] = id
			idToFiberMap[id] = primaryFiber
		end

		return fiberToIDMap[primaryFiber]
	end

	local _getInternalReactCons = exports.getInternalReactConstants(renderer.version)
	local getDisplayNameForFiber, getTypeSymbol, ReactPriorityLevels, ReactTypeOfWork, ReactTypeOfSideEffect =
		_getInternalReactCons.getDisplayNameForFiber,
		_getInternalReactCons.getTypeSymbol,
		_getInternalReactCons.ReactPriorityLevels,
		_getInternalReactCons.ReactTypeOfWork,
		_getInternalReactCons.ReactTypeOfSideEffect
	local PerformedWork = ReactTypeOfSideEffect.PerformedWork
	local FunctionComponent, ClassComponent, ContextConsumer, DehydratedSuspenseComponent, Fragment, ForwardRef, HostRoot, HostPortal, HostComponent, HostText, IncompleteClassComponent, IndeterminateComponent, MemoComponent, OffscreenComponent, SimpleMemoComponent, SuspenseComponent, SuspenseListComponent =
		ReactTypeOfWork.FunctionComponent,
		ReactTypeOfWork.ClassComponent,
		ReactTypeOfWork.ContextConsumer,
		ReactTypeOfWork.DehydratedSuspenseComponent,
		ReactTypeOfWork.Fragment,
		ReactTypeOfWork.ForwardRef,
		ReactTypeOfWork.HostRoot,
		ReactTypeOfWork.HostPortal,
		ReactTypeOfWork.HostComponent,
		ReactTypeOfWork.HostText,
		ReactTypeOfWork.IncompleteClassComponent,
		ReactTypeOfWork.IndeterminateComponent,
		ReactTypeOfWork.MemoComponent,
		ReactTypeOfWork.OffscreenComponent,
		ReactTypeOfWork.SimpleMemoComponent,
		ReactTypeOfWork.SuspenseComponent,
		ReactTypeOfWork.SuspenseListComponent
	local ImmediatePriority, UserBlockingPriority, NormalPriority, LowPriority, IdlePriority =
		ReactPriorityLevels.ImmediatePriority,
		ReactPriorityLevels.UserBlockingPriority,
		ReactPriorityLevels.NormalPriority,
		ReactPriorityLevels.LowPriority,
		ReactPriorityLevels.IdlePriority

	-- ROBLOX deviation: these need binding to self
	local overrideHookState = function(...)
		return renderer.overrideHookState(...)
	end
	local overrideHookStateDeletePath = function(...)
		return renderer.overrideHookStateDeletePath(...)
	end
	local overrideHookStateRenamePath = function(...)
		return renderer.overrideHookStateRenamePath(...)
	end
	local overrideProps = function(...)
		return renderer.overrideProps(...)
	end
	local overridePropsDeletePath = function(...)
		return renderer.overridePropsDeletePath(...)
	end
	local overridePropsRenamePath = function(...)
		return renderer.overridePropsRenamePath(...)
	end
	local setSuspenseHandler = function(...)
		return renderer.setSuspenseHandler(...)
	end
	local scheduleUpdate = function(...)
		return renderer.scheduleUpdate(...)
	end

	local supportsTogglingSuspense = typeof(setSuspenseHandler) == "function"
		and typeof(scheduleUpdate) == "function"

	-- Patching the console enables DevTools to do a few useful things:
	-- * Append component stacks to warnings and error messages
	-- * Disable logging during re-renders to inspect hooks (see inspectHooksOfFiber)
	--
	-- Don't patch in test environments because we don't want to interfere with Jest's own console overrides.
	-- ROBLOX deviation: instead of checking if `process.env.NODE_ENV ~= "production"`
	-- we use the __DEV__ global
	if _G.__DEV__ then
		registerRendererWithConsole(renderer)

		-- The renderer interface can't read these preferences directly,
		-- because it is stored in localStorage within the context of the extension.
		-- It relies on the extension to pass the preference through via the global.
		local appendComponentStack = window.__REACT_DEVTOOLS_APPEND_COMPONENT_STACK__
			~= false
		local breakOnConsoleErrors = window.__REACT_DEVTOOLS_BREAK_ON_CONSOLE_ERRORS__
			== true

		if appendComponentStack or breakOnConsoleErrors then
			patchConsole({
				appendComponentStack = appendComponentStack,
				breakOnConsoleErrors = breakOnConsoleErrors,
			})
		end
	end

	local debug_ = function(name: string, fiber: Fiber, parentFiber: Fiber?): ()
		if __DEBUG__ then
			-- ROBLOX deviation: Use string nil rather than null as it is Roblox convenion
			local displayName = getDisplayNameForFiber(fiber) or "nil"
			local id = getFiberID(fiber)
			local parentDisplayName = parentFiber ~= nil
					and getDisplayNameForFiber(
						parentFiber :: Fiber
					)
				or "nil"
			local parentID = parentFiber and getFiberID(parentFiber :: Fiber) or ""
			-- NOTE: calling getFiberID or getPrimaryFiber is unsafe here
			-- because it will put them in the map. For now, we'll omit them.
			-- TODO: better debugging story for this.
			-- ROBLOX deviation: avoid incompatible log formatting
			console.log(
				("[renderer] %s %s (%d) %s"):format(
					name,
					displayName,
					id,
					parentFiber
							and ("%s (%s)"):format(
								tostring(parentDisplayName),
								tostring(parentID)
							)
						or ""
				)
			)
		end
	end

	-- Configurable Components tree filters.
	-- ROBLOX deviation: adjusted to use Lua patterns, but we may actually want original RegExp
	local hideElementsWithDisplayNames: Set<string> = Set.new()
	local hideElementsWithPaths: Set<string> = Set.new()
	local hideElementsWithTypes: Set<ElementType> = Set.new()

	-- ROBLOX deviation: local variables need to be defined above their use in closures
	-- Roots don't have a real persistent identity.
	-- A root's "pseudo key" is "childDisplayName:indexWithThatName".
	-- For example, "App:0" or, in case of similar roots, "Story:0", "Story:1", etc.
	-- We will use this to try to disambiguate roots when restoring selection between reloads.
	local rootPseudoKeys: Map<number, string> = {}
	local rootDisplayNameCounter: Map<string, number> = {}

	-- ROBLOX deviation: definitions hoisted earlier in function
	local currentCommitProfilingMetadata: CommitProfilingData | nil = nil
	local displayNamesByRootID: DisplayNamesByRootID | nil = nil
	local idToContextsMap: Map<number, any> | nil = nil
	local initialTreeBaseDurationsMap: Map<number, number> | nil = nil
	local initialIDToRootMap: Map<number, number> | nil = nil
	local isProfiling: boolean = false
	local profilingStartTime: number = 0
	local recordChangeDescriptions: boolean = false
	local rootToCommitProfilingMetadataMap: CommitProfilingMetadataMap | nil = nil

	local mostRecentlyInspectedElement: InspectedElement | nil = nil
	local hasElementUpdatedSinceLastInspected: boolean = false
	local currentlyInspectedPaths: Object = {}

	local forceFallbackForSuspenseIDs = Set.new()

	-- Highlight updates
	local traceUpdatesEnabled: boolean = false
	local traceUpdatesForNodes: Set<NativeType> = Set.new()

	-- ROBLOX deviation: hoise local variables
	-- Remember if we're trying to restore the selection after reload.
	-- In that case, we'll do some extra checks for matching mounts.
	local trackedPath: Array<PathFrame> | nil = nil
	local trackedPathMatchFiber: Fiber | nil = nil
	local trackedPathMatchDepth = -1
	local mightBeOnTrackedPath = false

	-- ROBLOX deviation: hoist function variables
	local getPrimaryFiber, unmountFiberChildrenRecursively, recordUnmount, setRootPseudoKey, removeRootPseudoKey, mountFiberRecursively, flushPendingEvents, getElementTypeForFiber, getContextChangedKeys, didHooksChange, getChangedKeys, getContextsForFiber, getDisplayNameForRoot, recordProfilingDurations, setTrackedPath, updateTrackedPathStateBeforeMount, updateTrackedPathStateAfterMount, findReorderedChildrenRecursively, findAllCurrentHostFibers, findCurrentFiberUsingSlowPathById, isMostRecentlyInspectedElementCurrent, getPathFrame

	local function applyComponentFilters(componentFilters: Array<ComponentFilter>)
		hideElementsWithTypes:clear()
		hideElementsWithDisplayNames:clear()
		hideElementsWithPaths:clear()
		-- ROBLOX TODO: translate to Array.forEach
		for _, componentFilter in ipairs(componentFilters) do
			if not componentFilter.isEnabled then
				continue
			end
			if componentFilter.type == ComponentFilterDisplayName then
				-- ROBLOX deviation: use value directly as pattern rather than creating a RegExp
				hideElementsWithDisplayNames:add(
					(componentFilter :: RegExpComponentFilter).value
				)
			elseif componentFilter.type == ComponentFilterElementType then
				hideElementsWithTypes:add(
					(componentFilter :: ElementTypeComponentFilter).value
				)
			elseif componentFilter.type == ComponentFilterLocation then
				if
					(componentFilter :: RegExpComponentFilter).isValid
					and (componentFilter :: RegExpComponentFilter).value ~= ""
				then
					-- ROBLOX deviation: use value directly as pattern rather than creating a RegExp
					hideElementsWithPaths:add(
						(componentFilter :: RegExpComponentFilter).value
					)
				end
			elseif componentFilter.type == ComponentFilterHOC then
				hideElementsWithDisplayNames:add("%(")
			else
				console.warn(
					('Invalid component filter type "%d"'):format(componentFilter.type)
				)
			end
		end
	end

	-- The renderer interface can't read saved component filters directly,
	-- because they are stored in localStorage within the context of the extension.
	-- Instead it relies on the extension to pass filters through.
	if window.__REACT_DEVTOOLS_COMPONENT_FILTERS__ ~= nil then
		applyComponentFilters(window.__REACT_DEVTOOLS_COMPONENT_FILTERS__)
	else
		-- Unfortunately this feature is not expected to work for React Native for now.
		-- It would be annoying for us to spam YellowBox warnings with unactionable stuff,
		-- so for now just skip this message...
		--console.warn('⚛️ DevTools: Could not locate saved component filters');

		-- Fallback to assuming the default filters in this case.
		applyComponentFilters(getDefaultComponentFilters())
	end

	-- If necessary, we can revisit optimizing this operation.
	-- For example, we could add a new recursive unmount tree operation.
	-- The unmount operations are already significantly smaller than mount operations though.
	-- This is something to keep in mind for later.
	local function updateComponentFilters(componentFilters: Array<ComponentFilter>)
		if isProfiling then
			-- Re-mounting a tree while profiling is in progress might break a lot of assumptions.
			-- If necessary, we could support this- but it doesn't seem like a necessary use case.
			error("Cannot modify filter preferences while profiling")
		end

		-- Recursively unmount all roots.
		-- ROBLOX deviation: for loop instead of forEach
		for root in pairs(hook.getFiberRoots(rendererID)) do
			currentRootID = getFiberID(getPrimaryFiber(root.current))
			unmountFiberChildrenRecursively(root.current)
			recordUnmount(root.current, false)
			currentRootID = -1
		end

		applyComponentFilters(componentFilters)

		-- Reset pseudo counters so that new path selections will be persisted.
		rootDisplayNameCounter = {}

		-- Recursively re-mount all roots with new filter criteria applied.
		for root in pairs(hook.getFiberRoots(rendererID)) do
			currentRootID = getFiberID(getPrimaryFiber(root.current :: Fiber))

			setRootPseudoKey(currentRootID, root.current :: Fiber)
			mountFiberRecursively(root.current :: Fiber, nil, false, false)
			flushPendingEvents(root)

			currentRootID = -1
		end
	end

	-- NOTICE Keep in sync with get*ForFiber methods
	local function shouldFilterFiber(fiber: Fiber): boolean
		local _debugSource, tag, type_ = fiber._debugSource, fiber.tag, fiber.type

		if tag == DehydratedSuspenseComponent then
			-- TODO: ideally we would show dehydrated Suspense immediately.
			-- However, it has some special behavior (like disconnecting
			-- an alternate and turning into real Suspense) which breaks DevTools.
			-- For now, ignore it, and only show it once it gets hydrated.
			-- https://github.com/bvaughn/react-devtools-experimental/issues/197
			return true
		elseif
			tag == HostPortal
			or tag == HostText
			or tag == Fragment
			or tag == OffscreenComponent
		then
			return true
		elseif tag == HostRoot then
			-- It is never valid to filter the root element.
			return false
		else
			local typeSymbol = getTypeSymbol(type_)
			if
				typeSymbol == CONCURRENT_MODE_NUMBER
				or typeSymbol == CONCURRENT_MODE_SYMBOL_STRING
				or typeSymbol == DEPRECATED_ASYNC_MODE_SYMBOL_STRING
				or typeSymbol == STRICT_MODE_NUMBER
				or typeSymbol == STRICT_MODE_SYMBOL_STRING
			then
				return true
			end
		end

		local elementType = getElementTypeForFiber(fiber)

		if hideElementsWithTypes:has(elementType) then
			return true
		end
		if hideElementsWithDisplayNames.size > 0 then
			local displayName = getDisplayNameForFiber(fiber)
			if displayName ~= nil then
				-- eslint-disable-next-line no-for-of-loops/no-for-of-loops
				for _, displayNameRegExp in hideElementsWithDisplayNames:ipairs() do
					-- ROBLOX deviation: these are patterns not RegExps
					if (displayName :: string):match(displayNameRegExp) then
						return true
					end
				end
			end
		end
		if _debugSource ~= nil and hideElementsWithPaths.size > 0 then
			local fileName = _debugSource.fileName

			-- eslint-disable-next-line no-for-of-loops/no-for-of-loops
			for _, pathRegExp in hideElementsWithPaths:ipairs() do
				-- ROBLOX deviation: these are patterns not RegExps
				if fileName:match(pathRegExp) then
					return true
				end
			end
		end

		return false
	end

	-- NOTICE Keep in sync with shouldFilterFiber() and other get*ForFiber methods
	getElementTypeForFiber = function(fiber: Fiber): ElementType
		local type_, tag = fiber.type, fiber.tag

		if tag == ClassComponent or tag == IncompleteClassComponent then
			return ElementTypeClass
		elseif tag == FunctionComponent or tag == IndeterminateComponent then
			return ElementTypeFunction
		elseif tag == ForwardRef then
			return ElementTypeForwardRef
		elseif tag == HostRoot then
			return ElementTypeRoot
		elseif tag == HostComponent then
			return ElementTypeHostComponent
		elseif tag == HostPortal or tag == HostText or tag == Fragment then
			return ElementTypeOtherOrUnknown
		elseif tag == MemoComponent or tag == SimpleMemoComponent then
			return ElementTypeMemo
		elseif tag == SuspenseComponent then
			return ElementTypeSuspense
		elseif tag == SuspenseListComponent then
			return ElementTypeSuspenseList
		else
			local typeSymbol = getTypeSymbol(type_)
			if
				typeSymbol == CONCURRENT_MODE_NUMBER
				or typeSymbol == CONCURRENT_MODE_SYMBOL_STRING
				or typeSymbol == DEPRECATED_ASYNC_MODE_SYMBOL_STRING
			then
				return ElementTypeContext
			elseif
				typeSymbol == PROVIDER_NUMBER or typeSymbol == PROVIDER_SYMBOL_STRING
			then
				return ElementTypeContext
			elseif
				typeSymbol == CONTEXT_NUMBER or typeSymbol == CONTEXT_SYMBOL_STRING
			then
				return ElementTypeContext
			elseif
				typeSymbol == STRICT_MODE_NUMBER
				or typeSymbol == STRICT_MODE_SYMBOL_STRING
			then
				return ElementTypeOtherOrUnknown
			elseif
				typeSymbol == PROFILER_NUMBER or typeSymbol == PROFILER_SYMBOL_STRING
			then
				return ElementTypeProfiler
			else
				return ElementTypeOtherOrUnknown
			end
		end
	end

	-- This is a slightly annoying indirection.
	-- It is currently necessary because DevTools wants to use unique objects as keys for instances.
	-- However fibers have two versions.
	-- We use this set to remember first encountered fiber for each conceptual instance.
	getPrimaryFiber = function(fiber: Fiber): Fiber
		if primaryFibers:has(fiber) then
			return fiber
		end

		local alternate = fiber.alternate

		if alternate ~= nil and primaryFibers:has(alternate) then
			return alternate :: Fiber
		end

		primaryFibers:add(fiber)

		return fiber
	end

	local function getChangeDescription(
		prevFiber: Fiber | nil,
		nextFiber: Fiber
	): ChangeDescription | nil
		local fiberType = getElementTypeForFiber(nextFiber)
		if
			fiberType == ElementTypeClass
			or fiberType == ElementTypeFunction
			or fiberType == ElementTypeMemo
			or fiberType == ElementTypeForwardRef
			-- ROBLOX deviation: Include host components in the report
			or fiberType == ElementTypeHostComponent
		then
			if prevFiber == nil then
				return {
					context = nil,
					didHooksChange = false,
					isFirstMount = true,
					props = nil,
					state = nil,
				}
			else
				return {
					context = getContextChangedKeys(nextFiber),
					didHooksChange = didHooksChange(
						(prevFiber :: Fiber).memoizedState,
						nextFiber.memoizedState
					),
					isFirstMount = false,
					props = getChangedKeys(
						(prevFiber :: Fiber).memoizedProps,
						nextFiber.memoizedProps
					),
					state = getChangedKeys(
						(prevFiber :: Fiber).memoizedState,
						nextFiber.memoizedState
					),
				}
			end
		else
			return nil
		end
	end

	local function updateContextsForFiber(fiber: Fiber)
		if getElementTypeForFiber(fiber) == ElementTypeClass then
			if idToContextsMap ~= nil then
				local id = getFiberID(getPrimaryFiber(fiber))
				local contexts = getContextsForFiber(fiber)
				if contexts ~= nil then
					(idToContextsMap :: Map<number, any>)[id] = contexts
				end
			end
		end
	end

	-- Differentiates between a null context value and no context.
	local NO_CONTEXT = {}

	-- ROBLOX deviation: Luau can't express return type: [Object, any]
	getContextsForFiber = function(fiber: Fiber): Array<any> | nil
		if getElementTypeForFiber(fiber) == ElementTypeClass then
			local instance = fiber.stateNode
			local legacyContext = NO_CONTEXT
			local modernContext = NO_CONTEXT
			if instance ~= nil then
				if instance.constructor and instance.constructor.contextType ~= nil then
					modernContext = instance.context
				else
					legacyContext = instance.context
					if legacyContext and #Object.keys(legacyContext) == 0 then
						legacyContext = NO_CONTEXT
					end
				end
			end
			return { legacyContext, modernContext }
		end
		return nil
	end

	-- Record all contexts at the time profiling is started.
	-- Fibers only store the current context value,
	-- so we need to track them separately in order to determine changed keys.
	local function crawlToInitializeContextsMap(fiber: Fiber)
		updateContextsForFiber(fiber)
		local current = fiber.child
		while current ~= nil do
			crawlToInitializeContextsMap(current :: Fiber)
			current = (current :: Fiber).sibling
		end
	end

	getContextChangedKeys = function(fiber: Fiber): nil | boolean | Array<string>
		if getElementTypeForFiber(fiber) == ElementTypeClass then
			if idToContextsMap ~= nil then
				local id = getFiberID(getPrimaryFiber(fiber))
				local prevContexts = (idToContextsMap :: Map<number, any>)[id]
				local nextContexts = getContextsForFiber(fiber)

				if prevContexts == nil or nextContexts == nil then
					return nil
				end

				local prevLegacyContext, prevModernContext =
					prevContexts[1], prevContexts[2]
				local nextLegacyContext, nextModernContext =
					(nextContexts :: Array<any>)[1], (nextContexts :: Array<any>)[2]

				if nextLegacyContext ~= NO_CONTEXT then
					return getChangedKeys(prevLegacyContext, nextLegacyContext)
				elseif nextModernContext ~= NO_CONTEXT then
					return prevModernContext ~= nextModernContext
				end
			end
		end
		return nil
	end
	local function areHookInputsEqual(nextDeps: Array<any>, prevDeps: Array<any> | nil)
		if prevDeps == nil then
			return false
		end

		local i = 1
		while i < #(prevDeps :: Array<any>) and i < #nextDeps do
			if is(nextDeps[i], (prevDeps :: Array<any>)[i]) then
				continue
			end
			return false
		end
		return true
	end

	local function isEffect(memoizedState)
		return memoizedState ~= nil
			and typeof(memoizedState) == "table"
			and memoizedState.tag ~= nil
			and memoizedState.create ~= nil
			and memoizedState.destroy ~= nil
			and memoizedState.deps ~= nil
			and (memoizedState.deps == nil or Array.isArray(memoizedState.deps))
			and memoizedState.next
	end

	local function didHookChange(prev: any, next: any): boolean
		local prevMemoizedState = prev.memoizedState
		local nextMemoizedState = next.memoizedState

		if isEffect(prevMemoizedState) and isEffect(nextMemoizedState) then
			return prevMemoizedState ~= nextMemoizedState
				and not areHookInputsEqual(nextMemoizedState.deps, prevMemoizedState.deps)
		end
		return nextMemoizedState ~= prevMemoizedState
	end
	didHooksChange = function(prev: any, next_: any): boolean
		if prev == nil or next_ == nil then
			return false
		end
		-- We can't report anything meaningful for hooks changes.
		-- ROBLOX deviation: hasOwnProperty doesn't exist
		if
			next_["baseState"]
			and next_["memoizedState"]
			and next_["next"]
			and next_["queue"]
		then
			while next_ ~= nil do
				if didHookChange(prev, next_) then
					return true
				else
					next_ = next_.next
					prev = prev.next
				end
			end
		end

		return false
	end
	getChangedKeys = function(prev: any, next_: any): nil | Array<string>
		if prev == nil or next_ == nil then
			return nil
		end
		-- We can't report anything meaningful for hooks changes.
		-- ROBLOX deviation: hasOwnProperty doesn't exist
		if
			next_["baseState"]
			and next_["memoizedState"]
			and next_["next"]
			and next_["queue"] ~= nil
		then
			return nil
		end

		-- ROBLOX deviation: Avoid an additional Set allocation here as that
		-- creates unneccessary tables and requires extra iteration.
		-- Instead, iterate through the prev keys first and check if they have
		-- changed in next, then check next for any new keys.

		-- local keys = Set.new({
		-- 	table.unpack(Object.keys(prev)),
		-- 	table.unpack(Object.keys(next_)),
		-- })
		-- local changedKeys = {}
		-- -- eslint-disable-next-line no-for-of-loops/no-for-of-loops
		-- for _, key in keys:ipairs() do
		-- 	if prev[key] ~= next_[key] then
		local changedKeys = {}

		for key, value in pairs(prev) do
			if value ~= next_[key] then
				table.insert(changedKeys, key)
			end
		end
		for key, value in pairs(next_) do
			if prev[key] == nil then
				table.insert(changedKeys, key)
			end
		end

		return changedKeys
	end

	-- eslint-disable-next-line no-unused-vars
	local function didFiberRender(prevFiber: Fiber, nextFiber: Fiber): boolean
		local tag = nextFiber.tag
		if
			tag == ClassComponent
			or tag == FunctionComponent
			or tag == ContextConsumer
			or tag == MemoComponent
			or tag == SimpleMemoComponent
		then
			-- For types that execute user code, we check PerformedWork effect.
			-- We don't reflect bailouts (either referential or sCU) in DevTools.
			-- eslint-disable-next-line no-bitwise
			return bit32.band(getFiberFlags(nextFiber), PerformedWork) == PerformedWork
		else
			-- Note: ContextConsumer only gets PerformedWork effect in 16.3.3+
			-- so it won't get highlighted with React 16.3.0 to 16.3.2.
			-- For host components and other types, we compare inputs
			-- to determine whether something is an update.
			return prevFiber.memoizedProps ~= nextFiber.memoizedProps
				or prevFiber.memoizedState ~= nextFiber.memoizedState
				or prevFiber.ref ~= nextFiber.ref
		end
	end

	local pendingOperations: Array<number> = {}
	local pendingRealUnmountedIDs: Array<number> = {}
	local pendingSimulatedUnmountedIDs: Array<number> = {}
	local pendingOperationsQueue: Array<Array<number>> | nil = {}
	local pendingStringTable: Map<string, number> = {}
	local pendingStringTableLength: number = 0
	local pendingUnmountedRootID: number | nil = nil

	local function pushOperation(op: number): ()
		-- ROBLOX deviation: Use global
		if global.__DEV__ then
			if not Number.isInteger(op) then
				console.error(
					"pushOperation() was called but the value is not an integer.",
					op
				)
			end
		end
		table.insert(pendingOperations, op)
	end
	flushPendingEvents = function(root: Object): ()
		if
			#pendingOperations == 0
			and #pendingRealUnmountedIDs == 0
			and #pendingSimulatedUnmountedIDs == 0
			and pendingUnmountedRootID == nil
		then
			-- If we aren't profiling, we can just bail out here.
			-- No use sending an empty update over the bridge.
			--
			-- The Profiler stores metadata for each commit and reconstructs the app tree per commit using:
			-- (1) an initial tree snapshot and
			-- (2) the operations array for each commit
			-- Because of this, it's important that the operations and metadata arrays align,
			-- So it's important not to omit even empty operations while profiling is active.
			if not isProfiling then
				return
			end
		end

		local numUnmountIDs = #pendingRealUnmountedIDs
			+ #pendingSimulatedUnmountedIDs
			+ (pendingUnmountedRootID == nil and 0 or 1)
		local operations: Array<string | number> = Array.new(
			-- ROBLOX deviation: don't create an array of specified length
			-- Identify which renderer this update is coming from.
			-- 2 -- [rendererID, rootFiberID]
			-- 				-- How big is the string table?
			-- 				+ 1 -- [stringTableLength]
			-- 				-- Then goes the actual string table.
			-- 				+ pendingStringTableLength
			-- 				-- All unmounts are batched in a single message.
			-- 				-- [TREE_OPERATION_REMOVE, removedIDLength, ...ids]
			-- 				+ numUnmountIDs
			-- 			> 0
			-- 		and (2 + numUnmountIDs)
			-- 	or 0
			-- 		-- Regular operations
			-- 		+ #pendingOperations
		)

		-- Identify which renderer this update is coming from.
		-- This enables roots to be mapped to renderers,
		-- Which in turn enables fiber props, states, and hooks to be inspected.
		local i = 1

		-- ROBLOX deviation: instead of i++
		local function POSTFIX_INCREMENT()
			local prevI = i
			i += 1
			return prevI
		end

		operations[POSTFIX_INCREMENT()] = rendererID
		operations[POSTFIX_INCREMENT()] = currentRootID -- Use this ID in case the root was unmounted!

		-- Now fill in the string table.
		-- [stringTableLength, str1Length, ...str1, str2Length, ...str2, ...]
		-- ROBLOX deviation: [stringCount, str1, str2, ...]
		operations[POSTFIX_INCREMENT()] = pendingStringTableLength

		-- ROBLOX deviation: insert operations in pendingStringTable value-order
		local stringTableStartIndex = #operations

		for key, value in pairs(pendingStringTable) do
			-- ROBLOX deviation: Don't encode strings
			-- operations[POSTFIX_INCREMENT()] = key:len()
			-- local encodedKey = utfEncodeString(key)
			-- for j = 1, #encodedKey do
			-- 	operations[i + j] = encodedKey[j]
			-- end
			-- i = i + key:len()
			operations[stringTableStartIndex + value] = key

			-- ROBLOX deviation: ensure increment is still called
			POSTFIX_INCREMENT()
		end

		if numUnmountIDs > 0 then
			-- All unmounts except roots are batched in a single message.
			operations[POSTFIX_INCREMENT()] = TREE_OPERATION_REMOVE :: number
			-- The first number is how many unmounted IDs we're gonna send.
			operations[POSTFIX_INCREMENT()] = numUnmountIDs :: number

			-- Fill in the real unmounts in the reverse order.
			-- They were inserted parents-first by React, but we want children-first.
			-- So we traverse our array backwards.
			for j = #pendingRealUnmountedIDs, 1, -1 do
				operations[POSTFIX_INCREMENT()] = pendingRealUnmountedIDs[j] :: number
			end

			-- Fill in the simulated unmounts (hidden Suspense subtrees) in their order.
			-- (We want children to go before parents.)
			-- They go *after* the real unmounts because we know for sure they won't be
			-- children of already pushed "real" IDs. If they were, we wouldn't be able
			-- to discover them during the traversal, as they would have been deleted.
			for j = 1, #pendingSimulatedUnmountedIDs do
				operations[i + j] = pendingSimulatedUnmountedIDs[j] :: number
			end

			i = i + #pendingSimulatedUnmountedIDs

			-- The root ID should always be unmounted last.
			if pendingUnmountedRootID ~= nil then
				operations[i] = pendingUnmountedRootID :: number
				i = i + 1
			end
		end

		-- Fill in the rest of the operations.
		for j = 1, #pendingOperations do
			-- ROBLOX deviation: 1-indexing math
			operations[i + j - 1] = pendingOperations[j] :: number
		end

		i = i + #pendingOperations

		-- Let the frontend know about tree operations.
		-- The first value in this array will identify which root it corresponds to,
		-- so we do no longer need to dispatch a separate root-committed event.
		if pendingOperationsQueue ~= nil then
			-- Until the frontend has been connected, store the tree operations.
			-- This will let us avoid walking the tree later when the frontend connects,
			-- and it enables the Profiler's reload-and-profile functionality to work as well.
			table.insert(pendingOperationsQueue :: Array<any>, operations)
		else
			-- If we've already connected to the frontend, just pass the operations through.
			hook.emit("operations", operations)
		end

		-- ROBLOX deviation: replace table instead of truncating it
		pendingOperations = {}
		pendingRealUnmountedIDs = {}
		pendingSimulatedUnmountedIDs = {}
		pendingUnmountedRootID = nil
		pendingStringTable = {}
		pendingStringTableLength = 0
	end

	local function getStringID(str: string | nil): number
		if str == nil or str == "" then
			return 0
		end

		local existingID: number? = pendingStringTable[str :: string]

		if existingID ~= nil then
			return existingID :: number
		end

		local stringID = #Object.keys(pendingStringTable) + 1

		pendingStringTable[str :: string] = stringID
		-- The string table total length needs to account
		-- both for the string length, and for the array item
		-- that contains the length itself. Hence + 1.
		-- ROBLOX deviation: Don't encode strings, so just count one for the single string entry
		-- pendingStringTableLength = pendingStringTableLength + (str:len() + 1)
		pendingStringTableLength += 1
		return stringID
	end

	local function recordMount(fiber: Fiber, parentFiber: Fiber | nil)
		-- ROBLOX deviation: use global
		if global.__DEBUG__ then
			debug_("recordMount()", fiber, parentFiber)
		end

		local isRoot = fiber.tag == HostRoot
		local id = getFiberID(getPrimaryFiber(fiber))
		local hasOwnerMetadata = fiber["_debugOwner"] ~= nil
		local isProfilingSupported = fiber["treeBaseDuration"] ~= nil

		if isRoot then
			pushOperation(TREE_OPERATION_ADD)
			pushOperation(id)
			pushOperation(ElementTypeRoot)
			pushOperation(isProfilingSupported and 1 or 0)
			pushOperation(hasOwnerMetadata and 1 or 0)

			if isProfiling then
				if displayNamesByRootID ~= nil then
					(displayNamesByRootID :: Map<number, string>)[id] =
						getDisplayNameForRoot(
							fiber
						)
				end
			end
		else
			local key = fiber.key
			local displayName = getDisplayNameForFiber(fiber)
			local elementType = getElementTypeForFiber(fiber)
			local _debugOwner = fiber._debugOwner
			local ownerID = _debugOwner
					and getFiberID(getPrimaryFiber(_debugOwner :: Fiber))
				or 0
			local parentID = parentFiber
					and getFiberID(getPrimaryFiber(parentFiber :: Fiber))
				or 0

			local displayNameStringID = getStringID(displayName)

			-- This check is a guard to handle a React element that has been modified
			-- in such a way as to bypass the default stringification of the "key" property.
			local keyString = (function(): string?
				if key == nil then
					return nil
				end
				return "" .. key
			end)()
			local keyStringID = getStringID(keyString)

			pushOperation(TREE_OPERATION_ADD)
			pushOperation(id)
			pushOperation(elementType)
			pushOperation(parentID)
			pushOperation(ownerID)
			pushOperation(displayNameStringID)
			pushOperation(keyStringID)
		end
		if isProfilingSupported then
			idToRootMap[id] = currentRootID
			recordProfilingDurations(fiber)
		end
	end
	recordUnmount = function(fiber: Fiber, isSimulated: boolean)
		-- ROBLOX deviation: use global
		if global.__DEBUG__ then
			debug_("recordUnmount()", fiber)
		end

		if trackedPathMatchFiber ~= nil then
			-- We're in the process of trying to restore previous selection.
			-- If this fiber matched but is being unmounted, there's no use trying.
			-- Reset the state so we don't keep holding onto it.
			if
				fiber == trackedPathMatchFiber
				or fiber == (trackedPathMatchFiber :: Fiber).alternate
			then
				setTrackedPath(nil)
			end
		end

		local isRoot = fiber.tag == HostRoot
		local primaryFiber = getPrimaryFiber(fiber)

		if not fiberToIDMap[primaryFiber] then
			-- If we've never seen this Fiber, it might be because
			-- it is inside a non-current Suspense fragment tree,
			-- and so the store is not even aware of it.
			-- In that case we can just ignore it, or otherwise
			-- there will be errors later on.
			primaryFibers:delete(primaryFiber)
			-- TODO: this is fragile and can obscure actual bugs.
			return
		end

		local id = getFiberID(primaryFiber)

		if isRoot then
			-- Roots must be removed only after all children (pending and simulated) have been removed.
			-- So we track it separately.
			pendingUnmountedRootID = id
		elseif not shouldFilterFiber(fiber) then
			-- To maintain child-first ordering,
			-- we'll push it into one of these queues,
			-- and later arrange them in the correct order.
			if isSimulated then
				table.insert(pendingSimulatedUnmountedIDs, id)
			else
				table.insert(pendingRealUnmountedIDs, id)
			end
		end

		fiberToIDMap[primaryFiber] = nil
		idToFiberMap[id] = nil
		primaryFibers[primaryFiber] = nil

		-- ROBLOX deviation: hasOwnProperty doesn't exist
		local isProfilingSupported = fiber["treeBaseDuration"] ~= nil

		if isProfilingSupported then
			idToRootMap[id] = nil
			idToTreeBaseDurationMap[id] = nil
		end
	end
	mountFiberRecursively = function(
		fiber: Fiber,
		parentFiber: Fiber | nil,
		traverseSiblings: boolean,
		traceNearestHostComponentUpdate: boolean
	)
		if __DEBUG__ then
			debug_("mountFiberRecursively()", fiber, parentFiber)
		end

		-- If we have the tree selection from previous reload, try to match this Fiber.
		-- Also remember whether to do the same for siblings.
		local mightSiblingsBeOnTrackedPath = updateTrackedPathStateBeforeMount(fiber)
		local shouldIncludeInTree = not shouldFilterFiber(fiber)

		if shouldIncludeInTree then
			recordMount(fiber, parentFiber)
		end
		if traceUpdatesEnabled then
			if traceNearestHostComponentUpdate then
				local elementType = getElementTypeForFiber(fiber)
				-- If an ancestor updated, we should mark the nearest host nodes for highlighting.
				if elementType == ElementTypeHostComponent then
					traceUpdatesForNodes:add(fiber.stateNode)

					traceNearestHostComponentUpdate = false
				end
			end

			-- We intentionally do not re-enable the traceNearestHostComponentUpdate flag in this branch,
			-- because we don't want to highlight every host node inside of a newly mounted subtree.
		end

		local isSuspense = fiber.tag == ReactTypeOfWork.SuspenseComponent

		if isSuspense then
			local isTimedOut = fiber.memoizedState ~= nil

			if isTimedOut then
				-- Special case: if Suspense mounts in a timed-out state,
				-- get the fallback child from the inner fragment and mount
				-- it as if it was our own child. Updates handle this too.
				local primaryChildFragment = fiber.child
				local fallbackChildFragment = (function()
					if primaryChildFragment then
						return primaryChildFragment.sibling
					end
					return nil
				end)()
				local fallbackChild = (function()
					if fallbackChildFragment then
						return fallbackChildFragment.child
					end
					return nil
				end)()

				if fallbackChild ~= nil then
					mountFiberRecursively(
						fallbackChild,
						(function()
							if shouldIncludeInTree then
								return fiber
							end

							return parentFiber :: Fiber
						end)(),
						true,
						traceNearestHostComponentUpdate
					)
				end
			else
				local primaryChild = nil
				local areSuspenseChildrenConditionallyWrapped = OffscreenComponent == -1

				if areSuspenseChildrenConditionallyWrapped then
					primaryChild = fiber.child
				elseif fiber.child ~= nil then
					primaryChild = (fiber.child :: Fiber).child
				end
				if primaryChild ~= nil then
					mountFiberRecursively(
						primaryChild,
						(function()
							if shouldIncludeInTree then
								return fiber
							end

							return parentFiber :: Fiber
						end)(),
						true,
						traceNearestHostComponentUpdate
					)
				end
			end
		else
			if fiber.child ~= nil then
				mountFiberRecursively(
					fiber.child,
					(function()
						if shouldIncludeInTree then
							return fiber
						end
						return parentFiber :: Fiber
					end)(),
					true,
					traceNearestHostComponentUpdate
				)
			end
		end

		-- We're exiting this Fiber now, and entering its siblings.
		-- If we have selection to restore, we might need to re-activate tracking.
		updateTrackedPathStateAfterMount(mightSiblingsBeOnTrackedPath)

		if traverseSiblings and fiber.sibling ~= nil then
			mountFiberRecursively(
				fiber.sibling,
				parentFiber :: Fiber,
				true,
				traceNearestHostComponentUpdate
			)
		end
	end

	-- We use this to simulate unmounting for Suspense trees
	-- when we switch from primary to fallback.
	unmountFiberChildrenRecursively = function(fiber: Fiber)
		-- ROBLOX deviation: use global
		if global.__DEBUG__ then
			debug_("unmountFiberChildrenRecursively()", fiber)
		end

		-- We might meet a nested Suspense on our way.
		local isTimedOutSuspense = fiber.tag == ReactTypeOfWork.SuspenseComponent
			and fiber.memoizedState ~= nil
		local child = fiber.child

		if isTimedOutSuspense then
			-- If it's showing fallback tree, let's traverse it instead.
			local primaryChildFragment = fiber.child
			local fallbackChildFragment = (function()
				if primaryChildFragment then
					return primaryChildFragment.sibling
				end
				return nil
			end)()

			-- Skip over to the real Fiber child.
			child = (function()
				if fallbackChildFragment then
					return fallbackChildFragment.child
				end
				return nil
			end)()
		end

		while child ~= nil do
			-- Record simulated unmounts children-first.
			-- We skip nodes without return because those are real unmounts.
			if (child :: Fiber).return_ ~= nil then
				unmountFiberChildrenRecursively(child :: Fiber)
				recordUnmount(child :: Fiber, true)
			end

			child = (child :: Fiber).sibling
		end
	end
	recordProfilingDurations = function(fiber: Fiber)
		local id = getFiberID(getPrimaryFiber(fiber))
		local actualDuration, treeBaseDuration =
			fiber.actualDuration, fiber.treeBaseDuration

		idToTreeBaseDurationMap[id] = treeBaseDuration or 0

		if isProfiling then
			local alternate = fiber.alternate

			-- It's important to update treeBaseDuration even if the current Fiber did not render,
			-- because it's possible that one of its descendants did.
			if
				alternate == nil
				or treeBaseDuration ~= (alternate :: Fiber).treeBaseDuration
			then
				local convertedTreeBaseDuration = math.floor(
					(treeBaseDuration or 0) * 1000
				)

				pushOperation(TREE_OPERATION_UPDATE_TREE_BASE_DURATION)
				pushOperation(id)
				pushOperation(convertedTreeBaseDuration)
			end
			if alternate == nil or didFiberRender((alternate :: Fiber), fiber) then
				if actualDuration ~= nil then
					-- The actual duration reported by React includes time spent working on children.
					-- This is useful information, but it's also useful to be able to exclude child durations.
					-- The frontend can't compute this, since the immediate children may have been filtered out.
					-- So we need to do this on the backend.
					-- Note that this calculated self duration is not the same thing as the base duration.
					-- The two are calculated differently (tree duration does not accumulate).
					local selfDuration = actualDuration :: number
					local child = fiber.child

					while child ~= nil do
						selfDuration = selfDuration
							- ((child :: Fiber).actualDuration or 0)
						child = (child :: Fiber).sibling
					end

					-- If profiling is active, store durations for elements that were rendered during the commit.
					-- Note that we should do this for any fiber we performed work on, regardless of its actualDuration value.
					-- In some cases actualDuration might be 0 for fibers we worked on (particularly if we're using Date.now)
					-- In other cases (e.g. Memo) actualDuration might be greater than 0 even if we "bailed out".
					local metadata = currentCommitProfilingMetadata :: CommitProfilingData
					table.insert(metadata.durations, id)
					table.insert(metadata.durations, actualDuration :: number)
					table.insert(metadata.durations, selfDuration)
					metadata.maxActualDuration = math.max(
						metadata.maxActualDuration,
						actualDuration :: number
					)

					if recordChangeDescriptions then
						local changeDescription = getChangeDescription(alternate, fiber)
						if changeDescription ~= nil then
							if metadata.changeDescriptions ~= nil then
								(
									metadata.changeDescriptions :: Map<number, ChangeDescription>
								)[id] =
									changeDescription :: ChangeDescription
							end
						end

						updateContextsForFiber(fiber)
					end
				end
			end
		end
	end
	local function recordResetChildren(fiber: Fiber, childSet: Fiber)
		-- The frontend only really cares about the displayName, key, and children.
		-- The first two don't really change, so we are only concerned with the order of children here.
		-- This is trickier than a simple comparison though, since certain types of fibers are filtered.
		local nextChildren: Array<number> = {}

		-- This is a naive implementation that shallowly recourses children.
		-- We might want to revisit this if it proves to be too inefficient.
		local child: Fiber? = childSet

		while child ~= nil do
			findReorderedChildrenRecursively(child :: Fiber, nextChildren)

			child = (child :: Fiber).sibling
		end

		local numChildren = #nextChildren

		if numChildren < 2 then
			-- No need to reorder.
			return
		end

		pushOperation(TREE_OPERATION_REORDER_CHILDREN)
		pushOperation(getFiberID(getPrimaryFiber(fiber)))
		pushOperation(numChildren)

		for i = 1, #nextChildren do
			pushOperation(nextChildren[i])
		end
	end

	findReorderedChildrenRecursively = function(fiber: Fiber, nextChildren: Array<number>)
		if not shouldFilterFiber(fiber) then
			table.insert(nextChildren, getFiberID(getPrimaryFiber(fiber)))
		else
			local child = fiber.child
			while child ~= nil do
				findReorderedChildrenRecursively(child, nextChildren)
				child = (child :: Fiber).sibling
			end
		end
	end

	-- Returns whether closest unfiltered fiber parent needs to reset its child list.
	local function updateFiberRecursively(
		nextFiber: Fiber,
		prevFiber: Fiber,
		parentFiber: Fiber | nil,
		traceNearestHostComponentUpdate: boolean
	): boolean
		-- ROBLOX deviation: use global
		if global.__DEBUG__ then
			debug_("updateFiberRecursively()", nextFiber, parentFiber)
		end
		if traceUpdatesEnabled then
			local elementType = getElementTypeForFiber(nextFiber)

			if traceNearestHostComponentUpdate then
				-- If an ancestor updated, we should mark the nearest host nodes for highlighting.
				if elementType == ElementTypeHostComponent then
					traceUpdatesForNodes:add(nextFiber.stateNode)

					traceNearestHostComponentUpdate = false
				end
			else
				if
					elementType == ElementTypeFunction
					or elementType == ElementTypeClass
					or elementType == ElementTypeContext
				then
					-- Otherwise if this is a traced ancestor, flag for the nearest host descendant(s).
					traceNearestHostComponentUpdate = didFiberRender(prevFiber, nextFiber)
				end
			end
		end
		if
			mostRecentlyInspectedElement ~= nil
			and (mostRecentlyInspectedElement :: InspectedElement).id == getFiberID(
				getPrimaryFiber(nextFiber)
			)
			and didFiberRender(prevFiber, nextFiber)
		then
			-- If this Fiber has updated, clear cached inspected data.
			-- If it is inspected again, it may need to be re-run to obtain updated hooks values.
			hasElementUpdatedSinceLastInspected = true
		end

		local shouldIncludeInTree = not shouldFilterFiber(nextFiber)
		local isSuspense = nextFiber.tag == SuspenseComponent
		local shouldResetChildren = false
		-- The behavior of timed-out Suspense trees is unique.
		-- Rather than unmount the timed out content (and possibly lose important state),
		-- React re-parents this content within a hidden Fragment while the fallback is showing.
		-- This behavior doesn't need to be observable in the DevTools though.
		-- It might even result in a bad user experience for e.g. node selection in the Elements panel.
		-- The easiest fix is to strip out the intermediate Fragment fibers,
		-- so the Elements panel and Profiler don't need to special case them.
		-- Suspense components only have a non-null memoizedState if they're timed-out.
		local prevDidTimeout = isSuspense and prevFiber.memoizedState ~= nil
		local nextDidTimeOut = isSuspense and nextFiber.memoizedState ~= nil

		-- The logic below is inspired by the code paths in updateSuspenseComponent()
		-- inside ReactFiberBeginWork in the React source code.
		if prevDidTimeout and nextDidTimeOut then
			-- Fallback -> Fallback:
			-- 1. Reconcile fallback set.
			local nextFiberChild = nextFiber.child
			local nextFallbackChildSet = (function()
				if nextFiberChild then
					return nextFiberChild.sibling
				end

				return nil
			end)()
			-- Note: We can't use nextFiber.child.sibling.alternate
			-- because the set is special and alternate may not exist.
			local prevFiberChild = prevFiber.child
			local prevFallbackChildSet = (function()
				if prevFiberChild then
					return prevFiberChild.sibling
				end

				return nil
			end)()

			if
				nextFallbackChildSet ~= nil
				and prevFallbackChildSet ~= nil
				and updateFiberRecursively(
					nextFallbackChildSet :: Fiber,
					prevFallbackChildSet :: Fiber,
					nextFiber :: Fiber,
					traceNearestHostComponentUpdate
				)
			then
				shouldResetChildren = true
			end
		elseif prevDidTimeout and not nextDidTimeOut then
			-- Fallback -> Primary:
			-- 1. Unmount fallback set
			-- Note: don't emulate fallback unmount because React actually did it.
			-- 2. Mount primary set
			local nextPrimaryChildSet = nextFiber.child

			if nextPrimaryChildSet ~= nil then
				mountFiberRecursively(
					nextPrimaryChildSet :: Fiber,
					nextFiber :: Fiber,
					true,
					traceNearestHostComponentUpdate
				)
			end

			shouldResetChildren = true
		elseif not prevDidTimeout and nextDidTimeOut then
			-- Primary -> Fallback:
			-- 1. Hide primary set
			-- This is not a real unmount, so it won't get reported by React.
			-- We need to manually walk the previous tree and record unmounts.
			unmountFiberChildrenRecursively(prevFiber)

			-- 2. Mount fallback set
			local nextFiberChild = nextFiber.child
			local nextFallbackChildSet = (function()
				if nextFiberChild then
					return nextFiberChild.sibling
				end

				return nil
			end)()

			if nextFallbackChildSet ~= nil then
				mountFiberRecursively(
					nextFallbackChildSet,
					nextFiber,
					true,
					traceNearestHostComponentUpdate
				)

				shouldResetChildren = true
			end
		else
			-- Common case: Primary -> Primary.
			-- This is the same code path as for non-Suspense fibers.
			if nextFiber.child ~= prevFiber.child then
				-- If the first child is different, we need to traverse them.
				-- Each next child will be either a new child (mount) or an alternate (update).
				local nextChild: Fiber? = nextFiber.child
				local prevChildAtSameIndex = prevFiber.child

				while nextChild do
					-- We already know children will be referentially different because
					-- they are either new mounts or alternates of previous children.
					-- Schedule updates and mounts depending on whether alternates exist.
					-- We don't track deletions here because they are reported separately.
					if (nextChild :: Fiber).alternate then
						local prevChild = (nextChild :: Fiber).alternate

						if
							updateFiberRecursively(
								nextChild :: Fiber,
								prevChild :: Fiber,
								(function()
									if shouldIncludeInTree then
										return nextFiber :: Fiber
									end
									return parentFiber :: Fiber
								end)(),
								traceNearestHostComponentUpdate
							)
						then
							-- If a nested tree child order changed but it can't handle its own
							-- child order invalidation (e.g. because it's filtered out like host nodes),
							-- propagate the need to reset child order upwards to this Fiber.
							shouldResetChildren = true
						end
						-- However we also keep track if the order of the children matches
						-- the previous order. They are always different referentially, but
						-- if the instances line up conceptually we'll want to know that.
						if prevChild ~= prevChildAtSameIndex then
							shouldResetChildren = true
						end
					else
						mountFiberRecursively(
							nextChild :: Fiber,
							(function()
								if shouldIncludeInTree then
									return nextFiber :: Fiber
								end
								return parentFiber :: Fiber
							end)(),
							false,
							traceNearestHostComponentUpdate
						)

						shouldResetChildren = true
					end

					-- Try the next child.
					nextChild = nextChild.sibling :: Fiber

					-- Advance the pointer in the previous list so that we can
					-- keep comparing if they line up.
					if not shouldResetChildren and prevChildAtSameIndex ~= nil then
						prevChildAtSameIndex = (prevChildAtSameIndex :: Fiber).sibling
					end
				end

				-- If we have no more children, but used to, they don't line up.
				if prevChildAtSameIndex ~= nil then
					shouldResetChildren = true
				end
			else
				if traceUpdatesEnabled then
					-- If we're tracing updates and we've bailed out before reaching a host node,
					-- we should fall back to recursively marking the nearest host descendants for highlight.
					if traceNearestHostComponentUpdate then
						local hostFibers = findAllCurrentHostFibers(
							getFiberID(getPrimaryFiber(nextFiber))
						)

						for _, hostFiber in ipairs(hostFibers) do
							traceUpdatesForNodes:add(hostFiber.stateNode)
						end
					end
				end
			end
		end
		if shouldIncludeInTree then
			-- ROBLOX deviation: hasOwnProperty doesn't exist
			local isProfilingSupported = nextFiber["treeBaseDuration"] ~= nil

			if isProfilingSupported then
				recordProfilingDurations(nextFiber)
			end
		end
		if shouldResetChildren then
			-- We need to crawl the subtree for closest non-filtered Fibers
			-- so that we can display them in a flat children set.
			if shouldIncludeInTree then
				-- Normally, search for children from the rendered child.
				local nextChildSet = nextFiber.child

				if nextDidTimeOut then
					-- Special case: timed-out Suspense renders the fallback set.
					local nextFiberChild = nextFiber.child

					nextChildSet = (function()
						if nextFiberChild then
							return nextFiberChild.sibling
						end

						return nil
					end)()
				end
				if nextChildSet ~= nil then
					recordResetChildren(nextFiber, nextChildSet :: Fiber)
				end

				-- We've handled the child order change for this Fiber.
				-- Since it's included, there's no need to invalidate parent child order.
				return false
			else
				-- Let the closest unfiltered parent Fiber reset its child order instead.
				return true
			end
		else
			return false
		end
	end
	local function cleanup()
		-- We don't patch any methods so there is no cleanup.
	end

	local function flushInitialOperations()
		local localPendingOperationsQueue = pendingOperationsQueue

		pendingOperationsQueue = nil

		if
			localPendingOperationsQueue ~= nil
			and #(localPendingOperationsQueue :: Array<Array<number>>) > 0
		then
			-- ROBLOX deviation: for loop instead of forEach
			for _, operations in
				ipairs(localPendingOperationsQueue :: Array<Array<number>>)
			do
				hook.emit("operations", operations)
			end
		else
			-- Before the traversals, remember to start tracking
			-- our path in case we have selection to restore.
			if trackedPath ~= nil then
				mightBeOnTrackedPath = true
			end

			-- If we have not been profiling, then we can just walk the tree and build up its current state as-is.
			-- ROBLOX deviation: for loop instead of forEach
			for root in pairs(hook.getFiberRoots(rendererID)) do
				currentRootID = getFiberID(getPrimaryFiber(root.current))

				setRootPseudoKey(currentRootID, root.current)

				-- Checking root.memoizedInteractions handles multi-renderer edge-case-
				-- where some v16 renderers support profiling and others don't.
				if isProfiling and root.memoizedInteractions ~= nil then
					-- If profiling is active, store commit time and duration, and the current interactions.
					-- The frontend may request this information after profiling has stopped.
					currentCommitProfilingMetadata = {
						-- ROBLOX deviation: use bare table instead of Map type
						changeDescriptions = recordChangeDescriptions and {} or nil,
						durations = {},
						commitTime = getCurrentTime() - profilingStartTime,
						-- ROBLOX TODO: Work out how to deviate this assignment, it's messy
						interactions = Array.map(
							Array.from(root.memoizedInteractions :: Array<any>),
							function(interaction)
								return Object.assign({}, interaction, {
									timestamp = interaction.timestamp
										- profilingStartTime,
								})
							end
						),
						maxActualDuration = 0,
						priorityLevel = nil,
					}
				end

				mountFiberRecursively(root.current, nil, false, false)
				flushPendingEvents(root)
				currentRootID = -1
			end
		end
	end

	local function handleCommitFiberUnmount(fiber)
		-- This is not recursive.
		-- We can't traverse fibers after unmounting so instead
		-- we rely on React telling us about each unmount.
		recordUnmount(fiber, false)
	end

	local formatPriorityLevel = function(priorityLevel: number?)
		if priorityLevel == nil then
			return "Unknown"
		end
		if priorityLevel == ImmediatePriority then
			return "Immediate"
		elseif priorityLevel == UserBlockingPriority then
			return "User-Blocking"
		elseif priorityLevel == NormalPriority then
			return "Normal"
		elseif priorityLevel == LowPriority then
			return "Low"
		elseif priorityLevel == IdlePriority then
			return "Idle"
			-- ROBLOX deviation: no need to check for NoPriority
		else
			return "Unknown"
		end
	end

	local function handleCommitFiberRoot(root: Object, priorityLevel: number?)
		local current = root.current
		local alternate = current.alternate

		currentRootID = getFiberID(getPrimaryFiber(current))

		-- Before the traversals, remember to start tracking
		-- our path in case we have selection to restore.
		if trackedPath ~= nil then
			mightBeOnTrackedPath = true
		end
		if traceUpdatesEnabled then
			traceUpdatesForNodes:clear()
		end

		-- Checking root.memoizedInteractions handles multi-renderer edge-case-
		-- where some v16 renderers support profiling and others don't.
		local isProfilingSupported = root.memoizedInteractions ~= nil

		if isProfiling and isProfilingSupported then
			-- If profiling is active, store commit time and duration, and the current interactions.
			-- The frontend may request this information after profiling has stopped.
			currentCommitProfilingMetadata = {
				-- ROBLOX deviation: use bare table instead of Map type
				changeDescriptions = recordChangeDescriptions and {} or nil,
				durations = {},
				commitTime = getCurrentTime() - profilingStartTime,
				interactions = Array.map(
					Array.from(root.memoizedInteractions),
					function(interaction)
						return Object.assign({}, interaction, {
							timestamp = interaction.timestamp - profilingStartTime,
						})
					end
				),
				maxActualDuration = 0,
				priorityLevel = (function(): string?
					if priorityLevel == nil then
						return nil
					end
					return formatPriorityLevel(priorityLevel)
				end)(),
			}
		end
		if alternate then
			-- TODO: relying on this seems a bit fishy.
			local wasMounted = (alternate :: Fiber).memoizedState ~= nil
				and (alternate :: Fiber).memoizedState.element ~= nil
			local isMounted = current.memoizedState ~= nil
				and current.memoizedState.element ~= nil

			if not wasMounted and isMounted then
				-- Mount a new root.
				setRootPseudoKey(currentRootID, current)
				mountFiberRecursively(current :: Fiber, nil, false, false)
			elseif wasMounted and isMounted then
				-- Update an existing root.
				updateFiberRecursively(current, alternate, nil, false)
			elseif wasMounted and not isMounted then
				-- Unmount an existing root.
				removeRootPseudoKey(currentRootID)
				recordUnmount(current, false)
			end
		else
			-- Mount a new root.
			setRootPseudoKey(currentRootID, current)
			mountFiberRecursively(current :: Fiber, nil, false, false)
		end
		if isProfiling and isProfilingSupported then
			local commitProfilingMetadata = (
				rootToCommitProfilingMetadataMap :: Map<any, any>
			)[currentRootID]

			if commitProfilingMetadata ~= nil then
				table.insert(commitProfilingMetadata, currentCommitProfilingMetadata)
			else
				(rootToCommitProfilingMetadataMap :: Map<any, any>)[currentRootID] = {
					currentCommitProfilingMetadata,
				}
			end
		end

		-- We're done here.
		flushPendingEvents(root)

		if traceUpdatesEnabled then
			hook.emit("traceUpdates", traceUpdatesForNodes)
		end

		currentRootID = -1
	end
	findAllCurrentHostFibers = function(id: number): Array<Fiber>
		local fibers = {}
		local fiber: Fiber? = findCurrentFiberUsingSlowPathById(id)

		if not fiber then
			return fibers
		end

		-- Next we'll drill down this component to find all HostComponent/Text.
		local node = fiber :: Fiber

		while true do
			if node.tag == HostComponent or node.tag == HostText then
				table.insert(fibers, node)
			elseif node.child then
				-- ROBLOX TODO: What do we use instead of "return"?
				(node.child :: Fiber).return_ = node
				node = node.child :: Fiber
			end
			if node == fiber then
				return fibers
			end

			while not node.sibling do
				if not node.return_ or node.return_ == fiber then
					return fibers
				end

				node = node.return_ :: Fiber
			end

			(node.sibling :: Fiber).return_ = node.return_ :: Fiber
			node = node.sibling :: Fiber
		end

		-- Flow needs the return here, but ESLint complains about it.
		-- eslint-disable-next-line no-unreachable
		return fibers
	end
	local function findNativeNodesForFiberID(id: number)
		-- ROBLOX try
		local ok, result = pcall(function()
			local fiber: Fiber? = findCurrentFiberUsingSlowPathById(id)
			if fiber == nil then
				return nil
			end
			-- Special case for a timed-out Suspense.
			local isTimedOutSuspense = (fiber :: Fiber).tag == SuspenseComponent
				and (fiber :: Fiber).memoizedState ~= nil
			if isTimedOutSuspense then
				-- A timed-out Suspense's findDOMNode is useless.
				-- Try our best to find the fallback directly.
				local maybeFallbackFiber = (fiber :: Fiber).child
					and ((fiber :: Fiber).child :: Fiber).sibling
				if maybeFallbackFiber ~= nil then
					fiber = maybeFallbackFiber :: Fiber
				end
			end
			local hostFibers = findAllCurrentHostFibers(id)
			-- ROBLOX deviation: filter for Boolean doesn't make sense
			return Array.map(hostFibers :: Array<Fiber>, function(hostFiber: Fiber)
				return hostFiber.stateNode
			end)
		end)
		-- ROBLOX catch
		if not ok then
			-- The fiber might have unmounted by now.
			return nil
		end
		return result
	end

	local function getDisplayNameForFiberID(id)
		local fiber: Fiber? = idToFiberMap[id]
		return (function(): string?
			if fiber ~= nil then
				return getDisplayNameForFiber(fiber :: Fiber)
			end
			return nil
		end)()
	end

	local function getFiberIDForNative(
		hostInstance,
		findNearestUnfilteredAncestor: boolean?
	): number?
		findNearestUnfilteredAncestor = findNearestUnfilteredAncestor or false
		local fiber = renderer.findFiberByHostInstance(hostInstance)

		if fiber ~= nil then
			if findNearestUnfilteredAncestor then
				while fiber ~= nil and shouldFilterFiber(fiber :: Fiber) do
					fiber = (fiber :: Fiber).return_
				end
			end
			return getFiberID(getPrimaryFiber(fiber :: Fiber))
		end

		return nil
	end

	-- ROBLOX deviation: The copied code is indeed copied, but from ReactFiberTreeReflection.lua

	-- This function is copied from React and should be kept in sync:
	-- https://github.com/facebook/react/blob/master/packages/react-reconciler/src/ReactFiberTreeReflection.js
	-- It would be nice if we updated React to inject this function directly (vs just indirectly via findDOMNode).
	-- BEGIN copied code

	-- ROBLOX NOTE: Copied these supporting functions from ReactFiberTreeReflection
	local function assertIsMounted(fiber)
		invariant(
			getNearestMountedFiber(fiber) == fiber,
			"Unable to find node on an unmounted component."
		)
	end

	findCurrentFiberUsingSlowPathById = function(id: number): Fiber | nil
		local fiber: Fiber? = idToFiberMap[id]

		if fiber == nil then
			console.warn(('Could not find Fiber with id "%s"'):format(tostring(id)))
			return nil
		end

		-- ROBLOX NOTE: Copied from ReactFiberTreeReflection.lua
		local alternate = (fiber :: Fiber).alternate
		if not alternate then
			-- If there is no alternate, then we only need to check if it is mounted.
			local nearestMounted = getNearestMountedFiber((fiber :: Fiber))
			invariant(
				nearestMounted ~= nil,
				"Unable to find node on an unmounted component."
			)
			if nearestMounted ~= (fiber :: Fiber) then
				return nil
			end
			return (fiber :: Fiber)
		end
		-- If we have two possible branches, we'll walk backwards up to the root
		-- to see what path the root points to. On the way we may hit one of the
		-- special cases and we'll deal with them.
		local a = fiber :: Fiber
		local b = alternate :: Fiber
		while true do
			local parentA = a.return_
			if parentA == nil then
				-- We're at the root.
				break
			end
			local parentB = (parentA :: Fiber).alternate
			if parentB == nil then
				-- There is no alternate. This is an unusual case. Currently, it only
				-- happens when a Suspense component is hidden. An extra fragment fiber
				-- is inserted in between the Suspense fiber and its children. Skip
				-- over this extra fragment fiber and proceed to the next parent.
				local nextParent = (parentA :: Fiber).return_
				if nextParent ~= nil then
					a = nextParent :: Fiber
					b = nextParent :: Fiber
					continue
				end
				-- If there's no parent, we're at the root.
				break
			end

			-- If both copies of the parent fiber point to the same child, we can
			-- assume that the child is current. This happens when we bailout on low
			-- priority: the bailed out fiber's child reuses the current child.
			if (parentA :: Fiber).child == (parentB :: Fiber).child then
				local child = (parentA :: Fiber).child
				while child do
					if child == a then
						-- We've determined that A is the current branch.
						assertIsMounted(parentA)
						return fiber
					end
					if child == b then
						-- We've determined that B is the current branch.
						assertIsMounted(parentA)
						return alternate
					end
					child = child.sibling :: Fiber
				end
				-- We should never have an alternate for any mounting node. So the only
				-- way this could possibly happen is if this was unmounted, if at all.
				invariant(false, "Unable to find node on an unmounted component.")
			end

			if a.return_ ~= b.return_ then
				-- The return pointer of A and the return pointer of B point to different
				-- fibers. We assume that return pointers never criss-cross, so A must
				-- belong to the child set of A.return_, and B must belong to the child
				-- set of B.return_.
				a = parentA :: Fiber
				b = parentB :: Fiber
			else
				-- The return pointers point to the same fiber. We'll have to use the
				-- default, slow path: scan the child sets of each parent alternate to see
				-- which child belongs to which set.
				--
				-- Search parent A's child set
				local didFindChild = false
				local child = (parentA :: Fiber).child
				while child do
					if child == a then
						didFindChild = true
						a = parentA :: Fiber
						b = parentB :: Fiber
						break
					end
					if child == b then
						didFindChild = true
						b = parentA :: Fiber
						a = parentB :: Fiber
						break
					end
					child = child.sibling :: Fiber
				end
				if not didFindChild then
					-- Search parent B's child set
					child = (parentB :: Fiber).child
					while child do
						if child == a then
							didFindChild = true
							a = parentB :: Fiber
							b = parentA :: Fiber
							break
						end
						if child == b then
							didFindChild = true
							b = parentB :: Fiber
							a = parentA :: Fiber
							break
						end
						child = child.sibling :: Fiber
					end
					invariant(
						didFindChild,
						"Child was not found in either parent set. This indicates a bug "
							.. "in React related to the return pointer. Please file an issue."
					)
				end
			end

			invariant(
				a.alternate == b,
				"Return fibers should always be each others' alternates. "
					.. "This error is likely caused by a bug in React. Please file an issue."
			)
		end
		-- If the root is not a host container, we're in a disconnected tree. I.e.
		-- unmounted.
		invariant(a.tag == HostRoot, "Unable to find node on an unmounted component.")
		if a.stateNode.current == a then
			-- We've determined that A is the current branch.
			return fiber
		end
		-- Otherwise B has to be current branch.
		return alternate
	end
	-- END copied code

	local function prepareViewAttributeSource(
		id: number,
		path: Array<string | number>
	): ()
		local isCurrent = isMostRecentlyInspectedElementCurrent(id)

		if isCurrent then
			window["$attribute"] = getInObject(mostRecentlyInspectedElement :: any, path)
		end
	end
	local function prepareViewElementSource(id: number): ()
		local fiber: Fiber? = idToFiberMap[id]

		if fiber == nil then
			console.warn(('Could not find Fiber with id "%s"'):format(tostring(id)))
			return
		end

		local elementType, tag, type_ =
			(fiber :: Fiber).elementType, (fiber :: Fiber).tag, (fiber :: Fiber).type

		if
			tag == ClassComponent
			or tag == FunctionComponent
			or tag == IncompleteClassComponent
			or tag == IndeterminateComponent
		then
			global["$type"] = type_
		elseif tag == ForwardRef then
			global["$type"] = type_.render
		elseif tag == MemoComponent or tag == SimpleMemoComponent then
			global["$type"] = elementType ~= nil
					and elementType.type ~= nil
					and elementType.type
				or type_
		else
			global["$type"] = nil
		end
	end

	local function getOwnersList(id: number): Array<Owner> | nil
		local fiber: Fiber? = findCurrentFiberUsingSlowPathById(id)

		if fiber == nil then
			return nil
		end

		local _debugOwner = (fiber :: Fiber)._debugOwner
		local owners = {
			{
				displayName = getDisplayNameForFiber((fiber :: Fiber)) or "Anonymous",
				id = id,
				type = getElementTypeForFiber((fiber :: Fiber)),
			},
		}

		if _debugOwner then
			local owner: Fiber? = _debugOwner

			while owner ~= nil do
				Array.unshift(owners, {
					displayName = getDisplayNameForFiber(owner :: Fiber) or "Anonymous",
					id = getFiberID(getPrimaryFiber(owner :: Fiber)),
					type = getElementTypeForFiber(owner :: Fiber),
				})

				owner = (owner :: Fiber)._debugOwner or nil
			end
		end

		return owners
	end

	-- Fast path props lookup for React Native style editor.
	-- Could use inspectElementRaw() but that would require shallow rendering hooks components,
	-- and could also mess with memoization.
	local function getInstanceAndStyle(id: number): InstanceAndStyle
		local instance = nil
		local style = nil
		local fiber: Fiber? = findCurrentFiberUsingSlowPathById(id)

		if fiber ~= nil then
			instance = (fiber :: Fiber).stateNode

			if (fiber :: Fiber).memoizedProps ~= nil then
				style = (fiber :: Fiber).memoizedProps.style
			end
		end

		return {
			instance = instance,
			style = style,
		}
	end

	local function inspectElementRaw(id: number): InspectedElement | nil
		local fiber: Fiber? = findCurrentFiberUsingSlowPathById(id)

		if fiber == nil then
			return nil
		end

		local _debugOwner, _debugSource, stateNode, key, memoizedProps, memoizedState, dependencies, tag, type_ =
			(fiber :: Fiber)._debugOwner,
			(fiber :: Fiber)._debugSource,
			(fiber :: Fiber).stateNode,
			(fiber :: Fiber).key,
			(fiber :: Fiber).memoizedProps,
			(fiber :: Fiber).memoizedState,
			(fiber :: Fiber).dependencies,
			(fiber :: Fiber).tag,
			(fiber :: Fiber).type

		local elementType = getElementTypeForFiber(fiber :: Fiber)

		local usesHooks = (
				tag == FunctionComponent
				or tag == SimpleMemoComponent
				or tag == ForwardRef
			) and (not not memoizedState or not not dependencies)

		local typeSymbol = getTypeSymbol(type_)
		local canViewSource = false
		local context = nil

		if
			tag == ClassComponent
			or tag == FunctionComponent
			or tag == IncompleteClassComponent
			or tag == IndeterminateComponent
			or tag == MemoComponent
			or tag == ForwardRef
			or tag == SimpleMemoComponent
		then
			canViewSource = true

			if stateNode and stateNode.context ~= nil then
				-- Don't show an empty context object for class components that don't use the context API.
				local shouldHideContext = elementType == ElementTypeClass
					and not (type_.contextTypes or type_.contextType)

				if not shouldHideContext then
					context = stateNode.context
				end
			end
		elseif typeSymbol == CONTEXT_NUMBER or typeSymbol == CONTEXT_SYMBOL_STRING then
			-- 16.3-16.5 read from "type" because the Consumer is the actual context object.
			-- 16.6+ should read from "type._context" because Consumer can be different (in DEV).
			-- NOTE Keep in sync with getDisplayNameForFiber()
			local consumerResolvedContext = type_._context or type_

			-- Global context value.
			context = consumerResolvedContext._currentValue or nil

			-- Look for overridden value.
			local current = (fiber :: Fiber).return_

			while current ~= nil do
				local currentType = (current :: Fiber).type
				local currentTypeSymbol = getTypeSymbol(currentType)

				if
					currentTypeSymbol == PROVIDER_NUMBER
					or currentTypeSymbol == PROVIDER_SYMBOL_STRING
				then
					-- 16.3.0 exposed the context object as "context"
					-- PR #12501 changed it to "_context" for 16.3.1+
					-- NOTE Keep in sync with getDisplayNameForFiber()
					local providerResolvedContext = currentType._context
						or currentType.context

					if providerResolvedContext == consumerResolvedContext then
						context = (current :: Fiber).memoizedProps.value

						break
					end
				end

				current = (current :: Fiber).return_
			end
		end

		local hasLegacyContext = false

		if context ~= nil then
			hasLegacyContext = not not type_.contextTypes
			-- To simplify hydration and display logic for context, wrap in a value object.
			-- Otherwise simple values (e.g. strings, booleans) become harder to handle.
			context = { value = context }
		end

		local owners = nil

		if _debugOwner then
			owners = {}
			local owner: Fiber? = _debugOwner
			while owner ~= nil do
				table.insert(owners, {
					displayName = getDisplayNameForFiber(owner :: Fiber) or "Anonymous",
					id = getFiberID(getPrimaryFiber(owner :: Fiber)),
					type = getElementTypeForFiber(owner :: Fiber),
				})
				owner = (owner :: Fiber)._debugOwner or nil
			end
		end

		local isTimedOutSuspense = tag == SuspenseComponent and memoizedState ~= nil
		local hooks = nil

		if usesHooks then
			local originalConsoleMethods = {}

			-- Temporarily disable all console logging before re-running the hook.
			-- ROBLOX TODO: Is iterating over console methods be sensible here?
			for method, _ in pairs(console) do
				pcall(function()
					originalConsoleMethods[method] = console[method]
					console[method] = function() end
				end)
			end

			pcall(function()
				hooks = inspectHooksOfFiber(fiber :: Fiber, renderer.currentDispatcherRef)
			end)

			-- Restore originl console functionality.
			for method, _ in pairs(console) do
				pcall(function()
					console[method] = originalConsoleMethods[method]
				end)
			end
		end

		local rootType = nil
		local current = fiber :: Fiber

		while current.return_ ~= nil do
			current = current.return_ :: Fiber
		end
		local fiberRoot = current.stateNode
		if fiberRoot ~= nil and fiberRoot._debugRootType ~= nil then
			rootType = fiberRoot._debugRootType
		end

		return {
			id = id,
			-- Does the current renderer support editable hooks and function props?
			canEditHooks = typeof(overrideHookState) == "function",
			canEditFunctionProps = typeof(overrideProps) == "function",
			-- Does the current renderer support advanced editing interface?
			canEditHooksAndDeletePaths = typeof(overrideHookStateDeletePath)
				== "function",
			canEditHooksAndRenamePaths = typeof(overrideHookStateRenamePath)
				== "function",
			canEditFunctionPropsDeletePaths = typeof(overridePropsDeletePath)
				== "function",
			canEditFunctionPropsRenamePaths = typeof(overridePropsRenamePath)
				== "function",
			canToggleSuspense = supportsTogglingSuspense
				-- If it's showing the real content, we can always flip fallback.
				and (
					not isTimedOutSuspense
					-- If it's showing fallback because we previously forced it to,
					-- allow toggling it back to remove the fallback override.
					or forceFallbackForSuspenseIDs[id]
				),

			-- Can view component source location.
			canViewSource = canViewSource,

			-- Does the component have legacy contexted to it.
			hasLegacyContext = hasLegacyContext,
			key = (function()
				if key ~= nil then
					return key
				end

				return nil
			end)(),
			displayName = getDisplayNameForFiber(fiber :: Fiber),
			type_ = elementType,

			-- Inspectable properties.
			-- TODO Review sanitization approach for the below inspectable values.
			context = context,
			hooks = hooks,
			props = memoizedProps,
			state = (function()
				if usesHooks then
					return nil
				end

				return memoizedState
			end)(),

			-- List of owners
			owners = owners,

			-- Location of component in source code.
			source = _debugSource or nil,

			rootType = rootType,
			rendererPackageName = renderer.rendererPackageName,
			rendererVersion = renderer.version,
		} :: InspectedElement
	end

	isMostRecentlyInspectedElementCurrent = function(id: number): boolean
		return mostRecentlyInspectedElement ~= nil
			and (mostRecentlyInspectedElement :: InspectedElement).id == id
			and not hasElementUpdatedSinceLastInspected
	end

	-- Track the intersection of currently inspected paths,
	-- so that we can send their data along if the element is re-rendered.
	local function mergeInspectedPaths(path: Array<string | number>)
		local current = currentlyInspectedPaths

		-- ROBLOX deviation: for loop instead of forEach
		for _, key in ipairs(path) do
			if not current[key] then
				current[key] = {}
			end
			current = current[key]
		end
	end

	local function createIsPathAllowed(
		key: string | nil,
		secondaryCategory: string | nil -- ROBLOX TODO: Luau can't express literal type: 'hooks'
	)
		-- This function helps prevent previously-inspected paths from being dehydrated in updates.
		-- This is important to avoid a bad user experience where expanded toggles collapse on update.
		return function(path: Array<string | number>): boolean
			if secondaryCategory == "hooks" then
				if #path == 1 then
					-- Never dehydrate the "hooks" object at the top levels.
					return true
				end
				if path[#path] == "subHooks" or path[#path - 1] == "subHooks" then
					-- Dehydrating the 'subHooks' property makes the HooksTree UI a lot more complicated,
					-- so it's easiest for now if we just don't break on this boundary.
					-- We can always dehydrate a level deeper (in the value object).
					return true
				end
			end

			local current = (function()
				if key == nil then
					return currentlyInspectedPaths
				end
				return currentlyInspectedPaths[key :: string]
			end)()

			if not current then
				return false
			end

			for i = 1, #path do
				current = current[path[i]]
				if not current then
					return false
				end
			end
			return true
		end
	end

	local function updateSelectedElement(inspectedElement: InspectedElement): ()
		local hooks, id, props =
			inspectedElement.hooks, inspectedElement.id, inspectedElement.props
		local fiber: Fiber? = idToFiberMap[id]

		if fiber == nil then
			console.warn(('Could not find Fiber with id "%s"'):format(tostring(id)))

			return
		end

		local elementType, stateNode, tag, type_ =
			(fiber :: Fiber).elementType,
			(fiber :: Fiber).stateNode,
			(fiber :: Fiber).tag,
			(fiber :: Fiber).type

		if
			tag == ClassComponent
			or tag == IncompleteClassComponent
			or tag == IndeterminateComponent
		then
			global["$r"] = stateNode
		elseif tag == FunctionComponent then
			global["$r"] = {
				hooks = hooks,
				props = props,
				type = type_,
			}
		elseif tag == ForwardRef then
			global["$r"] = {
				props = props,
				type = type_.render,
			}
		elseif tag == MemoComponent or tag == SimpleMemoComponent then
			global["$r"] = {
				props = props,
				type = elementType ~= nil
						and elementType.type ~= nil
						and elementType.type
					or type_,
			}
		else
			global["$r"] = nil
		end
	end

	local function storeAsGlobal(
		id: number,
		path: Array<string | number>,
		count: number
	): ()
		local isCurrent = isMostRecentlyInspectedElementCurrent(id)

		if isCurrent then
			local value = getInObject(mostRecentlyInspectedElement :: any, path)
			local key = ("$reactTemp%s"):format(tostring(count))

			window[key] = value

			console.log(key)
			console.log(value)
		end
	end

	local function copyElementPath(id: number, path: Array<string | number>): ()
		local isCurrent = isMostRecentlyInspectedElementCurrent(id)

		if isCurrent then
			copyToClipboard(getInObject(mostRecentlyInspectedElement :: any, path))
		end
	end

	local function inspectElement(
		id: number,
		path: Array<string | number>?
	): InspectedElementPayload
		local isCurrent = isMostRecentlyInspectedElementCurrent(id)

		if isCurrent then
			if path ~= nil then
				mergeInspectedPaths(path :: Array<string>)

				local secondaryCategory = nil

				if (path :: Array<string>)[1] == "hooks" then
					secondaryCategory = "hooks"
				end

				-- If this element has not been updated since it was last inspected,
				-- we can just return the subset of data in the newly-inspected path.
				return {
					id = id,
					type = "hydrated-path",
					path = path,
					value = cleanForBridge(
						getInObject(mostRecentlyInspectedElement :: any, path),
						createIsPathAllowed(nil, secondaryCategory),
						path
					),
				}
			else
				-- If this element has not been updated since it was last inspected, we don't need to re-run it.
				-- Instead we can just return the ID to indicate that it has not changed.
				return {
					id = id,
					type = "no-change",
				}
			end
		else
			hasElementUpdatedSinceLastInspected = false

			if
				mostRecentlyInspectedElement == nil
				or (mostRecentlyInspectedElement :: InspectedElement).id ~= id
			then
				currentlyInspectedPaths = {}
			end

			mostRecentlyInspectedElement = inspectElementRaw(id)

			if mostRecentlyInspectedElement == nil then
				return {
					id = id,
					type = "not-found",
				}
			end
			if path ~= nil then
				mergeInspectedPaths(path :: Array<string>)
			end

			-- Any time an inspected element has an update,
			-- we should update the selected $r value as wel.
			-- Do this before dehydration (cleanForBridge).
			updateSelectedElement(mostRecentlyInspectedElement :: InspectedElement)

			-- Clone before cleaning so that we preserve the full data.
			-- This will enable us to send patches without re-inspecting if hydrated paths are requested.
			-- (Reducing how often we shallow-render is a better DX for function components that use hooks.)
			local cleanedInspectedElement = Object.assign(
				{},
				mostRecentlyInspectedElement
			)

			cleanedInspectedElement.context = cleanForBridge(
				cleanedInspectedElement.context,
				createIsPathAllowed("context", nil)
			)
			cleanedInspectedElement.hooks = cleanForBridge(
				cleanedInspectedElement.hooks,
				createIsPathAllowed("hooks", "hooks")
			)
			cleanedInspectedElement.props = cleanForBridge(
				cleanedInspectedElement.props,
				createIsPathAllowed("props", nil)
			)
			cleanedInspectedElement.state = cleanForBridge(
				cleanedInspectedElement.state,
				createIsPathAllowed("state", nil)
			)

			return {
				id = id,
				type = "full-data",
				value = cleanedInspectedElement,
			}
		end
	end

	local function logElementToConsole(id: number)
		local result: InspectedElement? = (function()
			if isMostRecentlyInspectedElementCurrent(id) then
				return mostRecentlyInspectedElement
			end

			return inspectElementRaw(id)
		end)()

		if result == nil then
			console.warn(('Could not find Fiber with id "%s"'):format(tostring(id)))
			return
		end

		-- ROBLOX TODO: Do we want to support this? Seems out of scope
		-- local supportsGroup = typeof(console.groupCollapsed) == 'function'

		-- if supportsGroup then
		--     console.groupCollapsed(('[Click to expand] %c<%s />'):format(result.displayName or 'Component'), 'color: var(--dom-tag-name-color); font-weight: normal;')
		-- end
		if (result :: InspectedElement).props ~= nil then
			console.log("Props:", (result :: InspectedElement).props)
		end
		if (result :: InspectedElement).state ~= nil then
			console.log("State:", (result :: InspectedElement).state)
		end
		if (result :: InspectedElement).hooks ~= nil then
			console.log("Hooks:", (result :: InspectedElement).hooks)
		end

		local nativeNodes = findNativeNodesForFiberID(id)

		if nativeNodes ~= nil then
			console.log("Nodes:", nativeNodes)
		end
		if (result :: InspectedElement).source ~= nil then
			console.log("Location:", (result :: InspectedElement).source)
		end

		-- ROBLOX deviation: not needed
		-- if (window.chrome || /firefox/i.test(navigator.userAgent)) {
		-- 	console.log(
		-- 	  'Right-click any value to save it as a global variable for further inspection.',
		-- 	);
		--   }

		-- if supportsGroup then
		-- 	console.groupEnd()
		-- end
	end

	local function deletePath(
		type_: string, -- ROBLOX TODO: Luau can't express literal types: 'context' | 'hooks' | 'props' | 'state',
		id: number,
		hookID: number?,
		path: Array<string | number>
	): ()
		local fiber: Fiber? = findCurrentFiberUsingSlowPathById(id)

		if fiber ~= nil then
			local instance = (fiber :: Fiber).stateNode

			if type_ == "context" then
				-- To simplify hydration and display of primitive context values (e.g. number, string)
				-- the inspectElement() method wraps context in a {value: ...} object.
				-- We need to remove the first part of the path (the "value") before continuing.
				path = Array.slice(path, 1)

				if (fiber :: Fiber).tag == ClassComponent then
					if #path == 0 then
						-- Simple context value (noop)
					else
						deletePathInObject(instance.context, path)
					end
					instance:forceUpdate()
				elseif (fiber :: Fiber).tag == FunctionComponent then
					-- Function components using legacy context are not editable
					-- because there's no instance on which to create a cloned, mutated context.
				end
			elseif type_ == "hooks" then
				if type(overrideHookStateDeletePath) == "function" then
					overrideHookStateDeletePath((fiber :: Fiber), hookID, path)
				end
			elseif type_ == "props" then
				if instance == nil then
					if type(overridePropsDeletePath) == "function" then
						overridePropsDeletePath((fiber :: Fiber), path)
					end
				else
					(fiber :: Fiber).pendingProps = copyWithDelete(instance.props, path)
					instance:forceUpdate()
				end
			elseif type_ == "state" then
				deletePathInObject(instance.state, path)
				instance:forceUpdate()
			end
		end
	end

	local function renamePath(
		type_: string, -- ROBLOX deviation: Luau can't express: 'context' | 'hooks' | 'props' | 'state',
		id: number,
		hookID: number?,
		oldPath: Array<string | number>,
		newPath: Array<string | number>
	): ()
		local fiber: Fiber? = findCurrentFiberUsingSlowPathById(id)

		if fiber ~= nil then
			local instance = (fiber :: Fiber).stateNode

			if type_ == "context" then
				-- To simplify hydration and display of primitive context values (e.g. number, string)
				-- the inspectElement() method wraps context in a {value: ...} object.
				-- We need to remove the first part of the path (the "value") before continuing.
				oldPath = Array.slice(oldPath, 1)
				newPath = Array.slice(newPath, 1)

				if (fiber :: Fiber).tag == ClassComponent then
					if #oldPath == 0 then
						-- Simple context value (noop)
					else
						renamePathInObject(instance.context, oldPath, newPath)
					end
					instance:forceUpdate()
				elseif (fiber :: Fiber).tag == FunctionComponent then
					-- Function components using legacy context are not editable
					-- because there's no instance on which to create a cloned, mutated context.
				end
			elseif type_ == "hooks" then
				if type(overrideHookStateRenamePath) == "function" then
					overrideHookStateRenamePath(fiber, hookID, oldPath, newPath)
				end
			elseif type_ == "props" then
				if instance == nil then
					if type(overridePropsRenamePath) == "function" then
						overridePropsRenamePath(fiber, oldPath, newPath)
					end
				else
					(fiber :: Fiber).pendingProps = copyWithRename(
						instance.props,
						oldPath,
						newPath
					)
					instance:forceUpdate()
				end
			elseif type_ == "state" then
				renamePathInObject(instance.state, oldPath, newPath)
				instance:forceUpdate()
			end
		end
	end

	local function overrideValueAtPath(
		type_: string, -- ROBLOX deviation: Luau can't express: 'context' | 'hooks' | 'props' | 'state',
		id: number,
		hookID: number?,
		path: Array<string | number>,
		value: any
	): ()
		local fiber: Fiber? = findCurrentFiberUsingSlowPathById(id)

		if fiber ~= nil then
			local instance = (fiber :: Fiber).stateNode

			if type_ == "context" then
				-- To simplify hydration and display of primitive context values (e.g. number, string)
				-- the inspectElement() method wraps context in a {value: ...} object.
				-- We need to remove the first part of the path (the "value") before continuing.
				path = Array.slice(path, 1)

				if (fiber :: Fiber).tag == ClassComponent then
					if #path == 0 then
						-- Simple context value
						instance.context = value
					else
						setInObject(instance.context, path, value)
					end
					instance:forceUpdate()
				elseif (fiber :: Fiber).tag == FunctionComponent then
					-- Function components using legacy context are not editable
					-- because there's no instance on which to create a cloned, mutated context.
				end
			elseif type_ == "hooks" then
				if type(overrideHookState) == "function" then
					overrideHookState((fiber :: Fiber), hookID, path, value)
				end
			elseif type_ == "props" then
				if instance == nil then
					if type(overrideProps) == "function" then
						overrideProps((fiber :: Fiber), path, value)
					end
				else
					(fiber :: Fiber).pendingProps = copyWithSet(
						instance.props,
						path,
						value
					)
					instance:forceUpdate()
				end
			elseif type_ == "state" then
				setInObject(instance.state, path, value)
				instance:forceUpdate()
			end
		end
	end

	type CommitProfilingData = {
		changeDescriptions: Map<number, ChangeDescription> | nil,
		commitTime: number,
		durations: Array<number>,
		interactions: Array<Interaction>,
		maxActualDuration: number,
		priorityLevel: string | nil,
	}

	type CommitProfilingMetadataMap = Map<number, Array<CommitProfilingData>>
	type DisplayNamesByRootID = Map<number, string>

	local function getProfilingData(): ProfilingDataBackend
		local dataForRoots: Array<ProfilingDataForRootBackend> = {}

		if rootToCommitProfilingMetadataMap == nil then
			error("getProfilingData() called before any profiling data was recorded")
		end

		for rootID, commitProfilingMetadata in
			pairs(rootToCommitProfilingMetadataMap :: CommitProfilingMetadataMap)
		do
			local commitData = {}
			local initialTreeBaseDurations = {}
			local allInteractions = {}
			local interactionCommits = {}
			local displayName = displayNamesByRootID ~= nil
					and (displayNamesByRootID :: DisplayNamesByRootID)[rootID]
				or "Unknown"

			if initialTreeBaseDurationsMap ~= nil then
				for id, treeBaseDuration in
					pairs(initialTreeBaseDurationsMap :: Map<number, number>)
				do
					if
						initialIDToRootMap ~= nil
						and (initialIDToRootMap :: Map<number, number>)[id] == rootID
					then
						-- We don't need to convert milliseconds to microseconds in this case,
						-- because the profiling summary is JSON serialized.
						table.insert(initialTreeBaseDurations, { id, treeBaseDuration })
					end
				end
			end

			for commitIndex, commitProfilingData in ipairs(commitProfilingMetadata) do
				local changeDescriptions, durations, interactions, maxActualDuration, priorityLevel, commitTime =
					commitProfilingData.changeDescriptions,
					commitProfilingData.durations,
					commitProfilingData.interactions,
					commitProfilingData.maxActualDuration,
					commitProfilingData.priorityLevel,
					commitProfilingData.commitTime
				local interactionIDs = {}

				for _, interaction in ipairs(interactions) do
					if not allInteractions[interaction.id] then
						allInteractions[interaction.id] = interaction
					end

					table.insert(interactionIDs, interaction.id)

					local commitIndices = interactionCommits[interaction.id]

					if commitIndices ~= nil then
						table.insert(commitIndices, commitIndex)
					else
						interactionCommits[interaction.id] = { commitIndex }
					end
				end

				local fiberActualDurations = {}
				local fiberSelfDurations = {}

				for i = 1, #durations, 3 do
					local fiberID = durations[i]
					table.insert(fiberActualDurations, { fiberID, durations[i + 1] })
					table.insert(fiberSelfDurations, { fiberID, durations[i + 2] })
				end

				table.insert(commitData, {
					changeDescriptions = changeDescriptions ~= nil and Array.from(
						Object.entries(changeDescriptions)
					) or nil,
					duration = maxActualDuration,
					fiberActualDurations = fiberActualDurations,
					fiberSelfDurations = fiberSelfDurations,
					interactionIDs = interactionIDs,
					priorityLevel = priorityLevel,
					timestamp = commitTime,
				})
			end
			table.insert(dataForRoots, {
				commitData = commitData,
				displayName = displayName,
				initialTreeBaseDurations = initialTreeBaseDurations,
				interactionCommits = Array.from(Object.entries(interactionCommits)),
				interactions = Array.from(Object.entries(allInteractions)),
				rootID = rootID,
			})
		end

		return {
			dataForRoots = dataForRoots,
			rendererID = rendererID,
		}
	end

	local function startProfiling(shouldRecordChangeDescriptions: boolean)
		if isProfiling then
			return
		end

		recordChangeDescriptions = shouldRecordChangeDescriptions

		-- Capture initial values as of the time profiling starts.
		-- It's important we snapshot both the durations and the id-to-root map,
		-- since either of these may change during the profiling session
		-- (e.g. when a fiber is re-rendered or when a fiber gets removed).
		displayNamesByRootID = {}
		initialTreeBaseDurationsMap = Object.assign({}, idToTreeBaseDurationMap)
		initialIDToRootMap = Object.assign({}, idToRootMap)
		idToContextsMap = {}

		for root in pairs(hook.getFiberRoots(rendererID)) do
			local rootID = getFiberID(getPrimaryFiber(root.current));
			(displayNamesByRootID :: DisplayNamesByRootID)[rootID] =
				getDisplayNameForRoot(
					root.current
				)

			if shouldRecordChangeDescriptions then
				-- Record all contexts at the time profiling is started.
				-- Fibers only store the current context value,
				-- so we need to track them separately in order to determine changed keys.
				crawlToInitializeContextsMap(root.current)
			end
		end

		isProfiling = true
		profilingStartTime = getCurrentTime()
		rootToCommitProfilingMetadataMap = {}
	end

	local function stopProfiling()
		isProfiling = false
		recordChangeDescriptions = false
	end

	-- Automatically start profiling so that we don't miss timing info from initial "mount".
	if sessionStorageGetItem(SESSION_STORAGE_RELOAD_AND_PROFILE_KEY) == "true" then
		startProfiling(
			sessionStorageGetItem(SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY)
				== "true"
		)
	end

	-- React will switch between these implementations depending on whether
	-- we have any manually suspended Fibers or not.
	local function shouldSuspendFiberAlwaysFalse()
		return false
	end

	local function shouldSuspendFiberAccordingToSet(fiber: Fiber)
		local id = getFiberID(getPrimaryFiber(fiber))
		return forceFallbackForSuspenseIDs:has(id)
	end
	local function overrideSuspense(id, forceFallback)
		if
			typeof(setSuspenseHandler) ~= "function"
			or typeof(scheduleUpdate) ~= "function"
		then
			error(
				"Expected overrideSuspense() to not get called for earlier React versions."
			)
		end
		if forceFallback then
			forceFallbackForSuspenseIDs:add(id)

			if forceFallbackForSuspenseIDs.size == 1 then
				-- First override is added. Switch React to slower path.
				setSuspenseHandler(shouldSuspendFiberAccordingToSet)
			end
		else
			forceFallbackForSuspenseIDs:delete(id)

			if forceFallbackForSuspenseIDs.size == 0 then
				-- Last override is gone. Switch React back to fast path.
				setSuspenseHandler(shouldSuspendFiberAlwaysFalse)
			end
		end

		local fiber: Fiber? = idToFiberMap[id]

		if fiber ~= nil then
			scheduleUpdate(fiber :: Fiber)
		end
	end

	setTrackedPath = function(path: Array<PathFrame> | nil)
		if path == nil then
			trackedPathMatchFiber = nil
			trackedPathMatchDepth = -1
			mightBeOnTrackedPath = false
		end

		trackedPath = path
	end

	-- We call this before traversing a new mount.
	-- It remembers whether this Fiber is the next best match for tracked path.
	-- The return value signals whether we should keep matching siblings or not.
	updateTrackedPathStateBeforeMount = function(fiber: Fiber): boolean
		if trackedPath == nil or not mightBeOnTrackedPath then
			-- Fast path: there's nothing to track so do nothing and ignore siblings.
			return false
		end

		local returnFiber = fiber.return_
		local returnAlternate = (function()
			if returnFiber ~= nil then
				return (returnFiber :: Fiber).alternate
			end
			return nil
		end)()
		-- By now we know there's some selection to restore, and this is a new Fiber.
		-- Is this newly mounted Fiber a direct child of the current best match?
		-- (This will also be true for new roots if we haven't matched anything yet.)
		if
			trackedPathMatchFiber == returnFiber
			or trackedPathMatchFiber == returnAlternate and returnAlternate ~= nil
		then
			-- Is this the next Fiber we should select? Let's compare the frames.
			local actualFrame = getPathFrame(fiber)
			local expectedFrame: PathFrame? =
				(trackedPath :: Array<PathFrame>)[trackedPathMatchDepth + 1]

			if expectedFrame == nil then
				error("Expected to see a frame at the next depth.")
			end
			if
				actualFrame.index == (expectedFrame :: PathFrame).index
				and actualFrame.key == (expectedFrame :: PathFrame).key
				and actualFrame.displayName
					== (expectedFrame :: PathFrame).displayName
			then
				-- We have our next match.
				trackedPathMatchFiber = fiber
				trackedPathMatchDepth = trackedPathMatchDepth + 1
				-- Are we out of frames to match?
				if trackedPathMatchDepth == #(trackedPath :: Array<PathFrame>) - 1 then
					-- There's nothing that can possibly match afterwards.
					-- Don't check the children.
					mightBeOnTrackedPath = false
				else
					-- Check the children, as they might reveal the next match.
					mightBeOnTrackedPath = true
				end
				-- In either case, since we have a match, we don't need
				-- to check the siblings. They'll never match.
				return false
			end
		end

		-- This Fiber's parent is on the path, but this Fiber itself isn't.
		-- There's no need to check its children--they won't be on the path either.
		mightBeOnTrackedPath = false
		-- However, one of its siblings may be on the path so keep searching.
		return true
	end

	updateTrackedPathStateAfterMount = function(mightSiblingsBeOnTrackedPath)
		-- updateTrackedPathStateBeforeMount() told us whether to match siblings.
		-- Now that we're entering siblings, let's use that information.
		mightBeOnTrackedPath = mightSiblingsBeOnTrackedPath
	end

	-- ROBLOX deviation: rootPseudoKeys and rootDisplayNameCounter defined earlier in the file
	setRootPseudoKey = function(id: number, fiber: Fiber)
		local name = getDisplayNameForRoot(fiber)
		local counter = rootDisplayNameCounter[name] or 0
		rootDisplayNameCounter[name] = counter + 1
		local pseudoKey = ("%s:%d"):format(name, counter)
		rootPseudoKeys[id] = pseudoKey
	end
	removeRootPseudoKey = function(id: number)
		local pseudoKey: string? = rootPseudoKeys[id]

		if pseudoKey == nil then
			error("Expected root pseudo key to be known.")
		end

		-- ROBLOX deviation: No existing lastIndexOf implementation
		-- local name = pseudoKey:sub(1, String.lastIndexOf(pseudoKey, ':'))
		local name = (pseudoKey :: string):gsub("%:[0-9]$", "")
		local counter = rootDisplayNameCounter[name]

		if counter == nil then
			error("Expected counter to be known.")
		end
		if counter > 1 then
			rootDisplayNameCounter[name] = counter - 1
		else
			rootDisplayNameCounter[name] = nil
		end

		rootPseudoKeys[id] = nil
	end

	getDisplayNameForRoot = function(fiber: Fiber): string
		local preferredDisplayName = nil
		local fallbackDisplayName = nil
		local child = fiber.child
		-- Go at most three levels deep into direct children
		-- while searching for a child that has a displayName.
		for i = 0, 3 - 1 do
			if child == nil then
				break
			end

			local displayName = getDisplayNameForFiber(child :: Fiber)

			if displayName ~= nil then
				-- Prefer display names that we get from user-defined components.
				-- We want to avoid using e.g. 'Suspense' unless we find nothing else.
				if typeof((child :: Fiber).type) == "function" then
					-- There's a few user-defined tags, but we'll prefer the ones
					-- that are usually explicitly named (function or class components).
					preferredDisplayName = displayName
				elseif fallbackDisplayName == nil then
					fallbackDisplayName = displayName
				end
			end
			if preferredDisplayName ~= nil then
				break
			end

			child = (child :: Fiber).child
		end

		return preferredDisplayName or fallbackDisplayName or "Anonymous"
	end

	getPathFrame = function(fiber: Fiber): PathFrame
		local key = fiber.key
		local displayName = getDisplayNameForFiber(fiber)
		local index = fiber.index

		if fiber.tag == HostRoot then
			-- Roots don't have a real displayName, index, or key.
			-- Instead, we'll use the pseudo key (childDisplayName:indexWithThatName).
			local id = getFiberID(getPrimaryFiber(fiber))
			local pseudoKey: string? = rootPseudoKeys[id]
			if pseudoKey == nil then
				error("Expected mounted root to have known pseudo key.")
			end
			displayName = pseudoKey :: string
		elseif fiber.tag == HostComponent then
			displayName = fiber.type
		end

		return {
			displayName = displayName,
			key = key,
			index = index,
		}
	end

	-- Produces a serializable representation that does a best effort
	-- of identifying a particular Fiber between page reloads.
	-- The return path will contain Fibers that are "invisible" to the store
	-- because their keys and indexes are important to restoring the selection.
	local function getPathForElement(id: number): Array<PathFrame> | nil
		local fiber: Fiber? = idToFiberMap[id]
		if fiber == nil then
			return nil
		end

		local keyPath = {}
		while fiber ~= nil do
			table.insert(keyPath, getPathFrame(fiber :: Fiber))
			fiber = (fiber :: Fiber).return_
		end

		Array.reverse(keyPath)
		return keyPath
	end

	local function getBestMatchForTrackedPath(): PathMatch | nil
		if trackedPath == nil then
			-- Nothing to match.
			return nil
		end
		if trackedPathMatchFiber == nil then
			-- We didn't find anything.
			return nil
		end

		-- Find the closest Fiber store is aware of.
		local fiber: Fiber? = trackedPathMatchFiber
		while fiber ~= nil and shouldFilterFiber(fiber :: Fiber) do
			fiber = (fiber :: Fiber).return_
		end

		if fiber == nil then
			return nil
		end

		return {
			id = getFiberID(getPrimaryFiber(fiber :: Fiber)),
			isFullMatch = trackedPathMatchDepth == #(trackedPath :: Array<PathFrame>),
		}
	end

	local function setTraceUpdatesEnabled(isEnabled: boolean): ()
		traceUpdatesEnabled = isEnabled
	end

	return {
		cleanup = cleanup,
		copyElementPath = copyElementPath,
		deletePath = deletePath,
		findNativeNodesForFiberID = findNativeNodesForFiberID,
		flushInitialOperations = flushInitialOperations,
		getBestMatchForTrackedPath = getBestMatchForTrackedPath,
		getDisplayNameForFiberID = getDisplayNameForFiberID,
		getFiberIDForNative = getFiberIDForNative,
		getInstanceAndStyle = getInstanceAndStyle,
		getOwnersList = getOwnersList,
		getPathForElement = getPathForElement,
		getProfilingData = getProfilingData,
		handleCommitFiberRoot = handleCommitFiberRoot,
		handleCommitFiberUnmount = handleCommitFiberUnmount,
		inspectElement = inspectElement,
		logElementToConsole = logElementToConsole,
		prepareViewAttributeSource = prepareViewAttributeSource,
		prepareViewElementSource = prepareViewElementSource,
		overrideSuspense = overrideSuspense,
		overrideValueAtPath = overrideValueAtPath,
		renamePath = renamePath,
		renderer = renderer,
		setTraceUpdatesEnabled = setTraceUpdatesEnabled,
		setTrackedPath = setTrackedPath,
		startProfiling = startProfiling,
		stopProfiling = stopProfiling,
		storeAsGlobal = storeAsGlobal,
		updateComponentFilters = updateComponentFilters,
		-- ROBLOX deviation: expose extra function for Roblox Studio use
		getDisplayNameForRoot = getDisplayNameForRoot,
	}
end

return exports
