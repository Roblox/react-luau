-- Upstream: https://github.com/facebook/react/blob/16654436039dd8f16a63928e71081c7745872e8f/packages/react-test-renderer/src/ReactTestRenderer.js
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */

local Packages = script.Parent.Parent
-- local jest = require(Packages.RobloxJest)
local Scheduler = require(Packages.Scheduler)
local console = require(Packages.Shared).console
local LuauPolyfill = require(Packages.LuauPolyfill)
local Symbol = LuauPolyfill.Symbol
local Array = LuauPolyfill.Array
local Object = LuauPolyfill.Object
local setTimeout = LuauPolyfill.setTimeout
local ReactTypes = require(Packages.Shared)
type React_Element<T> = ReactTypes.React_Element<T>

local ReactInternalTypes = require(Packages.ReactReconciler)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot

type Thenable<R> = ReactTypes.Thenable<R>

-- ROBLOX TODO: split below to silence analyze, but why is analyze throwing in first place?
local ReactTestHostConfig = require(script.Parent.ReactTestHostConfig)
-- ROBLOX deviation: For all tests, we mock the reconciler into a configurable
-- function interface that allows injection of HostConfig
local ReactReconciler = require(Packages.ReactReconciler)
local ReactFiberReconciler = ReactReconciler(ReactTestHostConfig)

local getPublicRootInstance = ReactFiberReconciler.getPublicRootInstance
local createContainer = ReactFiberReconciler.createContainer
local updateContainer = ReactFiberReconciler.updateContainer
local flushSync = ReactFiberReconciler.flushSync
local injectIntoDevTools = ReactFiberReconciler.injectIntoDevTools
local batchedUpdates = ReactFiberReconciler.batchedUpdates
local act = ReactFiberReconciler.act
local IsThisRendererActing = ReactFiberReconciler.IsThisRendererActing
local findCurrentFiberUsingSlowPath = ReactFiberReconciler.findCurrentFiberUsingSlowPath
local ReactWorkTags = ReactFiberReconciler.ReactWorkTags
local Fragment = ReactWorkTags.Fragment
local FunctionComponent = ReactWorkTags.FunctionComponent
local ClassComponent = ReactWorkTags.ClassComponent
local HostComponent = ReactWorkTags.HostComponent
local HostPortal = ReactWorkTags.HostPortal
local HostText = ReactWorkTags.HostText
local HostRoot = ReactWorkTags.HostRoot
local ContextConsumer = ReactWorkTags.ContextConsumer
local ContextProvider = ReactWorkTags.ContextProvider
local Mode = ReactWorkTags.Mode
local ForwardRef = ReactWorkTags.ForwardRef
local Profiler = ReactWorkTags.Profiler
local MemoComponent = ReactWorkTags.MemoComponent
local SimpleMemoComponent = ReactWorkTags.SimpleMemoComponent
local Block = ReactWorkTags.Block
local IncompleteClassComponent = ReactWorkTags.IncompleteClassComponent
local ScopeComponent = ReactWorkTags.ScopeComponent
local Shared = require(Packages.Shared)
local invariant = Shared.invariant

local getComponentName = Shared.getComponentName
local ReactVersion = Shared.ReactVersion
local ReactSharedInternals = require(Packages.Shared).ReactSharedInternals
local enqueueTask = Shared.enqueueTask
local getPublicInstance = ReactTestHostConfig.getPublicInstance
local ReactRootTags = ReactFiberReconciler.ReactRootTags
local ConcurrentRoot = ReactRootTags.ConcurrentRoot
local LegacyRoot = ReactRootTags.LegacyRoot
local IsSomeRendererActing = ReactSharedInternals.IsSomeRendererActing
local JSON = game:GetService("HttpService")

-- ROBLOX deviation: add type for Array and Object
type Array<T> = { [number]: T }
type Object = { [string]: any }

type TestRendererOptions = {
	createNodeMock: (element: React_Element<any>) -> any,
	unstable_isConcurrent: boolean,
}

type ReactTestRendererJSON = {
	type: string,
	-- props: {[propName: string]: any, ...},
	props: { [string]: any },
	children: nil | Array<ReactTestRendererNode>,
	-- $$typeof?: Symbol, -- Optional because we add it with defineProperty().
}
type ReactTestRendererNode = ReactTestRendererJSON | string

-- type FindOptions = $Shape<{
--     -- performs a "greedy" search: if a matching node is found, will continue
--     -- to search within the matching node's children. (default: true)
--     deep: boolean,
--     ...
-- }>
type FindOptions = any

