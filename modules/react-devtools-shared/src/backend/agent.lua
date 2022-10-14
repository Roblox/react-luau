-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/agent.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
]]

local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Set<T> = LuauPolyfill.Set<T>
local console = LuauPolyfill.console
local JSON = game:GetService("HttpService")
local global = _G
type Function = (...any) -> ...any
type Array<T> = { [number]: T }
type Object = { [string]: any }

local EventEmitter = require(script.Parent.Parent.events)
type EventEmitter<Events> = EventEmitter.EventEmitter<Events>
-- ROBLOX FIXME: need to implement lodash.throttle, pass through for now
-- import throttle from 'lodash.throttle';
local throttle = function(fn: Function, _limit: number): Function
	return fn
end
local constants = require(script.Parent.Parent.constants)
local SESSION_STORAGE_LAST_SELECTION_KEY = constants.SESSION_STORAGE_LAST_SELECTION_KEY
local SESSION_STORAGE_RELOAD_AND_PROFILE_KEY =
	constants.SESSION_STORAGE_RELOAD_AND_PROFILE_KEY
local SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY =
	constants.SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY
local __DEBUG__ = constants.__DEBUG__
local storage = require(script.Parent.Parent.storage)
local sessionStorageGetItem = storage.sessionStorageGetItem
local sessionStorageRemoveItem = storage.sessionStorageRemoveItem
local sessionStorageSetItem = storage.sessionStorageSetItem
-- local Highlighter = require(script.Parent.views.Highlighter)
-- local setupHighlighter = Highlighter.default
-- ROBLOX TODO: stub for now
local setupHighlighter = function(bridge, agent) end
-- local TraceUpdates = require(script.Parent.views.TraceUpdates)
-- local setupTraceUpdates = TraceUpdates.initialize
-- local setTraceUpdatesEnabled = TraceUpdates.toggleEnabled
-- ROBLOX TODO: stub these for now
local setupTraceUpdates = function(agent) end
local setTraceUpdatesEnabled = function(enabled: boolean) end

-- local console = require(script.Parent.console)
-- local patchConsole = console.patch
-- local unpatchConsole = console.unpatch
-- ROBLOX TODO: stub these for now. they're used to force the debugger to break immediately when console.error is called
local patchConsole = function(obj) end
local unpatchConsole = function() end

local Bridge = require(script.Parent.Parent.bridge)
type BackendBridge = Bridge.BackendBridge

local BackendTypes = require(script.Parent.types)
type InstanceAndStyle = BackendTypes.InstanceAndStyle
type NativeType = BackendTypes.NativeType
type OwnersList = BackendTypes.OwnersList
type PathFrame = BackendTypes.PathFrame
type PathMatch = BackendTypes.PathMatch
type RendererID = BackendTypes.RendererID
type RendererInterface = BackendTypes.RendererInterface

local SharedTypes = require(script.Parent.Parent.types)
type ComponentFilter = SharedTypes.ComponentFilter

local debug_ = function(methodName, ...)
	if __DEBUG__ then
		-- ROBLOX deviation: simpler print
		print(methodName, ...)
	end
end

type ElementAndRendererID = { id: number, rendererID: number }

type StoreAsGlobalParams = {
	count: number,
	id: number,
	path: Array<string | number>,
	rendererID: number,
}

type CopyElementParams = {
	id: number,
	path: Array<string | number>,
	rendererID: number,
}

type InspectElementParams = {
	id: number,
	path: Array<string | number>?,
	rendererID: number,
}

type OverrideHookParams = {
	id: number,
	hookID: number,
	path: Array<string | number>,
	rendererID: number,
	wasForwarded: boolean?,
	value: any,
}

type SetInParams = {
	id: number,
	path: Array<string | number>,
	rendererID: number,
	wasForwarded: boolean?,
	value: any,
}

-- ROBLOX deviation: Luau can't do literal enumerations: 'props' | 'hooks' | 'state' | 'context';
type PathType = string

type DeletePathParams = {
	type: PathType,
	hookID: number?,
	id: number,
	path: Array<string | number>,
	rendererID: number,
}

