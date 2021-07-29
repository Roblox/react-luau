-- upstream: https://github.com/facebook/react/blob/56e9feead0f91075ba0a4f725c9e4e343bca1c67/packages/react/src/React.js
local React = script.Parent
local Packages = React.Parent
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
-- ROBLOX DEVIATION: Bindings
local ReactBinding = require(React["ReactBinding.roblox"])
local ReactSymbols = require(Packages.Shared).ReactSymbols

local createElement = _G.__DEV__ and
	ReactElementValidator.createElementWithValidation or
	ReactElement.createElement
local cloneElement = _G.__DEV__ and
	ReactElementValidator.cloneElementWithValidation or
	ReactElement.cloneElement

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
	-- ROBLOX TODO: useDebugValue
	useLayoutEffect = ReactHooks.useLayoutEffect,
	useMemo = ReactHooks.useMemo,
	useMutableSource = ReactHooks.useMutableSource,
	useReducer = ReactHooks.useReducer,
	useRef = ReactHooks.useRef,
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

	-- ROBLOX DEVIATION: Bindings
	createBinding = ReactBinding.create,
	joinBindings = ReactBinding.join,

	-- ROBLOX FIXME: These aren't supposed to be exposed, but they're needed by
	-- the renderer in order to update properly
	__subscribeToBinding = ReactBinding.subscribe,
}