export type Predicate = (Object) -> boolean?

local defaultTestOptions = {
	createNodeMock = function()
		return nil
	end,
}

local function toJSON(inst)
	if inst.isHidden then
		-- Omit timed out children from output entirely. This seems like the least
		-- surprising behavior. We could perhaps add a separate API that includes
		-- them, if it turns out people need it.
		return nil
	end

	-- ROBLOX deviation: if/else instead of switch
	if inst.tag == "TEXT" then
		return inst.text
	elseif inst.tag == "INSTANCE" then
		-- /* eslint-disable no-unused-vars */
		-- We don't include the `children` prop in JSON.
		-- Instead, we will include the actual rendered children.
		local props = Object.assign({}, inst.props)
		props.children = nil

		-- /* eslint-enable */
		local renderedChildren = nil
		if inst.children and #inst.children ~= 0 then
			for i = 1, #inst.children do
				local renderedChild = toJSON(inst.children[i])
				if renderedChild ~= nil then
					if renderedChildren == nil then
						renderedChildren = { renderedChild }
					else
						table.insert(renderedChildren, renderedChild)
					end
				end
			end
		end
		local json: ReactTestRendererJSON = {
			type = inst.type,
			props = props,
			children = renderedChildren,
		}
		-- ROBLOX TODO: Symbol.for
		setmetatable(json, {
			__index = function(t, k)
				if k == "$$typeof" then
					return Symbol.for_("react.test.json")
				end
				return
			end,
		})

		return json
	else
		error("Unexpected node type in toJSON: " .. tostring(inst.tag))
	end
end

