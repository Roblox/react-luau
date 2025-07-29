--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/6edaf6f764f23043f0cd1c2da355b42f641afd8b/packages/react-refresh/src/ReactFreshRuntime.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

type void = nil --[[ ROBLOX FIXME: adding `void` type alias to make it easier to use Luau `void` equivalent when supported ]]
type Function = (...unknown) -> ()

local Packages = script.Parent.Parent

local LuauPolyfill = require(Packages.LuauPolyfill)
local Array = LuauPolyfill.Array
local Error = LuauPolyfill.Error
local Map = LuauPolyfill.Map
local Set = LuauPolyfill.Set
local WeakMap = LuauPolyfill.WeakMap
type Array<T> = LuauPolyfill.Array<T>
type Map<T, U> = LuauPolyfill.Map<T, U>
type Set<T> = LuauPolyfill.Set<T>
type WeakMap<T, U> = LuauPolyfill.WeakMap<T, U>

local exports = {}

local ReactReconciler = require(Packages.ReactReconciler)
type Instance = ReactReconciler.Instance
type FiberRoot = ReactReconciler.FiberRoot
type Family = ReactReconciler.Family
type RefreshUpdate = ReactReconciler.RefreshUpdate
type ScheduleRefresh = ReactReconciler.ScheduleRefresh
type ScheduleRoot = ReactReconciler.ScheduleRoot
type FindHostInstancesForRefresh = ReactReconciler.FindHostInstancesForRefresh
type SetRefreshHandler = ReactReconciler.SetRefreshHandler
local Shared = require(Packages.Shared)
type ReactNodeList = Shared.ReactNodeList

local ReactSymbols = Shared.ReactSymbols
local REACT_MEMO_TYPE = ReactSymbols.REACT_MEMO_TYPE
local REACT_FORWARD_REF_TYPE = ReactSymbols.REACT_FORWARD_REF_TYPE

type Signature = {
	ownKey: string,
	forceReset: boolean,
	fullKey: string | nil, -- Contains keys of nested Hooks. Computed lazily.
	getCustomHooks: () -> Array<Function>,
}

type RendererHelpers = {
	findHostInstancesForRefresh: FindHostInstancesForRefresh,
	scheduleRefresh: ScheduleRefresh,
	scheduleRoot: ScheduleRoot,
	setRefreshHandler: SetRefreshHandler,
}

local __DEV__ = _G.__DEV__

if not __DEV__ then
	error(
		Error.new(
			"React Refresh runtime should not be included in the production bundle."
		)
	)
end

-- In old environments, we'll leak previous types after every edit.
-- ROBLOX deviation: always use WeakMap
-- local PossiblyWeakMap = if typeof(WeakMap) == "function" then WeakMap else Map
local PossiblyWeakMap = WeakMap

-- We never remove these associations.
-- It's OK to reference families, but use WeakMap/Set for types.
local allFamiliesByID: Map<string, Family> = Map.new()
-- ROBLOX deviation: Luau does not handle these type unions very well
-- local allFamiliesByType:  --[[$FlowIssue]]WeakMap<any, Family> | Map<any, Family> =
-- 	PossiblyWeakMap.new()
-- local allSignaturesByType:  --[[$FlowIssue]]WeakMap<any, Signature> | Map<any, Signature> =
-- 	PossiblyWeakMap.new()
local allFamiliesByType: WeakMap<any, Family> = PossiblyWeakMap.new()
local allSignaturesByType: WeakMap<any, Signature> = PossiblyWeakMap.new()
-- This WeakMap is read by React, so we only put families
-- that have actually been edited here. This keeps checks fast.
-- $FlowIssue
-- ROBLOX deviation: Luau does not handle these type unions very well
-- local updatedFamiliesByType:  --[[$FlowIssue]]WeakMap<any, Family> | Map<any, Family> =
-- 	PossiblyWeakMap.new()
local updatedFamiliesByType: WeakMap<any, Family> = PossiblyWeakMap.new()

