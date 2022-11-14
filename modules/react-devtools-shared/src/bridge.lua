--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/bridge.js
-- /*
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  */
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
local console = require(Packages.Shared).console
type Array<T> = { [number]: T }
type Function = (...any) -> ...any

local EventEmitter = require(script.Parent.events)
type EventEmitter<T> = EventEmitter.EventEmitter<T>

local Types = require(script.Parent.types)
type ComponentFilter = Types.ComponentFilter
type Wall = Types.Wall
local BackendTypes = require(script.Parent.backend.types)
type InspectedElementPayload = BackendTypes.InspectedElementPayload
type OwnersList = BackendTypes.OwnersList
type ProfilingDataBackend = BackendTypes.ProfilingDataBackend
type RendererID = BackendTypes.RendererID

local BATCH_DURATION = 100

type Message = { event: string, payload: any }

type ElementAndRendererID = { id: number, rendererID: RendererID }

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type HighlightElementInDOM = ElementAndRendererID & {
	displayName: string?,
	hideAfterTimeout: boolean,
	openNativeElementsPanel: boolean,
	scrollIntoView: boolean,
}

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type OverrideValue = ElementAndRendererID & {
	path: Array<string | number>,
	wasForwarded: boolean?,
	value: any,
}

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type OverrideHookState = OverrideValue & { hookID: number }

-- ROBLOX deviation: 'props' | 'hooks' | 'state' | 'context';
type PathType = string

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type DeletePath =
	ElementAndRendererID
	& { type: PathType, hookID: number?, path: Array<string | number> }

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type RenamePath = ElementAndRendererID & {
	type: PathType,
	hookID: number?,
	oldPath: Array<string | number>,
	newPath: Array<string | number>,
}

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type OverrideValueAtPath = ElementAndRendererID & {
	type: PathType,
	hookID: number?,
	path: Array<string | number>,
	value: any,
}

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type OverrideSuspense = ElementAndRendererID & { forceFallback: boolean }

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type CopyElementPathParams = ElementAndRendererID & { path: Array<string | number> }

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type ViewAttributeSourceParams = ElementAndRendererID & { path: Array<string | number> }

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type InspectElementParams = ElementAndRendererID & { path: Array<string | number>? }

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type StoreAsGlobalParams =
	ElementAndRendererID
	& { count: number, path: Array<string | number> }

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type NativeStyleEditor_RenameAttributeParams = ElementAndRendererID & {
	oldName: string,
	newName: string,
	value: string,
}

-- ROBLOX deviation: Luau can't use ...type, use intersection instead
type NativeStyleEditor_SetValueParams =
	ElementAndRendererID
	& { name: string, value: string }

type UpdateConsolePatchSettingsParams = {
	appendComponentStack: boolean,
	breakOnConsoleErrors: boolean,
}

-- ROBLOX deviation: Luau can't define object types in a function type
type IsSupported = { isSupported: boolean, validAttributes: Array<string> }

type BackendEvents = {
	extensionBackendInitialized: () -> (),
	inspectedElement: (InspectedElementPayload) -> (),
	isBackendStorageAPISupported: (boolean) -> (),
	-- ROBLOX deviation: don't binary encode strings
	operations: (Array<number | string>) -> (),
	ownersList: (OwnersList) -> (),
	overrideComponentFilters: (Array<ComponentFilter>) -> (),
	profilingData: (ProfilingDataBackend) -> (),
	profilingStatus: (boolean) -> (),
	reloadAppForProfiling: () -> (),
	selectFiber: (number) -> (),
	shutdown: () -> (),
	stopInspectingNative: (boolean) -> (),
	syncSelectionFromNativeElementsPanel: () -> (),
	syncSelectionToNativeElementsPanel: () -> (),
	unsupportedRendererVersion: (RendererID) -> (),

	-- React Native style editor plug-in.
	isNativeStyleEditorSupported: (IsSupported) -> (),
	-- ROBLOX deviation: StyleAndLayoutPayload type not transliterated
	NativeStyleEditor_styleAndLayout: () -> (),
}

