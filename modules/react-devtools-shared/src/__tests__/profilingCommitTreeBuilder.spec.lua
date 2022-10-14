--!nonstrict
-- ROBLOX FIXME: Type '({| count: number |}) -> {ReactElement<{ key: number }, a>}' could not be converted into '((React_ElementProps<any>?, any) -> (Array<(Array<*CYCLE*> | React_Element<any> | boolean | number | string | t1)?> | React_Element<any> | boolean | number | string | t1)?) | LazyComponent<a, React_ElementProps<any>?> | ReactContext<any> | ReactProviderType<any> | React_ComponentType<React_ElementProps<any>?> | string where t1 = {| [string]: (boolean | number | string | t1 | {(*CYCLE* | boolean | number | string | t1 | {| key: (number | string)?, props: {| __source: {| fileName: string, lineNumber: number |}?, children: any?, key: (number | string)?, ref: (((any?) -> ()) | {| current: any? |})? |}?, ref: any, type: any |})?}... *TRUNCATED*'; none of the union options are compatible
-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/__tests__/profilingCOmmitTreeBuilder-test.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
 ]]

return function()
	local Packages = script.Parent.Parent.Parent
	local JestGlobals = require(Packages.Dev.JestGlobals)
	local jestExpect = JestGlobals.expect

	local devtoolsTypes = require(script.Parent.Parent.devtools.types)
	type Store = devtoolsTypes.Store

	local global = _G

	xdescribe("commit tree", function()
		local React
		local ReactRoblox
		local Scheduler
		local store: Store
		local utils
		local act

		beforeEach(function()
			utils = require(script.Parent.utils)
			act = utils.act
			utils.beforeEachProfiling()

			store = global.store
			store:setCollapseNodesByDefault(false)
			store:setRecordChangeDescriptions(true)

			React = require(Packages.React)
			ReactRoblox = require(Packages.ReactRoblox)
			Scheduler = require(Packages.Dev.Scheduler)
		end)
		it("should be able to rebuild the store tree for each commit", function()
			local function Child()
				Scheduler.unstable_advanceTime(2)
				return nil
			end
			local ChildMemo = React.memo(Child)

			local function Parent(props: { count: number })
				local count = props.count
				Scheduler.unstable_advanceTime(10)

				local Children = table.create(count)
				for i = 1, count do
					Children[i] = React.createElement(ChildMemo, { key = i - 1 })
				end

				return Children
			end

			local root = ReactRoblox.createRoot(Instance.new("Frame"))

			act(function()
				store._profilerStore:startProfiling()
			end)
			act(function()
				root:render(React.createElement(Parent, { count = 1 }))
			end)
			act(function()
				root:render(React.createElement(Parent, { count = 3 }))
			end)
			act(function()
				root:render(React.createElement(Parent, { count = 2 }))
			end)
			act(function()
				root:render(React.createElement(Parent, { count = 0 }))
			end)
			act(function()
				store._profilerStore:stopProfiling()
			end)

			local rootID = store:getRoots()[1]
			for commitIndex = 1, 4 do
				local profilingCache = store._profilerStore:profilingCache()
				local commitTree = profilingCache:getCommitTree({
					commitIndex = commitIndex,
					rootID = rootID,
				})

				jestExpect(commitTree).toMatchSnapshot(
					string.format("%d: CommitTree", commitIndex - 1)
				)
			end
		end)
	end)
end
