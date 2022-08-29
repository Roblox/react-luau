-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/devtools/store.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Set = LuauPolyfill.Set
local Object = LuauPolyfill.Object
local inspect = LuauPolyfill.util.inspect

type Array<T> = LuauPolyfill.Array<T>
type Map<K, V> = { [K]: V }
type Object = LuauPolyfill.Object
type Set<K> = LuauPolyfill.Set<K>
local console = require(Packages.Shared).console

local EventEmitter = require(script.Parent.Parent.events)
type EventEmitter<T> = EventEmitter.EventEmitter<T>
local constants = require(script.Parent.Parent.constants)
local TREE_OPERATION_ADD = constants.TREE_OPERATION_ADD
local TREE_OPERATION_REMOVE = constants.TREE_OPERATION_REMOVE
local TREE_OPERATION_REORDER_CHILDREN = constants.TREE_OPERATION_REORDER_CHILDREN
local TREE_OPERATION_UPDATE_TREE_BASE_DURATION =
	constants.TREE_OPERATION_UPDATE_TREE_BASE_DURATION
local types = require(script.Parent.Parent.types)
local ElementTypeRoot = types.ElementTypeRoot
local utils = require(script.Parent.Parent.utils)
local getSavedComponentFilters = utils.getSavedComponentFilters
local saveComponentFilters = utils.saveComponentFilters
local separateDisplayNameAndHOCs = utils.separateDisplayNameAndHOCs
local shallowDiffers = utils.shallowDiffers
-- ROBLOX deviation: don't use string encoding
-- local utfDecodeString = utils.utfDecodeString
local storage = require(script.Parent.Parent.storage)
local localStorageGetItem = storage.localStorageGetItem
local localStorageSetItem = storage.localStorageSetItem
local __DEBUG__ = constants.__DEBUG__

-- ROBLOX TODO: implement ProfilerStore
-- local ProfilerStoreModule = require(script.Parent.ProfilerStore)
-- local ProfilerStore = ProfilerStoreModule.ProfilerStore
-- type ProfilerStore = ProfilerStoreModule.ProfilerStore
type ProfilerStore = Object
local ProfilerStore = {
	new = function(...) end,
}

local ComponentsTypes = require(script.Parent.Parent.devtools.views.Components.types)
type Element = ComponentsTypes.Element
local Types = require(script.Parent.Parent.types)
type ComponentFilter = Types.ComponentFilter
type ElementType = Types.ElementType
local Bridge = require(script.Parent.Parent.bridge)
type FrontendBridge = Bridge.FrontendBridge

local debug_ = function(methodName, ...)
	if __DEBUG__ then
		print("Store", methodName, ...)
	end
end

local LOCAL_STORAGE_COLLAPSE_ROOTS_BY_DEFAULT_KEY =
	"React::DevTools::collapseNodesByDefault"
local LOCAL_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY =
	"React::DevTools::recordChangeDescriptions"

type Config = {
	isProfiling: boolean?,
	supportsNativeInspection: boolean?,
	supportsReloadAndProfile: boolean?,
	supportsProfiling: boolean?,
	supportsTraceUpdates: boolean?,
}

type Capabilities = { hasOwnerMetadata: boolean, supportsProfiling: boolean }

-- /**
--  * The store is the single source of truth for updates from the backend.
--  * ContextProviders can subscribe to the Store for specific things they want to provide.
--  */
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
-- ROBLOX deviation: equivalent of sub-class
local Store = setmetatable({}, { __index = EventEmitter })
local StoreMetatable = { __index = Store }

