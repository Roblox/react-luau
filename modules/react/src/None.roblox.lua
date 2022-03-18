local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)

-- Roact uses `Object.assign` internally to assign new state values; the same
-- None value should give us the proper semantics. We can re-export this value
-- as React.None for easy use, and to mirror Roact.None in legacy Roact.
return LuauPolyfill.Object.None
