--!strict
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
type Array<T> = LuauPolyfill.Array<T>
type Object = LuauPolyfill.Object
type void = nil
type NonMaybeType<T> = T

local flowtypes = require(script.Parent["flowtypes.roblox"])
type React_Element<T> = flowtypes.React_Element<T>
type React_Node = flowtypes.React_Node
type SimpleMap<K, V> = { [K]: V }
type Iterable<T> = SimpleMap<string | number, T> | Array<T>

export type ReactNode<T = any> =
	React_Element<T>
	| ReactPortal
	-- | ReactText
	| ReactFragment
	| ReactProvider<T>
	| ReactConsumer<T>

export type ReactEmpty = nil | void | boolean

export type ReactFragment = ReactEmpty | Iterable<React_Node>

export type ReactNodeList = ReactEmpty | React_Node

-- ROBLOX deviation START: Roblox renderer doesn't support TextNode, only use of this type is in this file
-- export type ReactText = string | number;
-- ROBLOX deviation END
export type ReactProvider<T> = {
	["$$typeof"]: number,
	type: ReactProviderType<T>,
	key: nil | string,
	ref: nil,
	props: {
		value: T,
		children: ReactNodeList?,
		-- ROBLOX deviation START: only make this open to extension if absolutely necessary
		-- ...
		-- ROBLOX deviation END
	},
	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END
}

export type ReactProviderType<T> = {
	["$$typeof"]: number,
	_context: ReactContext<T>,
	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END
}

export type ReactConsumer<T> = {
	["$$typeof"]: number,
	type: ReactContext<T>, -- ROBLOX FIXME: Luau can't do <T> because:  Recursive type being used with different parameters
	key: nil | string,
	ref: nil,
	props: {
		children: (value: T) -> ReactNodeList,
		unstable_observedBits: number?,
		-- ROBLOX deviation START: only make this open to extension if absolutely necessary
		-- ...
		-- ROBLOX deviation END
	},
	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END
}

export type ReactContext<T> = {
	["$$typeof"]: number,
	Consumer: ReactContext<T>,
	Provider: ReactProviderType<T>,
	_calculateChangedBits: ((T, T) -> number)?,
	_currentValue: T,
	_currentValue2: T,
	_threadCount: number,
	-- DEV only
	_currentRenderer: Object | nil,
	_currentRenderer2: Object | nil,
	-- This value may be added by application code
	-- to improve DEV tooling display names
	displayName: string?,
	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END
}

export type ReactPortal = {
	["$$typeof"]: number,
	key: nil | string,
	containerInfo: any,
	children: ReactNodeList,
	-- TODO: figure out the API for cross-renderer implementation.
	implementation: any,
	-- ROBLOX deviation START: only make this open to extension if absolutely necessary
	-- ...
	-- ROBLOX deviation END
}

export type RefObject = { current: any }

-- ROBLOX deviation START: No Luau support for numeric literal types
-- export type EventPriority = 0 | 1 | 2;
export type EventPriority = number
-- ROBLOX deviation END

local exports = {}
exports.DiscreteEvent = 0
exports.UserBlockingEvent = 1
exports.ContinuousEvent = 2

export type ReactFundamentalComponentInstance<C, H> = {
	currentFiber: Object,
	instance: any,
	prevProps: Object?,
	props: Object,
	impl: ReactFundamentalImpl<C, H>,
	state: Object,
}

export type ReactFundamentalImpl<C, H> = {
	displayName: string,
	reconcileChildren: boolean,
	getInitialState: nil | (Object) -> (Object),
	getInstance: (C, Object, Object) -> (H),
	getServerSideString: nil | (C, Object) -> (string),
	getServerSideStringClose: nil | (C, Object) -> (string),
	onMount: (C, any, Object, Object) -> (),
	shouldUpdate: nil | (C, Object?, Object, Object) -> (boolean),
	onUpdate: nil | (C, any, Object?, Object, Object) -> (),
	onUnmount: nil | (C, any, Object, Object) -> (),
	onHydrate: nil | (C, Object, Object) -> boolean,
	onFocus: nil | (C, Object, Object) -> boolean,
}
export type ReactFundamentalComponent<C, H> = {
	["$$typeof"]: number,
	impl: ReactFundamentalImpl<C, H>,
}