function Store.new(bridge: FrontendBridge, config: Config?)
	local self = setmetatable(EventEmitter.new() :: any, StoreMetatable)
	config = config or {}

	-- ROBLOX deviation: define fields in constructor
	self._bridge = bridge

	-- Should new nodes be collapsed by default when added to the tree?
	self._collapseNodesByDefault = true

	self._componentFilters = {}

	-- At least one of the injected renderers contains (DEV only) owner metadata.
	self._hasOwnerMetadata = false

	-- Map of ID to (mutable) Element.
	-- Elements are mutated to avoid excessive cloning during tree updates.
	-- The InspectedElementContext also relies on this mutability for its WeakMap usage.
	self._idToElement = {} :: Map<number, Element>

	-- Should the React Native style editor panel be shown?
	self._isNativeStyleEditorSupported = false

	-- Can the backend use the Storage API (e.g. localStorage)?
	-- If not, features like reload-and-profile will not work correctly and must be disabled.
	self._isBackendStorageAPISupported = false

	self._nativeStyleEditorValidAttributes = nil

	-- Map of element (id) to the set of elements (ids) it owns.
	-- This map enables getOwnersListForElement() to avoid traversing the entire tree.
	self._ownersMap = {} :: Map<number, Set<number>>

	self._profilerStore = nil

	self._recordChangeDescriptions = false

	-- Incremented each time the store is mutated.
	-- This enables a passive effect to detect a mutation between render and commit phase.
	self._revision = 0

	-- This Array must be treated as immutable!
	-- Passive effects will check it for changes between render and mount.
	self._roots = {} :: Array<number>

	self._rootIDToCapabilities = {} :: Map<number, Capabilities>

	-- Renderer ID is needed to support inspection fiber props, state, and hooks.
	self._rootIDToRendererID = {} :: Map<number, number>

	-- These options may be initially set by a confiugraiton option when constructing the Store.
	-- In the case of "supportsProfiling", the option may be updated based on the injected renderers.
	self._supportsNativeInspection = true
	self._supportsProfiling = false
	self._supportsReloadAndProfile = false
	self._supportsTraceUpdates = false

	self._unsupportedRendererVersionDetected = false

	-- Total number of visible elements (within all roots).
	-- Used for windowing purposes.
	self._weightAcrossRoots = 0

	if __DEBUG__ then
		debug_("constructor", "subscribing to Bridge")
	end

	self._collapseNodesByDefault = localStorageGetItem(
		LOCAL_STORAGE_COLLAPSE_ROOTS_BY_DEFAULT_KEY
	) == "true"

	self._recordChangeDescriptions = localStorageGetItem(
		LOCAL_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY
	) == "true"

	self._componentFilters = getSavedComponentFilters()

	local isProfiling = false
	if config ~= nil then
		isProfiling = (config :: Config).isProfiling == true

		local supportsNativeInspection = (config :: Config).supportsNativeInspection
		local supportsProfiling = (config :: Config).supportsProfiling
		local supportsReloadAndProfile = (config :: Config).supportsReloadAndProfile
		local supportsTraceUpdates = (config :: Config).supportsTraceUpdates

		self._supportsNativeInspection = supportsNativeInspection ~= false
		if supportsProfiling then
			self._supportsProfiling = true
		end
		if supportsReloadAndProfile then
			self._supportsReloadAndProfile = true
		end
		if supportsTraceUpdates then
			self._supportsTraceUpdates = true
		end
	end

	-- ROBLOX deviation: bind methods which don't pass self to this instance
	self._onBridgeOperations = self.onBridgeOperations
	self.onBridgeOperations = function(...)
		self:_onBridgeOperations(...)
	end
	self._onBridgeOverrideComponentFilters = self.onBridgeOverrideComponentFilters
	self.onBridgeOverrideComponentFilters = function(...)
		self:_onBridgeOverrideComponentFilters(...)
	end
	self._onBridgeShutdown = self.onBridgeShutdown
	self.onBridgeShutdown = function(...)
		self:_onBridgeShutdown(...)
	end
	self._onBridgeStorageSupported = self.onBridgeStorageSupported
	self.onBridgeStorageSupported = function(...)
		self:_onBridgeStorageSupported(...)
	end
	self._onBridgeNativeStyleEditorSupported = self.onBridgeNativeStyleEditorSupported
	self.onBridgeNativeStyleEditorSupported = function(...)
		self:_onBridgeNativeStyleEditorSupported(...)
	end
	self._onBridgeUnsupportedRendererVersion = self.onBridgeUnsupportedRendererVersion
	self.onBridgeUnsupportedRendererVersion = function(...)
		self:_onBridgeUnsupportedRendererVersion(...)
	end

	bridge:addListener("operations", self.onBridgeOperations)
	bridge:addListener("overrideComponentFilters", self.onBridgeOverrideComponentFilters)
	bridge:addListener("shutdown", self.onBridgeShutdown)
	bridge:addListener("isBackendStorageAPISupported", self.onBridgeStorageSupported)
	bridge:addListener(
		"isNativeStyleEditorSupported",
		self.onBridgeNativeStyleEditorSupported
	)
	bridge:addListener(
		"unsupportedRendererVersion",
		self.onBridgeUnsupportedRendererVersion
	)

	-- ROBLOX FIXME: lazy init this since ProfilerStore doesn't exist in our port yet
	if isProfiling then
		self._profilerStore = ProfilerStore.new(bridge, self, isProfiling)
	end

	return self