type FrontendEvents = {
	clearNativeElementHighlight: () -> (),
	copyElementPath: (CopyElementPathParams) -> (),
	deletePath: (DeletePath) -> (),
	getOwnersList: (ElementAndRendererID) -> (),
	getProfilingData: ({ rendererID: RendererID }) -> (),
	getProfilingStatus: () -> (),
	highlightNativeElement: (HighlightElementInDOM) -> (),
	inspectElement: (InspectElementParams) -> (),
	logElementToConsole: (ElementAndRendererID) -> (),
	overrideSuspense: (OverrideSuspense) -> (),
	overrideValueAtPath: (OverrideValueAtPath) -> (),
	profilingData: (ProfilingDataBackend) -> (),
	reloadAndProfile: (boolean) -> (),
	renamePath: (RenamePath) -> (),
	selectFiber: (number) -> (),
	setTraceUpdatesEnabled: (boolean) -> (),
	shutdown: () -> (),
	startInspectingNative: () -> (),
	startProfiling: (boolean) -> (),
	stopInspectingNative: (boolean) -> (),
	stopProfiling: () -> (),
	storeAsGlobal: (StoreAsGlobalParams) -> (),
	updateComponentFilters: (Array<ComponentFilter>) -> (),
	updateConsolePatchSettings: (UpdateConsolePatchSettingsParams) -> (),
	viewAttributeSource: (ViewAttributeSourceParams) -> (),
	viewElementSource: (ElementAndRendererID) -> (),

	-- React Native style editor plug-in.
	NativeStyleEditor_measure: (ElementAndRendererID) -> (),
	NativeStyleEditor_renameAttribute: (NativeStyleEditor_RenameAttributeParams) -> (),
	NativeStyleEditor_setValue: (NativeStyleEditor_SetValueParams) -> (),

	-- Temporarily support newer standalone front-ends sending commands to older embedded backends.
	-- We do this because React Native embeds the React DevTools backend,
	-- but cannot control which version of the frontend users use.
	--
	-- Note that nothing in the newer backend actually listens to these events,
	-- but the new frontend still dispatches them (in case older backends are listening to them instead).
	--
	-- Note that this approach does no support the combination of a newer backend with an older frontend.
	-- It would be more work to suppot both approaches (and not run handlers twice)
	-- so I chose to support the more likely/common scenario (and the one more difficult for an end user to "fix").
	overrideContext: (OverrideValue) -> (),
	overrideHookState: (OverrideHookState) -> (),
	overrideProps: (OverrideValue) -> (),
	overrideState: (OverrideValue) -> (),
}

-- ROBLOX deviation: Luau can't spread keys of a type as string
type EventName = string -- $Keys<OutgoingEvents>
-- ROBLOX deviation: Luau can't express
-- type $ElementType<T, K extends keyof T> = T[K];
type ElementType<T, U> = any

export type Bridge<
	OutgoingEvents,
	IncomingEvents -- ROBLOX deviation: Luau can't express	-- > extends EventEmitter<{|	--   ...IncomingEvents,	--   ...OutgoingEvents,	-- |}> {
> = EventEmitter<any> & {
	_isShutdown: boolean,
	_messageQueue: Array<any>,
	_timeoutID: TimeoutID | nil,
	_wall: Wall,
	_wallUnlisten: Function | nil,
	send: (
		self: Bridge<OutgoingEvents, IncomingEvents>,
		eventName: EventName,
		...ElementType<OutgoingEvents, IncomingEvents>
	) -> (),
	shutdown: (self: Bridge<OutgoingEvents, IncomingEvents>) -> (),
	_flush: (self: Bridge<OutgoingEvents, IncomingEvents>) -> (),
	overrideValueAtPath: (
		self: Bridge<OutgoingEvents, IncomingEvents>,
		_ref: OverrideValueAtPath
	) -> (),
}

type Bridge_Statics = {
	new: (wall: Wall) -> Bridge<any, any>,
}

-- ROBLOX deviation: not sure where TimeoutID comes from in upstream
type TimeoutID = any
local Bridge: Bridge<any, any> & Bridge_Statics = setmetatable(
	{},
	{ __index = EventEmitter }
) :: any
local BridgeMetatable = { __index = Bridge }

function Bridge.new(wall: Wall)
	local self = setmetatable(EventEmitter.new() :: any, BridgeMetatable)

	-- ROBLOX deviation: initializers from class declaration
	self._isShutdown = false
	self._messageQueue = {} :: Array<Array<any>>
	self._timeoutID = nil
	-- _wall
	self._wallUnlisten = nil

	self._wall = wall
	self._wallUnlisten = wall.listen(function(message: Message)
		self:emit(message.event, message.payload)
	end) or nil

	-- Temporarily support older standalone front-ends sending commands to newer embedded backends.
	-- We do this because React Native embeds the React DevTools backend,
	-- but cannot control which version of the frontend users use.
	self:addListener("overrideValueAtPath", self.overrideValueAtPath)

	-- ROBLOX deviation: just expose wall as an instance field, instead of read-only property
	self.wall = wall

	return self
