-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/types.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Object = LuauPolyfill.Object
type Array<T> = LuauPolyfill.Array<T>
type Function = (...any) -> any
type Map<K, V> = LuauPolyfill.Map<K, V>
type Set<T> = LuauPolyfill.Set<T>
type Symbol = Object
local exports = {}

-- ROBLOX deviation: rotriever re-exports types to the top-level export
local ReactShared = require(Packages.Shared)
type ReactContext<T> = ReactShared.ReactContext<T>
type Source = ReactShared.Source
local ReactInternalTypes = require(Packages.ReactReconciler)
type Fiber = ReactInternalTypes.Fiber
local Types = require(script.Parent.Parent.types)
type ComponentFilter = Types.ComponentFilter
type ElementType = Types.ElementType

local DevToolsViewsProfilerTypes =
	require(script.Parent.Parent.devtools.views.Profiler.types)
type Interaction = DevToolsViewsProfilerTypes.Interaction

type ResolveNativeStyle = (any) -> Object?

-- ROBLOX deviation: Luau currently can't express enumerations of literals
--  | 0 -- PROD
--  | 1; -- DEV
type BundleType = number

export type WorkTag = number
export type WorkFlags = number
export type ExpirationTime = number

export type WorkTagMap = {
	Block: WorkTag,
	ClassComponent: WorkTag,
	ContextConsumer: WorkTag,
	ContextProvider: WorkTag,
	CoroutineComponent: WorkTag,
	CoroutineHandlerPhase: WorkTag,
	DehydratedSuspenseComponent: WorkTag,
	ForwardRef: WorkTag,
	Fragment: WorkTag,
	FunctionComponent: WorkTag,
	HostComponent: WorkTag,
	HostPortal: WorkTag,
	HostRoot: WorkTag,
	HostText: WorkTag,
	IncompleteClassComponent: WorkTag,
	IndeterminateComponent: WorkTag,
	LazyComponent: WorkTag,
	MemoComponent: WorkTag,
	Mode: WorkTag,
	OffscreenComponent: WorkTag,
	Profiler: WorkTag,
	SimpleMemoComponent: WorkTag,
	SuspenseComponent: WorkTag,
	SuspenseListComponent: WorkTag,
	YieldComponent: WorkTag,
}

-- TODO: If it's useful for the frontend to know which types of data an Element has
-- (e.g. props, state, context, hooks) then we could add a bitmask field for this
-- to keep the number of attributes small.
export type FiberData = {
	key: string | nil,
	displayName: string | nil,
	type: ElementType,
}

export type NativeType = Object
export type RendererID = number
type Dispatcher = ReactShared.Dispatcher
export type CurrentDispatcherRef = { current: nil | Dispatcher }

export type GetDisplayNameForFiberID = (number, boolean?) -> string | nil

export type GetFiberIDForNative = (NativeType, boolean?) -> number | nil
export type FindNativeNodesForFiberID = (number) -> Array<NativeType>?

export type ReactProviderType<T> = {
	-- ROBLOX TODO: Luau can't express field names that require quoted accessor
	--   $$typeof: Symbol | number,
	[string]: Symbol | number,
	_context: ReactContext<T>,
	--   ...
}

-- ROBLOX deviation: most of the instance methods are nil-able upstream, but we can't typecheck inline when using the colon call operator
export type ReactRenderer = {
	findFiberByHostInstance: (NativeType) -> Fiber?,
	version: string,
	rendererPackageName: string,
	bundleType: BundleType,
	-- 16.9+
	overrideHookState: ((
		self: ReactRenderer,
		Object,
		number,
		Array<string | number>,
		any
	) -> ()),
	-- 17+
	overrideHookStateDeletePath: ((
		self: ReactRenderer,
		Object,
		number,
		Array<string | number>
	) -> ()),
	-- 17+
	overrideHookStateRenamePath: ((
		self: ReactRenderer,
		Object,
		number,
		Array<string | number>,
		Array<string | number>
	) -> ()),
	-- 16.7+
	overrideProps: ((self: ReactRenderer, Object, Array<string | number>, any) -> ()),
	-- 17+
	overridePropsDeletePath: (
		(self: ReactRenderer, Object, Array<string | number>) -> ()
	),
	-- 17+
	overridePropsRenamePath: ((
		self: ReactRenderer,
		Object,
		Array<string | number>,
		Array<string | number>
	) -> ()),
	-- 16.9+
	scheduleUpdate: ((self: ReactRenderer, Object) -> ()),
	setSuspenseHandler: (
		self: ReactRenderer,
		shouldSuspend: (fiber: Object) -> boolean
	) -> (),
	-- Only injected by React v16.8+ in order to support hooks inspection.
	currentDispatcherRef: CurrentDispatcherRef?,
	-- Only injected by React v16.9+ in DEV mode.
	-- Enables DevTools to append owners-only component stack to error messages.
	getCurrentFiber: (() -> Fiber | nil)?,
	-- Uniquely identifies React DOM v15.
	ComponentTree: any?,
	-- Present for React DOM v12 (possibly earlier) through v15.
	Mount: any?,
	--   ...
}

