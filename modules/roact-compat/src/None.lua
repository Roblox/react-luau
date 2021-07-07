local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)

-- Roact uses `Object.assign` internally to assign new state values; the same
-- None value should give us the proper semantics.

-- TODO: However, it also requires that downstream users create their own
-- dependency on `LuauPolyfill` in order to use it. We should consider whether
-- we ought to re-export this ourselves as a true deviation
return LuauPolyfill.Object.None
