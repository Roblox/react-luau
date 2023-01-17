--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/376d5c1b5aa17724c5fea9412f8fcde14a7b23f1/packages/react/src/ReactCurrentDispatcher.js
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

--[[*
 * Keeps track of the current dispatcher.
]]
local Packages = script.Parent.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Array<T> = LuauPolyfill.Array<T>

-- ROBLOX deviation: we duplicate the Dispatcher type here because upstream has a circular dependency between Shared and Reconciler
local ReactElementType = require(script.Parent.Parent.ReactElementType)
type Source = ReactElementType.Source
local ReactTypes = require(script.Parent.Parent.ReactTypes)
type RefObject = ReactTypes.RefObject
type ReactContext<T> = ReactTypes.ReactContext<T>
-- ROBLOX deviation START: binding support
type ReactBinding<T> = ReactTypes.ReactBinding<T>
type ReactBindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>
-- ROBLOX deviation END: binding support
type MutableSourceVersion = ReactTypes.MutableSourceVersion
type MutableSource<Source> = ReactTypes.MutableSource<Source>
type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<
	Source,
	Snapshot
>
type MutableSourceGetSnapshotFn<Source, Snapshot> = ReactTypes.MutableSourceGetSnapshotFn<
	Source,
	Snapshot
>

type BasicStateAction<S> = ((S) -> S) | S
type Dispatch<A> = (A) -> ()

export type Dispatcher = {
	readContext: <T>(
		context: ReactContext<T>,
		observedBits: nil | number | boolean
	) -> T,
	useState: <S>(initialState: (() -> S) | S) -> (S, Dispatch<BasicStateAction<S>>),
	useReducer: <S, I, A>(
		reducer: (S, A) -> S,
		initialArg: I,
		init: ((I) -> S)?
	) -> (S, Dispatch<A>),
	useContext: <T>(
		context: ReactContext<T>,
		observedBits: nil | number | boolean
	) -> T,
	-- ROBLOX deviation START: TS models this slightly differently, which is needed to have an initially empty ref and clear the ref, and still typecheck
	useRef: <T>(initialValue: T) -> { current: T | nil },
	-- ROBLOX deviation END
	-- ROBLOX deviation START: Bindings are a feature unique to Roact
	useBinding: <T>(initialValue: T) -> (ReactBinding<T>, ReactBindingUpdater<T>),
	-- ROBLOX deviation END
	useEffect: (
		-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
		create: (() -> ()) | (() -> (() -> ())),
		deps: Array<any> | nil
	) -> (),
	useLayoutEffect: (
		-- ROBLOX TODO: Luau needs union type packs for this type to translate idiomatically
		create: (() -> ()) | (() -> (() -> ())),
		deps: Array<any> | nil
	) -> (),
	useCallback: <T>(callback: T, deps: Array<any> | nil) -> T,
	useMemo: <T...>(nextCreate: () -> T..., deps: Array<any> | nil) -> T...,
	useImperativeHandle: <T>(
		ref: { current: T | nil } | ((inst: T | nil) -> any) | nil,
		create: () -> T,
		deps: Array<any> | nil
	) -> (),
	useDebugValue: <T>(value: T, formatterFn: ((value: T) -> any)?) -> (),
	-- ROBLOX TODO: make these non-optional and implement them in the dispatchers
	useDeferredValue: (<T>(value: T) -> T)?,
	useTransition: (() -> ((() -> ()) -> (), boolean))?, -- ROBLOX deviation: Luau doesn't support jagged array types [(() -> ()) -> (), boolean],
	useMutableSource: <Source, Snapshot>(
		source: MutableSource<Source>,
		getSnapshot: MutableSourceGetSnapshotFn<Source, Snapshot>,
		subscribe: MutableSourceSubscribeFn<Source, Snapshot>
	) -> Snapshot,
	useOpaqueIdentifier: () -> any,

	unstable_isNewReconciler: boolean?,
	-- [string]: any,
}

local ReactCurrentDispatcher: { current: nil | Dispatcher } = {
	--[[
		* @internal
		* @type {ReactComponent}
		*/
	]]
	current = nil,
}

return ReactCurrentDispatcher