type RenamePathParams = {
	type: PathType,
	hookID: number?,
	id: number,
	oldPath: Array<string | number>,
	newPath: Array<string | number>,
	rendererID: number,
}

type OverrideValueAtPathParams = {
	type: PathType,
	hookID: number?,
	id: number,
	path: Array<string | number>,
	rendererID: number,
	value: any,
}

type OverrideSuspenseParams = { id: number, rendererID: number, forceFallback: boolean }

type PersistedSelection = { rendererID: number, path: Array<PathFrame> }

export type Agent = EventEmitter<{
	hideNativeHighlight: Array<any>,
	showNativeHighlight: Array<NativeType>,
	shutdown: any,
	traceUpdates: Set<NativeType>,
}> & {
	_bridge: BackendBridge,
	_isProfiling: boolean,
	_recordChangeDescriptions: boolean,
	_rendererInterfaces: { [RendererID]: RendererInterface },
	_persistedSelection: PersistedSelection | nil,
	_persistedSelectionMatch: PathMatch | nil,
	_traceUpdatesEnabled: boolean,

	getRendererInterfaces: (self: Agent) -> { [RendererID]: RendererInterface },
	copyElementPath: (self: Agent, copyElementParams: CopyElementParams) -> (),
	deletePath: (self: Agent, deletePathParams: DeletePathParams) -> (),
	getInstanceAndStyle: (
		self: Agent,
		elementAndRendererId: ElementAndRendererID
	) -> InstanceAndStyle | nil,
	getIDForNode: (self: Agent, node: Object) -> number | nil,
	getProfilingData: (self: Agent, rendererIdObject: { rendererID: RendererID }) -> (),
	getProfilingStatus: (self: Agent) -> (),
	getOwnersList: (self: Agent, elementAndRendererID: ElementAndRendererID) -> (),
	inspectElement: (self: Agent, inspectElementParams: InspectElementParams) -> (),
	logElementToConsole: (self: Agent, elementAndRendererID: ElementAndRendererID) -> (),
	overrideSuspense: (self: Agent, overrideSuspenseParams: OverrideSuspenseParams) -> (),
	overrideValueAtPath: (
		self: Agent,
		overrideValueAtPathParams: OverrideValueAtPathParams
	) -> (),
	overrideContext: (self: Agent, setInParams: SetInParams) -> (),
	overrideHookState: (self: Agent, overrideHookParams: OverrideHookParams) -> (),
	overrideProps: (self: Agent, setInParams: SetInParams) -> (),
	overrideState: (self: Agent, setInParams: SetInParams) -> (),
	reloadAndProfile: (self: Agent, recordChangeDescriptions: boolean) -> (),
	renamePath: (self: Agent, renamePathParams: RenamePathParams) -> (),
	selectNode: (self: Agent, target: Object) -> (),
	setRendererInterface: (
		self: Agent,
		rendererID: number,
		rendererInterface: RendererInterface
	) -> (),
	setTraceUpdatesEnabled: (self: Agent, traceUpdatesEnabled: boolean) -> (),
	syncSelectionFromNativeElementsPanel: (self: Agent) -> (),
	shutdown: (self: Agent) -> (),
	startProfiling: (self: Agent, recordChangeDescriptions: boolean) -> (),
	stopProfiling: (self: Agent) -> (),
	storeAsGlobal: (self: Agent, storeAsGlobalParams: StoreAsGlobalParams) -> (),
	updateConsolePatchSettings: (
		self: Agent,
		_ref16: { appendComponentStack: boolean, breakOnConsoleErrors: boolean }
	) -> (),
	updateComponentFilters: (self: Agent, componentFilters: Array<ComponentFilter>) -> (),
	viewAttributeSource: (self: Agent, copyElementParams: CopyElementParams) -> (),
	viewElementSource: (self: Agent, elementAndRendererID: ElementAndRendererID) -> (),
	onTraceUpdates: (self: Agent, nodes: Set<NativeType>) -> (),
	onHookOperations: (self: Agent, operations: Array<number>) -> (),
	onUnsupportedRenderer: (self: Agent, rendererID: number) -> (),

	_throttledPersistSelection: (self: Agent, rendererID: number, id: number) -> (),
}