end

-- This is only used in tests to avoid memory leaks.
function Store:assertExpectedRootMapSizes()
	if #self._roots == 0 then
		-- The only safe time to assert these maps are empty is when the store is empty.
		self:assertMapSizeMatchesRootCount(self._idToElement, "_idToElement")
		self:assertMapSizeMatchesRootCount(self._ownersMap, "_ownersMap")
	end

	-- These maps should always be the same size as the number of roots
	self:assertMapSizeMatchesRootCount(
		self._rootIDToCapabilities,
		"_rootIDToCapabilities"
	)
	self:assertMapSizeMatchesRootCount(self._rootIDToRendererID, "_rootIDToRendererID")
end

-- This is only used in tests to avoid memory leaks.
function Store:assertMapSizeMatchesRootCount(map: Map<any, any>, mapName: string)
	local expectedSize = #self._roots
	local mapSize = #Object.keys(map)
	if mapSize ~= expectedSize then
		error(
			string.format(
				"Expected %s to contain %s items, but it contains %s items\n\n%s",
				mapName,
				tostring(expectedSize),
				tostring(mapSize),
				inspect(map, { depth = 20 })
			)
		)
	end
end

-- ROBLOX deviation: get / setters not supported in luau
function Store:getCollapseNodesByDefault(): boolean
	return self._collapseNodesByDefault
end

function Store:setCollapseNodesByDefault(value: boolean)
	self._collapseNodesByDefault = value

	localStorageSetItem(
		LOCAL_STORAGE_COLLAPSE_ROOTS_BY_DEFAULT_KEY,
		if value then "true" else "false"
	)
	self:emit("collapseNodesByDefault")
end
function Store:getComponentFilters(): Array<ComponentFilter>
	return self._componentFilters
end

function Store:setComponentFilters(value: Array<ComponentFilter>): ()
	-- ROBLOX TODO: Profiler is not implemented so store will error when attempting to check self._profilerStore.isProfiling if we don't check for existence first
	if self._profilerStore and self._profilerStore.isProfiling then
		-- Re-mounting a tree while profiling is in progress might break a lot of assumptions.
		-- If necessary, we could support this- but it doesn't seem like a necessary use case.
		error("Cannot modify filter preferences while profiling")
	end

	-- Filter updates are expensive to apply (since they impact the entire tree).
	-- Let's determine if they've changed and avoid doing this work if they haven't.
	local prevEnabledComponentFilters = Array.filter(
		self._componentFilters,
		function(filter)
			return filter.isEnabled
		end
	)
	local nextEnabledComponentFilters = Array.filter(value, function(filter)
		return filter.isEnabled
	end)
	local haveEnabledFiltersChanged = #prevEnabledComponentFilters
		~= #nextEnabledComponentFilters

	if not haveEnabledFiltersChanged then
		-- ROBLOX deviation: 1-indexing use 1 not 0
		for i = 1, #nextEnabledComponentFilters do
			local prevFilter = prevEnabledComponentFilters[i]
			local nextFilter = nextEnabledComponentFilters[i]

			if shallowDiffers(prevFilter, nextFilter) then
				haveEnabledFiltersChanged = true
				break
			end
		end
	end

	self._componentFilters = value

	-- Update persisted filter preferences stored in localStorage.
	saveComponentFilters(value)

	-- Notify the renderer that filter prefernces have changed.
	-- This is an expensive opreation; it unmounts and remounts the entire tree,
	-- so only do it if the set of enabled component filters has changed.
	if haveEnabledFiltersChanged then
		self._bridge:send("updateComponentFilters", value)
	end

	self:emit("componentFilters")
end
function Store:getHasOwnerMetadata(): boolean
	return self._hasOwnerMetadata
end
function Store:getNativeStyleEditorValidAttributes(): Array<string> | nil
	return self._nativeStyleEditorValidAttributes
end
function Store:getNumElements(): number
	return self._weightAcrossRoots
end
function Store:getProfilerStore(): ProfilerStore
	return self._profilerStore
end
function Store:getRecordChangeDescriptions(): boolean
	return self._recordChangeDescriptions
