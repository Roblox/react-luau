--!strict
local FakeTimers = require(script.Parent.FakeTimers)

type CleanupFn = () -> any

local requiredModules: { [ModuleScript]: any } = {}
local moduleCleanup: { [ModuleScript]: (() -> any)? } = {}
local mocks: { [ModuleScript]: CleanupFn } = {}

if _G.__NO_LOADMODULE__ then
	warn(
		"debug.loadmodule not enabled. Test plans relying on resetModules "
			.. "will not work properly."
	)

	return {
		requireOverride = require,
		resetModules = function()
			-- Should we warn on calling this more than once?
		end,
		mock = function(module: ModuleScript, fn: () -> any)
			-- Since we can't mock underneath require, we'll overwrite the
			-- require module altogether with the result of the mock
			local mockResult = fn()
			local realModule = require(module)
			for k, v in pairs(mockResult) do
				realModule[k] = v
			end
			for k, _v in pairs(realModule) do
				if mockResult[k] == nil then
					realModule[k] = nil
				end
			end
		end,
		unmock = function(_module: ModuleScript)
			-- no op
		end,
	}
end

local function requireOverride(scriptInstance: ModuleScript): any
	-- This is crucial! We need to have an early out here so that we don't
	-- override requires of ourself; this would result in the module cache
	-- deviating into a bunch of separate ones.
	--
	-- TODO: This is a little janky, so we should find a way to do this that's a
	-- little more robust. We may want to apply it to anything in RobloxJest?
	if
		scriptInstance == script
		or scriptInstance == script.Parent
		or scriptInstance.Name == "jest-roblox"
		-- for the 2021 version of the Studio Inspector plugin
		or scriptInstance.Name == "DeveloperTools"
	then
		return require(scriptInstance)
	end
	-- FIXME: an extra special hack that prevents us from frequently reloading
	-- `jest-roblox`, and therefore dodges the expensive modules found in:
	-- jest-roblox -> luau-polyfill@0.1.5 -> RegExp
	if scriptInstance.Name == "RegExp" then
		return require(scriptInstance)
	end

	-- If already loaded and cached, return cached module. This should behave
	-- similarly to normal `require` behavior
	if requiredModules[scriptInstance] ~= nil then
		return requiredModules[scriptInstance]
	end

	local moduleResult
	-- First, check the mock cache and see if this is being mocked
	if typeof(mocks[scriptInstance]) == "function" then
		-- ROBLOX FIXME: Luau flow analysis bug workaround
		moduleResult = (mocks[scriptInstance] :: () -> any)()

		if moduleResult == nil then
			error(
				string.format(
					"[Mock Error]: %s did not return a valid result\n"
						.. "\tmocks must return a non-nil value",
					tostring(scriptInstance)
				)
			)
		end
	else
		-- Narrowing this type here lets us appease the type checker while still
		-- counting on types for the rest of this file
		local loadmodule: (ModuleScript) -> (any, string, CleanupFn) = debug["loadmodule"]
		local moduleFunction, errorMessage, cleanup = loadmodule(scriptInstance)
		assert(moduleFunction ~= nil, errorMessage)

		getfenv(moduleFunction).require = requireOverride
		getfenv(moduleFunction).delay = FakeTimers.delayOverride
		getfenv(moduleFunction).tick = FakeTimers.tickOverride
		getfenv(moduleFunction).task = FakeTimers.taskOverride
		moduleResult = moduleFunction()

		if moduleResult == nil then
			error(
				string.format(
					"[Module Error]: %s did not return a valid result\n"
						.. "\tModuleScripts must return a non-nil value",
					tostring(scriptInstance)
				)
			)
		end
		moduleCleanup[scriptInstance] = cleanup
	end

	-- Load normally into the require cache
	requiredModules[scriptInstance] = moduleResult

	return moduleResult
end

local function resetModules()
	-- Clear all modules in the override require cache
	requiredModules = {}

	for script,cleanup in pairs(moduleCleanup) do
		(cleanup :: CleanupFn)()
	end

	moduleCleanup = {}
end

local function mock(scriptInstance: ModuleScript, callback: () -> any)
	-- If there's a cached actual value, clear it out so that a new require
	-- will get the mock
	if requiredModules[scriptInstance] ~= nil then
		requiredModules[scriptInstance] = nil
		local cleanup = moduleCleanup[scriptInstance]
		if cleanup then
			(cleanup :: CleanupFn)()
			moduleCleanup[scriptInstance] = nil
		end
	end

	-- Silence type errors
	local getfenv: any = getfenv
	-- Make sure that the further requires used by this mock will also be using
	-- the require override
	getfenv(callback).require = requireOverride
	getfenv(callback).delay = FakeTimers.delayOverride
	getfenv(callback).tick = FakeTimers.tickOverride
	mocks[scriptInstance] = callback
end

local function unmock(scriptInstance: ModuleScript)
	-- If there's a cached mock value, clear it out so that a new require won't
	-- get the mock
	if requiredModules[scriptInstance] ~= nil then
		requiredModules[scriptInstance] = nil
		local cleanup = moduleCleanup[scriptInstance]
		if cleanup then
			(cleanup :: CleanupFn)()
			moduleCleanup[scriptInstance] = nil
		end
	end

	mocks[scriptInstance] = nil
end

return {
	requireOverride = requireOverride,
	resetModules = resetModules,
	mock = mock,
	unmock = unmock,
}