export type ChangeDescription = {
	context: Array<string> | boolean | nil,
	didHooksChange: boolean,
	isFirstMount: boolean,
	props: Array<string> | nil,
	state: Array<string> | nil,
}

export type CommitDataBackend = {
	-- Tuple of fiber ID and change description
	-- ROBLOX TODO: how to express bracket syntax embedded in Array type?
	-- changeDescriptions: Array<[number, ChangeDescription]> | nil,
	changeDescriptions: Array<Array<number | ChangeDescription>> | nil,
	duration: number,
	-- Tuple of fiber ID and actual duration
	fiberActualDurations: Array<Array<number>>,
	-- Tuple of fiber ID and computed "self" duration
	fiberSelfDurations: Array<Array<number>>,
	interactionIDs: Array<number>,
	priorityLevel: string | nil,
	timestamp: number,
}

export type ProfilingDataForRootBackend = {
	commitData: Array<CommitDataBackend>,
	displayName: string,
	-- Tuple of Fiber ID and base duration
	-- ROBLOX TODO: how to express bracket syntax embedded in Array type?

	initialTreeBaseDurations: Array<any>,
	-- Tuple of Interaction ID and commit indices
	interactionCommits: Array<any>,
	interactions: Array<any>,
	rootID: number,
}

-- Profiling data collected by the renderer interface.
-- This information will be passed to the frontend and combined with info it collects.
export type ProfilingDataBackend = {
	dataForRoots: Array<ProfilingDataForRootBackend>,
	rendererID: number,
}

-- ROBLOX deviation: Roact stable keys - slightly widen the type definition of a
-- stable key so that it's likely to work with existing Roact code. Includes
-- numbers for mixed/sparse tables
type RoactStableKey = string | number

export type PathFrame = {
	key: RoactStableKey | nil,
	index: number,
	displayName: string | nil,
}

export type PathMatch = { id: number, isFullMatch: boolean }

export type Owner = { displayName: string | nil, id: number, type: ElementType }

export type OwnersList = { id: number, owners: Array<Owner> | nil }

export type InspectedElement = {
	id: number,

	displayName: string | nil,

	-- Does the current renderer support editable hooks and function props?
	canEditHooks: boolean,
	canEditFunctionProps: boolean,

	-- Does the current renderer support advanced editing interface?
	canEditHooksAndDeletePaths: boolean,
	canEditHooksAndRenamePaths: boolean,
	canEditFunctionPropsDeletePaths: boolean,
	canEditFunctionPropsRenamePaths: boolean,

	-- Is this Suspense, and can its value be overridden now?
	canToggleSuspense: boolean,

	-- Can view component source location.
	canViewSource: boolean,

	-- Does the component have legacy context attached to it.
	hasLegacyContext: boolean,

	-- Inspectable properties.
	context: Object | nil,
	hooks: Object | nil,
	props: Object | nil,
	state: Object | nil,
	key: number | string | nil,

	-- List of owners
	owners: Array<Owner> | nil,

	-- Location of component in source code.
	source: Source | nil,

	type_: ElementType,

	-- Meta information about the root this element belongs to.
	rootType: string | nil,

	-- Meta information about the renderer that created this element.
	rendererPackageName: string | nil,
	rendererVersion: string | nil,
}

exports.InspectElementFullDataType = "full-data"
exports.InspectElementNoChangeType = "no-change"
exports.InspectElementNotFoundType = "not-found"
exports.InspectElementHydratedPathType = "hydrated-path"

type InspectElementFullData = {
	id: number,
	-- ROBLOX TODO: Luau can't express literals
	--   type: 'full-data',
	type: string,
	value: InspectedElement,
}