-- This is cleared on every performReactRefresh() call.
-- It is an array of [Family, NextType] tuples.
local pendingUpdates: Array<Array<Family | any>> = {}

-- This is injected by the renderer via DevTools global hook.
local helpersByRendererID: Map<number, RendererHelpers> = Map.new()

local helpersByRoot: Map<FiberRoot, RendererHelpers> = Map.new()

-- We keep track of mounted roots so we can schedule updates.
local mountedRoots: Set<FiberRoot> = Set.new()
-- If a root captures an error, we remember it so we can retry on edit.
local failedRoots: Set<FiberRoot> = Set.new()

-- In environments that support WeakMap, we also remember the last element for every root.
-- It needs to be weak because we do this even for roots that failed to mount.
-- If there is no WeakMap, we won't attempt to do retrying.
-- $FlowIssue
local rootElements: WeakMap<any, ReactNodeList> | nil = -- $FlowIssue
	if typeof(WeakMap) == "function" then WeakMap.new() else nil

local isPerformingRefresh = false

local function computeFullKey(signature: Signature): string
	if signature.fullKey ~= nil then
		return signature.fullKey
	end

	local fullKey: string = signature.ownKey
	local hooks
	do --[[ ROBLOX COMMENT: try-catch block conversion ]]
		local _ok, result, hasReturned = xpcall(function()
			hooks = signature.getCustomHooks()
		end, function(err)
			-- This can happen in an edge case, e.g. if expression like Foo.useSomething
			-- depends on Foo which is lazily initialized during rendering.
			-- In that case just assume we'll have to remount.
			signature.forceReset = true
			signature.fullKey = fullKey
			return fullKey, true
		end)
		if hasReturned then
			return result
		end
	end

	for i = 1, #hooks do
		local hook = hooks[i]
		if typeof(hook) ~= "function" then
			-- Something's wrong. Assume we need to remount.
			signature.forceReset = true
			signature.fullKey = fullKey
			return fullKey
		end
		local nestedHookSignature = allSignaturesByType:get(hook)
		if nestedHookSignature == nil then
			-- No signature means Hook wasn't in the source code, e.g. in a library.
			-- We'll skip it because we can assume it won't change during this session.
			continue
		end
		local nestedHookKey = computeFullKey(nestedHookSignature)
		if nestedHookSignature.forceReset then
			signature.forceReset = true
		end
		fullKey ..= "\n---\n" .. nestedHookKey
	end

	signature.fullKey = fullKey
	return fullKey
end

local function haveEqualSignatures(prevType, nextType)
	local prevSignature = allSignaturesByType:get(prevType)
	local nextSignature = allSignaturesByType:get(nextType)

	if prevSignature == nil and nextSignature == nil then
		return true
	end
	if prevSignature == nil or nextSignature == nil then
		return false
	end
	if computeFullKey(prevSignature) ~= computeFullKey(nextSignature) then
		return false
	end
	if nextSignature.forceReset then
		return false
	end

	return true
end

local function isReactClass(type_)
	return typeof(type_) == "table"
		and type_.prototype
		and type_.prototype.isReactComponent
end

local function canPreserveStateBetween(prevType, nextType)
	if isReactClass(prevType) or isReactClass(nextType) then
		return false
	end
	if haveEqualSignatures(prevType, nextType) then
		return true
	end
	return false
end

local function resolveFamily(type_)
	-- Only check updated types to keep lookups fast.
	return updatedFamiliesByType:get(type_)
end

-- If we didn't care about IE11, we could use new Map/Set(iterable).
local function cloneMap<K, V>(map: Map<K, V>): Map<K, V>
	local clone = Map.new()
	map.forEach(map, function(value, key)
		clone:set(key, value)
	end)
	return clone
end
local function cloneSet<T>(set: Set<T>): Set<T>
	local clone = Set.new()
	set.forEach(set, function(value)
		clone:add(value)
	end)
	return clone