export type ReactScope = {
	["$$typeof"]: number,
}

export type ReactScopeQuery = (
	type: string,
	-- ROBLOX deviation START: leave closed to extension unless necessary
	props: { [string]: any? },
	-- ROBLOX deviation END
	instance: any
) -> boolean

export type ReactScopeInstance = {
	DO_NOT_USE_queryAllNodes: (ReactScopeQuery) -> nil | Array<Object>,
	DO_NOT_USE_queryFirstNode: (ReactScopeQuery) -> nil | Object,
	containsNode: (Object) -> boolean,
	getChildContextValues: <T>(context: ReactContext<T>) -> Array<T>,
}

-- ROBLOX deviation START: Bindings are unique to Roact
-- FIXME Luau: can't create recursive type with different parameters, so we
-- need to split the generic `map` method into a different type and then
-- re-combine those types together
type CoreReactBinding<T> = {
	getValue: (self: CoreReactBinding<T>) -> T,
	_source: string?,
}
type ReactBindingMap = {
	map: <T, U>(
		self: CoreReactBinding<T> & ReactBindingMap,
		(T) -> U
	) -> ReactBindingMap & CoreReactBinding<U>,
}

export type ReactBinding<T> = CoreReactBinding<T> & ReactBindingMap
export type ReactBindingUpdater<T> = (T) -> ()
-- ROBLOX deviation END

-- Mutable source version can be anything (e.g. number, string, immutable data structure)
-- so long as it changes every time any part of the source changes.
export type MutableSourceVersion = NonMaybeType<any>

export type MutableSourceGetSnapshotFn<Source, Snapshot> = (source: Source) -> Snapshot

export type MutableSourceSubscribeFn<Source, Snapshot> = (
	source: Source,
	callback: (snapshot: Snapshot) -> ()
) -> (() -> ())

export type MutableSourceGetVersionFn = (
	_source: NonMaybeType<any>
) -> MutableSourceVersion

export type MutableSource<Source> = {
	_source: Source,

	_getVersion: MutableSourceGetVersionFn,

	-- Tracks the version of this source at the time it was most recently read.
	-- Used to determine if a source is safe to read from before it has been subscribed to.
	-- Version number is only used during mount,
	-- since the mechanism for determining safety after subscription is expiration time.
	--
	-- As a workaround to support multiple concurrent renderers,
	-- we categorize some renderers as primary and others as secondary.
	-- We only expect there to be two concurrent renderers at most:
	-- React Native (primary) and Fabric (secondary);
	-- React DOM (primary) and React ART (secondary).
	-- Secondary renderers store their context values on separate fields.
	-- We use the same approach for Context.
	_workInProgressVersionPrimary: nil | MutableSourceVersion,
	_workInProgressVersionSecondary: nil | MutableSourceVersion,

	-- DEV only
	-- Used to detect multiple renderers using the same mutable source.
	_currentPrimaryRenderer: Object | nil,
	_currentSecondaryRenderer: Object | nil,
}

-- The subset of a Thenable required by things thrown by Suspense.
-- This doesn't require a value to be passed to either handler.
export type Wakeable = {
	andThen: (
		self: Wakeable,
		onFulfill: () -> ...any,
		onReject: () -> ...any
		-- ROBLOX FIXME Luau: needs union type packs to parse () | Wakeable
	) -> nil | Wakeable,
	-- Special flag to opt out of tracing interactions across a Suspense boundary.
	__reactDoNotTraceInteractions: boolean?,
}

-- The subset of a Promise that React APIs rely on. This resolves a value.
-- This doesn't require a return value neither from the handler nor the
-- then function.
-- ROBLOX FIXME: workaround for Luau recursive type used with different parameters. delete this copy once that issue is resolved.
export type _Thenable<R> = {
	andThen: <U>(
		self: _Thenable<R>,
		onFulfill: (R) -> ...U,
		onReject: (error: any) -> ...U
	) -> (),
}

export type Thenable<R> = {
	andThen: <U>(
		self: Thenable<R>,
		onFulfill: (R) -> ...(_Thenable<U> | U),
		onReject: (error: any) -> ...(_Thenable<U> | U)
		-- ROBLOX FIXME Luau: need union type packs to parse () | Thenable<U>: CLI-49836
	) -> nil | _Thenable<U>,
}

return exports