end

function Bridge:send(event: EventName, ...: ElementType<any, EventName>)
	local payload = { ... }
	if self._isShutdown then
		console.warn(
			string.format(
				'Cannot send message "%s" through a Bridge that has been shutdown.',
				event
			)
		)
		return
	end

	-- When we receive a message:
	-- - we add it to our queue of messages to be sent
	-- - if there hasn't been a message recently, we set a timer for 0 ms in
	--   the future, allowing all messages created in the same tick to be sent
	--   together
	-- - if there *has* been a message flushed in the last BATCH_DURATION ms
	--   (or we're waiting for our setTimeout-0 to fire), then _timeoutID will
	--   be set, and we'll simply add to the queue and wait for that
	table.insert(self._messageQueue, event)
	table.insert(self._messageQueue, payload)

	if not self._timeoutID then
		self._timeoutID = LuauPolyfill.setTimeout(function()
			self:_flush()
		end, 0)
	end
end

function Bridge:shutdown()
	if self._isShutdown then
		console.warn("Bridge was already shutdown.")
		return
	end

	-- Queue the shutdown outgoing message for subscribers.
	self:send("shutdown")

	-- Mark this bridge as destroyed, i.e. disable its public API.
	self._isShutdown = true

	-- Disable the API inherited from EventEmitter that can add more listeners and send more messages.
	-- $FlowFixMe This property is not writable.
	self.addListener = function() end
	-- $FlowFixMe This property is not writable.
	self.emit = function() end
	-- NOTE: There's also EventEmitter API like `on` and `prependListener` that we didn't add to our Flow type of EventEmitter.

	-- Unsubscribe this bridge incoming message listeners to be sure, and so they don't have to do that.
	self:removeAllListeners()

	-- Stop accepting and emitting incoming messages from the wall.
	local wallUnlisten = self._wallUnlisten

	if wallUnlisten then
		wallUnlisten()
	end

	-- Synchronously flush all queued outgoing messages.
	-- At this step the subscribers' code may run in this call stack.
	repeat
		self:_flush()
	until #self._messageQueue == 0

	-- Make sure once again that there is no dangling timer.
	if self._timeoutID ~= nil then
		LuauPolyfill.clearTimeout(self._timeoutID)

		self._timeoutID = nil
	end
end

function Bridge:_flush(): ()
	-- This method is used after the bridge is marked as destroyed in shutdown sequence,
	-- so we do not bail out if the bridge marked as destroyed.
	-- It is a private method that the bridge ensures is only called at the right times.

	if self._timeoutID ~= nil then
		LuauPolyfill.clearTimeout(self._timeoutID)

		self._timeoutID = nil
	end
	if #self._messageQueue > 0 then
		-- ROBLOX deviation: Use a while loop instead of for loop to handle new insertions during the loop
		local i = 1
		while i < #self._messageQueue do
			self._wall.send(
				self._messageQueue[i],
				table.unpack(self._messageQueue[i + 1])
			)
			i += 2
		end
		table.clear(self._messageQueue)

		-- Check again for queued messages in BATCH_DURATION ms. This will keep
		-- flushing in a loop as long as messages continue to be added. Once no
		-- more are, the timer expires.
		self._timeoutID = LuauPolyfill.setTimeout(function()
			self:_flush()
		end, BATCH_DURATION)
	end
end

-- Temporarily support older standalone backends by forwarding "overrideValueAtPath" commands
-- to the older message types they may be listening to.
function Bridge:overrideValueAtPath(_ref: OverrideValueAtPath)
	local id, path, rendererID, type_, value =
		_ref.id, _ref.path, _ref.rendererID, _ref.type, _ref.value
	if type_ == "context" then
		self:send("overrideContext", {
			id = id,
			path = path,
			rendererID = rendererID,
			wasForwarded = true,
			value = value,
		})
	elseif type_ == "hooks" then
		self:send("overrideHookState", {
			id = id,
			path = path,
			rendererID = rendererID,
			wasForwarded = true,
			value = value,
		})
	elseif type_ == "props" then
		self:send("overrideProps", {
			id = id,
			path = path,
			rendererID = rendererID,
			wasForwarded = true,
			value = value,
		})
	elseif type_ == "state" then
		self:send("overrideState", {
			id = id,
			path = path,
			rendererID = rendererID,
			wasForwarded = true,
			value = value,
		})
	end
end

export type BackendBridge = Bridge<BackendEvents, FrontendEvents>
export type FrontendBridge = Bridge<FrontendEvents, BackendEvents>

return Bridge
