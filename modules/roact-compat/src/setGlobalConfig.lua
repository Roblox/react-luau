local warnOnce = require(script.Parent.warnOnce)

return function(_config)
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
		warnOnce(
			"setGlobalConfig",
			"Roact 17 uses a `_G.__DEV__` flag to enable development behavior. "
				.. "If you're seeing this warning, you already have it enabled. "
				.. "Please remove any redundant uses of `setGlobalConfig`."
		)
	end
	-- No equivalent behavior can be applied here
end