type Agent_Statics = {
	new: (bridge: BackendBridge) -> Agent,
}

local Agent: Agent & Agent_Statics = setmetatable({}, { __index = EventEmitter }) :: any

local AgentMetatable = { __index = Agent }
-- ROBLOX deviation: equivalent of sub-class

function Agent.new(bridge: BackendBridge)
	local self = setmetatable(EventEmitter.new() :: any, AgentMetatable)

	-- ROBLOX deviation: define fields in constructor
	self._bridge = bridge
	self._isProfiling = false
	self._recordChangeDescriptions = false
	self._rendererInterfaces = {}
	self._persistedSelection = nil
	self._persistedSelectionMatch = nil
	self._traceUpdatesEnabled = false

	if sessionStorageGetItem(SESSION_STORAGE_RELOAD_AND_PROFILE_KEY) == "true" then
		self._recordChangeDescriptions = sessionStorageGetItem(
			SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY
		) == "true"
		self._isProfiling = true

		sessionStorageRemoveItem(SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY)
		sessionStorageRemoveItem(SESSION_STORAGE_RELOAD_AND_PROFILE_KEY)
	end

	local persistedSelectionString = sessionStorageGetItem(
		SESSION_STORAGE_LAST_SELECTION_KEY
	)

	if persistedSelectionString ~= nil then
		self._persistedSelection = JSON.JSONDecode(persistedSelectionString)
	end

	local function wrapSelf(method: Function)
		return function(...)
			method(self, ...)
		end
	end

	bridge:addListener("copyElementPath", wrapSelf(self.copyElementPath))
	bridge:addListener("deletePath", wrapSelf(self.deletePath))
	bridge:addListener("getProfilingData", wrapSelf(self.getProfilingData))
	bridge:addListener("getProfilingStatus", wrapSelf(self.getProfilingStatus))
	bridge:addListener("getOwnersList", wrapSelf(self.getOwnersList))
	bridge:addListener("inspectElement", wrapSelf(self.inspectElement))
	bridge:addListener("logElementToConsole", wrapSelf(self.logElementToConsole))
	bridge:addListener("overrideSuspense", wrapSelf(self.overrideSuspense))
	bridge:addListener("overrideValueAtPath", wrapSelf(self.overrideValueAtPath))
	bridge:addListener("reloadAndProfile", wrapSelf(self.reloadAndProfile))
	bridge:addListener("renamePath", wrapSelf(self.renamePath))
	bridge:addListener("setTraceUpdatesEnabled", wrapSelf(self.setTraceUpdatesEnabled))
	bridge:addListener("startProfiling", wrapSelf(self.startProfiling))
	bridge:addListener("stopProfiling", wrapSelf(self.stopProfiling))
	bridge:addListener("storeAsGlobal", wrapSelf(self.storeAsGlobal))
	bridge:addListener(
		"syncSelectionFromNativeElementsPanel",
		wrapSelf(self.syncSelectionFromNativeElementsPanel)
	)
	bridge:addListener("shutdown", wrapSelf(self.shutdown))
	bridge:addListener(
		"updateConsolePatchSettings",
		wrapSelf(self.updateConsolePatchSettings)
	)
	bridge:addListener("updateComponentFilters", wrapSelf(self.updateComponentFilters))
	bridge:addListener("viewAttributeSource", wrapSelf(self.viewAttributeSource))
	bridge:addListener("viewElementSource", wrapSelf(self.viewElementSource))

	-- Temporarily support older standalone front-ends sending commands to newer embedded backends.
	-- We do this because React Native embeds the React DevTools backend,
	-- but cannot control which version of the frontend users use.
	bridge:addListener("overrideContext", wrapSelf(self.overrideContext))
	bridge:addListener("overrideHookState", wrapSelf(self.overrideHookState))
	bridge:addListener("overrideProps", wrapSelf(self.overrideProps))
	bridge:addListener("overrideState", wrapSelf(self.overrideState))

	if self._isProfiling then
		bridge:send("profilingStatus", true)
	end

	-- Notify the frontend if the backend supports the Storage API (e.g. localStorage).
	-- If not, features like reload-and-profile will not work correctly and must be disabled.
	-- ROBLOX deviation: Storage is supported, but we don't use localStorage per se
	local isBackendStorageAPISupported = true

	bridge:send("isBackendStorageAPISupported", isBackendStorageAPISupported)
	-- ROBLOX TODO: implement Highlighter stub
	setupHighlighter(bridge, self)
	setupTraceUpdates(self)

	return self