type InspectElementHydratedPath = {
	id: number,
	-- ROBLOX TODO: Luau can't express literals
	--   type: 'hydrated-path',
	type: string,
	path: Array<string | number>,
	value: any,
}

type InspectElementNoChange = {
	id: number,
	-- ROBLOX TODO: Luau can't express literals
	--   type: 'no-change',
	type: string,
}

type InspectElementNotFound = {
	id: number,
	-- ROBLOX TODO: Luau can't express literals
	--   type: 'not-found',
	type: string,
}

export type InspectedElementPayload =
	InspectElementFullData
	| InspectElementHydratedPath
	| InspectElementNoChange
	| InspectElementNotFound

export type InstanceAndStyle = { instance: Object | nil, style: Object | nil }

-- ROBLOX TODO: Luau can't express literals
--   type Type = 'props' | 'hooks' | 'state' | 'context';
type Type = string

export type RendererInterface = {
	cleanup: () -> (),
	copyElementPath: (number, Array<string | number>) -> (),
	deletePath: (Type, number, number?, Array<string | number>) -> (),
	findNativeNodesForFiberID: FindNativeNodesForFiberID,
	flushInitialOperations: () -> (),
	getBestMatchForTrackedPath: () -> PathMatch | nil,
	getFiberIDForNative: GetFiberIDForNative,
	getDisplayNameForFiberID: GetDisplayNameForFiberID,
	getInstanceAndStyle: (number) -> InstanceAndStyle,
	getProfilingData: () -> ProfilingDataBackend,
	getOwnersList: (number) -> Array<Owner> | nil,
	getPathForElement: (number) -> Array<PathFrame> | nil,
	handleCommitFiberRoot: (Object, number?) -> (),
	handleCommitFiberUnmount: (Object) -> (),
	inspectElement: (number, Array<string | number>?) -> InspectedElementPayload,
	logElementToConsole: (number) -> (),
	overrideSuspense: (number, boolean) -> (),
	overrideValueAtPath: (Type, number, number?, Array<string | number>, any) -> (),
	prepareViewAttributeSource: (number, Array<string | number>) -> (),
	prepareViewElementSource: (number) -> (),
	renamePath: (
		Type,
		number,
		number?,
		Array<string | number>,
		Array<string | number>
	) -> (),
	renderer: ReactRenderer | nil,
	setTraceUpdatesEnabled: (boolean) -> (),
	setTrackedPath: (Array<PathFrame> | nil) -> (),
	startProfiling: (boolean) -> (),
	stopProfiling: () -> (),
	storeAsGlobal: (number, Array<string | number>, number) -> (),
	updateComponentFilters: (Array<ComponentFilter>) -> (),
	-- ROBLOX TODO: once we are back up to 70% coverage, use [string]: any to approximate the ... below
	--   ...
	-- ROBLOX deviation: add specific exports needed so the contract is explcit and explicitly typed
	getDisplayNameForRoot: (fiber: Fiber) -> string,
}

export type Handler = (any) -> ()

-- ROBLOX TODO? move these types into shared so reconciler and devtools don't have circlar dep?
export type DevToolsHook = {
	listeners: {
		[string]: Array<Handler>, --[[ ...]]
	},
	rendererInterfaces: Map<RendererID, RendererInterface>,
	renderers: Map<RendererID, ReactRenderer>,

	emit: (string, any) -> (),
	getFiberRoots: (RendererID) -> Set<Object>,
	inject: (ReactRenderer) -> number | nil,
	on: (string, Handler) -> (),
	off: (string, Handler) -> (),
	reactDevtoolsAgent: Object?,
	sub: (string, Handler) -> (() -> ()),

	-- Used by react-native-web and Flipper/Inspector
	resolveRNStyle: ResolveNativeStyle?,
	nativeStyleEditorValidAttributes: Array<string>?,

	-- React uses these methods.
	checkDCE: (Function) -> (),
	onCommitFiberUnmount: (RendererID, Object) -> (),
	onCommitFiberRoot: (
		RendererID,
		Object,
		-- Added in v16.9 to support Profiler priority labels
		number?,
		-- Added in v16.9 to support Fast Refresh
		boolean?
	) -> (),
	-- ROBLOX deviation: track specific additions to interface needed instead of catch-all
	supportsFiber: boolean,
	isDisabled: boolean?,
	--   ...
}

return exports