end

local function performReactRefresh(): RefreshUpdate | nil
	if not __DEV__ then
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
	if #pendingUpdates == 0 then
		return nil
	end
	if isPerformingRefresh then
		return nil
	end

	isPerformingRefresh = true
	do --[[ ROBLOX COMMENT: try-finally block conversion ]]
		local ok, result, hasReturned = pcall(function()
			local staleFamilies = Set.new()
			local updatedFamilies = Set.new()
			local updates = pendingUpdates
			pendingUpdates = {}
			Array.forEach(updates, function(ref0)
				local family: Family, nextType: any = table.unpack(ref0, 1, 2)
				-- Now that we got a real edit, we can create associations
				-- that will be read by the React reconciler.
				local prevType = family.current
				updatedFamiliesByType:set(prevType, family)
				updatedFamiliesByType:set(nextType, family)
				family.current = nextType

				-- Determine whether this should be a re-render or a re-mount.
				if canPreserveStateBetween(prevType, nextType) then
					updatedFamilies:add(family)
				else
					staleFamilies:add(family)
				end
			end)

			-- TODO: rename these fields to something more meaningful.
			local update: RefreshUpdate = {
				updatedFamilies = updatedFamilies, -- Families that will re-render preserving state
				staleFamilies = staleFamilies, -- Families that will be remounted
			}

			helpersByRendererID.forEach(helpersByRendererID, function(helpers)
				-- Even if there are no roots, set the handler on first update.
				-- This ensures that if *new* roots are mounted, they'll use the resolve handler.
				helpers.setRefreshHandler(resolveFamily)
			end)

			local didError = false
			local firstError = nil

			-- We snapshot maps and sets that are mutated during commits.
			-- If we don't do this, there is a risk they will be mutated while
			-- we iterate over them. For example, trying to recover a failed root
			-- may cause another root to be added to the failed list -- an infinite loop.
			local failedRootsSnapshot = cloneSet(failedRoots)
			local mountedRootsSnapshot = cloneSet(mountedRoots)
			local helpersByRootSnapshot = cloneMap(helpersByRoot)

			failedRootsSnapshot.forEach(failedRootsSnapshot, function(root)
				local helpers = helpersByRootSnapshot:get(root)
				if helpers == nil then
					error(
						Error.new(
							"Could not find helpers for a root. This is a bug in React Refresh."
						)
					)
				end
				if not failedRoots:has(root) then
					-- No longer failed.
				end
				if rootElements == nil then
					return
				end
				if not rootElements:has(root) then
					return
				end
				local element = rootElements:get(root)
				do --[[ ROBLOX COMMENT: try-catch block conversion ]]
					xpcall(function()
						helpers.scheduleRoot(root, element)
					end, function(err)
						if not didError then
							didError = true
							firstError = err
						end
						-- Keep trying other roots.
					end)
				end
				return
			end)
			mountedRootsSnapshot.forEach(mountedRootsSnapshot, function(root)
				local helpers = helpersByRootSnapshot:get(root)
				if helpers == nil then
					error(
						Error.new(
							"Could not find helpers for a root. This is a bug in React Refresh."
						)
					)
				end
				if not mountedRoots:has(root) then
					-- No longer mounted.
				end
				do --[[ ROBLOX COMMENT: try-catch block conversion ]]
					xpcall(function()
						helpers.scheduleRefresh(root, update)
					end, function(err)
						if not didError then
							didError = true
							firstError = err
						end
						-- Keep trying other roots.
					end)
				end
			end)
			if didError then
				error(firstError)
			end
			return update, true
		end)
		do
			isPerformingRefresh = false
		end
		if hasReturned then
			return result
		end
		if not ok then
			error(result)
		end
	end
	return nil
end
exports.performReactRefresh = performReactRefresh