end

-- ROBLOX FIXME: this needs to be a property getter via an __index override
function Agent:getRendererInterfaces()
	return self._rendererInterfaces
end

function Agent:copyElementPath(copyElementParams: CopyElementParams): ()
	local id, path, rendererID =
		copyElementParams.id, copyElementParams.path, copyElementParams.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).copyElementPath(id, path)
	end
end
function Agent:deletePath(deletePathParams: DeletePathParams): ()
	local hookID, id, path, rendererID, type_ =
		deletePathParams.hookID,
		deletePathParams.id,
		deletePathParams.path,
		deletePathParams.rendererID,
		deletePathParams.type
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).deletePath(type_, id, hookID, path)
	end
end
function Agent:getInstanceAndStyle(
	elementAndRendererId: ElementAndRendererID
): InstanceAndStyle | nil
	local id, rendererID = elementAndRendererId.id, elementAndRendererId.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(string.format('Invalid renderer id "%d"', rendererID))
		return nil
	end

	return (renderer :: RendererInterface).getInstanceAndStyle(id)
end

function Agent:getIDForNode(node: Object): number | nil
	for _rendererID, renderer in self._rendererInterfaces do
		local ok, result = pcall(renderer.getFiberIDForNative, node, true)
		if ok and result ~= nil then
			return result
		end
		-- Some old React versions might throw if they can't find a match.
		-- If so we should ignore it...
	end
	return nil
end
function Agent:getProfilingData(rendererIdObject: { rendererID: RendererID }): ()
	local rendererID = rendererIdObject.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(string.format('Invalid renderer id "%d"', rendererID))
	end

	self._bridge:send("profilingData", (renderer :: RendererInterface).getProfilingData())
end
function Agent:getProfilingStatus()
	self._bridge:send("profilingStatus", self._isProfiling)
end
function Agent:getOwnersList(elementAndRendererID: ElementAndRendererID)
	local id, rendererID = elementAndRendererID.id, elementAndRendererID.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		local owners = (renderer :: RendererInterface).getOwnersList(id)

		self._bridge:send("ownersList", {
			id = id,
			owners = owners,
		})
	end
end
function Agent:inspectElement(inspectElementParams: InspectElementParams)
	local id, path, rendererID =
		inspectElementParams.id,
		inspectElementParams.path,
		inspectElementParams.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		self._bridge:send(
			"inspectedElement",
			(renderer :: RendererInterface).inspectElement(id, path)
		)

		-- When user selects an element, stop trying to restore the selection,
		-- and instead remember the current selection for the next reload.
		if
			(self._persistedSelectionMatch :: PathMatch?) == nil
			or (self._persistedSelectionMatch :: PathMatch).id ~= id
		then
			self._persistedSelection = nil
			self._persistedSelectionMatch = nil;

			(renderer :: RendererInterface).setTrackedPath(nil)
			self:_throttledPersistSelection(rendererID, id)
		end

		-- TODO: If there was a way to change the selected DOM element
		-- in native Elements tab without forcing a switch to it, we'd do it here.
		-- For now, it doesn't seem like there is a way to do that:
		-- https://github.com/bvaughn/react-devtools-experimental/issues/102
		-- (Setting $0 doesn't work, and calling inspect() switches the tab.)
	end
end
function Agent:logElementToConsole(elementAndRendererID: ElementAndRendererID)
	local id, rendererID = elementAndRendererID.id, elementAndRendererID.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).logElementToConsole(id)
	end
end
function Agent:overrideSuspense(overrideSuspenseParams: OverrideSuspenseParams)
	local id, rendererID, forceFallback =
		overrideSuspenseParams.id,
		overrideSuspenseParams.rendererID,
		overrideSuspenseParams.forceFallback
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).overrideSuspense(id, forceFallback)
	end
