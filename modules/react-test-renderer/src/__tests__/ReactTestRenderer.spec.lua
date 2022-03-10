--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @emails react-core
 ]]

-- 'use strict'

return function()
  local Packages = script.Parent.Parent.Parent
  local ReactRoblox
  local ReactTestRenderer
  local jestExpect = require(Packages.Dev.JestGlobals).expect
  local RobloxJest = require(Packages.Dev.RobloxJest)

  describe('ReactTestRenderer', function()
    beforeEach(function()
      RobloxJest.resetModules()
			RobloxJest.useRealTimers()
      ReactRoblox = require(Packages.Dev.ReactRoblox)

      -- Isolate test renderer.
      RobloxJest.resetModules()
      ReactTestRenderer = require(Packages.ReactTestRenderer)
    end)

    it('should warn if used to render a ReactRoblox portal', function()
      local container = Instance.new("Folder")

      jestExpect(function()
        jestExpect(function()
          ReactTestRenderer.create(ReactRoblox.createPortal('foo', container))
        end).toThrow()
        -- ROBLOX deviation START: This has `Warning: ` appended to it versus upstream, wording adjusted to not mention ReactDOM
      end).toErrorDev("Warning: An invalid container has been provided.", {
        -- ROBLOX deviation END
        withoutStack = true,
      })


    end)

    -- describe('timed out Suspense hidden subtrees should not be observable via toJSON', () => {
    --   local AsyncText
    --   local PendingResources
    --   local TextResource

    --   beforeEach(() => {
    --     PendingResources = {}
    --     TextResource = ReactCache.unstable_createResource(
    --       text =>
    --         new Promise(resolve => {
    --           PendingResources[text] = resolve
    --         }),
    --       text => text,
    --     )

    --     AsyncText = ({text}) => {
    --       local value = TextResource.read(text)
    --       return value
    --     }
    --   })

    --   it('for root Suspense components', async done => {
    --     local App = ({text}) => {
    --       return (
    --         <React.Suspense fallback="fallback">
    --           <AsyncText text={text} />
    --         </React.Suspense>
    --       )
    --     }

    --     local root = ReactTestRenderer.create(<App text="initial" />)
    --     PendingResources.initial('initial')
    --     await Promise.resolve()
    --     Scheduler.unstable_flushAll()
    --     expect(root.toJSON()).toEqual('initial')

    --     root.update(<App text="dynamic" />)
    --     expect(root.toJSON()).toEqual('fallback')

    --     PendingResources.dynamic('dynamic')
    --     await Promise.resolve()
    --     Scheduler.unstable_flushAll()
    --     expect(root.toJSON()).toEqual('dynamic')

    --     done()
    --   })

    --   it('for nested Suspense components', async done => {
    --     local App = ({text}) => {
    --       return (
    --         <div>
    --           <React.Suspense fallback="fallback">
    --             <AsyncText text={text} />
    --           </React.Suspense>
    --         </div>
    --       )
    --     }

    --     local root = ReactTestRenderer.create(<App text="initial" />)
    --     PendingResources.initial('initial')
    --     await Promise.resolve()
    --     Scheduler.unstable_flushAll()
    --     expect(root.toJSON().children).toEqual(['initial'])

    --     root.update(<App text="dynamic" />)
    --     expect(root.toJSON().children).toEqual(['fallback'])

    --     PendingResources.dynamic('dynamic')
    --     await Promise.resolve()
    --     Scheduler.unstable_flushAll()
    --     expect(root.toJSON().children).toEqual(['dynamic'])

    --     done()
    --   })
    -- })
  end)
end