local function register(type_, id: string): ()
	if __DEV__ then
		if type_ == nil then
			return
		end
		if typeof(type_) ~= "function" and typeof(type_) ~= "table" then
			return
		end

		-- This can happen in an edge case, e.g. if we register
		-- return value of a HOC but it returns a cached component.
		-- Ignore anything but the first registration for each type.
		if allFamiliesByType:has(type_) then
			return
		end
		-- Create family or remember to update it.
		-- None of this bookkeeping affects reconciliation
		-- until the first performReactRefresh() call above.
		local family = allFamiliesByID:get(id)
		if family == nil then
			family = { current = type_ }
			-- ROBLOX Luau FIXME: control flow analysis
			allFamiliesByID:set(id, family :: Family)
		else
			table.insert(pendingUpdates, { family, type_ })
		end
		-- ROBLOX Luau FIXME: control flow analysis
		allFamiliesByType:set(type_, family :: Family)

		-- Visit inner types because we might not have registered them.
		if typeof(type_) == "table" and type_ ~= nil then
			local condition_ = type_["$$typeof"]
			if condition_ == REACT_FORWARD_REF_TYPE then
				register(type_.render, tostring(id) .. "$render")
			elseif condition_ == REACT_MEMO_TYPE then
				register(type_.type, tostring(id) .. "$type")
			end
		end
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports.register = register

local function setSignature(
	type_,
	key: string,
	forceReset_: boolean?,
	getCustomHooks: (() -> Array<Function>)?
): ()
	local forceReset: boolean = if forceReset_ ~= nil then forceReset_ else false
	if __DEV__ then
		allSignaturesByType:set(type_, {
			forceReset = forceReset,
			ownKey = key,
			fullKey = nil,
			getCustomHooks = getCustomHooks or function()
				return {}
			end,
		})
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports.setSignature = setSignature

-- This is lazily called during first render for a type.
-- It captures Hook list at that time so inline requires don't break comparisons.
local function collectCustomHooksForSignature(type_)
	if __DEV__ then
		local signature = allSignaturesByType:get(type_)
		if signature ~= nil then
			computeFullKey(signature)
		end
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports.collectCustomHooksForSignature = collectCustomHooksForSignature

local function getFamilyByID(id: string): Family | void
	if __DEV__ then
		return allFamiliesByID:get(id)
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports.getFamilyByID = getFamilyByID

local function getFamilyByType(type_): Family | void
	if __DEV__ then
		return allFamiliesByType:get(type_)
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports.getFamilyByType = getFamilyByType

local function findAffectedHostInstances(families: Array<Family>): Set<Instance>
	if __DEV__ then
		local affectedInstances = Set.new()
		mountedRoots:forEach(function(root)
			local helpers = helpersByRoot:get(root)
			if helpers == nil then
				error(
					Error.new(
						"Could not find helpers for a root. This is a bug in React Refresh."
					)
				)
			end
			local instancesForRoot = helpers.findHostInstancesForRefresh(root, families)
			instancesForRoot:forEach(function(inst)
				affectedInstances:add(inst)
			end)
		end)
		return affectedInstances
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports.findAffectedHostInstances = findAffectedHostInstances