end
function Agent:overrideValueAtPath(overrideValueAtPathParams: OverrideValueAtPathParams)
	local hookID, id, path, rendererID, type_, value =
		overrideValueAtPathParams.hookID,
		overrideValueAtPathParams.id,
		overrideValueAtPathParams.path,
		overrideValueAtPathParams.rendererID,
		overrideValueAtPathParams.type,
		overrideValueAtPathParams.value
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).overrideValueAtPath(
			type_,
			id,
			hookID,
			path,
			value
		)
	end
end

-- Temporarily support older standalone front-ends by forwarding the older message types
-- to the new "overrideValueAtPath" command the backend is now listening to.
function Agent:overrideContext(setInParams: SetInParams)
	local id, path, rendererID, wasForwarded, value =
		setInParams.id,
		setInParams.path,
		setInParams.rendererID,
		setInParams.wasForwarded,
		setInParams.value

	-- Don't forward a message that's already been forwarded by the front-end Bridge.
	-- We only need to process the override command once!
	if not wasForwarded then
		self:overrideValueAtPath({
			id = id,
			path = path,
			rendererID = rendererID,
			type = "context",
			value = value,
		})
	end
end

-- Temporarily support older standalone front-ends by forwarding the older message types
-- to the new "overrideValueAtPath" command the backend is now listening to.
function Agent:overrideHookState(overrideHookParams: OverrideHookParams)
	local id, _hookID, path, rendererID, wasForwarded, value =
		overrideHookParams.id,
		overrideHookParams.hookID,
		overrideHookParams.path,
		overrideHookParams.rendererID,
		overrideHookParams.wasForwarded,
		overrideHookParams.value

	-- Don't forward a message that's already been forwarded by the front-end Bridge.
	-- We only need to process the override command once!
	if not wasForwarded then
		self:overrideValueAtPath({
			id = id,
			path = path,
			rendererID = rendererID,
			type = "hooks",
			value = value,
		})
	end
end

-- Temporarily support older standalone front-ends by forwarding the older message types
-- to the new "overrideValueAtPath" command the backend is now listening to.
function Agent:overrideProps(setInParams: SetInParams)
	local id, path, rendererID, wasForwarded, value =
		setInParams.id,
		setInParams.path,
		setInParams.rendererID,
		setInParams.wasForwarded,
		setInParams.value

	-- Don't forward a message that's already been forwarded by the front-end Bridge.
	-- We only need to process the override command once!
	if not wasForwarded then
		self:overrideValueAtPath({
			id = id,
			path = path,
			rendererID = rendererID,
			type = "props",
			value = value,
		})
	end
end

-- Temporarily support older standalone front-ends by forwarding the older message types
-- to the new "overrideValueAtPath" command the backend is now listening to.
function Agent:overrideState(setInParams: SetInParams)
	local id, path, rendererID, wasForwarded, value =
		setInParams.id,
		setInParams.path,
		setInParams.rendererID,
		setInParams.wasForwarded,
		setInParams.value

	-- Don't forward a message that's already been forwarded by the front-end Bridge.
	-- We only need to process the override command once!
	if not wasForwarded then
		self:overrideValueAtPath({
			id = id,
			path = path,
			rendererID = rendererID,
			type = "state",
			value = value,
		})
	end
end
function Agent:reloadAndProfile(recordChangeDescriptions: boolean)
	sessionStorageSetItem(SESSION_STORAGE_RELOAD_AND_PROFILE_KEY, "true")
	sessionStorageSetItem(
		SESSION_STORAGE_RECORD_CHANGE_DESCRIPTIONS_KEY,
		(function()
			if recordChangeDescriptions then
				return "true"
			end

			return "false"
		end)()
	)

	-- This code path should only be hit if the shell has explicitly told the Store that it supports profiling.
	-- In that case, the shell must also listen for this specific message to know when it needs to reload the app.
	-- The agent can't do this in a way that is renderer agnostic.
	self._bridge:send("reloadAppForProfiling")
