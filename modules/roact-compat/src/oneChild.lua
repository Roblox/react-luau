local Packages = script.Parent.Parent
local React = require(Packages.React)

local warnOnce = require(script.Parent.warnOnce)

local function oneChild(children)
	if _G.__DEV__ and _G.__COMPAT_WARNINGS__ then
		warnOnce(
			"oneChild",
			"You likely don't need this at all! If you were assigning children "
				.. "via `React.oneChild(someChildren)`, you can simply use "
				.. "`someChildren` directly."
		)
	end

	-- This behavior is a bit different from upstream, so we're adapting current
	-- Roact's logic (which will unwrap a table with a single member)
	if not children then
		return nil
	end

	local key, child = next(children)

	if not child then
		return nil
	end

	local after = next(children, key)

	if after then
		error("Expected at most one child, had more than one child.", 2)
	end

	return React.Children.only(child)
end

return oneChild
