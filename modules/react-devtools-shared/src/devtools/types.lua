--!strict
local Packages = script.Parent.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
type Array<T> = LuauPolyfill.Array<T>
type Map<K, V> = LuauPolyfill.Map<K, V>
type Object = LuauPolyfill.Object
type Set<K> = LuauPolyfill.Set<K>

local ComponentsTypes = require(script.Parent.Parent.devtools.views.Components.types)
type Element = ComponentsTypes.Element

local Types = require(script.Parent.Parent.types)
type ComponentFilter = Types.ComponentFilter
type ElementType = Types.ElementType

local EventEmitter = require(script.Parent.Parent.events)
type EventEmitter<T> = EventEmitter.EventEmitter<T>

local Bridge = require(script.Parent.Parent.bridge)
type FrontendBridge = Bridge.FrontendBridge

local backendTypes = require(script.Parent.Parent.backend.types)
type ProfilingDataBackend = backendTypes.ProfilingDataBackend

local profilerTypes = require(script.Parent.views.Profiler.types)
type CommitDataFrontend = profilerTypes.CommitDataFrontend
type ProfilingDataForRootFrontend = profilerTypes.ProfilingDataForRootFrontend
type ProfilingDataFrontend = profilerTypes.ProfilingDataFrontend
type SnapshotNode = profilerTypes.SnapshotNode

export type Capabilities = { hasOwnerMetadata: boolean, supportsProfiling: boolean }

export type Store = EventEmitter<
	{
		collapseNodesByDefault: Array<any>,
		componentFilters: Array<any>,
		mutated: Array<any>, -- ROBLOX deviation: can't express jagged array types in Luau
		recordChangeDescriptions: Array<any>,
		roots: Array<any>,
		supportsNativeStyleEditor: Array<any>,
		supportsProfiling: Array<any>,
		supportsReloadAndProfile: Array<any>,
		unsupportedRendererVersionDetected: Array<any>,
	}
> & {
	_bridge: FrontendBridge,

	-- Should new nodes be collapsed by default when added to the tree?
	_collapseNodesByDefault: boolean,

	_componentFilters: Array<ComponentFilter>,

	-- At least one of the injected renderers contains (DEV only) owner metadata.
	_hasOwnerMetadata: boolean,

	-- Map of ID to (mutable) Element.
	-- Elements are mutated to avoid excessive cloning during tree updates.
	-- The InspectedElementContext also relies on this mutability for its WeakMap usage.
	_idToElement: Map<number, Element>,

	-- Should the React Native style editor panel be shown?
	_isNativeStyleEditorSupported: boolean,

	-- Can the backend use the Storage API (e.g. localStorage)?
	-- If not, features like reload-and-profile will not work correctly and must be disabled.
	_isBackendStorageAPISupported: boolean,

	_nativeStyleEditorValidAttributes: Array<string> | nil,

	-- Map of element (id) to the set of elements (ids) it owns.
	-- This map enables getOwnersListForElement() to avoid traversing the entire tree.
	_ownersMap: Map<number, Set<number>>,

	_profilerStore: ProfilerStore,

	_recordChangeDescriptions: boolean,

	-- Incremented each time the store is mutated.
	-- This enables a passive effect to detect a mutation between render and commit phase.
	_revision: number,

	-- This Array must be treated as immutable!
	-- Passive effects will check it for changes between render and mount.
	_roots: Array<number>,

	_rootIDToCapabilities: Map<number, Capabilities>,

	-- Renderer ID is needed to support inspection fiber props, state, and hooks.
	_rootIDToRendererID: Map<number, number>,

	-- These options may be initially set by a confiugraiton option when constructing the Store.
	-- In the case of "supportsProfiling", the option may be updated based on the injected renderers.
	_supportsNativeInspection: boolean,
	_supportsProfiling: boolean,
	_supportsReloadAndProfile: boolean,
	_supportsTraceUpdates: boolean,

	_unsupportedRendererVersionDetected: boolean,

	-- Total number of visible elements (within all roots).
	-- Used for windowing purposes.
	_weightAcrossRoots: number,
	assertExpectedRootMapSizes: (self: Store) -> (),
	assertMapSizeMatchesRootCount: (
		self: Store,
		map: Map<any, any>,
		mapName: string
	) -> (),
	getCollapseNodesByDefault: (self: Store) -> boolean,
	setCollapseNodesByDefault: (self: Store, boolean) -> (),
	getComponentFilters: (self: Store) -> Array<ComponentFilter>,
	setComponentFilters: (self: Store, Array<ComponentFilter>) -> (),
	getHasOwnerMetadata: (self: Store) -> boolean,
	getNativeStyleEditorValidAttributes: (self: Store) -> Array<string> | nil,
	getNumElements: (self: Store) -> number,
	getProfilerStore: (self: Store) -> ProfilerStore,
	getRecordChangeDescriptions: (self: Store) -> boolean,
	setRecordChangeDescriptions: (self: Store, value: boolean) -> (),
	getRevision: (self: Store) -> number,
	getRootIDToRendererID: (self: Store) -> Map<number, number>,
	getRoots: (self: Store) -> Array<number>,
	getSupportsNativeInspection: (self: Store) -> boolean,
	getSupportsNativeStyleEditor: (self: Store) -> boolean,
	getSupportsProfiling: (self: Store) -> boolean,
	getSupportsReloadAndProfile: (self: Store) -> boolean,
	getSupportsTraceUpdates: (self: Store) -> boolean,
	getUnsupportedRendererVersionDetected: (self: Store) -> boolean,
	containsElement: (self: Store, id: number) -> boolean,
	getElementAtIndex: (self: Store, index: number) -> Element | nil,
	getElementIDAtIndex: (self: Store, index: number) -> number | nil,
	getElementByID: (self: Store, id: number) -> Element | nil,
	getIndexOfElementID: (self: Store, id: number) -> number | nil,
	getOwnersListForElement: (self: Store, ownerID: number) -> Array<Element>,
	getRendererIDForElement: (self: Store, id: number) -> number | nil,
	getRootIDForElement: (self: Store, id: number) -> number | nil,
	isInsideCollapsedSubTree: (self: Store, id: number) -> boolean,
	toggleIsCollapsed: (self: Store, id: number, isCollapsed: boolean) -> (),
	_adjustParentTreeWeight: (
		self: Store,
		parentElement: Element | nil,
		weightDelta: number
	) -> (),
	onBridgeNativeStyleEditorSupported: (
		self: Store,
		options: {
			isSupported: boolean,
			validAttributes: Array<string>,
		}
	) -> (),
	onBridgeOperations: (self: Store, operations: Array<number>) -> (),
	onBridgeOverrideComponentFilters: (
		self: Store,
		componentFilters: Array<ComponentFilter>
	) -> (),
	onBridgeShutdown: (self: Store) -> (),
	onBridgeStorageSupported: (self: Store, isBackendStorageAPISupported: boolean) -> (),
	onBridgeUnsupportedRendererVersion: (self: Store) -> (),
}

