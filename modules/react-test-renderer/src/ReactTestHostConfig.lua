-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react-test-renderer/src/ReactTestHostConfig.js
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

local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
type Object = LuauPolyfill.Object
local setTimeout = LuauPolyfill.setTimeout
local clearTimeout = LuauPolyfill.clearTimeout

-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactTypes = require(Packages.Shared)
type ReactFundamentalComponentInstance<T, U> = ReactTypes.ReactFundamentalComponentInstance<
	T,
	U
>

local ReactSymbols = require(Packages.Shared).ReactSymbols
local REACT_OPAQUE_ID_TYPE = ReactSymbols.REACT_OPAQUE_ID_TYPE

local RobloxComponentProps = require(script.Parent.roblox.RobloxComponentProps)

type Array<T> = { [number]: T }
type Function = (any) -> any

export type Type = string
export type Props = Object
export type Container = {
	children: Array<Instance | TextInstance>,
	createNodeMock: Function,
	tag: string, -- ROBLOX deviation: Luau can't specify literals
}
export type Instance = {
	type: string,
	props: Object,
	isHidden: boolean,
	children: Array<Instance | TextInstance>,
	internalInstanceHandle: Object,
	rootContainerInstance: Container,
	tag: "INSTANCE",
}
export type TextInstance = {
	text: string,
	isHidden: boolean,
	tag: string,
}
export type HydratableInstance = Instance | TextInstance
export type PublicInstance = Instance | TextInstance
export type HostContext = Object
export type UpdatePayload = Object
-- Unused
-- export type ChildSet = void;

-- FIXME (roblox): This typically uses a builtin flowtype called 'TimeoutID', we
-- should find a common solution for polyfill types with Luau
export type TimeoutHandle = any
export type NoTimeout = number
export type EventResponder = any
-- deviation: explicitly include `$$typeof` in type def
export type OpaqueIDType = string | Object
-- export type OpaqueIDType = string | {
-- 	toString: () -> string?,
-- 	valueOf: () -> string?,
-- };

export type RendererInspectionConfig = {}

local ReactFiberHostConfig = require(Packages.Shared).ReactFiberHostConfig
local exports = Object.assign(
	{},
	ReactFiberHostConfig.WithNoPersistence,
	ReactFiberHostConfig.WithNoHydration,
	ReactFiberHostConfig.WithNoTestSelectors
) :: { [string]: any }

local NO_CONTEXT = {}
local UPDATE_SIGNAL = {}
local nodeToInstanceMap: { [Object]: Instance? } = {}

if _G.__DEV__ then
	Object.freeze(NO_CONTEXT)
	Object.freeze(UPDATE_SIGNAL)
end

exports.getPublicInstance = function(inst: Instance | TextInstance)
	-- ROBLOX FIXME Luau: Luau should narrow to Instance based on singleton type comparison
	if inst.tag == "INSTANCE" then
		local createNodeMock = (inst :: Instance).rootContainerInstance.createNodeMock
		local mockNode = createNodeMock({
			type = (inst :: Instance).type,
			props = (inst :: Instance).props,
		})
		if typeof(mockNode) == "table" then
			nodeToInstanceMap[mockNode] = inst :: Instance
		end
		return mockNode
	else
		return inst
	end
end

exports.appendChild = function(
	parentInstance: Instance | Container,
	child: Instance | TextInstance
)
	if _G.__DEV__ then
		if not Array.isArray(parentInstance.children) then
			console.error(
				"An invalid container has been provided. "
					.. "This may indicate that another renderer is being used in addition to the test renderer. "
					.. "(For example, ReactNoop.createPortal inside of a ReactTestRenderer tree.) "
					.. "This is not supported."
			)
		end
	end
	local index = Array.indexOf(parentInstance.children, child)
	if index ~= -1 then
		Array.splice(parentInstance.children, index, 1)
	end
	table.insert(parentInstance.children, child)
end

