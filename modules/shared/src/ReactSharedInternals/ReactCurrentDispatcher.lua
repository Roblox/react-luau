--!strict
-- upstream: https://github.com/facebook/react/blob/376d5c1b5aa17724c5fea9412f8fcde14a7b23f1/packages/react/src/ReactCurrentDispatcher.js
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
type MutableSourceVersion = ReactTypes.MutableSourceVersion
type MutableSource<Source> = ReactTypes.MutableSource<Source>
type MutableSourceSubscribeFn<Source, Snapshot> = ReactTypes.MutableSourceSubscribeFn<Source, Snapshot>
type MutableSourceGetSnapshotFn<Source, Snapshot> = ReactTypes.MutableSourceGetSnapshotFn<Source, Snapshot>

type BasicStateAction<S> = ((S) -> S) | S
type Dispatch<A> = (A) -> ()

-- ROBLOX FIXME: function generics
type _T = any
type _S = any
type _I = any
type _A = any
type Snapshot = any
export type Dispatcher = {
	readContext: (
		context: ReactContext<_T>,
		observedBits: nil | number | boolean
	) -> _T,
	useState: (initialState: (() -> _S) | _S) -> (_S, Dispatch<BasicStateAction<_S>>),
	useReducer: (
		reducer: (_S, _A) -> _S,
		initialArg: _I,
		init: ((_I) -> _S)?
	) -> (_S, Dispatch<BasicStateAction<_S>>),
	useContext: (
		context: ReactContext<_T>,
		observedBits: nil | number | boolean
	) -> _T,
	useRef: (initialValue: _T) -> {current: _T},
	useEffect: (
		create: () -> (() -> ()) | nil,
		deps: Array<any> | nil
	) -> (),
	useLayoutEffect: (
		create: () -> (() -> ()) | nil,
		deps: Array<any> | nil
	) -> (),
	useCallback: (callback: _T, deps: Array<any> | nil) -> _T,
	useMemo: (nextCreate: () -> _T, deps: Array<any> | nil) -> _T,
	useImperativeHandle: (
		ref: {current: _T | nil} | ((inst: _T | nil) -> any) | nil,
		create: () -> _T,
		deps: Array<any> | nil
	) -> (),
	useDebugValue: (value: _T, formatterFn: ((value: _T) -> any)?) -> (),
	-- ROBLOX TODO: make these non-optional and implement them in the dispatchers
	useDeferredValue: ((value: _T) -> _T)?,
	useTransition: (() -> ((() -> ()) -> (), boolean))?, -- ROBLOX deviation: Luau doesn't support jagged array types [(() -> ()) -> (), boolean],
	useMutableSource: (
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
