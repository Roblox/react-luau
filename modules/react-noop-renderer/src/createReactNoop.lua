-- upstream: https://github.com/facebook/react/blob/e7b255341b059b4e2a109847395d0d0ba2633999/packages/react-noop-renderer/src/createReactNoop.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]
--!nolint LocalShadowPedantic
--!nolint LocalShadow

--[[*
 * This is a renderer of React that doesn't have a render target output.
 * It is useful to demonstrate the internals of the reconciler in isolation
 * and for testing semantics of reconciliation separate from the host
 * environment.
]]

local Packages = script.Parent.Parent
local RobloxJest = require(Packages.RobloxJest)
local Cryo = require(Packages.Cryo)
local LuauPolyfill = require(Packages.LuauPolyfill)

local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local Object = LuauPolyfill.Object
type Function = (...any) -> ...any
local setTimeout = LuauPolyfill.setTimeout
local clearTimeout = LuauPolyfill.clearTimeout
local console = require(Packages.Shared).console

local ReactReconciler = require(Packages.ReactReconciler)
type Fiber = ReactReconciler.Fiber
type UpdateQueue<T> = ReactReconciler.UpdateQueue<T>
local ReactShared = require(Packages.Shared)
type ReactNodeList = ReactShared.ReactNodeList
type Thenable<T> = ReactShared.Thenable<T, any>

type RootTag = ReactReconciler.RootTag
local Scheduler = require(Packages.Scheduler)
-- deviation: These are only used for the JSX logic that's currently omitted
local ReactSymbols = require(Packages.Shared).ReactSymbols
local REACT_FRAGMENT_TYPE = ReactSymbols.REACT_FRAGMENT_TYPE
local REACT_ELEMENT_TYPE = ReactSymbols.REACT_ELEMENT_TYPE

-- local ConcurrentRoot = ReactRootTags.ConcurrentRoot
-- local BlockingRoot = ReactRootTags.BlockingRoot
-- local LegacyRoot = ReactRootTags.LegacyRoot

local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local enqueueTask = require(Packages.Shared).enqueueTask
local IsSomeRendererActing = ReactSharedInternals.IsSomeRendererActing

type Object = { [string]: any }
type Array<T> = { [number]: T }

type HostContext = Object
type Container = {
	rootID: string,
	children: Array<Instance | TextInstance>,
	pendingChildren: Array<Instance | TextInstance>,
	-- ...
}
type Props = {
	prop: any,
	hidden: boolean,
	children: any?,
	bottom: number?,
	left: number?,
	right: number?,
	top: number?,
	-- ...
}
type Instance = {
	type: string,
	id: number,
	children: Array<Instance | TextInstance>,
	text: string | nil,
	prop: any,
	hidden: boolean,
	context: HostContext,
}
type TextInstance = {
	text: string,
	id: number,
	hidden: boolean,
	context: HostContext,
}

local NO_CONTEXT = {}
local UPPERCASE_CONTEXT = {}
local UPDATE_SIGNAL = {}
if _G.__DEV__ then
	Object.freeze(NO_CONTEXT)
	Object.freeze(UPDATE_SIGNAL)
end