exports.insertBefore = function(
	parentInstance: Instance | Container,
	child: Instance | TextInstance,
	beforeChild: Instance | TextInstance
)
	local index = Array.indexOf(parentInstance.children, child)
	if index ~= -1 then
		Array.splice(parentInstance.children, index, 1)
	end
	local beforeIndex = Array.indexOf(parentInstance.children, beforeChild)
	Array.splice(parentInstance.children, beforeIndex, 0, child)
end

exports.removeChild = function(
	parentInstance: Instance | Container,
	child: Instance | TextInstance
)
	RobloxComponentProps.removeTags(child)
	local index = Array.indexOf(parentInstance.children, child)
	Array.splice(parentInstance.children, index, 1)
end

exports.clearContainer = function(container: Container)
	Array.splice(container.children, 0)
end

exports.getRootHostContext = function(rootContainerInstance: Container): HostContext
	return NO_CONTEXT
end

exports.getChildHostContext = function(
	parentHostContext: HostContext,
	type: string,
	rootContainerInstance: Container
): HostContext
	return NO_CONTEXT
end

exports.prepareForCommit = function(containerInfo: Container): Object?
	-- noop
	return nil
end

exports.resetAfterCommit = function(containerInfo: Container)
	-- noop
end

exports.createInstance = function(
	type: string,
	props: Props,
	rootContainerInstance: Container,
	hostContext: Object,
	internalInstanceHandle: Object
): Instance
	return {
		type = type,
		props = props,
		isHidden = false,
		children = {},
		internalInstanceHandle = internalInstanceHandle,
		rootContainerInstance = rootContainerInstance,
		tag = "INSTANCE",
	}
end

exports.appendInitialChild = function(
	parentInstance: Instance,
	child: Instance | TextInstance
)
	local index = Array.indexOf(parentInstance.children, child)
	if index ~= -1 then
		Array.splice(parentInstance.children, index, 1)
	end
	table.insert(parentInstance.children, child)
end

exports.finalizeInitialChildren = function(
	testElement: Instance,
	type_: string,
	props: Props,
	rootContainerInstance: Container,
	hostContext: Object
): boolean
	RobloxComponentProps.setInitialTags(testElement, type_, props, rootContainerInstance)
	return false
end

exports.prepareUpdate = function(
	testElement: Instance,
	type: string,
	oldProps: Props,
	newProps: Props,
	rootContainerInstance: Container,
	hostContext: Object
): Object?
	return UPDATE_SIGNAL
end

exports.shouldSetTextContent = function(type: string, props: Props): boolean
	return false
end

exports.createTextInstance = function(
	text: string,
	rootContainerInstance: Container,
	hostContext: Object,
	internalInstanceHandle: Object
): TextInstance
	return {
		text = text,
		isHidden = false,
		tag = "TEXT",
	}
end

exports.isPrimaryRenderer = false
exports.warnsIfNotActing = true

exports.scheduleTimeout = setTimeout
exports.cancelTimeout = clearTimeout
exports.noTimeout = -1

-- -------------------
--     Mutation
-- -------------------

exports.supportsMutation = true

exports.commitUpdate = function(
	instance: Instance,
	updatePayload: { [any]: any },
	type: string,
	oldProps: Props,
	newProps: Props,
	internalInstanceHandle: Object
)
	instance.type = type
	instance.props = newProps
	RobloxComponentProps.updateTags(instance, newProps, oldProps)
end

exports.commitMount = function(
	instance: Instance,
	type: string,
	newProps: Props,
	internalInstanceHandle: Object
)
	-- noop
end

exports.commitTextUpdate = function(
	textInstance: TextInstance,
	oldText: string,
	newText: string
)
	textInstance.text = newText
end

exports.resetTextContent = function(testElement: Instance)
	-- noop
end

exports.appendChildToContainer = exports.appendChild
exports.insertInContainerBefore = exports.insertBefore
exports.removeChildFromContainer = exports.removeChild

exports.hideInstance = function(instance: Instance)
	instance.isHidden = true
end

exports.hideTextInstance = function(textInstance: TextInstance)
	textInstance.isHidden = true
end

exports.unhideInstance = function(instance: Instance, props: Props)
	instance.isHidden = false
end

exports.unhideTextInstance = function(textInstance: TextInstance, text: string)
	textInstance.isHidden = false