end
function Agent:renamePath(renamePathParams: RenamePathParams)
	local hookID, id, newPath, oldPath, rendererID, type_ =
		renamePathParams.hookID,
		renamePathParams.id,
		renamePathParams.newPath,
		renamePathParams.oldPath,
		renamePathParams.rendererID,
		renamePathParams.type
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).renamePath(type_, id, hookID, oldPath, newPath)
	end
end
function Agent:selectNode(target: Object): ()
	local id = self:getIDForNode(target)

	if id ~= nil then
		self._bridge:send("selectFiber", id)
	end
end
function Agent:setRendererInterface(
	rendererID: number,
	rendererInterface: RendererInterface
)
	self._rendererInterfaces[rendererID] = rendererInterface

	if self._isProfiling then
		rendererInterface.startProfiling(self._recordChangeDescriptions)
	end

	rendererInterface.setTraceUpdatesEnabled(self._traceUpdatesEnabled)

	-- When the renderer is attached, we need to tell it whether
	-- we remember the previous selection that we'd like to restore.
	-- It'll start tracking mounts for matches to the last selection path.
	local selection: PersistedSelection? = self._persistedSelection

	if
		selection ~= nil
		and (selection :: PersistedSelection).rendererID == rendererID
	then
		rendererInterface.setTrackedPath((selection :: PersistedSelection).path)
	end
end
function Agent:setTraceUpdatesEnabled(traceUpdatesEnabled: boolean)
	self._traceUpdatesEnabled = traceUpdatesEnabled

	setTraceUpdatesEnabled(traceUpdatesEnabled)

	for _rendererID, renderer in self._rendererInterfaces do
		renderer.setTraceUpdatesEnabled(traceUpdatesEnabled)
	end
end
function Agent:syncSelectionFromNativeElementsPanel()
	local target = global.__REACT_DEVTOOLS_GLOBAL_HOOK__["$0"]

	if target == nil then
		return
	end

	self:selectNode(target)
end
function Agent:shutdown()
	-- Clean up the overlay if visible, and associated events.
	self:emit("shutdown")
end
function Agent:startProfiling(recordChangeDescriptions: boolean)
	self._recordChangeDescriptions = recordChangeDescriptions
	self._isProfiling = true

	for _rendererID, renderer in self._rendererInterfaces do
		renderer.startProfiling(recordChangeDescriptions)
	end

	self._bridge:send("profilingStatus", self._isProfiling)
end
function Agent:stopProfiling()
	self._isProfiling = false
	self._recordChangeDescriptions = false

	for _rendererID, renderer in self._rendererInterfaces do
		renderer.stopProfiling()
	end

	self._bridge:send("profilingStatus", self._isProfiling)
end

function Agent:storeAsGlobal(storeAsGlobalParams: StoreAsGlobalParams)
	local count, id, path, rendererID =
		storeAsGlobalParams.count,
		storeAsGlobalParams.id,
		storeAsGlobalParams.path,
		storeAsGlobalParams.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).storeAsGlobal(id, path, count)
	end
end

function Agent:updateConsolePatchSettings(
	_ref16: {
		appendComponentStack: boolean,
		breakOnConsoleErrors: boolean,
	}
)
	local appendComponentStack, breakOnConsoleErrors =
		_ref16.appendComponentStack, _ref16.breakOnConsoleErrors

	-- If the frontend preference has change,
	-- or in the case of React Native- if the backend is just finding out the preference-
	-- then install or uninstall the console overrides.
	-- It's safe to call these methods multiple times, so we don't need to worry about that.
	if appendComponentStack or breakOnConsoleErrors then
		patchConsole({
			appendComponentStack = appendComponentStack,
			breakOnConsoleErrors = breakOnConsoleErrors,
		})
	else
		unpatchConsole()
	end
end
function Agent:updateComponentFilters(componentFilters: Array<ComponentFilter>)
	for _rendererID, renderer in self._rendererInterfaces do
		renderer.updateComponentFilters(componentFilters)
	end
end
function Agent:viewAttributeSource(copyElementParams: CopyElementParams)
	local id, path, rendererID =
		copyElementParams.id, copyElementParams.path, copyElementParams.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).prepareViewAttributeSource(id, path)
	end