end
function Store:setRecordChangeDescriptions(value: boolean): ()
	self._recordChangeDescriptions = value

	localStorageSetItem(
		LOCAL_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY,
		if value then "true" else "false"
	)
	self:emit("recordChangeDescriptions")
end
function Store:getRevision(): number
	return self._revision
end
function Store:getRootIDToRendererID(): Map<number, number>
	return self._rootIDToRendererID
end
function Store:getRoots(): Array<number>
	return self._roots
end
function Store:getSupportsNativeInspection(): boolean
	return self._supportsNativeInspection
end
function Store:getSupportsNativeStyleEditor(): boolean
	return self._isNativeStyleEditorSupported
end
function Store:getSupportsProfiling(): boolean
	return self._supportsProfiling
end
function Store:getSupportsReloadAndProfile(): boolean
	return self._supportsReloadAndProfile and self._isBackendStorageAPISupported
end
function Store:getSupportsTraceUpdates(): boolean
	return self._supportsTraceUpdates
end
function Store:getUnsupportedRendererVersionDetected(): boolean
	return self._unsupportedRendererVersionDetected
end
function Store:containsElement(id: number): boolean
	return self._idToElement[id] ~= nil
end
function Store:getElementAtIndex(index: number): Element?
	if index < 0 or index >= self:getNumElements() then
		console.warn(
			string.format(
				"Invalid index %d specified; store contains %d items.",
				index,
				self:getNumElements()
			)
		)
		return nil
	end

	-- Find which root this element is in...
	local rootID
	local root
	local rootWeight = 0

	-- ROBLOX deviation: 1-indexing use 1 not 0
	for i = 1, #self._roots do
		rootID = self._roots[i]
		root = self._idToElement[rootID]
		if #root.children == 0 then
			continue
		elseif rootWeight + root.weight > index then
			break
		else
			rootWeight = rootWeight + root.weight
		end
	end

	-- Find the element in the tree using the weight of each node...
	-- Skip over the root itself, because roots aren't visible in the Elements tree.
	local currentElement = root
	local currentWeight = rootWeight - 1

	while index ~= currentWeight do
		local numChildren = #currentElement.children

		-- ROBLOX deviation: 1-indexing use 1 not 0
		for i = 1, numChildren do
			local childID = currentElement.children[i]
			local child = self._idToElement[childID]
			local childWeight = if child.isCollapsed then 1 else child.weight
			if index <= currentWeight + childWeight then
				currentWeight += 1
				currentElement = child
				break
			else
				currentWeight += childWeight
			end
		end
	end
	return currentElement or nil
end

function Store:getElementIDAtIndex(index: number): number | nil
	local element: Element? = self:getElementAtIndex(index)

	return (function(): number?
		if element == nil then
			return nil
		end
		return (element :: Element).id
	end)()
end
function Store:getElementByID(id: number): Element | nil
	local element = self._idToElement[id]

	if element == nil then
		console.warn(string.format('No element found with id "%s"', tostring(id)))

		return nil
	end

	return element
end
function Store:getIndexOfElementID(id: number): number | nil
	local element: Element? = self:getElementByID(id)

	if element == nil or (element :: Element).parentID == 0 then
		return nil
	end

	-- Walk up the tree to the root.
	-- Increment the index by one for each node we encounter,
	-- and by the weight of all nodes to the left of the current one.
	-- This should be a relatively fast way of determining the index of a node within the tree.
	local previousID = id
	local currentID = (element :: Element).parentID
	local index = 0

	while true do
		local current = self._idToElement[currentID]
		local children = current.children

		-- ROBLOX deviation: 1-indexing use 1 not 0
		for i = 1, #children do
			local childID = children[i]
			if childID == previousID then
				break
			end

			local child = self._idToElement[childID]
			index += if child.isCollapsed then 1 else child.weight
		end

		-- We found the root; stop crawling.
		if current.parentID == 0 then
			break
		end

		index += 1
		previousID = current.id
		currentID = current.parentID
	end

	-- At this point, the current ID is a root (from the previous loop).
	-- We also need to offset the index by previous root weights.
	for i = 1, #self._roots do
		local rootID = self._roots[i]
		if rootID == currentID then
			break
		end
		local root = self._idToElement[rootID]
		index += root.weight
	end

	return index
end

