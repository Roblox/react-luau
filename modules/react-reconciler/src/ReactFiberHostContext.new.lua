--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberHostContext.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

-- local Packages = script.Parent.Parent

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactFiberStack = require(script.Parent["ReactFiberStack.new"])
type StackCursor<T> = ReactFiberStack.StackCursor<T>
local ReactFiberHostConfig = require(script.Parent.ReactFiberHostConfig)
type Container = ReactFiberHostConfig.Container
type HostContext = ReactFiberHostConfig.HostContext

-- local invariant = require(Packages.Shared).invariant

local getChildHostContext = ReactFiberHostConfig.getChildHostContext
local getRootHostContext = ReactFiberHostConfig.getRootHostContext
local createCursor = ReactFiberStack.createCursor
local push = ReactFiberStack.push
local pop = ReactFiberStack.pop

-- FIXME (roblox): The upstream code here should be guaranteeing that the type
-- is always this exact object, but I think ours will match against any empty
-- table
-- declare class NoContextT {}
type NoContextT = {}
local NO_CONTEXT: NoContextT = {}

local contextStackCursor: StackCursor<HostContext | NoContextT> = createCursor(NO_CONTEXT)
local contextFiberStackCursor: StackCursor<Fiber | NoContextT> = createCursor(NO_CONTEXT)
local rootInstanceStackCursor: StackCursor<Container | NoContextT> =
	createCursor(NO_CONTEXT)

function requiredContext<Value>(c: Value | NoContextT): Value
	-- ROBLOX performance: eliminate expensive optional cmp in hot path
	-- invariant(
	--   c ~= NO_CONTEXT,
	--   "Expected host context to exist. This error is likely caused by a bug " ..
	--     "in React. Please file an issue."
	-- )
	return c :: any
end

function getRootHostContainer(): Container
	-- ROBLOX performance: inline requiredContext impl for hot path
	-- local rootInstance = requiredContext(rootInstanceStackCursor.current)
	-- return rootInstance
	return rootInstanceStackCursor.current
end

function pushHostContainer(fiber: Fiber, nextRootInstance: Container)
	-- Push current root instance onto the stack
	-- This allows us to reset root when portals are popped.
	push(rootInstanceStackCursor, nextRootInstance, fiber)
	-- Track the context and the Fiber that provided it.
	-- This enables us to pop only Fibers that provide unique contexts.
	push(contextFiberStackCursor, fiber, fiber)

	-- Finally, we need to push the host context to the stack.
	-- However, we can't just call getRootHostContext() and push it because
	-- we'd have a different number of entries on the stack depending on
	-- whether getRootHostContext() throws somewhere in renderer code or not.
	-- So we push an empty value first. This lets us safely unwind on errors.
	push(contextStackCursor, NO_CONTEXT, fiber)
	local nextRootContext = getRootHostContext(nextRootInstance)
	-- Now that we know this function doesn't throw, replace it.
	pop(contextStackCursor, fiber)
	push(contextStackCursor, nextRootContext, fiber)
end

function popHostContainer(fiber: Fiber)
	pop(contextStackCursor, fiber)
	pop(contextFiberStackCursor, fiber)
	pop(rootInstanceStackCursor, fiber)
end

function getHostContext(): HostContext
	-- ROBLOX performance: inline requiredContext impl for hot path
	-- local context = requiredContext(contextStackCursor.current)
	-- return context
	return contextStackCursor.current
end

function pushHostContext(fiber: Fiber)
	local rootInstance: Container = requiredContext(rootInstanceStackCursor.current)
	local context: HostContext = requiredContext(contextStackCursor.current)
	local nextContext = getChildHostContext(context, fiber.type, rootInstance)

	-- Don't push this Fiber's context unless it's unique.
	if context == nextContext then
		return
	end

	-- Track the context and the Fiber that provided it.
	-- This enables us to pop only Fibers that provide unique contexts.
	push(contextFiberStackCursor, fiber, fiber)
	push(contextStackCursor, nextContext, fiber)
end

function popHostContext(fiber: Fiber)
	-- Do not pop unless this Fiber provided the current context.
	-- pushHostContext() only pushes Fibers that provide unique contexts.
	if contextFiberStackCursor.current ~= fiber then
		return
	end

	pop(contextStackCursor, fiber)
	pop(contextFiberStackCursor, fiber)
end

return {
	getHostContext = getHostContext,
	getRootHostContainer = getRootHostContainer,
	popHostContainer = popHostContainer,
	popHostContext = popHostContext,
	pushHostContainer = pushHostContainer,
	pushHostContext = pushHostContext,
}
