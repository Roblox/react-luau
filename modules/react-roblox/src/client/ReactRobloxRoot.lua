--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/8e5adfbd7e605bda9c5e96c10e015b3dc0df688e/packages/react-dom/src/client/ReactDOMRoot.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

local Packages = script.Parent.Parent.Parent

local ReactRobloxHostTypes = require(script.Parent["ReactRobloxHostTypes.roblox"])
type Container = ReactRobloxHostTypes.Container
type RootType = ReactRobloxHostTypes.RootType
type RootOptions = ReactRobloxHostTypes.RootOptions

local ReconcilerTypes = require(Packages.ReactReconciler)
type RootTag = ReconcilerTypes.RootTag
local ReactTypes = require(Packages.Shared)
type MutableSource<T> = ReactTypes.MutableSource<T>
type ReactNodeList = ReactTypes.ReactNodeList
local ReactInternalTypes = require(Packages.ReactReconciler)
type FiberRoot = ReactInternalTypes.FiberRoot

type Array<T> = { [number]: T }

local ReactRobloxComponentTree = require(script.Parent.ReactRobloxComponentTree)
-- local isContainerMarkedAsRoot = ReactRobloxComponentTree.isContainerMarkedAsRoot
local markContainerAsRoot = ReactRobloxComponentTree.markContainerAsRoot
local unmarkContainerAsRoot = ReactRobloxComponentTree.unmarkContainerAsRoot
-- local listenToAllSupportedEvents = require(script.Parent.Parent.events.DOMPluginEventSystem).listenToAllSupportedEvents
-- local eagerlyTrapReplayableEvents = require(script.Parent.Parent.events.ReactDOMEventReplaying).eagerlyTrapReplayableEvents
-- local HTMLNodeType = require(script.Parent.Parent.shared.HTMLNodeType)
-- local ELEMENT_NODE = HTMLNodeType.ELEMENT_NODE
-- local COMMENT_NODE = HTMLNodeType.COMMENT_NODE
-- local DOCUMENT_NODE = HTMLNodeType.DOCUMENT_NODE
-- local DOCUMENT_FRAGMENT_NODE = HTMLNodeType.DOCUMENT_FRAGMENT_NODE
-- local ensureListeningTo = require(Packages.ReactDOMComponent).ensureListeningTo

-- ROBLOX deviation: Use the config-injecting entry point for the reconciler
local ReactFiberReconciler = require(script.Parent.Parent["ReactReconciler.roblox"])
local createContainer = ReactFiberReconciler.createContainer
local updateContainer = ReactFiberReconciler.updateContainer
-- local findHostInstanceWithNoPortals = ReactFiberReconciler.findHostInstanceWithNoPortals
-- local registerMutableSourceForHydration = ReactFiberReconciler.registerMutableSourceForHydration
local invariant = require(Packages.Shared).invariant
local enableEagerRootListeners =
	require(Packages.Shared).ReactFeatureFlags.enableEagerRootListeners

local BlockingRoot = ReactFiberReconciler.ReactRootTags.BlockingRoot
local ConcurrentRoot = ReactFiberReconciler.ReactRootTags.ConcurrentRoot
local LegacyRoot = ReactFiberReconciler.ReactRootTags.LegacyRoot

local createRootImpl

local ReactRobloxRoot = {}
ReactRobloxRoot.__index = ReactRobloxRoot

function ReactRobloxRoot.new(container: Container, options: RootOptions?): RootType
	local root: RootType = (setmetatable({}, ReactRobloxRoot) :: any) :: RootType
	root._internalRoot = createRootImpl(container, ConcurrentRoot, options)

	return root
end

local function createBlockingRoot(
	container: Container,
	tag: RootTag,
	options: RootOptions?
): RootType
	-- deviation: We can just share the logic here via metatables
	local root: RootType = (setmetatable({}, ReactRobloxRoot) :: any) :: RootType
	root._internalRoot = createRootImpl(container, tag, options)

	return root
end

function ReactRobloxRoot:render(children: ReactNodeList)
	local root = self._internalRoot
	-- if _G.__DEV__ then
	--   if typeof (arguments[1] == 'function')
	--     console.error(
	--       'render(...): does not support the second callback argument. ' +
	--         'To execute a side effect after rendering, declare it in a component body with useEffect().',
	--     )
	--   end
	--   local container = root.containerInfo

	--   if container.nodeType ~= COMMENT_NODE)
	--     local hostInstance = findHostInstanceWithNoPortals(root.current)
	--     if hostInstance)
	--       if hostInstance.parentNode ~= container)
	--         console.error(
	--           'render(...): It looks like the React-rendered content of the ' +
	--             'root container was removed without using React. This is not ' +
	--             'supported and will cause errors. Instead, call ' +
	--             "root.unmount() to empty a root's container.",
	--         )
	--       end
	--     end
	--   end
	-- end
	updateContainer(children, root, nil)
end

