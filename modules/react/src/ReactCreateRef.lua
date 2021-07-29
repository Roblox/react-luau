-- upstream: https://github.com/facebook/react/blob/b87aabdfe1b7461e7331abb3601d9e6bb27544bc/packages/react/src/ReactCreateRef.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 * @flow
*]]

local exports = {}

-- ROBLOX DEVIATION: In Roact, refs are implemented in terms of bindings
--[[
  A ref is nothing more than a binding with a special field 'current'
  that maps to the getValue method of the binding
]]
local Binding = require(script.Parent["ReactBinding.roblox"])

-- an immutable object with a single mutable value
exports.createRef = function(): any -- ROBLOX FIXME: Redefine RefObject type
  local binding, _ = Binding.create(nil)

  local ref = {}

  --[[
    A ref is just redirected to a binding via its metatable
  ]]
  setmetatable(ref, {
    __index = function(self, key)
      if key == "current" then
        return binding:getValue()
      else
        return binding[key]
      end
    end,
    __newindex = function(self, key, value)
      if key == "current" then
        -- ROBLOX FIXME: Bindings - This is not allowed in Roact, but is okay in
        -- React. Lots of discussion at
        -- https://github.com/DefinitelyTyped/DefinitelyTyped/issues/31065
        -- error("Cannot assign to the 'current' property of refs", 2)
        Binding.update(binding, value)
      end

      binding[key] = value
    end,
    __tostring = function(self)
      return ("Ref(%s)"):format(tostring(binding:getValue()))
    end,
  })

  return ref
end

return exports
