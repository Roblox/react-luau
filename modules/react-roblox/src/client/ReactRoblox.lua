--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOM.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
local Packages = script.Parent.Parent.Parent

local ReactTypes = require(Packages.Shared)
type ReactNodeList = ReactTypes.ReactNodeList
local ReactRobloxHostTypes = require(script.Parent["ReactRobloxHostTypes.roblox"])
type Container = ReactRobloxHostTypes.Container

-- local '../shared/checkReact'
-- local ReactRobloxLegacy = require(script.Parent.ReactRobloxLegacy)
-- local findDOMNode = ReactRobloxLegacy.findDOMNode
-- local render = ReactRobloxLegacy.render
-- local hydrate = ReactRobloxLegacy.hydrate
-- local unstable_renderSubtreeIntoContainer = ReactRobloxLegacy.unstable_renderSubtreeIntoContainer
-- local unmountComponentAtNode = ReactRobloxLegacy.unmountComponentAtNode

local ReactRobloxRoot
ReactRobloxRoot = require(script.Parent.ReactRobloxRoot)
local createRoot = ReactRobloxRoot.createRoot
local createBlockingRoot = ReactRobloxRoot.createBlockingRoot
local createLegacyRoot = ReactRobloxRoot.createLegacyRoot
local isValidContainer = ReactRobloxRoot.isValidContainer
-- local createEventHandle = require(script.Parent.ReactDOMEventHandle).createEventHandle

-- ROBLOX deviation: Use the config-injecting entry point for the reconciler
local ReactReconciler = require(script.Parent.Parent["ReactReconciler.roblox"])
-- local batchedEventUpdates = ReactReconciler.batchedEventUpdates
local batchedUpdates = ReactReconciler.batchedUpdates
-- local discreteUpdates = ReactReconciler.discreteUpdates
-- local flushDiscreteUpdates = ReactReconciler.flushDiscreteUpdates
-- local flushSync = ReactReconciler.flushSync
-- local flushControlled = ReactReconciler.flushControlled
local injectIntoDevTools = ReactReconciler.injectIntoDevTools
local flushPassiveEffects = ReactReconciler.flushPassiveEffects
local IsThisRendererActing = ReactReconciler.IsThisRendererActing
-- local attemptSynchronousHydration = ReactReconciler.attemptSynchronousHydration
-- local attemptUserBlockingHydration = ReactReconciler.attemptUserBlockingHydration
-- local attemptContinuousHydration = ReactReconciler.attemptContinuousHydration
-- local attemptHydrationAtCurrentPriority = ReactReconciler.attemptHydrationAtCurrentPriority
-- local runWithPriority = ReactReconciler.runWithPriority
-- local getCurrentUpdateLanePriority = ReactReconciler.getCurrentUpdateLanePriority

local createPortalImpl = ReactReconciler.createPortal
-- local canUseDOM = require(Packages.Shared).ExecutionEnvironment.canUseDOM
local ReactVersion = require(Packages.Shared).ReactVersion
local invariant = require(Packages.Shared).invariant
local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
-- local warnUnstableRenderSubtreeIntoContainer = ReactFeatureFlags.warnUnstableRenderSubtreeIntoContainer
local enableNewReconciler = ReactFeatureFlags.enableNewReconciler

local ReactRobloxComponentTree = require(script.Parent.ReactRobloxComponentTree)
local getInstanceFromNode = ReactRobloxComponentTree.getInstanceFromNode
local getNodeFromInstance = ReactRobloxComponentTree.getNodeFromInstance
local getFiberCurrentPropsFromNode = ReactRobloxComponentTree.getFiberCurrentPropsFromNode
local getClosestInstanceFromNode = ReactRobloxComponentTree.getClosestInstanceFromNode
-- local restoreControlledState = require(script.Parent.ReactRobloxComponent).restoreControlledState

-- local ReactDOMEventReplaying = require(Packages.Parent.Parent.events.ReactDOMEventReplaying)
-- local setAttemptSynchronousHydration = ReactDOMEventReplaying.setAttemptSynchronousHydration
-- local setAttemptUserBlockingHydration = ReactDOMEventReplaying.setAttemptUserBlockingHydration
-- local setAttemptContinuousHydration = ReactDOMEventReplaying.setAttemptContinuousHydration
-- local setAttemptHydrationAtCurrentPriority = ReactDOMEventReplaying.setAttemptHydrationAtCurrentPriority
-- local queueExplicitHydrationTarget = ReactDOMEventReplaying.queueExplicitHydrationTarget
-- local setGetCurrentUpdatePriority = ReactDOMEventReplaying.setGetCurrentUpdatePriority
-- local setAttemptHydrationAtPriority = ReactDOMEventReplaying.setAttemptHydrationAtPriority

