local Packages = script.Parent.Parent
local React = require(Packages.React)

local warnOnce = require(script.Parent.warnOnce)

return function(elements)
	if _G.__DEV__ then
		warnOnce(
			"createFragment",
			"Please instead use:\n\tReact.createElement(React.Fragment, ...)"
		)
	end
	return React.createElement(React.Fragment, nil, elements)
end
