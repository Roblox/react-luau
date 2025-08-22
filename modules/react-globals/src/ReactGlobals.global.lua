-- NOTE: No upstream

--[[
    Defines all React globals in a type-safe manner that's scoped to each
    copy of React. For backwards compatibility, this module will load the
    initial values for each flag from _G. However, this is considered legacy
    behavior and new code should import this package and set the flags directly.

    ## Globals Reference

    General debug-related flags:
    __DEV__
    __PROFILE__
    __EXPERIMENTAL__
    __DEBUG__
    __YOLO__
    __DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__

    Devtools flags:
    __REACT_DEVTOOLS_GLOBAL_HOOK__
    __REACT_DEVTOOLS_ATTACH__
    __REACT_DEVTOOLS_COMPONENT_FILTERS__
	__REACT_DEVTOOLS_APPEND_COMPONENT_STACK__
	__REACT_DEVTOOLS_BREAK_ON_CONSOLE_ERRORS__
    __LOCALSTORAGE__
    __SESSIONSTORAGE__

    Misc flags:
    __COMPAT_WARNINGS__
    __TESTEZ_RUNNING_TEST__
    __ROACT_17_MOCK_SCHEDULER__
    __ROACT_17_INLINE_ACT__
]]

local Packages = script.Parent.Parent
local SafeFlags = require(Packages.SafeFlags)

local FFlagReactIsolatedGlobalsEnabled =
	SafeFlags.createGetFFlag("ReactIsolatedGlobalsEnabled")()

if not FFlagReactIsolatedGlobalsEnabled then
	return _G :: ReactGlobals
end

type DevToolsHook = any
type DevToolsAttach = any
type DevToolsComponentFilters = { any }

local function loadFromGlobal<T>(globalValueKey: string, defaultValue: T): T
	local globalValue = _G[globalValueKey]
	if globalValue ~= nil then
		return globalValue
	end
	return defaultValue
end

local ReactGlobals = {
	__DEV__ = loadFromGlobal("__DEV__", false),
	__PROFILE__ = loadFromGlobal("__PROFILE__", false),
	__EXPERIMENTAL__ = loadFromGlobal("__EXPERIMENTAL__", false),
	__DEBUG__ = loadFromGlobal("__DEBUG__", false),
	__YOLO__ = loadFromGlobal("__YOLO__", false),
	__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__ = loadFromGlobal(
		"__DISABLE_ALL_WARNINGS_EXCEPT_PROP_VALIDATION__",
		false
	),

	__REACT_DEVTOOLS_GLOBAL_HOOK__ = loadFromGlobal(
		"__REACT_DEVTOOLS_GLOBAL_HOOK__",
		nil :: DevToolsHook?
	),
	__REACT_DEVTOOLS_ATTACH__ = loadFromGlobal(
		"__REACT_DEVTOOLS_ATTACH__",
		nil :: DevToolsAttach?
	),
	__REACT_DEVTOOLS_APPEND_COMPONENT_STACK__ = loadFromGlobal(
		"__REACT_DEVTOOLS_APPEND_COMPONENT_STACK__",
		false
	),
	__REACT_DEVTOOLS_BREAK_ON_CONSOLE_ERRORS__ = loadFromGlobal(
		"__REACT_DEVTOOLS_BREAK_ON_CONSOLE_ERRORS__",
		false
	),
	__REACT_DEVTOOLS_COMPONENT_FILTERS__ = loadFromGlobal(
		"__REACT_DEVTOOLS_COMPONENT_FILTERS__",
		nil :: DevToolsComponentFilters?
	),
	__LOCALSTORAGE__ = loadFromGlobal("__LOCALSTORAGE__", nil :: any?),
	__SESSIONSTORAGE__ = loadFromGlobal("__SESSIONSTORAGE__", nil :: any?),

	__COMPAT_WARNINGS__ = loadFromGlobal("__COMPAT_WARNINGS__", false),
	__TESTEZ_RUNNING_TEST__ = loadFromGlobal("__TESTEZ_RUNNING_TEST__", false),
	__ROACT_17_MOCK_SCHEDULER__ = loadFromGlobal("__ROACT_17_MOCK_SCHEDULER__", false),
	__ROACT_17_INLINE_ACT__ = loadFromGlobal("__ROACT_17_INLINE_ACT__", false),
}

export type ReactGlobals = typeof(ReactGlobals)

return ReactGlobals