export type ProfilingCache = {
	_fiberCommits: Map<number, Array<number>>,
	_profilerStore: ProfilerStore,
	getCommitTree: any,
	getFiberCommits: any,
	getFlamegraphChartData: any,
	getInteractionsChartData: any,
	getRankedChartData: any,
	invalidate: (self: ProfilingCache) -> (),
}

export type ProfilerStore = EventEmitter<{
	isProcessingData: any, --[[ ROBLOX TODO: Unhandled node for type: TupleTypeAnnotation ]] --[[ [] ]]
	isProfiling: any, --[[ ROBLOX TODO: Unhandled node for type: TupleTypeAnnotation ]] --[[ [] ]]
	profilingData: any, --[[ ROBLOX TODO: Unhandled node for type: TupleTypeAnnotation ]] --[[ [] ]]
}> & {
	_bridge: FrontendBridge, -- Suspense cache for lazily calculating derived profiling data.
	_cache: ProfilingCache, -- Temporary store of profiling data from the backend renderer(s).
	-- This data will be converted to the ProfilingDataFrontend format after being collected from all renderers.
	_dataBackends: Array<ProfilingDataBackend>, -- Data from the most recently completed profiling session,
	-- or data that has been imported from a previously exported session.
	-- This object contains all necessary data to drive the Profiler UI interface,
	-- even though some of it is lazily parsed/derived via the ProfilingCache.
	_dataFrontend: ProfilingDataFrontend | nil, -- Snapshot of all attached renderer IDs.
	-- Once profiling is finished, this snapshot will be used to query renderers for profiling data.
	--
	-- This map is initialized when profiling starts and updated when a new root is added while profiling;
	-- Upon completion, it is converted into the exportable ProfilingDataFrontend format.
	_initialRendererIDs: Set<number>, -- Snapshot of the state of the main Store (including all roots) when profiling started.
	-- Once profiling is finished, this snapshot can be used along with "operations" messages emitted during profiling,
	-- to reconstruct the state of each root for each commit.
	-- It's okay to use a single root to store this information because node IDs are unique across all roots.
	--
	-- This map is initialized when profiling starts and updated when a new root is added while profiling;
	-- Upon completion, it is converted into the exportable ProfilingDataFrontend format.
	_initialSnapshotsByRootID: Map<number, Map<number, SnapshotNode>>, -- Map of root (id) to a list of tree mutation that occur during profiling.
	-- Once profiling is finished, these mutations can be used, along with the initial tree snapshots,
	-- to reconstruct the state of each root for each commit.
	--
	-- This map is only updated while profiling is in progress;
	-- Upon completion, it is converted into the exportable ProfilingDataFrontend format.
	_inProgressOperationsByRootID: Map<number, Array<Array<number>>>, -- The backend is currently profiling.
	-- When profiling is in progress, operations are stored so that we can later reconstruct past commit trees.
	_isProfiling: boolean, -- Tracks whether a specific renderer logged any profiling data during the most recent session.
	_rendererIDsThatReportedProfilingData: Set<number>, -- After profiling, data is requested from each attached renderer using this queue.
	-- So long as this queue is not empty, the store is retrieving and processing profiling data from the backend.
	_rendererQueue: Set<number>,
	_store: Store,
	getCommitData: (
		self: ProfilerStore,
		rootID: number,
		commitIndex: number
	) -> CommitDataFrontend,
	getDataForRoot: (self: ProfilerStore, rootID: number) -> ProfilingDataForRootFrontend, -- Profiling data has been recorded for at least one root.
	didRecordCommits: (self: ProfilerStore) -> boolean,
	isProcessingData: (self: ProfilerStore) -> boolean,
	isProfiling: (self: ProfilerStore) -> boolean,
	profilingCache: (self: ProfilerStore) -> ProfilingCache,
	profilingData: (
		self: ProfilerStore,
		value: ProfilingDataFrontend?
	) -> (...ProfilingDataFrontend?),
	clear: (self: ProfilerStore) -> (),
	startProfiling: (self: ProfilerStore) -> (),
	stopProfiling: (self: ProfilerStore) -> (),
	_takeProfilingSnapshotRecursive: any,
	onBridgeOperations: (self: ProfilerStore, operations: Array<number>) -> (),
	onBridgeProfilingData: (self: ProfilerStore, dataBackend: ProfilingDataBackend) -> (),
	onBridgeShutdown: (self: ProfilerStore) -> (),
	onProfilingStatus: (self: ProfilerStore, isProfiling: boolean) -> (),
}

return true