function Store:getOwnersListForElement(ownerID: number): Array<Element>
	local list = {}
	local element = self._idToElement[ownerID]

	if element ~= nil then
		table.insert(list, Object.assign({}, element, { depth = 0 }))

		local unsortedIDs = self._ownersMap[ownerID]

		if unsortedIDs ~= nil then
			local depthMap = {
				[ownerID] = 0,
			}
			local unsortedIDsDefined: Set<number> = unsortedIDs :: any

			-- Items in a set are ordered based on insertion.
			-- This does not correlate with their order in the tree.
			-- So first we need to order them.
			-- I wish we could avoid this sorting operation; we could sort at insertion time,
			-- but then we'd have to pay sorting costs even if the owners list was never used.
			-- Seems better to defer the cost, since the set of ids is probably pretty small.
			local sortedIDs = Array.sort(
				Array.from(unsortedIDsDefined),
				function(idA: number, idB: number)
					return (self:getIndexOfElementID(idA) or 0)
						- (self:getIndexOfElementID(idB) or 0)
				end
			)

			-- Next we need to determine the appropriate depth for each element in the list.
			-- The depth in the list may not correspond to the depth in the tree,
			-- because the list has been filtered to remove intermediate components.
			-- Perhaps the easiest way to do this is to walk up the tree until we reach either:
			-- (1) another node that's already in the tree, or (2) the root (owner)
			-- at which point, our depth is just the depth of that node plus one.
			for _, id in sortedIDs do
				local innerElement: Element? = self._idToElement[id]

				if innerElement ~= nil then
					local parentID = (innerElement :: Element).parentID
					local depth = 0

					while parentID > 0 do
						if parentID == ownerID or unsortedIDsDefined[parentID] then
							depth = depthMap[parentID] + 1
							depthMap[id] = depth
							break
						end
						local parent: Element? = self._idToElement[parentID]
						if parent == nil then
							break
						end
						parentID = (parent :: Element).parentID
					end

					if depth == 0 then
						error("Invalid owners list")
					end

					table.insert(
						list,
						Object.assign({}, innerElement :: Element, { depth = depth })
					)
				end
			end
		end
	end

	return list
end

function Store:getRendererIDForElement(id: number): number | nil
	local current: Element? = self._idToElement[id]

	while current ~= nil do
		if (current :: Element).parentID == 0 then
			local rendererID = self._rootIDToRendererID[(current :: Element).id]
			if rendererID == nil then
				return nil
			end
			return rendererID
		else
			current = self._idToElement[(current :: Element).parentID]
		end
	end

	return nil
end

function Store:getRootIDForElement(id: number): number | nil
	local current: Element? = self._idToElement[id]

	while current ~= nil do
		if (current :: Element).parentID == 0 then
			return (current :: Element).id
		else
			current = self._idToElement[(current :: Element).parentID]
		end
	end
	return nil
end
function Store:isInsideCollapsedSubTree(id: number): boolean
	local current: Element? = self._idToElement[id]

	while current ~= nil do
		if (current :: Element).parentID == 0 then
			return false
		else
			current = self._idToElement[(current :: Element).parentID]

			if current ~= nil and (current :: Element).isCollapsed then
				return true
			end
		end
	end

	return false
