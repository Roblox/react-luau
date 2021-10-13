--!strict
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- deviation: Common types
type Array<T> = { [number]: T }
type Object = { [string]: any }

-- deviation: disabled flow types
-- export type ReactNode =
--   | React$Element<any>
--   | ReactPortal
--   | ReactText
--   | ReactFragment
--   | ReactProvider<any>
--   | ReactConsumer<any>;

-- ROBLOX deviation: alias for internal React$ flow types
export type React_Node =
	nil
	| boolean
	| number
	| string
	| React_Element<any>
	| React_Portal
	| Array<React_Node?>
export type React_Element<ElementType> = {
	type: ElementType,
	props: any?, -- ROBLOX TODO: can't find this definition React_ElementProps<ElementType>,
	key: React_Key | nil,
	ref: any,
}
export type React_Portal = any
export type React_Key = string | number


export type ReactEmpty = boolean?

-- deviation: No `Iterable` equivalent other than an array
export type ReactFragment = ReactEmpty | Array<React_Node>

export type ReactNodeList = ReactEmpty | React_Node

-- export type ReactText = string | number;

export type ReactProvider<T> = {
	-- ROBLOX TODO: remove [string] once we can express ["$$typeof"] as a type key
	-- $$typeof: Symbol | number,
	[string]: number,
	type: ReactProviderType<T>,
	key: nil | string,
	ref: nil,
	props: {
		value: T,
		children: ReactNodeList?,
		-- ...
	},
	-- ...
}

export type ReactProviderType<T> = {
	-- ROBLOX TODO: remove [string] once we can express ["$$typeof"] as a type key
	-- $$typeof: Symbol | number,
	[string]: number,
	_context: ReactContext<T>,
	-- ...
}

export type ReactConsumer<T> = {
	-- ROBLOX TODO: remove [string] once we can express ["$$typeof"] as a type key
	-- $$typeof: Symbol | number,
	[string]: number,
	type: ReactContext<T>,
	key: nil | string,
	ref: nil,
	props: {
		children: (value: T) -> ReactNodeList,
		unstable_observedBits: number?,
		-- ...
	},
  -- ...
}

export type ReactContext<T> = {
	-- ROBLOX TODO: remove [string] once we can express ["$$typeof"] as a type key
	-- $$typeof: Symbol | number,
	[string]: number,
	Consumer: ReactContext<T>,
	Provider: ReactProviderType<T>,
	_calculateChangedBits: ((T, T) -> number)?,
	_currentValue: T,
	_currentValue2: T,
	_threadCount: number,
	-- DEV only
	_currentRenderer: Object?,
	_currentRenderer2: Object?,
	-- This value may be added by application code
	-- to improve DEV tooling display names
	displayName: string?,
	-- ...
}

export type ReactPortal = {
	-- ROBLOX TODO: remove [string] once we can express ["$$typeof"] as a type key
	-- $$typeof: Symbol | number,
	[string]: number,
	key: string?,
	containerInfo: any,
	children: ReactNodeList,
	-- TODO: figure out the API for cross-renderer implementation.
	implementation: any,
	-- ...
}

export type RefObject = { current: any }

-- deviation: No Luau support for literal types
-- export type EventPriority = 0 | 1 | 2;
export type EventPriority = number

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
	-- ROBLOX TODO: remove [string] once we can express ["$$typeof"] as a type key
	-- $$typeof: Symbol | number,
	[string]: number,
	impl: ReactFundamentalImpl<C, H>,
}

export type ReactScope = {
	-- ROBLOX TODO: remove [string] once we can express ["$$typeof"] as a type key
	-- $$typeof: Symbol | number,
	[string]: number
}

export type ReactScopeQuery = (
	type: string,
	props: { [string]: any? },
	instance: any
) -> boolean

export type ReactScopeInstance = {
	DO_NOT_USE_queryAllNodes: (ReactScopeQuery) -> nil | Array<Object>,
	DO_NOT_USE_queryFirstNode: (ReactScopeQuery) -> nil | Object,
	containsNode: (Object) -> boolean,
	-- ROBLOX FIXME: function generics
	-- getChildContextValues: <T>(context: ReactContext<T>) => Array<T>,
	getChildContextValues: (context: ReactContext<any>) -> Array<any>,
}

-- Mutable source version can be anything (e.g. number, string, immutable data structure)
-- so long as it changes every time any part of the source changes.
-- ROBLOX deviation: we don't have mixed, or a type system that can represent the above
export type MutableSourceVersion = any -- $NonMaybeType<mixed>;

export type MutableSourceGetSnapshotFn<Source, Snapshot> = (
	source: Source
) -> Snapshot

export type MutableSourceSubscribeFn<Source, Snapshot> = (
	source: Source,
	callback: (snapshot: Snapshot) -> ()
) -> (() -> ())

export type MutableSourceGetVersionFn = (_source: any) -> MutableSourceVersion

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

-- -- The subset of a Thenable required by things thrown by Suspense.
-- -- This doesn't require a value to be passed to either handler.
export type Wakeable = {
	andThen: (
		self: Wakeable,
		onFulfill: () -> ...any,
		onReject: () -> ...any
	) -> Wakeable?,
	-- Special flag to opt out of tracing interactions across a Suspense boundary.
	__reactDoNotTraceInteractions: boolean?,
	-- [any]: any,
}

-- ROBLOX TODO: function generics
-- type system
-- -- The subset of a Promise that React APIs rely on. This resolves a value.
-- -- This doesn't require a return value neither from the handler nor the
-- -- then function.
-- export interface Thenable<+R> {
--   then<U>(
-- 	onFulfill: (value: R) => void | Thenable<U> | U,
-- 	onReject: (error: mixed) => void | Thenable<U> | U,
--   ): void | Thenable<U>;
-- }
type _U = any?
-- ROBLOX FIXME: workaround for Luau recursive type used with different parameters. delete this copy once that issue is resolved.
export type _Thenable<R> = {
	andThen: (
		self: _Thenable<R>,
		onFulfill: (R) -> () | any | _U,
		onReject: (error: any) -> () | any | _U
	) -> () | any,
}

export type Thenable<R> = {
	andThen: (
		self: Thenable<R>,
		onFulfill: (R) -> () | _Thenable<_U> | _U,
		onReject: (error: any) -> () | _Thenable<_U> | _U
	) -> () | _Thenable<_U>,
}

return exports
