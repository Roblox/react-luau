-- ROBLOX upstream https://github.com/facebook/react/blob/v17.0.1/scripts/jest/matchers/interactionTracingMatchers.js
local Packages = script.Parent.Parent.Parent
local JestDiff = require(Packages.JestDiff)
local LuauPolyfill = require(Packages.LuauPolyfill)
local Object = LuauPolyfill.Object
-- ROBLOX deviation: hoist and pre-declare functions
local toContainNoInteractions, toHaveBeenLastNotifiedOfWork, toHaveBeenLastNotifiedOfInteraction, toMatchInteraction, toMatchInteractions

function toContainNoInteractions(self, actualSet)
  return {
    message = function()
      if self.isNot then
        return "Expected interactions but there were none."
      end
      return "Expected no interactions but there were " .. tostring(#Object.keys(actualSet)) .. "."
    end,
    pass = #actualSet == 0,
  }
end

function toHaveBeenLastNotifiedOfInteraction(
  self,
  mockFunction,
  expectedInteraction
)
  local calls = mockFunction.mock.calls
  if #calls == 0 then
    return {
      message = function()
        return 'Mock function was not called'
      end,
      pass = false,
    }
  end

  local actualInteraction = calls[#calls][1]

  return toMatchInteraction(self, actualInteraction, expectedInteraction)
end

function toHaveBeenLastNotifiedOfWork(
  self,
  mockFunction,
  expectedInteractions,
  expectedThreadID
)
  local calls = mockFunction.mock.calls
  if #calls == 0 then
    return {
      message = function()
        return 'Mock function was not called'
      end,
      pass = false,
    }
  end

  local actualInteractions, actualThreadID = calls[#calls][1], calls[#calls][2]

  if expectedThreadID ~= nil then
    if expectedThreadID ~= actualThreadID then
      return {
        message = function()
            return JestDiff.diff(tostring(expectedThreadID), tostring(actualThreadID))
        end,
        pass = false,
      }
    end
  end

  return toMatchInteractions(self, actualInteractions, expectedInteractions)
end

function toMatchInteraction(self, actual, expected)
  for _, attribute in pairs(expected) do
    if actual[attribute] ~= expected[attribute] then
      return {
        message = function()
            return JestDiff.diff(expected, actual)
        end,

        pass = false,
      }
    end
  end

  return {pass = true}
end

function toMatchInteractions(self, actualSetOrArray, expectedSetOrArray)
  local actualArrayLength = 0
  -- ROBLOX deviation: differentiate between a Lua array and a table with an ipairs method
  if typeof(actualSetOrArray.ipairs) == "function" then
    for _, __ in actualSetOrArray:ipairs() do
      actualArrayLength += 1
    end
  else
    for _, __ in ipairs(actualSetOrArray) do
      actualArrayLength += 1
    end
  end

  local expectedArrayLength = 0
  -- ROBLOX deviation: differentiate between a Lua array and a table with an ipairs method
  if typeof(expectedSetOrArray.ipairs) == "function" then
    for _, __ in expectedSetOrArray:ipairs() do
      expectedArrayLength += 1
    end
  else
    for _, __ in ipairs(expectedSetOrArray) do
      expectedArrayLength += 1
    end
  end

  if actualArrayLength ~= expectedArrayLength then
    return {
      message = function()
        return string.format(
            "Expected %d interactions but there were %d", expectedArrayLength, actualArrayLength
        )
      end,
      pass = false,
    }
  end

  for i, actualInteraction in actualSetOrArray:ipairs() do
    local expectedInteraction = expectedSetOrArray._array and expectedSetOrArray._array[i] or expectedSetOrArray[i]
    local result = toMatchInteraction(self, actualInteraction, expectedInteraction)
    if result.pass == false then
      return result
    end
  end

  return {pass = true}
end

local exports = {
  toContainNoInteractions = toContainNoInteractions,
  toHaveBeenLastNotifiedOfInteraction = toHaveBeenLastNotifiedOfInteraction,
  toHaveBeenLastNotifiedOfWork = toHaveBeenLastNotifiedOfWork,
  toMatchInteraction = toMatchInteraction,
  toMatchInteractions = toMatchInteractions,
}

return exports
