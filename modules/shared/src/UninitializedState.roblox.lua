local console = require(script.Parent.console)

-- ROBLOX DEVIATION: Initialize state to a singleton that warns on access and errors on assignment
-- initial state singleton
local UninitializedState = {}

setmetatable(UninitializedState, {
  __index = function(table, key)
    if _G.__DEV__ then
      console.warn("Attempted to access unitialized state. Use setState to initialize state")
    end
    return nil
  end,
  __newindex = function(table, key)
    if _G.__DEV__ then
      console.error("Attempted to directly mutate state. Use setState to assign new values to state.")
    end
    return nil
  end,
  __tostring = function(self)
    return "<uninitialized component state>"
  end,
  __metatable = "UninitializedState"
})

return UninitializedState