local function injectIntoGlobalHook(globalObject: any): ()
	if __DEV__ then
		-- For React Native, the global hook will be set up by require('react-devtools-core').
		-- That code will run before us. So we need to monkeypatch functions on existing hook.

		-- For React Web, the global hook will be set up by the extension.
		-- This will also run before us.
		local hook = globalObject.__REACT_DEVTOOLS_GLOBAL_HOOK__
		if hook == nil then
			-- However, if there is no DevTools extension, we'll need to set up the global hook ourselves.
			-- Note that in this case it's important that renderer code runs *after* this method call.
			-- Otherwise, the renderer will think that there is no global hook, and won't do the injection.
			local nextID = 0
			hook = {
				renderers = Map.new(),
				supportsFiber = true,
				inject = function(injected)
					local ref = nextID
					nextID += 1
					return ref
				end,
				onScheduleFiberRoot = function(
					id: number,
					root: FiberRoot,
					children: ReactNodeList
				)
				end,
				onCommitFiberRoot = function(
					id: number,
					root: FiberRoot,
					maybePriorityLevel: any,
					didError: boolean
				)
				end,
				onCommitFiberUnmount = function() end,
			}
			globalObject.__REACT_DEVTOOLS_GLOBAL_HOOK__ = hook
		end

		-- Here, we just want to get a reference to scheduleRefresh.
		local oldInject = hook.inject
		hook.inject = function(injected)
			local id = oldInject(injected)
			if
				typeof(injected.scheduleRefresh) == "function"
				and typeof(injected.setRefreshHandler) == "function"
			then
				-- This version supports React Refresh.
				helpersByRendererID:set(id, injected)
			end
			return id
		end

		-- Do the same for any already injected roots.
		-- This is useful if ReactDOM has already been initialized.
		-- https://github.com/facebook/react/issues/17626
		Array.forEach(hook.renderers, function(injected, id)
			if
				typeof(injected.scheduleRefresh) == "function"
				and typeof(injected.setRefreshHandler) == "function"
			then
				-- This version supports React Refresh.
				helpersByRendererID:set(id, injected)
			end
		end)

		-- We also want to track currently mounted roots.
		local oldOnCommitFiberRoot = hook.onCommitFiberRoot
		local oldOnScheduleFiberRoot = hook.onScheduleFiberRoot or function() end
		hook.onScheduleFiberRoot = function(
			id: number,
			root: FiberRoot,
			children: ReactNodeList
		)
			if not isPerformingRefresh then
				-- If it was intentionally scheduled, don't attempt to restore.
				-- This includes intentionally scheduled unmounts.
				failedRoots:delete(root)
				if rootElements ~= nil then
					rootElements:set(root, children)
				end
			end
			return oldOnScheduleFiberRoot(id, root, children)
		end
		hook.onCommitFiberRoot = function(
			id: number,
			root: FiberRoot,
			maybePriorityLevel: any,
			didError: boolean
		)
			local helpers = helpersByRendererID:get(id)
			if helpers == nil then
				return
			end
			helpersByRoot:set(root, helpers)

			local current = root.current
			local alternate = current.alternate

			-- We need to determine whether this root has just (un)mounted.
			-- This logic is copy-pasted from similar logic in the DevTools backend.
			-- If this breaks with some refactoring, you'll want to update DevTools too.

			if alternate ~= nil then
				local wasMounted = alternate.memoizedState ~= nil
					and alternate.memoizedState.element ~= nil
				local isMounted = current.memoizedState ~= nil
					and current.memoizedState.element ~= nil

				if not wasMounted and isMounted then
					-- Mount a new root.
					mountedRoots:add(root)
					failedRoots:delete(root)
				elseif wasMounted and isMounted then
					-- Update an existing root.
					-- This doesn't affect our mounted root Set.
				elseif wasMounted and not isMounted then
					-- Unmount an existing root.
					mountedRoots:delete(root)
					if didError then
						-- We'll remount it on future edits.
						failedRoots:add(root)
					else
						helpersByRoot:delete(root)
					end
				elseif not wasMounted and not isMounted then
					if didError then
						-- We'll remount it on future edits.
						failedRoots:add(root)
					end
				end
			else
				-- Mount a new root.
				mountedRoots:add(root)
			end

			return oldOnCommitFiberRoot(id, root, maybePriorityLevel, didError)
		end
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end

exports.injectIntoGlobalHook = injectIntoGlobalHook
local function hasUnrecoverableErrors()
	-- TODO: delete this after removing dependency in RN.
	return false
end
exports.hasUnrecoverableErrors = hasUnrecoverableErrors

-- Exposed for testing.
local function _getMountedRootCount()
	if __DEV__ then
		return mountedRoots.size
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports._getMountedRootCount = _getMountedRootCount