-- local setBatchingImplementation = require(Packages.Parent.Parent.events.ReactDOMUpdateBatching).setBatchingImplementation
-- local ReactDOMControlledComponent = require(script.Parent.Parent.events.ReactDOMControlledComponent)
-- local setRestoreImplementation = ReactDOMControlledComponent.setRestoreImplementation
-- local enqueueStateRestore = ReactDOMControlledComponent.enqueueStateRestore
-- local restoreStateIfNeeded = ReactDOMControlledComponent.restoreStateIfNeeded

local Event = require(Packages.Shared).Event
local Change = require(Packages.Shared).Change
local Tag = require(Packages.Shared).Tag

-- setAttemptSynchronousHydration(attemptSynchronousHydration)
-- setAttemptUserBlockingHydration(attemptUserBlockingHydration)
-- setAttemptContinuousHydration(attemptContinuousHydration)
-- setAttemptHydrationAtCurrentPriority(attemptHydrationAtCurrentPriority)
-- setGetCurrentUpdatePriority(getCurrentUpdateLanePriority)
-- setAttemptHydrationAtPriority(runWithPriority)

-- local didWarnAboutUnstableCreatePortal = false
-- local didWarnAboutUnstableRenderSubtreeIntoContainer = false

-- deviation: Built-ins for maps and sets are not required
-- if _G.__DEV__ then
--   if
--     typeof Map ~= 'function' or
--     -- $FlowIssue Flow incorrectly thinks Map has no prototype
--     Map.prototype == nil or
--     typeof Map.prototype.forEach ~= 'function' or
--     typeof Set ~= 'function' or
--     -- $FlowIssue Flow incorrectly thinks Set has no prototype
--     Set.prototype == nil or
--     typeof Set.prototype.clear ~= 'function' or
--     typeof Set.prototype.forEach ~= 'function'
--   )
--     console.error(
--       'React depends on Map and Set built-in types. Make sure that you load a ' +
--         'polyfill in older browsers. https://reactjs.org/link/react-polyfills',
--     )
--   end
-- end

-- setRestoreImplementation(restoreControlledState)
-- setBatchingImplementation(
--   batchedUpdates,
--   discreteUpdates,
--   flushDiscreteUpdates,
--   batchedEventUpdates
-- )

local function createPortal(
	children: ReactNodeList,
	container: Container,
	key: string?
): any
	-- ): React$Portal
	invariant(
		isValidContainer(container),
		-- ROBLOX deviation: Use roblox engine terminology
		"Target container is not a Roblox Instance."
	)
	-- TODO: pass ReactDOM portal implementation as third argument
	-- $FlowFixMe The Flow type is opaque but there's no way to actually create it.
	-- ROBLOX FIXME: luau doesn't realize that this function errors, and it's
	-- expecting us to return something. Can be removed when implementation is
	-- done.
	return createPortalImpl(children, container, nil, key)
end

-- local function scheduleHydration(target: any)
--   if target then
--     queueExplicitHydrationTarget(target)
--   end
-- end

-- local function renderSubtreeIntoContainer(
--   parentComponent: React$Component<any, any>,
--   element: React$Element<any>,
--   containerNode: Container,
--   callback: ?Function,
-- )
-- local function renderSubtreeIntoContainer(
--   parentComponent: any,
--   element: any,
--   containerNode: Container,
--   callback: any
-- )
--   if _G.__DEV__ then
--     if
--       warnUnstableRenderSubtreeIntoContainer and
--       not didWarnAboutUnstableRenderSubtreeIntoContainer
--     then
--       didWarnAboutUnstableRenderSubtreeIntoContainer = true
--       console.warn(
--         "ReactDOM.unstable_renderSubtreeIntoContainer() is deprecated " ..
--           "and will be removed in a future major release. Consider using " ..
--           "React Portals instead."
--       )
--     end
--   end
--   return unstable_renderSubtreeIntoContainer(
--     parentComponent,
--     element,
--     containerNode,
--     callback
--   )
-- end

-- local function unstable_createPortal(
--   children: ReactNodeList,
--   container: Container,
--   key: string?
-- )
--   if _G.__DEV__ then
--     if not didWarnAboutUnstableCreatePortal then
--       didWarnAboutUnstableCreatePortal = true
--       console.warn(
--         "The ReactDOM.unstable_createPortal() alias has been deprecated, " ..
--           "and will be removed in React 18+. Update your code to use " ..
--           "ReactDOM.createPortal() instead. It has the exact same API, " ..
--           "but without the \"unstable_\" prefix."
--       )
--     end
--   end
--   return createPortal(children, container, key)
-- end

