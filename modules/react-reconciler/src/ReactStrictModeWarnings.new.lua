--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/702fad4b1b48ac8f626ed3f35e8f86f5ea728084/packages/react-reconciler/src/ReactStrictModeWarnings.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
local ReactCurrentFiber = require(script.Parent.ReactCurrentFiber)
local resetCurrentDebugFiberInDEV = ReactCurrentFiber.resetCurrentFiber
local setCurrentDebugFiberInDEV = ReactCurrentFiber.setCurrentFiber
local getComponentName = require(Packages.Shared).getComponentName
local StrictMode = require(script.Parent.ReactTypeOfMode).StrictMode

type Set<T> = { [T]: boolean }
type Array<T> = { [number]: T }
type Map<K, V> = { [K]: V }
type FiberArray = Array<Fiber>
type FiberToFiberComponentsMap = Map<Fiber, FiberArray>

local ReactStrictModeWarnings = {
	recordUnsafeLifecycleWarnings = function(fiber: Fiber, instance: any) end,
	flushPendingUnsafeLifecycleWarnings = function() end,
	recordLegacyContextWarning = function(fiber: Fiber, instance: any) end,
	flushLegacyContextWarning = function() end,
	discardPendingWarnings = function() end,
}

if _G.__DEV__ then
	local findStrictRoot = function(fiber: Fiber): Fiber | nil
		local maybeStrictRoot = nil

		-- ROBLOX FIXME Luau: Luau needs to understand while not nil loops
		local node: Fiber? = fiber
		while node ~= nil do
			if bit32.band(node.mode, StrictMode) ~= 0 then
				maybeStrictRoot = node
			end
			node = node.return_
		end

		return maybeStrictRoot
	end

	local setToSortedString = function(set): string
		local array = {}
		for key, value in set do
			table.insert(array, key)
		end
		table.sort(array)
		return table.concat(array, ", ")
	end

	local pendingComponentWillMountWarnings: Array<Fiber> = {}
	local pendingUNSAFE_ComponentWillMountWarnings: Array<Fiber> = {}
	local pendingComponentWillReceivePropsWarnings: Array<Fiber> = {}
	local pendingUNSAFE_ComponentWillReceivePropsWarnings: Array<Fiber> = {}
	local pendingComponentWillUpdateWarnings: Array<Fiber> = {}
	local pendingUNSAFE_ComponentWillUpdateWarnings: Array<Fiber> = {}

	-- Tracks components we have already warned about.
	local didWarnAboutUnsafeLifecycles = {}

	ReactStrictModeWarnings.recordUnsafeLifecycleWarnings =
		function(fiber: Fiber, instance: any)
			-- Dedupe strategy: Warn once per component.
			if didWarnAboutUnsafeLifecycles[fiber.type] then
				return
			end

			if
				typeof(instance.componentWillMount) == "function"
				-- Don't warn about react-lifecycles-compat polyfilled components.
				-- ROBLOX deviation: Lua doesn't allow fields on function
				-- instance.componentWillMount.__suppressDeprecationWarning ~= true
			then
				table.insert(pendingComponentWillMountWarnings, fiber)
			end

			if
				bit32.band(fiber.mode, StrictMode) ~= 0
				and typeof(instance.UNSAFE_componentWillMount) == "function"
			then
				table.insert(pendingUNSAFE_ComponentWillMountWarnings, fiber)
			end

			if
				typeof(instance.componentWillReceiveProps) == "function"
				-- ROBLOX deviation: Lua doesn't allow fields on function
				-- instance.componentWillReceiveProps.__suppressDeprecationWarning ~= true
			then
				table.insert(pendingComponentWillReceivePropsWarnings, fiber)
			end

			if
				bit32.band(fiber.mode, StrictMode) ~= 0
				and typeof(instance.UNSAFE_componentWillReceiveProps) == "function"
			then
				table.insert(pendingUNSAFE_ComponentWillReceivePropsWarnings, fiber)
			end

			if
				typeof(instance.componentWillUpdate) == "function"
				-- ROBLOX deviation: Lua doesn't allow fields on function
				-- instance.componentWillUpdate.__suppressDeprecationWarning ~= true
			then
				table.insert(pendingComponentWillUpdateWarnings, fiber)
			end

			if
				bit32.band(fiber.mode, StrictMode) ~= 0
				and typeof(instance.UNSAFE_componentWillUpdate) == "function"
			then
				table.insert(pendingUNSAFE_ComponentWillUpdateWarnings, fiber)
			end
		end

	ReactStrictModeWarnings.flushPendingUnsafeLifecycleWarnings = function()
		-- We do an initial pass to gather component names
		local componentWillMountUniqueNames = {}
		if #pendingComponentWillMountWarnings > 0 then
			for i, fiber in pendingComponentWillMountWarnings do
				componentWillMountUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end
			table.clear(pendingComponentWillMountWarnings)
		end

		local UNSAFE_componentWillMountUniqueNames = {}
		if #pendingUNSAFE_ComponentWillMountWarnings > 0 then
			for i, fiber in pendingUNSAFE_ComponentWillMountWarnings do
				UNSAFE_componentWillMountUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end
			table.clear(pendingUNSAFE_ComponentWillMountWarnings)
		end

		local componentWillReceivePropsUniqueNames = {}
		if #pendingComponentWillReceivePropsWarnings > 0 then
			for i, fiber in pendingComponentWillReceivePropsWarnings do
				componentWillReceivePropsUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end

			table.clear(pendingComponentWillReceivePropsWarnings)
		end

		local UNSAFE_componentWillReceivePropsUniqueNames = {}
		if #pendingUNSAFE_ComponentWillReceivePropsWarnings > 0 then
			for i, fiber in pendingUNSAFE_ComponentWillReceivePropsWarnings do
				UNSAFE_componentWillReceivePropsUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end

			table.clear(pendingUNSAFE_ComponentWillReceivePropsWarnings)
		end

		local componentWillUpdateUniqueNames = {}
		if #pendingComponentWillUpdateWarnings > 0 then
			for i, fiber in pendingComponentWillUpdateWarnings do
				componentWillUpdateUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end

			table.clear(pendingComponentWillUpdateWarnings)
		end

		local UNSAFE_componentWillUpdateUniqueNames = {}
		if #pendingUNSAFE_ComponentWillUpdateWarnings > 0 then
			for i, fiber in pendingUNSAFE_ComponentWillUpdateWarnings do
				UNSAFE_componentWillUpdateUniqueNames[getComponentName(fiber.type) or "Component"] =
					true
				didWarnAboutUnsafeLifecycles[fiber.type] = true
			end

			table.clear(pendingUNSAFE_ComponentWillUpdateWarnings)
		end

		-- Finally, we flush all the warnings
		-- UNSAFE_ ones before the deprecated ones, since they'll be 'louder'
		-- deviation: use `next` to determine whether set is empty
		if next(UNSAFE_componentWillMountUniqueNames) ~= nil then
			local sortedNames = setToSortedString(UNSAFE_componentWillMountUniqueNames)
			console.error(
				"Using UNSAFE_componentWillMount in strict mode is not recommended and may indicate bugs in your code. "
					.. "See https://reactjs.org/link/unsafe-component-lifecycles for details.\n\n"
					.. "* Move code with side effects to componentDidMount, and set initial state in the constructor.\n"
					.. "\nPlease update the following components: %s",
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(UNSAFE_componentWillReceivePropsUniqueNames) ~= nil then
			local sortedNames =
				setToSortedString(UNSAFE_componentWillReceivePropsUniqueNames)
			console.error(
				"Using UNSAFE_componentWillReceiveProps in strict mode is not recommended "
					.. "and may indicate bugs in your code. "
					.. "See https://reactjs.org/link/unsafe-component-lifecycles for details.\n\n"
					.. "* Move data fetching code or side effects to componentDidUpdate.\n"
					.. "* If you're updating state whenever props change, "
					.. "refactor your code to use memoization techniques or move it to "
					.. "static getDerivedStateFromProps. Learn more at: https://reactjs.org/link/derived-state\n"
					.. "\nPlease update the following components: %s",
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(UNSAFE_componentWillUpdateUniqueNames) ~= nil then
			local sortedNames = setToSortedString(UNSAFE_componentWillUpdateUniqueNames)
			console.error(
				"Using UNSAFE_componentWillUpdate in strict mode is not recommended "
					.. "and may indicate bugs in your code. "
					.. "See https://reactjs.org/link/unsafe-component-lifecycles for details.\n\n"
					.. "* Move data fetching code or side effects to componentDidUpdate.\n"
					.. "\nPlease update the following components: %s",
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(componentWillMountUniqueNames) ~= nil then
			local sortedNames = setToSortedString(componentWillMountUniqueNames)

			-- ROBLOX TODO: Make decisions about whether or not we'll support these
			-- methods in the first place
			-- deviation: Remove some non-applicable information
			console.warn(
				"componentWillMount has been renamed, and is not recommended for use. "
					.. "See https://reactjs.org/link/unsafe-component-lifecycles for details.\n\n"
					.. "* Move code with side effects to componentDidMount, and set initial state in the constructor.\n"
					.. "* Rename componentWillMount to UNSAFE_componentWillMount to suppress "
					.. "this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.\n"
					.. "\nPlease update the following components: %s",
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(componentWillReceivePropsUniqueNames) ~= nil then
			local sortedNames = setToSortedString(componentWillReceivePropsUniqueNames)

			-- ROBLOX TODO: Make decisions about whether or not we'll support these
			-- methods in the first place
			-- deviation: Remove some non-applicable information
			console.warn(
				"componentWillReceiveProps has been renamed, and is not recommended for use. "
					.. "See https://reactjs.org/link/unsafe-component-lifecycles for details.\n\n"
					.. "* Move data fetching code or side effects to componentDidUpdate.\n"
					.. "* If you're updating state whenever props change, refactor your "
					.. "code to use memoization techniques or move it to "
					.. "static getDerivedStateFromProps. Learn more at: https://reactjs.org/link/derived-state\n"
					.. "* Rename componentWillReceiveProps to UNSAFE_componentWillReceiveProps to suppress "
					.. "this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.\n"
					.. "\nPlease update the following components: %s",
				sortedNames
			)
		end

		-- deviation: use `next` to determine whether set is empty
		if next(componentWillUpdateUniqueNames) ~= nil then
			local sortedNames = setToSortedString(componentWillUpdateUniqueNames)

			-- ROBLOX TODO: Make decisions about whether or not we'll support these
			-- methods in the first place
			-- deviation: Remove some non-applicable information
			console.warn(
				"componentWillUpdate has been renamed, and is not recommended for use. "
					.. "See https://reactjs.org/link/unsafe-component-lifecycles for details.\n\n"
					.. "* Move data fetching code or side effects to componentDidUpdate.\n"
					.. "* Rename componentWillUpdate to UNSAFE_componentWillUpdate to suppress "
					.. "this warning in non-strict mode. In React 18.x, only the UNSAFE_ name will work.\n"
					.. "\nPlease update the following components: %s",
				sortedNames
			)
		end
	end

	local pendingLegacyContextWarning: FiberToFiberComponentsMap = {}

	-- Tracks components we have already warned about.
	local didWarnAboutLegacyContext = {}

	ReactStrictModeWarnings.recordLegacyContextWarning =
		function(fiber: Fiber, instance: any)
			local strictRoot = findStrictRoot(fiber)
			if strictRoot == nil then
				console.error(
					"Expected to find a StrictMode component in a strict mode tree. "
						.. "This error is likely caused by a bug in React. Please file an issue."
				)
				return
			end

			-- Dedup strategy: Warn once per component.
			if didWarnAboutLegacyContext[fiber.type] then
				return
			end

			-- ROBLOX FIXME Luau: Luau should narrow based on the nil guard
			local warningsForRoot = pendingLegacyContextWarning[strictRoot :: Fiber]

			-- ROBLOX deviation: Lua can't have fields on functions
			if
				typeof(fiber.type) ~= "function"
				and (
					fiber.type.contextTypes ~= nil
					or fiber.type.childContextTypes ~= nil
					or (
						instance ~= nil
						and typeof(instance.getChildContext) == "function"
					)
				)
			then
				if warningsForRoot == nil then
					warningsForRoot = {}
					-- ROBLOX FIXME Luau: Luau should narrow based on the nil guard
					pendingLegacyContextWarning[strictRoot :: Fiber] = warningsForRoot
				end
				table.insert(warningsForRoot, fiber)
			end
		end

	ReactStrictModeWarnings.flushLegacyContextWarning = function()
		for strictRoot, fiberArray in pendingLegacyContextWarning do
			if #fiberArray == 0 then
				return
			end
			local firstFiber = fiberArray[1]

			local uniqueNames = {}
			for i, fiber in fiberArray do
				uniqueNames[getComponentName(fiber.type) or "Component"] = true
				didWarnAboutLegacyContext[fiber.type] = true
			end

			local sortedNames = setToSortedString(uniqueNames)

			local ok, error_ = pcall(function()
				setCurrentDebugFiberInDEV(firstFiber)
				console.error(
					"Legacy context API has been detected within a strict-mode tree."
						.. "\n\nThe old API will be supported in all 16.x releases, but applications "
						.. "using it should migrate to the new version."
						.. "\n\nPlease update the following components: %s"
						.. "\n\nLearn more about this warning here: https://reactjs.org/link/legacy-context",
					sortedNames
				)
			end)

			-- finally
			resetCurrentDebugFiberInDEV()

			if not ok then
				error(error_)
			end
		end
	end

	ReactStrictModeWarnings.discardPendingWarnings = function()
		-- ROBLOX performance? use table.clear instead of assigning new array
		table.clear(pendingComponentWillMountWarnings)
		table.clear(pendingUNSAFE_ComponentWillMountWarnings)
		table.clear(pendingComponentWillReceivePropsWarnings)
		table.clear(pendingUNSAFE_ComponentWillReceivePropsWarnings)
		table.clear(pendingComponentWillUpdateWarnings)
		table.clear(pendingUNSAFE_ComponentWillUpdateWarnings)
		table.clear(pendingLegacyContextWarning)
	end
end

return ReactStrictModeWarnings