-- This is a wrapper over more primitive functions for setting signature.
-- Signatures let us decide whether the Hook order has changed on refresh.
--
-- This function is intended to be used as a transform target, e.g.:
-- var _s = createSignatureFunctionForTransform()
--
-- function Hello() {
--   const [foo, setFoo] = useState(0);
--   const value = useCustomHook();
--   _s(); /* Second call triggers collecting the custom Hook list.
--          * This doesn't happen during the module evaluation because we
--          * don't want to change the module order with inline requires.
--          * Next calls are noops. */
--   return <h1>Hi</h1>;
-- }
--
-- /* First call specifies the signature: */
-- _s(
--   Hello,
--   'useState{[foo, setFoo]}(0)',
--   () => [useCustomHook], /* Lazy to avoid triggering inline requires */
-- );
type SignatureStatus = "needsSignature" | "needsCustomHooks" | "resolved"
local function createSignatureFunctionForTransform()
	if __DEV__ then
		-- We'll fill in the signature in two steps.
		-- First, we'll know the signature itself. This happens outside the component.
		-- Then, we'll know the references to custom Hooks. This happens inside the component.
		-- After that, the returned function will be a fast path no-op.
		local status: SignatureStatus = "needsSignature"
		local savedType
		local hasCustomHooks
		return function<T>(
			type_,
			key: string,
			forceReset: boolean?,
			getCustomHooks: (() -> Array<Function>)?
		): T
			local condition_ = status
			if condition_ == "needsSignature" then
				if type_ ~= nil then
					-- If we received an argument, this is the initial registration call.
					savedType = type_
					hasCustomHooks = typeof(getCustomHooks) == "function"
					setSignature(type_, key, forceReset, getCustomHooks)
					-- The next call we expect is from inside a function, to fill in the custom Hooks.
					status = "needsCustomHooks"
				end
			elseif condition_ == "needsCustomHooks" then
				if hasCustomHooks then
					collectCustomHooksForSignature(savedType)
				end
				status = "resolved"
			elseif condition_ == "resolved" then
				-- Do nothing. Fast path for all future renders.
			end
			return type_
		end
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports.createSignatureFunctionForTransform = createSignatureFunctionForTransform

local function isLikelyComponentType(type_): boolean
	if __DEV__ then
		if typeof(type_) == "function" then
			-- First, deal with classes.
			-- if type_.prototype ~= nil then
			-- 	if type_.prototype.isReactComponent then
			-- 		-- React class.
			-- 		return true
			-- 	end
			-- 	local ownNames = Object.getOwnPropertyNames(type_.prototype)
			-- 	if #ownNames > 1 or ownNames[1] ~= "constructor" then
			-- 		-- This looks like a class.
			-- 		return false
			-- 	end
			-- 	-- eslint-disable-next-line no-proto
			-- 	if type_.prototype.__proto__ ~= Object.prototype then
			-- 		-- It has a superclass.
			-- 		return false
			-- 	end
			-- 	-- Pass through.
			-- 	-- This looks like a regular function with empty prototype.
			-- end
			-- -- For plain functions and arrows, use name as a heuristic.
			-- local name = type_.name or type_.displayName
			-- return typeof(name) == "string" and RegExp("^[A-Z]"):test(name)
			-- ROBLOX deviation: use debug.info and string.match
			local name = debug.info(type_, "n") or debug.info(type_, "s")
			return string.match(name, "^%u") ~= nil
		elseif typeof(type_) == "table" then
			if type_ ~= nil then
				local condition_ = type_["$$typeof"]
				if
					condition_ == REACT_FORWARD_REF_TYPE
					or condition_ == REACT_MEMO_TYPE
				then
					-- Definitely React components.
					return true
				else
					return false
				end
			end
			return false
		else
			return false
		end
	else
		error(Error.new("Unexpected call to React Refresh in a production environment."))
	end
end
exports.isLikelyComponentType = isLikelyComponentType

return exports