function ReactRobloxRoot:unmount()
	-- if _G.__DEV__ then
	--   if typeof arguments[0] == 'function')
	--     console.error(
	--       'unmount(...): does not support a callback argument. ' +
	--         'To execute a side effect after rendering, declare it in a component body with useEffect().',
	--     )
	--   end
	-- end
	local root = self._internalRoot
	local container = root.containerInfo
	updateContainer(nil, root, nil, function()
		unmarkContainerAsRoot(container)
	end)
end

-- ROBLOX TODO: add Options type
-- createRootImpl = function(
--   container: Container,
--   tag: RootTag,
--   options: RootOptions
-- )
createRootImpl = function(container: Container, tag: RootTag, options: any)
	-- Tag is either LegacyRoot or Concurrent Root
	local hydrate = options ~= nil and options.hydrate == true
	local hydrationCallbacks = if options ~= nil then options.hydrationOptions else nil
	local mutableSources = (
		options ~= nil
		and options.hydrationOptions ~= nil
		and options.hydrationOptions.mutableSources
	) or nil
	local root = createContainer(container, tag, hydrate, hydrationCallbacks)
	markContainerAsRoot(root.current, container)
	-- local containerNodeType = container.nodeType

	if enableEagerRootListeners then
		--   local rootContainerElement =
		--     container.nodeType == COMMENT_NODE and container.parentNode or container
		--   listenToAllSupportedEvents(rootContainerElement)
		-- } else {
		--   if hydrate and tag ~= LegacyRoot)
		--     local doc =
		--       containerNodeType == DOCUMENT_NODE
		--         ? container
		--         : container.ownerDocument
		--     -- We need to cast this because Flow doesn't work
		--     -- with the hoisted containerNodeType. If we inline
		--     -- it, then Flow doesn't complain. We intentionally
		--     -- hoist it to reduce code-size.
		--     eagerlyTrapReplayableEvents(container, ((doc: any): Document))
		--   } else if
		--     containerNodeType ~= DOCUMENT_FRAGMENT_NODE and
		--     containerNodeType ~= DOCUMENT_NODE
		--   )
		--     ensureListeningTo(container, 'onMouseEnter')
		--   end
	end

	if mutableSources then
		-- for (local i = 0; i < mutableSources.length; i++)
		--   local mutableSource = mutableSources[i]
		--   registerMutableSourceForHydration(root, mutableSource)
		-- end
	end

	return root
end

local exports = {}

local function isValidContainer(node: any): boolean
	-- ROBLOX TODO: This behavior will deviate, for now just check that it's an
	-- instance, which should be good enough
	return typeof(node) == "Instance"
	-- return not not (
	--   node and
	--   (node.nodeType == ELEMENT_NODE or
	--     node.nodeType == DOCUMENT_NODE or
	--     node.nodeType == DOCUMENT_FRAGMENT_NODE or
	--     (node.nodeType == COMMENT_NODE and
	--       node.nodeValue == ' react-mount-point-unstable '))
	-- )
end

exports.isValidContainer = isValidContainer

-- deviation: Create `Container` from instance
exports.createRoot = function(container: Container, options: RootOptions?): RootType
	invariant(
		isValidContainer(container),
		-- ROBLOX deviation: Use roblox engine terminology
		"createRoot(...): Target container is not a Roblox Instance."
	)
	warnIfReactDOMContainerInDEV(container)
	return ReactRobloxRoot.new(container, options)
end

exports.createBlockingRoot =
	function(container: Container, options: RootOptions?): RootType
		invariant(
			isValidContainer(container),
			-- ROBLOX deviation: Use roblox engine terminology
			"createRoot(...): Target container is not a Roblox Instance."
		)
		warnIfReactDOMContainerInDEV(container)
		return createBlockingRoot(container, BlockingRoot, options)
	end

exports.createLegacyRoot = function(container: Container, options: RootOptions?): RootType
	return createBlockingRoot(container, LegacyRoot, options)
end

function warnIfReactDOMContainerInDEV(container)
	if _G.__DEV__ then
		-- ROBLOX TODO: This behavior will deviate; should we validate that the
		-- container is not a PlayerGui of any sort?

		-- if
		--   container.nodeType == ELEMENT_NODE and
		--   container.tagName and
		--   container.tagName.toUpperCase() == 'BODY'
		-- then
		--   console.error(
		--     'createRoot(): Creating roots directly with document.body is ' ..
		--       'discouraged, since its children are often manipulated by third-party ' ..
		--       'scripts and browser extensions. This may lead to subtle ' ..
		--       'reconciliation issues. Try using a container element created ' ..
		--       'for your app.'
		--   )
		-- end
		-- if isContainerMarkedAsRoot(container) then
		--   if container._reactRootContainer then
		--     console.error(
		--       'You are calling ReactDOM.createRoot() on a container that was previously ' ..
		--         'passed to ReactDOM.render(). This is not supported.'
		--     )
		--   else
		--     console.error(
		--       'You are calling ReactDOM.createRoot() on a container that ' ..
		--         'has already been passed to createRoot() before. Instead, call ' ..
		--         'root.render() on the existing root instead if you want to update it.'
		--     )
		--   end
		-- end
	end
end

return exports
