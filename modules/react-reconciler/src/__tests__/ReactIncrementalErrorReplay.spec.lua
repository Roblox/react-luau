-- upstream: https://github.com/facebook/react/blob/d13f5b9538e48f74f7c571ef3cde652ca887cca0/packages/react-reconciler/src/__tests__/ReactIncrementalErrorReplay-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 * @jest-environment node
 --]]
--!strict

local Packages = script.Parent.Parent.Parent
local React
local ReactNoop
local Scheduler

return function()
    local RobloxJest = require(Packages.Dev.RobloxJest)
    local jestExpect = require(Packages.Dev.JestGlobals).expect

    beforeEach(function()
      RobloxJest.resetModules()

      React = require(Packages.React)
      ReactNoop = require(Packages.Dev.ReactNoopRenderer)
      Scheduler = require(Packages.Scheduler)
    end)

    -- ROBLOX deviation: this test doesn't make sense in not JSX
    -- it('should fail gracefully on error in the host environment', () => {
    --     ReactNoop.render(<errorInBeginPhase />);
    --     jestExpect(Scheduler).toFlushAndThrow('Error in host config.');
    --   });

    it("should ignore error if it doesn't throw on retry", function()
        local didInit = false

        local function badLazyInit()
            local needsInit = not didInit
            didInit = true
            if needsInit then
                error("Hi")
            end
        end

        local App = React.Component:extend("App")
        function App:render()
            badLazyInit()
            return React.createElement("TextLabel", {Text="Hello"})
        end
        ReactNoop.render(React.createElement(App))
        jestExpect(Scheduler).toFlushWithoutYielding()
    end)
end