local Internals = {
	-- Keep in sync with ReactTestUtils.js, and ReactTestUtilsAct.js.
	-- This is an array for better minification.
	Events = {
		getInstanceFromNode = getInstanceFromNode,
		getNodeFromInstance = getNodeFromInstance,
		getFiberCurrentPropsFromNode = getFiberCurrentPropsFromNode,
		-- enqueueStateRestore = enqueueStateRestore,
		-- restoreStateIfNeeded = restoreStateIfNeeded,
		flushPassiveEffects = flushPassiveEffects,
		-- TODO: This is related to `act`, not events. Move to separate key?
		IsThisRendererActing = IsThisRendererActing,
	},
}

local exports = {
	createPortal = createPortal,
	unstable_batchedUpdates = batchedUpdates,
	-- flushSync = flushSync,
	__SECRET_INTERNALS_DO_NOT_USE_OR_YOU_WILL_BE_FIRED = Internals,
	version = ReactVersion,
	-- Disabled behind disableLegacyReactDOMAPIs
	-- findDOMNode = findDOMNode,
	-- hydrate = hydrate,
	-- render = render,
	-- unmountComponentAtNode = unmountComponentAtNode,
	-- exposeConcurrentModeAPIs
	createRoot = createRoot,
	createBlockingRoot = createBlockingRoot,
	createLegacyRoot = createLegacyRoot,
	-- unstable_flushControlled = flushControlled,
	-- unstable_scheduleHydration = scheduleHydration,
	-- Disabled behind disableUnstableRenderSubtreeIntoContainer
	-- unstable_renderSubtreeIntoContainer = renderSubtreeIntoContainer,
	-- Disabled behind disableUnstableCreatePortal
	-- Temporary alias since we already shipped React 16 RC with it.
	-- TODO: remove in React 18.
	-- unstable_createPortal = unstable_createPortal,
	-- enableCreateEventHandleAPI
	-- unstable_createEventHandle = createEventHandle,
	-- TODO: Remove this once callers migrate to alternatives.
	-- This should only be used by React internals.
	-- unstable_runWithPriority = runWithPriority,

	-- ROBLOX deviation: Export logic attached from Roact

	-- ROBLOX FIXME: Is there a better way to provide this? Exposing these here
	-- means that a large number of react components that wouldn't otherwise need
	-- to import `ReactRoblox` will need to do so in order to set events/change
	Event = Event,
	Change = Change,
	Tag = Tag,
	unstable_isNewReconciler = enableNewReconciler,

	-- ROBLOX deviation: Export `act` function for testing purposes; in
	-- production (a.k.a. scheduler isn't mocked), give an instructive error
	act = function(_: () -> ()): ()
		error(
			"ReactRoblox.act is only available in testing environments, not "
				.. "production. Enable the `__ROACT_17_MOCK_SCHEDULER__` global in your "
				.. "test configuration in order to use `act`."
		)
	end,
}

if _G.__ROACT_17_MOCK_SCHEDULER__ then
	-- ROBLOX deviation: When the __ROACT_17_MOCK_SCHEDULER__ is enabled, we
	-- re-export the `act` function from ReactReconciler. The global will
	-- additionally force the scheduler to use the mock interface
	exports.act = ReactReconciler.act
end

-- ROBLOX deviation: we don't currently implement the logic below that uses this
-- value
local _foundDevTools = injectIntoDevTools({
	findFiberByHostInstance = getClosestInstanceFromNode,
	bundleType = if _G.__DEV__ then 1 else 0,
	version = ReactVersion,
	rendererPackageName = "ReactRoblox",
})

if _G.__DEV__ then
	-- if not foundDevTools and canUseDOM and window.top == window.self then
	--   If we're in Chrome or Firefox, provide a download link if not installed.
	--   if
	--     (navigator.userAgent.indexOf('Chrome') > -1 and
	--       navigator.userAgent.indexOf('Edge') == -1) or
	--     navigator.userAgent.indexOf('Firefox') > -1
	--   )
	--     local protocol = window.location.protocol
	--     -- Don't warn in exotic cases like chrome-extension://.
	--     if /^(https?|file):$/.test(protocol))
	--       -- eslint-disable-next-line react-internal/no-production-logging
	--       console.info(
	--         '%cDownload the React DevTools ' +
	--           'for a better development experience: ' +
	--           'https://reactjs.org/link/react-devtools' +
	--           (protocol == 'file:'
	--             ? '\nYou might need to use a local HTTP server (instead of file://): ' +
	--               'https://reactjs.org/link/react-devtools-faq'
	--             : ''),
	--         'font-weight:bold',
	--       )
	--     end
	--   end
	-- end
end

return exports