local function createReactNoop(reconciler, useMutation: boolean)
	local instanceCounter = 0
	local hostDiffCounter = 0
	local hostUpdateCounter = 0
	local hostCloneCounter = 0

	-- deviation: Pre-declare so lua understands that these exist
	local flushActWork, shouldSetTextContent, computeText, cloneInstance

	local function appendChildToContainerOrInstance(
		parentInstance: Container | Instance,
		child: Instance | TextInstance
	): ()
		local index = Array.indexOf(parentInstance.children, child)
		if index ~= -1 then
			Array.splice(parentInstance.children, index, 1)
		end
		table.insert(parentInstance.children, child)
	end

	local function appendChildToContainer(
		parentInstance: Container,
		child: Instance | TextInstance
	): ()
		if typeof(parentInstance.rootID) ~= "string" then
			-- Some calls to this aren't typesafe.
			-- This helps surface mistakes in tests.
			error(Error("appendChildToContainer() first argument is not a container."))
		end
		appendChildToContainerOrInstance(parentInstance, child)
	end

	local function appendChild(
		parentInstance: Instance,
		child: Instance | TextInstance
	): ()
		local parentInstance: any = parentInstance
		if typeof(parentInstance.rootID) == "string" then
			-- Some calls to this aren't typesafe.
			-- This helps surface mistakes in tests.
			error(Error("appendChild() first argument is not an instance."))
		end
		appendChildToContainerOrInstance(parentInstance, child)
	end

	local function insertInContainerOrInstanceBefore(
		parentInstance: Container | Instance,
		child: Instance | TextInstance,
		beforeChild: Instance | TextInstance
	): ()
		local index = Array.indexOf(parentInstance.children, child)
		if index ~= -1 then
			Array.splice(parentInstance.children, index, 1)
		end
		local beforeIndex = Array.indexOf(parentInstance.children, beforeChild)
		if beforeIndex == -1 then
			error(Error("This child does not exist."))
		end
		Array.splice(parentInstance.children, beforeIndex, 0, child)
	end

	local function insertInContainerBefore(
		parentInstance: Container,
		child: Instance | TextInstance,
		beforeChild: Instance | TextInstance
	)
		if typeof(parentInstance.rootID) ~= "string" then
			-- Some calls to this aren't typesafe.
			-- This helps surface mistakes in tests.
			error(Error("insertInContainerBefore() first argument is not a container."))
		end
		insertInContainerOrInstanceBefore(parentInstance, child, beforeChild)
	end

	local function insertBefore(
		parentInstance: Instance,
		child: Instance | TextInstance,
		beforeChild: Instance | TextInstance
	)
		local parentInstance: any = parentInstance
		if typeof(parentInstance.rootID) ~= "string" then
			-- Some calls to this aren't typesafe.
			-- This helps surface mistakes in tests.
			error(Error("insertBefore() first argument is not an instance."))
		end
		insertInContainerOrInstanceBefore(parentInstance, child, beforeChild)
	end

	local function clearContainer(container: Container)
		Array.splice(container.children, 0)
	end

	local function removeChildFromContainerOrInstance(
		parentInstance: Container | Instance,
		child: Instance | TextInstance
	)
		local index = Array.indexOf(parentInstance.children, child)
		if index == -1 then
			error(Error("This child does not exist."))
		end
		Array.splice(parentInstance.children, index, 1)
	end

	local function removeChildFromContainer(
		parentInstance: Container,
		child: Instance | TextInstance
	)
		if
			typeof(parentInstance) == "table"
			and typeof(parentInstance.rootID) ~= "string"
		then
			-- Some calls to this aren't typesafe.
			-- This helps surface mistakes in tests.
			error(Error("removeChildFromContainer() first argument is not a container."))
		end
		removeChildFromContainerOrInstance(parentInstance, child)
	end

	local function removeChild(parentInstance: Instance, child: Instance | TextInstance)
		local parentInstance: any = parentInstance
		if typeof(parentInstance.rootID) == "string" then
			-- Some calls to this aren't typesafe.
			-- This helps surface mistakes in tests.
			error(Error("removeChild() first argument is not an instance."))
		end
		removeChildFromContainerOrInstance(parentInstance, child)
	end

	cloneInstance = function(
		instance: Instance,
		updatePayload: Object?,
		type: string,
		oldProps: Props,
		newProps: Props,
		internalInstanceHandle: Object,
		keepChildren: boolean,
		recyclableInstance: Instance?
	)
		-- deviation: use metatable to define non-enumerable properties
		local children
		if keepChildren then
			children = instance.children
		else
			children = {}
		end

		local clone = setmetatable({
			type = type,
			children = children,
			prop = newProps.prop,
			-- ROBLOX TODO: matches upstream, but does it make sense in Lua?
			hidden = not not newProps.hidden,
		}, {
			__index = {
				id = instance.id,
				-- deviation: Not sure about this one
				-- text: shouldSetTextContent(type, newProps)
				-- 	? computeText((newProps.children: any) + '', instance.context)
				-- 	: null,
				text = shouldSetTextContent(type, newProps) and computeText(
					tostring(newProps.children),
					instance.context
				) or nil,
				context = instance.context,
			},
		})
		hostCloneCounter += 1
		return clone
	end

	shouldSetTextContent = function(type: string, props: Props): boolean
		if type == "errorInBeginPhase" then
			error(Error("Error in host config."))
		end
		return typeof(props.children) == "string" or typeof(props.children) == "number"
	end

	computeText = function(rawText, hostContext): string
		return hostContext == UPPERCASE_CONTEXT and string.upper(rawText) or rawText
	end

	local sharedHostConfig = {
		getRootHostContext = function()
			return NO_CONTEXT
		end,

		getChildHostContext = function(parentHostContext: HostContext, type: string, rootcontainerInstance: Container)
			if type == "uppercase" then
				return UPPERCASE_CONTEXT
			end
			return NO_CONTEXT
		end,

		getPublicInstance = function(instance)
			return instance
		end,

		createInstance = function(
			type: string,
			props: Props,
			rootContainerInstance: Container,
			hostContext: HostContext
		): Instance
			if type == "errorInCompletePhase" then
				error(Error("Error in host config."))
			end

			-- deviation: use metatable to define non-enumerable properties
			local inst = setmetatable({
				type = type,
				children = {},
				prop = props.prop,
				hidden = not not props.hidden,
			}, {
				-- Hide from unit tests
				__index = {
					id = instanceCounter,
					-- deviation: Not sure about this one
					-- text: shouldSetTextContent(type, props)
					-- 	? computeText((props.children: any) + '', hostContext)
					-- 	: null,
					text = shouldSetTextContent(type, props) and computeText(
						tostring(props.children),
						hostContext
					) or nil,
					context = hostContext,
				},
			})
			instanceCounter += 1
			return inst
		end,

		appendInitialChild = function(parentInstance: Instance, child: Instance | TextInstance)
			table.insert(parentInstance.children, child)
		end,

		finalizeInitialChildren = function(_domElement: Instance, _type: string, _props: Props): boolean
			return false
		end,

		prepareUpdate = function(instanceH: Instance, type: string, oldProps: Props, newProps: Props): Object?
			if type == "errorInCompletePhase" then
				error(Error("Error in host config."))
			end
			if oldProps == nil then
				error(Error("Should have old props"))
			end
			if newProps == nil then
				error(Error("Should have new props"))
			end
			hostDiffCounter += 1
			return UPDATE_SIGNAL
		end,

		shouldSetTextContent = shouldSetTextContent,

		-- deviation: FIXME: this might not make any sense in Roblox, which has
		-- no notion of non-styled text nodes
		createTextInstance = function(
			text: string,
			rootContainerInstance,
			hostContext: { [any]: any },
			internalInstanceHandle: { [any]: any }
		): TextInstance
			if hostContext == UPPERCASE_CONTEXT then
				text = string.upper(text)
			end
			-- deviation: use metatable to define non-enumerable properties
			local inst = setmetatable({
				text = text,
				hidden = false,
			}, {
				-- Hide from unit tests
				__index = {
					id = instanceCounter,
					context = hostContext,
				},
			})
			instanceCounter += 1
			return inst
		end,

		scheduleTimeout = setTimeout,
		cancelTimeout = clearTimeout,
		noTimeout = -1,

		prepareForCommit = function(): nil | { [any]: any }
			return nil
		end,

		resetAfterCommit = function() end,

		now = Scheduler.unstable_now,

		isPrimaryRenderer = true,
		warnsIfNotActing = true,
		supportsHydration = false,

		getFundamentalComponentInstance = function(fundamentalInstance): Instance
			local impl = fundamentalInstance.impl
			local props = fundamentalInstance.props
			local state = fundamentalInstance.state
			return impl.getInstance(nil, props, state)
		end,

		mountFundamentalComponent = function(fundamentalInstance)
			local impl = fundamentalInstance.impl
			local instance = fundamentalInstance.instance
			local props = fundamentalInstance.props
			local state = fundamentalInstance.state
			local onMount = impl.onUpdate
			if onMount ~= nil then
				onMount(nil, instance, props, state)
			end
		end,

		shouldUpdateFundamentalComponent = function(fundamentalInstance): boolean
			local impl = fundamentalInstance.impl
			local instance = fundamentalInstance.instance
			local prevProps = fundamentalInstance.prevProps
			local props = fundamentalInstance.props
			local state = fundamentalInstance.state
			local shouldUpdate = impl.shouldUpdate
			if shouldUpdate ~= nil then
				return shouldUpdate(nil, instance, prevProps, props, state)
			end
			return true
		end,

		updateFundamentalComponent = function(fundamentalInstance)
			local impl = fundamentalInstance.impl
			local instance = fundamentalInstance.instance
			local prevProps = fundamentalInstance.prevProps
			local props = fundamentalInstance.props
			local state = fundamentalInstance.state
			local onUpdate = impl.onUpdate
			if onUpdate ~= nil then
				onUpdate(nil, instance, prevProps, props, state)
			end
		end,

		unmountFundamentalComponent = function(fundamentalInstance)
			local impl = fundamentalInstance.impl
			local instance = fundamentalInstance.instance
			local props = fundamentalInstance.props
			local state = fundamentalInstance.state
			local onUnmount = impl.onUnmount
			if onUnmount ~= nil then
				onUnmount(nil, instance, props, state)
			end
		end,

		cloneFundamentalInstance = function(fundamentalInstance): Instance
			local instance = fundamentalInstance.instance
			-- TODO (roblox): Do we have to indirect some of these to make them
			-- not enumerable, like we do in `createInstance`
			return {
				children = {},
				text = instance.text,
				type = instance.type,
				prop = instance.prop,
				id = instance.id,
				context = instance.context,
				hidden = instance.hidden,
			}
		end,

		getInstanceFromNode = function()
			error(Error("Not yet implemented."))
		end,

		beforeActiveInstanceBlur = function()
			-- NO-OP
		end,

		afterActiveInstanceBlur = function()
			-- NO-OP
		end,

		preparePortalMount = function()
			-- NO-OP
		end,

		prepareScopeUpdate = function() end,

		getInstanceFromScope = function()
			error(Error("Not yet implemented."))
		end,
	}

	-- deviation: replace spread with manual table creation
	local hostConfig
	if useMutation then
		hostConfig = Cryo.Dictionary.join(sharedHostConfig, {
			supportsMutation = true,
			supportsPersistence = false,

			commitMount = function(instance: Instance, type: string, newProps: Props)
				-- Noop
			end,

			commitUpdate = function(
				instance: Instance,
				updatePayload: Object,
				type: string,
				oldProps: Props,
				newProps: Props
			)
				if oldProps == nil then
					error(Error("Should have old props"))
				end
				hostUpdateCounter += 1
				instance.prop = newProps.prop
				instance.hidden = not not newProps.hidden
				if shouldSetTextContent(type, newProps) then
					-- deviation: Not sure about this one
					instance.text = computeText(
						tostring(newProps.children),
						instance.context
					)
				end
			end,

			commitTextUpdate = function(textInstance: TextInstance, oldText: string, newText: string)
				hostUpdateCounter += 1
				textInstance.text = computeText(newText, textInstance.context)
			end,

			appendChild = appendChild,
			appendChildToContainer = appendChildToContainer,
			insertBefore = insertBefore,
			insertInContainerBefore = insertInContainerBefore,
			removeChild = removeChild,
			removeChildFromContainer = removeChildFromContainer,
			clearContainer = clearContainer,

			hideInstance = function(instance: Instance)
				instance.hidden = true
			end,

			hideTextInstance = function(textInstance: TextInstance)
				textInstance.hidden = true
			end,

			unhideInstance = function(instance: Instance, props: Props)
				if not props.hidden then
					instance.hidden = false
				end
			end,

			unhideTextInstance = function(textInstance: TextInstance, text: string)
				textInstance.hidden = false
			end,

			resetTextContent = function(instance: Instance)
				instance.text = nil
			end,
		})
	else
		hostConfig = Cryo.Dictionary.join(sharedHostConfig, {
			supportsMutation = false,
			supportsPersistence = true,

			cloneInstance = cloneInstance,
			clearContainer = clearContainer,

			createContainerChildSet = function(container: Container): Array<Instance | TextInstance>
				return {}
			end,

			appendChildToContainerChildSet = function(childSet: Array<Instance | TextInstance>, child: Instance | TextInstance)
				table.insert(childSet, child)
			end,

			finalizeContainerChildren = function(container: Container, newChildren: Array<Instance | TextInstance>)
				container.pendingChildren = newChildren
				if
					#newChildren == 1
					and newChildren[1].text == "Error when completing root"
				then
					-- Trigger an error for testing purposes
					error(Error("Error when completing root"))
				end
			end,

			replaceContainerChildren = function(container: Container, newChildren: Array<Instance | TextInstance>)
				container.children = newChildren
			end,

			cloneHiddenInstance = function(
				instance: Instance,
				type: string,
				props: Props,
				internalInstanceHandle: Object
			)
				local clone = cloneInstance(
					instance,
					nil,
					type,
					props,
					props,
					internalInstanceHandle,
					true,
					nil
				)
				clone.hidden = true
				return clone
			end,

			cloneHiddenTextInstance = function(instance: TextInstance, text: string, internalInstanceHandle: Object)
				-- deviation: use metatable to define non-enumerable properties
				local clone = setmetatable({
					text = instance.text,
					hidden = true,
				}, {
					-- Hide from unit tests
					__index = {
						id = instanceCounter,
						context = instance.context,
					},
				})
				instanceCounter += 1
				return clone
			end,
		})
	end

	local NoopRenderer = reconciler(hostConfig)
	-- ROBLOX deviation: We can't reach into the reconciler for these, so we
	-- extract them after we've initialized a mock reconciler
	local ReactRootTags = NoopRenderer.ReactRootTags
	local ConcurrentRoot = ReactRootTags.ConcurrentRoot
	local BlockingRoot = ReactRootTags.BlockingRoot
	local LegacyRoot = ReactRootTags.LegacyRoot

	local rootContainers = {}
	local roots = {}
	local DEFAULT_ROOT_ID = "<default>"

	local function childToJSX(child, text)
		if text ~= nil then
			return text
		end
		if child == nil then
			return nil
		end
		if typeof(child) == "string" then
			return child
		end
		if Array.isArray(child) then
			if #child == 0 then
				return nil
			end
			if #child == 1 then
				return childToJSX(child[1], nil)
			end
			local children = Array.map(child, function(c)
				return childToJSX(c, nil)
			end)
			if
				Array.every(children, function(c)
					return typeof(c) == "string" or typeof(c) == "number"
				end)
			then
				return Array.join(children, "")
			end
			return children
		end
		if Array.isArray(child.children) then
			-- ROBLOX DEVIATION: Luau flow syntax unsupported by Selene 0.11
			-- local instance: Instance = (child :: any)
			local instance = child
			local children = childToJSX(instance.children, instance.text)
			-- ROBLOX DEVIATION: Luau flow syntax unsupported by Selene 0.11
			-- local props = ({prop = instance.prop} :: any)
			local props = { prop = instance.prop }
			if instance.hidden then
				props.hidden = true
			end
			if children ~= nil then
				props.children = children
			end
			local store = nil
			if _G.__DEV__ then
				store = {}
			end
			return {
				["$$typeof"] = REACT_ELEMENT_TYPE,
				type = instance.type,
				key = nil,
				ref = nil,
				props = props,
				_owner = nil,
				_store = store,
			}
		end
		-- ROBLOX deviation: type erasure to workaround Luau narrowing issues
		-- local textInstance: TextInstance = (child: any)
		local textInstance = child
		if textInstance.hidden then
			return ""
		end
		return textInstance.text
	end

	local function getChildren(root)
		if root then
			return root.children
		else
			return nil
		end
	end

	local function getPendingChildren(root)
		if root then
			return root.pendingChildren
		else
			return nil
		end
	end

	local function getChildrenAsJSX(root)
		local children = childToJSX(getChildren(root), nil)
		if children == nil then
			return nil
		end
		if Array.isArray(children) then
			local store = nil
			if _G.__DEV__ then
				store = {}
			end
			return {
				["$$typeof"] = REACT_ELEMENT_TYPE,
				type = REACT_FRAGMENT_TYPE,
				key = nil,
				ref = nil,
				props = { children },
				_owner = nil,
				_store = store,
			}
		end
		return children
	end

	-- deviation: disabling JSX-related functionality
	local function getPendingChildrenAsJSX(root)
		error(Error("JSX Unsupported"))
	end
	-- function getPendingChildrenAsJSX(root) {
	-- 	local children = childToJSX(getChildren(root), nil)
	-- 	if (children == nil) {
	-- 		return nil
	-- 	}
	-- 	if (Array.isArray(children)) {
	-- 		return {
	-- 			$$typeof: REACT_ELEMENT_TYPE,
	-- 			type: REACT_FRAGMENT_TYPE,
	-- 			key: nil,
	-- 			ref: nil,
	-- 			props: {children},
	-- 			_owner: nil,
	-- 			_store: _G.__DEV__ ? {} : undefined,
	-- 		}
	-- 	}
	-- 	return children
	-- }

	local idCounter = 0

	local ReactNoop
	ReactNoop = {
		_Scheduler = Scheduler,

		getChildren = function(rootID: string?)
			rootID = rootID or DEFAULT_ROOT_ID
			local container = rootContainers[rootID]
			return getChildren(container)
		end,

		getPendingChildren = function(rootID: string?)
			rootID = rootID or DEFAULT_ROOT_ID
			local container = rootContainers[rootID]
			return getPendingChildren(container)
		end,

		getOrCreateRootContainer = function(rootID: string?, tag: RootTag)
			rootID = rootID or DEFAULT_ROOT_ID
			local root = roots[rootID]
			if not root then
				local container = {
					rootID = rootID :: string,
					pendingChildren = {},
					children = {},
				}
				rootContainers[rootID] = container
				root = NoopRenderer.createContainer(container, tag, false, nil)
				roots[rootID] = root
			end
			return root.current.stateNode.containerInfo
		end,

		-- TODO: Replace ReactNoop.render with createRoot + root.render
		createRoot = function()
			local container = {
				rootID = tostring(idCounter),
				pendingChildren = {},
				children = {},
			}
			idCounter += 1
			local fiberRoot = NoopRenderer.createContainer(
				container,
				ConcurrentRoot,
				false,
				nil
			)
			return {
				_Scheduler = Scheduler,
				render = function(children)
					NoopRenderer.updateContainer(children, fiberRoot, nil, nil)
				end,
				getChildren = function()
					return getChildren(container)
				end,
				getChildrenAsJSX = function()
					return getChildrenAsJSX(container)
				end,
			}
		end,

		createBlockingRoot = function()
			local container = {
				rootID = tostring(idCounter),
				pendingChildren = {},
				children = {},
			}
			idCounter += 1
			local fiberRoot = NoopRenderer.createContainer(
				container,
				BlockingRoot,
				false,
				nil
			)
			return {
				_Scheduler = Scheduler,
				render = function(children)
					NoopRenderer.updateContainer(children, fiberRoot, nil, nil)
				end,
				getChildren = function()
					return getChildren(container)
				end,
				getChildrenAsJSX = function()
					return getChildrenAsJSX(container)
				end,
			}
		end,

		createLegacyRoot = function()
			local container = {
				rootID = tostring(idCounter),
				pendingChildren = {},
				children = {},
			}
			idCounter += 1
			local fiberRoot = NoopRenderer.createContainer(
				container,
				LegacyRoot,
				false,
				nil
			)
			return {
				_Scheduler = Scheduler,
				render = function(children)
					NoopRenderer.updateContainer(children, fiberRoot, nil, nil)
				end,
				getChildren = function()
					return getChildren(container)
				end,
				getChildrenAsJSX = function()
					return getChildrenAsJSX(container)
				end,
			}
		end,

		getChildrenAsJSX = function(rootID: string?)
			rootID = rootID or DEFAULT_ROOT_ID
			local container = rootContainers[rootID]
			return getChildrenAsJSX(container)
		end,

		getPendingChildrenAsJSX = function(rootID: string?)
			rootID = rootID or DEFAULT_ROOT_ID
			local container = rootContainers[rootID]
			return getPendingChildrenAsJSX(container)
		end,

		createPortal = function(children, container: Container, key: string?)
			return NoopRenderer.createPortal(children, container, nil, key)
		end,

		-- Shortcut for testing a single root
		render = function(element, callback: Function?)
			ReactNoop.renderToRootWithID(element, DEFAULT_ROOT_ID, callback)
		end,

		renderLegacySyncRoot = function(element, callback: Function?)
			local rootID = DEFAULT_ROOT_ID
			local container = ReactNoop.getOrCreateRootContainer(rootID, LegacyRoot)
			local root = roots[container.rootID]
			NoopRenderer.updateContainer(element, root, nil, callback)
		end,

		renderToRootWithID = function(element, rootID: string, callback: Function?)
			local container = ReactNoop.getOrCreateRootContainer(rootID, ConcurrentRoot)
			local root = roots[container.rootID]
			NoopRenderer.updateContainer(element, root, nil, callback)
		end,

		unmountRootWithID = function(rootID: string)
			local root = roots[rootID]
			if root then
				NoopRenderer.updateContainer(nil, root, nil, function()
					roots[rootID] = nil
					rootContainers[rootID] = nil
				end)
			end
		end,

		findInstance = function(componentOrElement): nil | Instance | TextInstance
			if componentOrElement == nil then
				return nil
			end
			-- Unsound duck typing.
			local component: any = componentOrElement
			if typeof(component.id) == "number" then
				return component
			end
			if _G.__DEV__ then
				return NoopRenderer.findHostInstanceWithWarning(component, "findInstance")
			end
			return NoopRenderer.findHostInstance(component)
		end,

		flushNextYield = function(): Array<any>
			Scheduler.unstable_flushNumberOfYields(1)
			return Scheduler.unstable_clearYields()
		end,

		flushWithHostCounters = function(_fn: () -> ()):
			{
				hostDiffCounter: number,
				hostUpdateCounter: number,
			  }
			| {
				hostDiffCounter: number,
				hostCloneCounter: number,
			  }
			hostDiffCounter = 0
			hostUpdateCounter = 0
			hostCloneCounter = 0
			local ok, result = pcall(function()
				Scheduler.unstable_flushAll()
				if useMutation then
					return {
						hostDiffCounter = hostDiffCounter,
						hostUpdateCounter = hostUpdateCounter,
					}
				else
					return {
						hostDiffCounter = hostDiffCounter,
						hostCloneCounter = hostCloneCounter,
					}
				end
			end)

			hostDiffCounter = 0
			hostUpdateCounter = 0
			hostCloneCounter = 0

			if not ok then
				error(result)
			end
			return result
		end,

		expire = Scheduler.unstable_advanceTime,

		flushExpired = function(): Array<any>
			return Scheduler.unstable_flushExpired()
		end,

		unstable_runWithPriority = NoopRenderer.runWithPriority,

		batchedUpdates = NoopRenderer.batchedUpdates,

		deferredUpdates = NoopRenderer.deferredUpdates,

		unbatchedUpdates = NoopRenderer.unbatchedUpdates,

		discreteUpdates = NoopRenderer.discreteUpdates,

		flushDiscreteUpdates = NoopRenderer.flushDiscreteUpdates,

		flushSync = function(fn: () -> any)
			NoopRenderer.flushSync(fn)
		end,

		flushPassiveEffects = NoopRenderer.flushPassiveEffects,

		-- ROBLOX deviation: can't assign this now, since even if it's pre-declared,
		-- the current value will be nil
		-- act = noopAct,

		-- Logs the current state of the tree.
		dumpTree = function(rootID: string?)
			rootID = rootID or DEFAULT_ROOT_ID
			local root = roots[rootID]
			local rootContainer = rootContainers[rootID]
			if not root or not rootContainer then
				-- eslint-disable-next-line react-internal/no-production-logging
				console.log("Nothing rendered yet.")
				return
			end

			local bufferedLog = {}
			local function log(...)
				local argCount = select("#", ...)
				for i = 1, argCount do
					local arg = select(i, ...)
					table.insert(bufferedLog, arg)
				end
				table.insert(bufferedLog, "\n")
			end

			-- ROBLOX FIXME: This likely needs to be adopted to Roblox
			-- Instance structure as opposed to HTML DOM nodes
			local function logHostInstances(
				children: Array<Instance | TextInstance>,
				depth: number
			)
				-- ROBLOX deviation: May not be able to assume children is an array in
				-- Roblox (we use keys as names), so iterate with `pairs`

				-- ROBLOX FIXME: Might want to iterate in array order if
				-- children _is_ an array
				for _, child in pairs(children) do
					local indent = string.rep("  ", depth)
					if typeof(child.text) == "string" then
						log(indent .. "- " .. (child :: TextInstance).text)
					else
						-- $FlowFixMe - The child should've been refined now.
						log(indent .. "- " .. (child :: Instance).type .. "#" .. tostring(child.id))
						-- $FlowFixMe - The child should've been refined now.
						logHostInstances((child :: Instance).children, depth + 1)
					end
				end
			end

			local function logContainer(container: Container, depth: number)
				log(string.rep("  ", depth) .. "- [root#" .. container.rootID .. "]")
				logHostInstances(container.children, depth + 1)
			end

			local function logUpdateQueue(updateQueue: UpdateQueue<any>, depth: number)
				log(string.rep("  ", depth + 1) .. "QUEUED UPDATES")
				local first = updateQueue.firstBaseUpdate
				local update = first
				if update ~= nil then
					repeat
						log(
							string.rep("  ", depth + 1) .. "~",
								-- ROBLOX TODO: this is a bogus field, even in upstream
								"[" .. tostring((update :: any).expirationTime) .. "]"
						)
					until update == nil
				end

				local lastPending = updateQueue.shared.pending
				if lastPending ~= nil then
					local firstPending = lastPending.next
					local pendingUpdate = firstPending
					if pendingUpdate ~= nil then
						repeat
							log(
								string.rep("  ", depth + 1) .. "~",
								-- ROBLOX TODO: this is a bogus field, even in upstream
								"[" .. tostring((update :: any).expirationTime) .. "]"
							)
						until pendingUpdate == nil or pendingUpdate == firstPending
					end
				end
			end

			local function logFiber(fiber: Fiber, depth: number)
				log(
					string.rep("  ", depth)
							.. "- "
							-- need to explicitly coerce Symbol to a string
							.. fiber.type and (fiber.type.name or tostring(fiber.type))
						or "[root]",
					"["
						-- ROBLOX TODO: this field is bogus even in upstream, will always be nil
						.. tostring((fiber :: any).childExpirationTime)
						.. (fiber.pendingProps and "*" or "")
						.. "]"
				)
				if fiber.updateQueue then
					logUpdateQueue(fiber.updateQueue, depth)
				end
				-- local childInProgress = fiber.progressedChild
				-- if (childInProgress and childInProgress ~= fiber.child) {
				--   log(
				--     '  '.repeat(depth + 1) + 'IN PROGRESS: ' + fiber.pendingWorkPriority,
				--   )
				--   logFiber(childInProgress, depth + 1)
				--   if (fiber.child) {
				--     log('  '.repeat(depth + 1) + 'CURRENT')
				--   }
				-- } else if (fiber.child and fiber.updateQueue) {
				--   log('  '.repeat(depth + 1) + 'CHILDREN')
				-- }
				if fiber.child then
					logFiber(fiber.child, depth + 1)
				end
				if fiber.sibling then
					logFiber(fiber.sibling, depth)
				end
			end

			log("HOST INSTANCES:")
			logContainer(rootContainer, 0)
			log("FIBERS:")
			logFiber(root.current, 0)

			-- eslint-disable-next-line react-internal/no-production-logging
			for _, line in ipairs(bufferedLog) do
				console.log(line)
			end
		end,

		getRoot = function(rootID: string?)
			rootID = rootID or DEFAULT_ROOT_ID
			return roots[rootID]
		end,
	}

	-- This version of `act` is only used by our tests. Unlike the public version
	-- of `act`, it's designed to work identically in both production and
	-- development. It may have slightly different behavior from the public
	-- version, too, since our constraints in our test suite are not the same as
	-- those of developers using React — we're testing React itself, as opposed to
	-- building an app with React.

	local batchedUpdates = NoopRenderer.batchedUpdates
	local IsThisRendererActing = NoopRenderer.IsThisRendererActing
	local actingUpdatesScopeDepth = 0

	local function noopAct(scope: (() -> Thenable<any>) | () -> () )
		if Scheduler.unstable_flushAllWithoutAsserting == nil then
			error(
				Error("This version of `act` requires a special mock build of Scheduler.")
			)
		end
		if typeof(setTimeout) == "table" and setTimeout._isMockFunction ~= true then
			error(
				Error(
					"This version of `act` requires Jest's timer mocks "
						.. "(i.e. jest.useFakeTimers)."
				)
			)
		end

		local previousActingUpdatesScopeDepth = actingUpdatesScopeDepth
		local previousIsSomeRendererActing = IsSomeRendererActing.current
		local previousIsThisRendererActing = IsThisRendererActing.current
		IsSomeRendererActing.current = true
		IsThisRendererActing.current = true
		actingUpdatesScopeDepth += 1

		local unwind = function()
			actingUpdatesScopeDepth -= 1
			IsSomeRendererActing.current = previousIsSomeRendererActing
			IsThisRendererActing.current = previousIsThisRendererActing

			if _G.__DEV__ then
				if actingUpdatesScopeDepth > previousActingUpdatesScopeDepth then
					-- if it's _less than_ previousActingUpdatesScopeDepth, then we can
					-- assume the 'other' one has warned
					console.error(
						"You seem to have overlapping act() calls, this is not supported. "
							.. "Be sure to await previous act() calls before making a new one. "
					)
				end
			end
		end

		-- TODO: This would be way simpler if 1) we required a promise to be
		-- returned and 2) we could use async/await. Since it's only our used in
		-- our test suite, we should be able to.
		local ok, result = pcall(function()
			local thenable = batchedUpdates(scope)
			if typeof(thenable) == "table" and typeof(thenable.andThen) == "function" then
				return {
					andThen = function(self, resolve: () -> (), reject: (any) -> ())
						thenable:andThen(function()
							flushActWork(function()
								unwind()
								resolve()
							end, function(error_)
								unwind()
								reject(error_)
							end)
						end, function(err)
							unwind()
							reject(err)
						end)
					end,
				}
			else
				local ok, result = pcall(function()
					-- TODO: Let's not support non-async scopes at all in our tests. Need to
					-- migrate existing tests.
					local didFlushWork
					repeat
						didFlushWork = Scheduler.unstable_flushAllWithoutAsserting()
					until not didFlushWork
				end)
				unwind()
				if not ok then
					error(result)
				end
				-- ROBLOX deviation: upstream flowtype doesn't mind the inconsistent return, but Luau does
				return nil
			end
		end)
		if not ok then
			unwind()
			error(result)
		end
		return result
	end

	flushActWork = function(resolve, reject)
		-- Flush suspended fallbacks

		-- deviation: FIXME: figure out the difference between runAllTimers and
		-- runOnlyPendingTimers
		RobloxJest.runAllTimers()
		-- $FlowFixMe: Flow doesn't know about global Jest object
		-- jest.runOnlyPendingTimers()

		enqueueTask(function()
			local ok, result = pcall(function()
				local didFlushWork = Scheduler.unstable_flushAllWithoutAsserting()
				if didFlushWork then
					flushActWork(resolve, reject)
				else
					resolve()
				end
			end)
			if not ok then
				reject(result)
			end
		end)
	end

	-- ROBLOX deviation: assign this at the end once it's non-nil
	ReactNoop.act = noopAct

	return ReactNoop
end

return createReactNoop