local function flatten(arr)
	local result = {}
	local stack = {
		{
			i = 1,
			array = arr,
		},
	}

	while #stack ~= 0 do
		local n = table.remove(stack, #stack)

		while n.i <= #n.array do
			local el = n.array[n.i]

			n.i = n.i + 1

			if Array.isArray(el) then
				table.insert(stack, n)
				table.insert(stack, {
					i = 1,
					array = el,
				})
				break
			end

			table.insert(result, el)
		end
	end

	return result
end

local function nodeAndSiblingsArray(nodeWithSibling)
	local array = {}
	local node = nodeWithSibling

	while node ~= nil do
		table.insert(array, node)
		node = node.sibling
	end

	return array
end

-- ROBLOX deviation: toTree needs to be pre-declared to avoid function call cycle
local toTree

local function childrenToTree(node)
	if not node then
		return nil
	end

	local children = nodeAndSiblingsArray(node)

	if #children == 0 then
		return nil
	elseif #children == 1 then
		return toTree(children[1])
	end

	return flatten(Array.map(children, toTree))
end

-- ROBLOX deviation: change node variable name to nodeInput so we can keep the node name
-- for the majority of the function body after the initial nil check and recast
toTree = function(nodeInput: Fiber | nil)
	if nodeInput == nil then
		return nil
	end

	-- ROBLOX deviation: silence analyze by recasting
	local node: any = nodeInput

	-- ROBLOX deviation: swtich converted to if/else
	if node.tag == HostRoot then
		return childrenToTree(node.child)
	elseif node.tag == HostPortal then
		return childrenToTree(node.child)
	elseif node.tag == ClassComponent then
		return {
			nodeType = "component",
			type = node.type,
			-- ROBLOX deviation: Uses Object.assign for shallow copy
			props = Object.assign({}, node.memoizedProps),
			instance = node.stateNode,
			rendered = childrenToTree(node.child),
		}
	elseif node.tag == SimpleMemoComponent or node.tag == FunctionComponent then
		return {
			nodeType = "component",
			type = node.type,
			-- ROBLOX deviation: Uses Object.assign for shallow copy
			props = Object.assign({}, node.memoizedProps),
			instance = nil,
			rendered = childrenToTree(node.child),
		}
	elseif node.tag == Block then
		return {
			nodeType = "block",
			type = node.type,
			-- ROBLOX deviation: Uses Object.assign for shallow copy
			props = Object.assign({}, node.memoizedProps),
			instance = nil,
			rendered = childrenToTree(node.child),
		}
	elseif node.tag == HostComponent then
		return {
			nodeType = "host",
			type = node.type,
			-- ROBLOX deviation: Uses Object.assign for shallow copy
			props = Object.assign({}, node.memoizedProps),
			instance = nil, -- TODO: use createNodeMock here somehow?
			rendered = flatten(Array.map(nodeAndSiblingsArray(node.child), toTree)),
		}
	elseif node.tag == HostText then
		return node.stateNode.text
	elseif
		node.tag == Fragment
		or node.tag == ContextProvider
		or node.tag == ContextConsumer
		or node.tag == Mode
		or node.tag == Profiler
		or node.tag == ForwardRef
		or node.tag == MemoComponent
		or node.tag == IncompleteClassComponent
		or node.tag == ScopeComponent
	then
		return childrenToTree(node.child)
	else
		invariant(
			false,
			"toTree() does not yet know how to handle nodes with tag="
				.. tostring(node.tag)
		)
	end
	return
end

-- ROBLOX TODO: port ReactTestInstance type infered from the upstream class declaration
local ReactTestInstance = {}

-- ROBLOX deviation: not using Set()
local validWrapperTypes = {
	[FunctionComponent] = true,
	[ClassComponent] = true,
	[HostComponent] = true,
	[ForwardRef] = true,
	[MemoComponent] = true,
	[SimpleMemoComponent] = true,
	[Block] = true,
	-- Normally skipped, but used when there's more than one root child.
	[HostRoot] = true,
}

-- ROBLOX deviation: use table in place of WeakMap
local fiberToWrapper = {}
local function wrapFiber(fiber: Fiber): Object
	local wrapper = fiberToWrapper[fiber]

	if wrapper == nil and fiber.alternate ~= nil then
		wrapper = fiberToWrapper[fiber.alternate]
	end
	if wrapper == nil then
		wrapper = ReactTestInstance.new(fiber)
		fiberToWrapper["fiber"] = wrapper
	end

	return wrapper
end

local function getChildren(parent)
	local children = {}
	local startingNode = parent
	local node = startingNode

	if node.child == nil then
		return children
	end

	node.child.return_ = node
	node = node.child

	-- ROBLOX deviation: use break flag instead of labeled loops
	local breakOuter = false

	while true do
		local descend = false
		if validWrapperTypes[node.tag] ~= nil then
			table.insert(children, wrapFiber(node))
		elseif node.tag == HostText then
			table.insert(children, "" .. node.memoizedProps)
		else
			descend = true
		end
		if descend and node.child ~= nil then
			node.child.return_ = node
			node = node.child
			continue
		end
		while node.sibling == nil do
			if node.return_ == startingNode then
				breakOuter = true
				break
			end
			node = node.return_
		end
		-- ROBLOX deviation: use break flag instead of labeled loops
		if breakOuter then
			break
		end
		node.sibling.return_ = node.return_
		node = node.sibling
	end
	return children
end

local function findAll(
	root: Object,
	predicate: Predicate,
	options: FindOptions?
): Array<Object>
	-- ROBLOX deviation: ternary split to conditional statement
	local deep = true
	if options then
		deep = options.deep
	end
	local results = {}

	if predicate(root) then
		table.insert(results, root)
		if not deep then
			return results
		end
	end

	-- ROBLOX deviation: use for loop instead of forEach
	for _, child in ipairs(root.children) do
		if typeof(child) == "string" then
			continue
		end
		-- ROBLOX deviation: use for loop to insert mulltiple elements
		local findAllResult = findAll(child, predicate, options)
		for i = 1, #findAllResult do
			table.insert(results, findAllResult[i])
		end
	end
	return results
end

local function expectOne(all: Array<Object>, message: string): Object
	if #all == 1 then
		return all[1]
	end

	local prefix
	if #all == 0 then
		prefix = "No instances found "
	else
		prefix = ("Expected 1 but found %s instances "):format(tostring(#all))
	end

	error(prefix .. message)
end

local function propsMatch(props: Object, filter: Object): boolean
	for key, _ in pairs(filter) do
		if props[key] ~= filter[key] then
			return false
		end
	end
	return true
end

function ReactTestInstance:_currentFiber(): Fiber
	-- Throws if this component has been unmounted.
	local fiber = findCurrentFiberUsingSlowPath(self._fiber)
	invariant(
		fiber ~= nil,
		"Can't read from currently-mounting component. This error is likely "
			.. "caused by a bug in React. Please file an issue."
	)
	return fiber
end

-- ROBLOX deviation:  metatable includes upstream
-- getter methods and Class methods
local function ReactTestInstanceGetters(self, key)
	if key == "instance" then
		if self._fiber.tag == HostComponent then
			return getPublicInstance(self._fiber.stateNode)
		else
			return self._fiber.stateNode
		end
	elseif key == "type" then
		return self._fiber.type
	elseif key == "props" then
		return self:_currentFiber().memoizedProps
	elseif key == "parent" then
		local parent = self._fiber.return_
		while parent ~= nil do
			if validWrapperTypes[parent.tag] ~= nil then
				if parent.tag == HostRoot then
					-- Special case: we only "materialize" instances for roots
					-- if they have more than a single child. So we'll check that now.
					if #getChildren(parent) < 2 then
						return nil
					end
				end
				return wrapFiber(parent)
			end
			parent = parent.return_
		end
		return nil
	elseif key == "children" then
		return getChildren(self:_currentFiber())
	else
		return ReactTestInstance[key]
	end
end

function ReactTestInstance.new(fiber: Fiber)
	invariant(
		validWrapperTypes[fiber.tag] ~= nil,
		"Unexpected object passed to ReactTestInstance constructor (tag: %s). "
			.. "This is probably a bug in React.",
		fiber.tag
	)
	local testInstance = {}

	-- ROBLOX deviation: set metatable to ReactTestInstanceGetters which includes upstream
	-- getter methods and Class methods
	setmetatable(testInstance, {
		__index = ReactTestInstanceGetters,
	})
	testInstance._fiber = fiber
	return testInstance
end

-- Custom search functions
function ReactTestInstance:find(predicate: Predicate): Object
	return expectOne(
		self:findAll(predicate, { deep = false }),
		("matching custom predicate: %s"):format(tostring(predicate))
	)
end
function ReactTestInstance:findByType(type_: any): Object
	return expectOne(
		self:findAllByType(type_, { deep = false }),
		('with node type: "%s"'):format(getComponentName(type_) or "Unknown")
	)
end
function ReactTestInstance:findByProps(props: Object): Object
	return expectOne(
		self:findAllByProps(props, { deep = false }),
		("with props: %s"):format(JSON:JSONEncode(props))
	)
end
function ReactTestInstance:findAll(
	predicate: Predicate,
	options: FindOptions?
): Array<Object>
	return findAll(self, predicate, options)
end
function ReactTestInstance:findAllByType(type_: any, options: FindOptions?): Array<Object>
	return findAll(self, function(node)
		return node.type == type_
	end, options)
end
function ReactTestInstance:findAllByProps(
	props: Object,
	options: FindOptions?
): Array<Object>
	return findAll(self, function(node)
		return node.props and propsMatch(node.props, props)
	end, options)
end

local function create(element: React_Element<any>, options: TestRendererOptions)
	local createNodeMock = defaultTestOptions.createNodeMock
	local isConcurrent = false

	if typeof(options) == "table" and options ~= nil then
		if typeof(options.createNodeMock) == "function" then
			createNodeMock = options.createNodeMock
		end
		if options.unstable_isConcurrent == true then
			isConcurrent = true
		end
	end

	local container = {
		children = {},
		createNodeMock = createNodeMock,
		tag = "CONTAINER",
	}

	local rootArg = LegacyRoot
	if isConcurrent then
		rootArg = ConcurrentRoot
	end

	-- ROBLOX deviation: remove Fiber? type to silence analyze
	local root = createContainer(container, rootArg, false, nil)

	invariant(root ~= nil, "something went wrong")
	updateContainer(element, root, nil, nil)

	local entry = {
		_Scheduler = Scheduler,
		root = nil, -- makes flow happy
		-- we define a 'getter' for 'root' below using 'Object.defineProperty'
		toJSON = function()
			if root == nil or root.current == nil or container == nil then
				return nil
			end
			if #container.children == 0 then
				return nil
			end
			if #container.children == 1 then
				return toJSON(container.children[1])
			end
			if
				#container.children == 2
				and container.children[1].isHidden == true
				and container.children[2].isHidden == false
			then
				-- Omit timed out children from output entirely, including the fact that we
				-- temporarily wrap fallback and timed out children in an array.
				return toJSON(container.children[2])
			end

			local renderedChildren = nil

			if container.children and #container.children ~= 0 then
				for i = 1, #container.children do
					local renderedChild = toJSON(container.children[i])

					if renderedChild ~= nil then
						if renderedChildren == nil then
							renderedChildren = { renderedChild }
						else
							table.insert(renderedChildren, renderedChild)
						end
					end
				end
			end

			return renderedChildren
		end,
		toTree = function()
			if root == nil or root.current == nil then
				return nil
			end

			return toTree(root.current)
		end,
		update = function(newElement: React_Element<any>)
			if root == nil or root.current == nil then
				return
			end

			updateContainer(newElement, root, nil, nil)
		end,
		unmount = function()
			if root == nil or root.current == nil then
				return
			end

			updateContainer(nil, root, nil, nil)

			root = nil
		end,
		getInstance = function()
			if root == nil or root.current == nil then
				return nil
			end

			return getPublicRootInstance(root)
		end,
		unstable_flushSync = function(fn)
			return flushSync(fn)
		end,
	}

	setmetatable(entry, {
		__index = function(t, k)
			if k == "root" then
				if root == nil then
					error("Can't access .root on unmounted test renderer")
				end

				local children = getChildren(root.current)

				if #children == 0 then
					error("Can't access .root on unmounted test renderer")
				elseif #children == 1 then
					return children[1]
				else
					return wrapFiber(root.current)
				end
			end
			return
		end,
	})

	return entry
end

-- Enable ReactTestRenderer to be used to test DevTools integration.
local bundleType = 0
if _G.__DEV__ then
	bundleType = 1
end

injectIntoDevTools({
	findFiberByHostInstance = function()
		error("TestRenderer does not support findFiberByHostInstance()")
	end,
	bundleType = bundleType,
	version = ReactVersion,
	rendererPackageName = "react-test-renderer",
})

local actingUpdatesScopeDepth = 0

-- This version of `act` is only used by our tests. Unlike the public version
-- of `act`, it's designed to work identically in both production and
-- development. It may have slightly different behavior from the public
-- version, too, since our constraints in our test suite are not the same as
-- those of developers using React — we're testing React itself, as opposed to
-- building an app with React.
-- TODO: Migrate our tests to use ReactNoop. Although we would need to figure
-- out a solution for Relay, which has some Concurrent Mode tests.
local function unstable_concurrentAct(scope: () -> () | Thenable<any>)
	if Scheduler.unstable_flushAllWithoutAsserting == nil then
		error("This version of `act` requires a special mock build of Scheduler.")
	end
	if typeof(setTimeout) == "table" and setTimeout._isMockFunction ~= true then
		error(
			"This version of `act` requires Jest's timer mocks "
				.. "(i.e. jest.useFakeTimers)."
		)
	end

	local previousActingUpdatesScopeDepth = actingUpdatesScopeDepth
	local previousIsSomeRendererActing = IsSomeRendererActing.current
	local previousIsThisRendererActing = IsThisRendererActing.current

	IsSomeRendererActing.current = true
	IsThisRendererActing.current = true
	actingUpdatesScopeDepth = actingUpdatesScopeDepth + 1

	local unwind = function()
		actingUpdatesScopeDepth = actingUpdatesScopeDepth - 1
		IsSomeRendererActing.current = previousIsSomeRendererActing
		IsThisRendererActing.current = previousIsThisRendererActing

		if _G.__DEV__ then
			if actingUpdatesScopeDepth > previousActingUpdatesScopeDepth then
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
	local ok, _ = pcall(function()
		local thenable = batchedUpdates(scope)
		if
			typeof(thenable) == "table"
			and thenable ~= nil
			and typeof(thenable.andThen) == "function"
		then
			return function(resolve, reject)
				thenable:andThen(function()
					flushActWork(function()
						unwind()
						resolve()
					end, function(error_)
						unwind()
						reject(error_)
					end)
				end, function(error_)
					unwind()
					reject(error_)
				end)
			end
		else
			local _, _ = pcall(function()
				-- TODO: Let's not support non-async scopes at all in our tests. Need to
				-- migrate existing tests.
				local didFlushWork
				repeat
					didFlushWork = Scheduler.unstable_flushAllWithoutAsserting()
				until not didFlushWork
			end)
			-- ROBLOX finally
			unwind()
		end
		return
	end)
	if not ok then
		unwind()
		error("")
	end
end

function flushActWork(resolve, reject)
	-- Flush suspended fallbacks
	-- $FlowFixMe: Flow doesn't know about global Jest object

	-- ROBLOX TODO: Jest runONlyPendingTimers() not implemented (uncomment line below)
	-- jest.runOnlyPendingTimers()

	enqueueTask(function()
		local ok, _ = pcall(function()
			local didFlushWork = Scheduler.unstable_flushAllWithoutAsserting()
			if didFlushWork then
				flushActWork(resolve, reject)
			else
				resolve()
			end
		end)
		if not ok then
			reject(error)
		end
	end)
end

return {
	Scheduler = Scheduler,
	create = create,
	unstable_batchedUpdates = batchedUpdates,
	act = act,
	unstable_concurrentAct = unstable_concurrentAct,
}
