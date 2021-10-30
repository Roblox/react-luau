-- ROBLOX deviation: The setup function adds the glue required for DeveloperTools to initialize the Roact devtools correctly
local Packages = script.Parent

return {
	setup = function(debugMode: boolean)
		-- ROBLOX deviation: Set globals for React devtools to work
		_G.__DEV__ = true
		_G.__DEBUG__ = debugMode or false
		_G.__PROFILE__ = true
		_G.__EXPERIMENTAL__ = true
		-- ROBLOX deviation: Don't hide host coomponents as the current Developer Inspector uses on these to preserve a
		-- direct mapping between the Inspector tree and the Explorer tree as requested by design.
		_G.__REACT_DEVTOOLS_COMPONENT_FILTERS__ = {}

		local ReactDevtoolsShared = require(Packages.ReactDevtoolsShared)
		local setup = require(Packages.ReactDevtoolsExtensions.backend).setup
		local installHook = ReactDevtoolsShared.hook.installHook
		local Store = ReactDevtoolsShared.devtools.store

		-- ROBLOX deviation: Ensure that the global hook is installed before the injection into DevTools
		installHook(_G)

		-- ROBLOX deviation: Ensure that ReactRoblox is loaded after injection so that the ReactHostConfig is populated correctly
		require(Packages.React)
		require(Packages.ReactRoblox)

		local hook = _G.__REACT_DEVTOOLS_GLOBAL_HOOK__

		-- ROBLOX deviation: Make sure that this method was called before ReactRoblox was first required,
		-- otherwise the profiler will not be enabled for the session.
		local ReactFeatureFlags = require(Packages.Shared).ReactFeatureFlags
		if not ReactFeatureFlags.enableSchedulingProfiler then
			warn(
				"[DeveloperTools] React was initialized before DeveloperTools. Call inspector.setupReactDevtools before requiring React to enable profiling."
			)
		end

		local result = setup(hook)

		-- ROBLOX deviation: The DeveloperTools library is only passed the ReactDevtoolsExtensions API to keep the
		-- devtools init process compact for users. Initialize the store so DeveloperTools doesn't also need to be
		-- passed the ReactDevtoolsShared API.
		return {
			agent = result.agent,
			bridge = result.bridge,
			hook = result.hook,
			store = Store.new(result.bridge),
		}
	end,
}