end
-- TODO Maybe split this into two methods: expand() and collapse()
function Store:toggleIsCollapsed(id: number, isCollapsed: boolean): ()
	local didMutate = false
	local element: Element? = self:getElementByID(id)

	if element ~= nil then
		if isCollapsed then
			if (element :: Element).type == ElementTypeRoot then
				error("Root nodes cannot be collapsed")
			end
			if not (element :: Element).isCollapsed then
				didMutate = true;
				(element :: Element).isCollapsed = true

				local weightDelta = 1 - (element :: Element).weight
				local parentElement: Element? =
					self._idToElement[(element :: Element).parentID]

				-- We don't need to break on a collapsed parent in the same way as the expand case below.
				-- That's because collapsing a node doesn't "bubble" and affect its parents.
				while parentElement ~= nil do
					(parentElement :: Element).weight = (parentElement :: Element).weight
						+ weightDelta
					parentElement = self._idToElement[(parentElement :: Element).parentID]
				end
			end
		else
			local currentElement: Element? = element

			while currentElement ~= nil do
				local oldWeight = if (currentElement :: Element).isCollapsed
					then 1
					else (currentElement :: Element).weight

				if (currentElement :: Element).isCollapsed then
					didMutate = true;
					(currentElement :: Element).isCollapsed = false

					local newWeight = if (currentElement :: Element).isCollapsed
						then 1
						else (currentElement :: Element).weight
					local weightDelta = newWeight - oldWeight
					local parentElement: Element? = self._idToElement[(
						currentElement :: Element
					).parentID]

					while parentElement ~= nil do
						(parentElement :: Element).weight += weightDelta

						if (parentElement :: Element).isCollapsed then
							-- It's important to break on a collapsed parent when expanding nodes.
							-- That's because expanding a node "bubbles" up and expands all parents as well.
							-- Breaking in this case prevents us from over-incrementing the expanded weights.
							break
						end
						parentElement =
							self._idToElement[(parentElement :: Element).parentID]
					end
				end

				currentElement = if (currentElement :: Element).parentID ~= 0
					then self:getElementByID((currentElement :: Element).parentID)
					else nil
			end
		end

		-- Only re-calculate weights and emit an "update" event if the store was mutated.
		if didMutate then
			local weightAcrossRoots = 0
			for _i, rootID in self._roots do
				local elementById: Element? = self:getElementByID(rootID)
				local weight = (elementById :: Element).weight
				weightAcrossRoots = weightAcrossRoots + weight
			end
			self._weightAcrossRoots = weightAcrossRoots

			-- The Tree context's search reducer expects an explicit list of ids for nodes that were added or removed.
			-- In this  case, we can pass it empty arrays since nodes in a collapsed tree are still there (just hidden).
			-- Updating the selected search index later may require auto-expanding a collapsed subtree though.
			self:emit("mutated", {
				{},
				{},
			})
		end
	end
end

function Store:_adjustParentTreeWeight(parentElement: Element | nil, weightDelta: number)
	local isInsideCollapsedSubTree = false

	while parentElement ~= nil do
		(parentElement :: Element).weight = (parentElement :: Element).weight
			+ weightDelta

		-- Additions and deletions within a collapsed subtree should not bubble beyond the collapsed parent.
		-- Their weight will bubble up when the parent is expanded.
		if (parentElement :: Element).isCollapsed then
			isInsideCollapsedSubTree = true
			break
		end

		parentElement = self._idToElement[(parentElement :: Element).parentID]
	end

	-- Additions and deletions within a collapsed subtree should not affect the overall number of elements.
	if not isInsideCollapsedSubTree then
		self._weightAcrossRoots = (self._weightAcrossRoots :: number) + weightDelta
	end
end

function Store:onBridgeNativeStyleEditorSupported(
	options: {
		isSupported: boolean,
		validAttributes: Array<string>,
	}
)
	local isSupported, validAttributes = options.isSupported, options.validAttributes

	self._isNativeStyleEditorSupported = isSupported
	self._nativeStyleEditorValidAttributes = validAttributes or nil

	self:emit("supportsNativeStyleEditor")
end