end

exports.getFundamentalComponentInstance = function(fundamentalInstance: ReactFundamentalComponentInstance<
	any,
	any
>): Instance
	local impl = fundamentalInstance.impl
	local props = fundamentalInstance.props
	local state = fundamentalInstance.state
	return impl.getInstance(nil, props, state)
end

exports.mountFundamentalComponent = function(
	fundamentalInstance: ReactFundamentalComponentInstance<
		any,
		any
	>
)
	local impl = fundamentalInstance.impl
	local instance = fundamentalInstance.instance
	local props = fundamentalInstance.props
	local state = fundamentalInstance.state
	local onMount = impl.onMount
	if onMount ~= nil then
		onMount(nil, instance, props, state)
	end
end

exports.shouldUpdateFundamentalComponent = function(fundamentalInstance: ReactFundamentalComponentInstance<
	any,
	any
>): boolean
	local impl = fundamentalInstance.impl
	local prevProps = fundamentalInstance.prevProps
	local props = fundamentalInstance.props
	local state = fundamentalInstance.state
	local shouldUpdate = impl.shouldUpdate
	if shouldUpdate ~= nil then
		return shouldUpdate(nil, prevProps, props, state)
	end
	return true
end

exports.updateFundamentalComponent = function(
	fundamentalInstance: ReactFundamentalComponentInstance<
		any,
		any
	>
)
	local impl = fundamentalInstance.impl
	local instance = fundamentalInstance.instance
	local prevProps = fundamentalInstance.prevProps
	local props = fundamentalInstance.props
	local state = fundamentalInstance.state
	local onUpdate = impl.onUpdate
	if onUpdate ~= nil then
		onUpdate(nil, instance, prevProps, props, state)
	end
end

exports.unmountFundamentalComponent = function(fundamentalInstance: ReactFundamentalComponentInstance<
	any,
	any
>)
	local impl = fundamentalInstance.impl
	local instance = fundamentalInstance.instance
	local props = fundamentalInstance.props
	local state = fundamentalInstance.state
	local onUnmount = impl.onUnmount
	if onUnmount ~= nil then
		onUnmount(nil, instance, props, state)
	end
end

exports.getInstanceFromNode = function(mockNode: Object): Object?
	local instance = nodeToInstanceMap[mockNode]
	if instance ~= nil then
		return (instance :: Instance).internalInstanceHandle
	end
	return nil
end

local clientId: number = 0
exports.makeClientId = function(): OpaqueIDType
	-- FIXME (roblox): convert to base 36 representation
	-- return result = 'c_' + (clientId++).toString(36)
	local result = "c_" .. clientId
	clientId += 1
	return result
end

exports.makeClientIdInDEV = function(warnOnAccessInDEV: () -> ()): OpaqueIDType
	-- FIXME (roblox): convert to base 36 representation
	-- local id = 'c_' + (clientId++).toString(36)
	local id = "c_" .. clientId
	clientId += 1
	return {
		toString = function()
			warnOnAccessInDEV()
			return id
		end,
		valueOf = function()
			warnOnAccessInDEV()
			return id
		end,
	}
end

exports.isOpaqueHydratingObject = function(value: any): boolean
	return typeof(value) == "table" and value["$$typeof"] == REACT_OPAQUE_ID_TYPE
end

exports.makeOpaqueHydratingObject = function(attemptToReadValue: () -> ()): OpaqueIDType
	return {
		["$$typeof"] = REACT_OPAQUE_ID_TYPE,
		toString = attemptToReadValue,
		valueOf = attemptToReadValue,
	}
end

exports.beforeActiveInstanceBlur = function(internalInstanceHandle: Object)
	-- noop
end

exports.afterActiveInstanceBlur = function()
	-- noop
end

exports.preparePortalMount = function(portalInstance: Instance)
	-- noop
end

exports.prepareScopeUpdate = function(scopeInstance: Object, inst: Object)
	nodeToInstanceMap[scopeInstance] = inst
end

exports.getInstanceFromScope = function(scopeInstance: Object): Object?
	return nodeToInstanceMap[scopeInstance] or nil
end

return exports
