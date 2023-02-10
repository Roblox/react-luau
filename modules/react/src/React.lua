--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react/src/React.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 *]]

local React = script.Parent
local Packages = React.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Object = LuauPolyfill.Object

local createMutableSource = require(React.ReactMutableSource)
local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local ReactBaseClasses = require(React.ReactBaseClasses)
local ReactChildren = require(React.ReactChildren)
local ReactElementValidator = require(React.ReactElementValidator)
local ReactElement = require(React.ReactElement)
local ReactCreateRef = require(React.ReactCreateRef)
local ReactForwardRef = require(React.ReactForwardRef)
local ReactHooks = require(React.ReactHooks)
local ReactMemo = require(React.ReactMemo)
local ReactContext = require(React.ReactContext)
local ReactLazy = require(React.ReactLazy)
type LazyComponent<T, P> = ReactLazy.LazyComponent<T, P>

-- ROBLOX DEVIATION: Bindings
local ReactBinding = require(React["ReactBinding.roblox"])
-- ROBLOX DEVIATION: Re-export `None` marker
local ReactNone = require(React["None.roblox"])

local SharedModule = require(Packages.Shared)
local ReactSymbols = SharedModule.ReactSymbols

local shouldValidate = _G.__DEV__ or _G.__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__
local ReactTypes = require(Packages.Shared)
export type React_StatelessFunctionalComponent<P> =
	ReactTypes.React_StatelessFunctionalComponent<P>
export type React_ComponentType<P> = ReactTypes.React_ComponentType<P>
type React_AbstractComponent<P, T> = ReactTypes.React_AbstractComponent<P, T>
export type React_ElementProps<ElementType> = ReactTypes.React_ElementProps<ElementType>
export type ReactElement<P = Object, T = any> = ReactTypes.ReactElement<P, T>
export type ReactContext<T> = ReactTypes.ReactContext<T>
export type ReactProviderType<T> = ReactTypes.ReactProviderType<T>
export type React_Node = ReactTypes.React_Node
export type PureComponent<Props, State = nil> = ReactTypes.React_PureComponent<
	Props,
	State
>
-- ROBLOX deviation START: bindings support
export type ReactBinding<T> = ReactTypes.ReactBinding<T>
export type ReactBindingUpdater<T> = ReactTypes.ReactBindingUpdater<T>
-- ROBLOX deviation END

type createElementFn = <P, T>(
	type_: React_StatelessFunctionalComponent<P>
		| React_ComponentType<P>
		| React_AbstractComponent<P, T>
		| string
		| ReactContext<any>
		| ReactProviderType<any>
		| LazyComponent<T, P>,
	props: P?,
	...(React_Node | (...any) -> React_Node)
) -> ReactElement<P, T>

type cloneElementFn = <P, T>(
	element: ReactElement<P, T>,
	config: P?,
	...React_Node
) -> ReactElement<P, T>
-- ROBLOX FIXME Luau: these yield Cannot call non-function because the identical unions don't collapse
-- ROBLOX FIXME Luau: the next step is to add createElementFn here and work through issues, AFTER normalization and type packs work
local createElement = if shouldValidate
	then ReactElementValidator.createElementWithValidation :: createElementFn
	else ReactElement.createElement :: createElementFn
local cloneElement: cloneElementFn = if shouldValidate
	then ReactElementValidator.cloneElementWithValidation :: cloneElementFn
	else ReactElement.cloneElement :: cloneElementFn

return {
	Children = ReactChildren,
	createMutableSource = createMutableSource,
	createRef = ReactCreateRef.createRef,
	Component = ReactBaseClasses.Component,
	PureComponent = ReactBaseClasses.PureComponent,
	createContext = ReactContext.createContext,
	forwardRef = ReactForwardRef.forwardRef,
	lazy = ReactLazy.lazy,
	memo = ReactMemo.memo,
	useCallback = ReactHooks.useCallback,
	useContext = ReactHooks.useContext,
	useEffect = ReactHooks.useEffect,
	useImperativeHandle = ReactHooks.useImperativeHandle,
	useDebugValue = ReactHooks.useDebugValue,
	useLayoutEffect = ReactHooks.useLayoutEffect,
	useMemo = ReactHooks.useMemo,
	useMutableSource = ReactHooks.useMutableSource,
	useReducer = ReactHooks.useReducer,
	useRef = ReactHooks.useRef,
	-- ROBLOX deviation: bindings support
	useBinding = ReactHooks.useBinding,
	useState = ReactHooks.useState,
	Fragment = ReactSymbols.REACT_FRAGMENT_TYPE,
	Profiler = ReactSymbols.REACT_PROFILER_TYPE,
	StrictMode = ReactSymbols.REACT_STRICT_MODE_TYPE,
	unstable_DebugTracingMode = ReactSymbols.REACT_DEBUG_TRACING_MODE_TYPE,
	Suspense = ReactSymbols.REACT_SUSPENSE_TYPE,
	createElement = createElement,
	cloneElement = cloneElement,
	isValidElement = ReactElement.isValidElement,
	-- ROBLOX TODO: ReactVersion
	__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = ReactSharedInternals,
	-- Deprecated behind disableCreateFactory
	-- ROBLOX TODO: createFactory,
	-- Concurrent Mode
	-- ROBLOX TODO: useTransition,
	-- ROBLOX TODO: startTransition,
	-- ROBLOX TODO: useDeferredValue,
	-- ROBLOX TODO: REACT_SUSPENSE_LIST_TYPE as SuspenseList,
	unstable_LegacyHidden = ReactSymbols.REACT_LEGACY_HIDDEN_TYPE,
	-- enableBlocksAPI
	-- ROBLOX TODO: block,
	-- enableFundamentalAPI
	-- ROBLOX TODO: createFundamental as unstable_createFundamental,
	-- enableScopeAPI
	-- ROBLOX TODO: REACT_SCOPE_TYPE as unstable_Scope,
	-- ROBLOX TODO: useOpaqueIdentifier as unstable_useOpaqueIdentifier,

	-- ROBLOX deviation START: bindings support
	createBinding = ReactBinding.create,
	joinBindings = ReactBinding.join,
	-- ROBLOX deviation END

	-- ROBLOX DEVIATION: export the `None` placeholder for use with setState
	None = ReactNone,

	-- ROBLOX FIXME: These aren't supposed to be exposed, but they're needed by
	-- the renderer in order to update properly
	__subscribeToBinding = ReactBinding.subscribe,

	-- ROBLOX DEVIATION: export Change, Event, and Tag from React
	Event = require(Packages.Shared).Event,
	Change = require(Packages.Shared).Change,
	Tag = require(Packages.Shared).Tag,

	-- ROBLOX DEVIATION: used by error reporters to parse caught errors. React
	-- stringifies at its boundaries to maintain compatibility with
	-- ScriptContext signals that may ultimately catch them
	unstable_parseReactError = require(Packages.Shared).parseReactError,
}