function Store:onBridgeOperations(operations: Array<number>): ()
	if __DEBUG__ then
		console.groupCollapsed("onBridgeOperations")
		debug_("onBridgeOperations", table.concat(operations, ","))
	end

	local haveRootsChanged = false

	-- The first two values are always rendererID and rootID
	local rendererID = operations[1]
	local addedElementIDs = {}
	-- This is a mapping of removed ID -> parent ID:
	local removedElementIDs = {}
	-- We'll use the parent ID to adjust selection if it gets deleted.
	-- ROBLOX deviation: 1-indexed means this is 3, not 2
	local i = 3
	local stringTable: Array<any> = {
		-- ROBLOX deviation: element 1 corresponds to empty string
		"", -- ID = 0 corresponds to the null string.
	}

	-- ROBLOX deviation: use postfix as a function
	local function POSTFIX_INCREMENT()
		local prevI = i
		i += 1
		return prevI
	end

	local stringTableSize = operations[POSTFIX_INCREMENT()]
	local stringTableEnd = i + stringTableSize

	while i < stringTableEnd do
		-- ROBLOX deviation: don't binary encode strings, so store string directly rather than length
		-- local nextLength = operations[POSTFIX_INCREMENT()]
		-- local nextString = utfDecodeString(Array.slice(operations, i, i + nextLength))
		local nextString = operations[POSTFIX_INCREMENT()]

		table.insert(stringTable, nextString)
		-- ROBLOX deviation: don't binary encode strings, so no need to move pointer
		-- i = i + nextLength
	end

	-- ROBLOX deviation: 1-indexing, use <= not <
	while i <= #operations do
		local operation = operations[i]
		if operation == TREE_OPERATION_ADD then
			local id = operations[i + 1]
			local type_ = operations[i + 2]

			i += 3

			if self._idToElement[id] then
				error(
					(
						"Cannot add node %s because a node with that id is already in the Store."
					):format(tostring(id))
				)
			end

			local ownerID = 0
			local parentID = nil

			if type_ == ElementTypeRoot then
				if __DEBUG__ then
					debug_("Add", string.format("new root node %s", tostring(id)))
				end

				local supportsProfiling = operations[i] > 0
				i += 1

				local hasOwnerMetadata = operations[i] > 0

				i += 1
				self._roots = Array.concat(self._roots, id)

				self._rootIDToRendererID[id] = rendererID
				self._rootIDToCapabilities[id] = {
					hasOwnerMetadata = hasOwnerMetadata,
					supportsProfiling = supportsProfiling,
				}
				self._idToElement[id] = {
					children = {},
					depth = -1,
					displayName = nil,
					hocDisplayNames = nil,
					id = id,
					isCollapsed = false, -- Never collapse roots; it would hide the entire tree.
					key = nil,
					ownerID = 0,
					parentID = 0,
					type = type_,
					weight = 0,
				}
				haveRootsChanged = true
			else
				parentID = operations[i]
				i += 1
				ownerID = operations[i]
				i += 1

				local displayNameStringID = operations[i]
				-- ROBLOX deviation: 1-indexed
				local displayName = stringTable[displayNameStringID + 1]

				i += 1

				local keyStringID = operations[i]
				-- ROBLOX deviation: 1-indexed
				local key = stringTable[keyStringID + 1]

				i += 1

				if __DEBUG__ then
					debug_(
						"Add",
						string.format(
							"node %s (%s) as child of %s",
							tostring(id),
							displayName or "null",
							tostring(parentID)
						)
					)
				end
				if not self._idToElement[parentID] then
					error(
						(
							"Cannot add child %s to parent %s because parent node was not found in the Store."
						):format(tostring(id), tostring(parentID))
					)
				end

				local parentElement: Element? = self._idToElement[parentID]

				table.insert((parentElement :: Element).children, id)

				local displayNameWithoutHOCs, hocDisplayNames =
					separateDisplayNameAndHOCs(
						displayName,
						type_
					)

				local element = {
					children = {},
					depth = (parentElement :: Element).depth + 1,
					displayName = displayNameWithoutHOCs,
					hocDisplayNames = hocDisplayNames,
					id = id,
					isCollapsed = self._collapseNodesByDefault,
					key = key,
					ownerID = ownerID,
					parentID = (parentElement :: Element).id,
					type = type_,
					weight = 1,
				}

				self._idToElement[id] = element
				table.insert(addedElementIDs, id)
				self:_adjustParentTreeWeight(parentElement, 1)

				if ownerID > 0 then
					local set: Set<number>? = self._ownersMap[ownerID]

					if set == nil then
						set = Set.new()
						self._ownersMap[ownerID] = set
					end

					(set :: Set<number>):add(id)
				end
			end
		elseif operation == TREE_OPERATION_REMOVE then
			local removeLength = operations[i + 1]
			i += 2

			-- ROBLOX deviation: 1-indexing use 1 not 0
			for removeIndex = 1, removeLength do
				local id = operations[i]

				if not self._idToElement[id] then
					error(
						(
							"Cannot remove node %s because no matching node was found in the Store."
						):format(tostring(id))
					)
				end
				i += 1

				local element = self._idToElement[id]
				local children, ownerID, parentID, weight =
					element.children, element.ownerID, element.parentID, element.weight

				if #children > 0 then
					error(
						string.format(
							"Node %s was removed before its children.",
							tostring(id)
						)
					)
				end

				self._idToElement[id] = nil

				local parentElement: Element? = nil

				if parentID == 0 then
					if __DEBUG__ then
						debug_("Remove", string.format("node %s root", tostring(id)))
					end

					self._roots = Array.filter(self._roots, function(rootID)
						return rootID ~= id
					end)

					self._rootIDToRendererID[id] = nil
					self._rootIDToCapabilities[id] = nil

					haveRootsChanged = true
				else
					if __DEBUG__ then
						debug_(
							"Remove",
							string.format(
								"node %s from parent %s",
								tostring(id),
								tostring(parentID)
							)
						)
					end

					parentElement = self._idToElement[parentID]

					if parentElement == nil then
						error(
							(
								"Cannot remove node %s from parent %s because no matching node was found in the Store."
							):format(tostring(id), tostring(parentID))
						)
					end

					local index = Array.indexOf((parentElement :: Element).children, id)
					Array.splice((parentElement :: Element).children, index, 1)
				end

				self:_adjustParentTreeWeight(parentElement, -weight)
				removedElementIDs[id] = parentID
				self._ownersMap[id] = nil

				if ownerID > 0 then
					local set = self._ownersMap[ownerID]
					if set ~= nil then
						(set :: Set<number>)[id] = nil
					end
				end
			end
		elseif operation == TREE_OPERATION_REORDER_CHILDREN then
			local id = operations[i + 1]
			local numChildren = operations[i + 2]

			i = i + 3

			if not self._idToElement[id] then
				error(
					(
						"Cannot reorder children for node %s because no matching node was found in the Store."
					):format(tostring(id))
				)
			end

			local element = self._idToElement[id]
			local children = element.children

			if #children ~= numChildren then
				error("Children cannot be added or removed during a reorder operation.")
			end

			-- ROBLOX deviation: 1-indexing use 1 not 0
			for j = 1, numChildren do
				local childID = operations[i + j - 1]

				children[j] = childID

				if _G.__DEV__ then
					local childElement: Element? = self._idToElement[childID]

					if
						childElement == nil
						or (childElement :: Element).parentID ~= id
					then
						console.error(
							"Children cannot be added or removed during a reorder operation."
						)
					end
				end
			end

			i = i + numChildren

			if _G.__DEBUG__ then
				debug_(
					"Re-order",
					string.format(
						"Node %s children %s",
						tostring(id),
						Array.join(children, ",")
					)
				)
			end
		elseif operation == TREE_OPERATION_UPDATE_TREE_BASE_DURATION then
			-- Base duration updates are only sent while profiling is in progress.
			-- We can ignore them at this point.
			-- The profiler UI uses them lazily in order to generate the tree.
			i += 3
		else
			error("Unsupported Bridge operation " .. tostring(operation))
		end
	end

	self._revision += 1

	if haveRootsChanged then
		local prevSupportsProfiling = self._supportsProfiling

		self._hasOwnerMetadata = false
		self._supportsProfiling = false

		for _, capabilities in self._rootIDToCapabilities do
			local hasOwnerMetadata, supportsProfiling =
				capabilities.hasOwnerMetadata, capabilities.supportsProfiling

			if hasOwnerMetadata then
				self._hasOwnerMetadata = true
			end
			if supportsProfiling then
				self._supportsProfiling = true
			end
		end
		self:emit("roots")

		if self._supportsProfiling ~= prevSupportsProfiling then
			self:emit("supportsProfiling")
		end
	end
	if __DEBUG__ then
		-- ROBLOX deviation: inline require here to work around circular dependency
		local devtoolsUtils = require(script.Parent.utils) :: any
		local printStore = devtoolsUtils.printStore
		console.log(printStore(self, true))
		console.groupEnd()
	end

	self:emit("mutated", { addedElementIDs, removedElementIDs })
end

function Store:onBridgeOverrideComponentFilters(
	componentFilters: Array<ComponentFilter>
): ()
	self._componentFilters = componentFilters

	saveComponentFilters(componentFilters)
end

function Store:onBridgeShutdown(): ()
	if __DEBUG__ then
		debug_("onBridgeShutdown", "unsubscribing from Bridge")
	end

	self._bridge:removeListener("operations", self.onBridgeOperations)
	self._bridge:removeListener("shutdown", self.onBridgeShutdown)
	self._bridge:removeListener(
		"isBackendStorageAPISupported",
		self.onBridgeStorageSupported
	)
end

function Store:onBridgeStorageSupported(isBackendStorageAPISupported: boolean): ()
	self._isBackendStorageAPISupported = isBackendStorageAPISupported
	self:emit("supportsReloadAndProfile")
end

function Store:onBridgeUnsupportedRendererVersion(): ()
	self._unsupportedRendererVersionDetected = true
	self:emit("unsupportedRendererVersionDetected")
end

return Store