end
function Agent:viewElementSource(elementAndRendererID: ElementAndRendererID)
	local id, rendererID = elementAndRendererID.id, elementAndRendererID.rendererID
	local renderer = self._rendererInterfaces[rendererID]

	if renderer == nil then
		console.warn(
			string.format('Invalid renderer id "%d" for element "%d"', rendererID, id)
		)
	else
		(renderer :: RendererInterface).prepareViewElementSource(id)
	end
end
function Agent:onTraceUpdates(nodes: Set<NativeType>)
	self:emit("traceUpdates", nodes)
end
function Agent:onHookOperations(operations: Array<number>)
	if global.__DEBUG__ then
		debug_("onHookOperations", operations)
	end

	-- TODO:
	-- The chrome.runtime does not currently support transferables; it forces JSON serialization.
	-- See bug https://bugs.chromium.org/p/chromium/issues/detail?id=927134
	--
	-- Regarding transferables, the postMessage doc states:
	-- If the ownership of an object is transferred, it becomes unusable (neutered)
	-- in the context it was sent from and becomes available only to the worker it was sent to.
	--
	-- Even though Chrome is eventually JSON serializing the array buffer,
	-- using the transferable approach also sometimes causes it to throw:
	--   DOMException: Failed to execute 'postMessage' on 'Window': ArrayBuffer at index 0 is already neutered.
	--
	-- See bug https://github.com/bvaughn/react-devtools-experimental/issues/25
	--
	-- The Store has a fallback in place that parses the message as JSON if the type isn't an array.
	-- For now the simplest fix seems to be to not transfer the array.
	-- This will negatively impact performance on Firefox so it's unfortunate,
	-- but until we're able to fix the Chrome error mentioned above, it seems necessary.
	--
	self._bridge:send("operations", operations)

	if self._persistedSelection ~= nil then
		local rendererID = operations[1]

		if (self._persistedSelection :: PersistedSelection).rendererID == rendererID then
			-- Check if we can select a deeper match for the persisted selection.
			local renderer = self._rendererInterfaces[rendererID]

			if renderer == nil then
				console.warn(string.format('Invalid renderer id "%d"', rendererID))
			else
				local prevMatch = self._persistedSelectionMatch
				local nextMatch =
					(renderer :: RendererInterface).getBestMatchForTrackedPath()

				self._persistedSelectionMatch = nextMatch

				local prevMatchID = if prevMatch ~= nil then prevMatch.id else nil
				local nextMatchID = if nextMatch ~= nil then nextMatch.id else nil

				if prevMatchID ~= nextMatchID then
					if nextMatchID ~= nil then
						-- We moved forward, unlocking a deeper node.
						self._bridge:send("selectFiber", nextMatchID)
					end
				end
				if nextMatch ~= nil and (nextMatch :: PathMatch).isFullMatch then
					-- We've just unlocked the innermost selected node.
					-- There's no point tracking it further.
					self._persistedSelection = nil
					self._persistedSelectionMatch = nil;

					(renderer :: RendererInterface).setTrackedPath(nil)
				end
			end
		end
	end
end

function Agent:onUnsupportedRenderer(rendererID: number)
	self._bridge:send("unsupportedRendererVersion", rendererID)
end

Agent._throttledPersistSelection = throttle(function(self, rendererID: number, id: number)
	-- This is throttled, so both renderer and selected ID
	-- might not be available by the time we read them.
	-- This is why we need the defensive checks here.
	local renderer = self._rendererInterfaces[rendererID]
	local path = (function()
		if renderer ~= nil then
			return (renderer :: RendererInterface).getPathForElement(id)
		end

		return nil
	end)()

	if path ~= nil then
		sessionStorageSetItem(
			SESSION_STORAGE_LAST_SELECTION_KEY,
			JSON:JSONEncode({
				rendererID = rendererID,
				path = path,
			})
		)
	else
		sessionStorageRemoveItem(SESSION_STORAGE_LAST_SELECTION_KEY)
	end
end, 1000)

return Agent
