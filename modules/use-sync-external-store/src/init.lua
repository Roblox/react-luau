--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/use-sync-external-store/src/useSyncExternalStoreWithSelector.js#L13-L132

local Packages = script.Parent
local React = require(Packages.React)
local is = require(Packages.Shared).objectIs

local function useSyncExternalStoreWithSelector<Snapshot, Selection>(
	subscribe: (() -> ()) -> () -> (),
	getSnapshot: () -> Snapshot,
	getServerSnapshot: (() -> Snapshot)?,
	selector: (Snapshot) -> Selection,
	isEqual: ((Selection, Selection) -> boolean)?
): Selection
	local getSelection, getServerSelection = React.useMemo(function()
		local hasMemo = false
		local memoizedSnapshot: Snapshot
		local memoizedSelection: Selection

		local function memoizedSelector(nextSnapshot: Snapshot): Selection
			if not hasMemo then
				hasMemo = true
				memoizedSnapshot = nextSnapshot
				memoizedSelection = selector(nextSnapshot)
				return memoizedSelection
			end

			if is(memoizedSnapshot, nextSnapshot) then
				return memoizedSelection
			end

			memoizedSnapshot = nextSnapshot
			memoizedSelection = selector(nextSnapshot)
			return memoizedSelection
		end

		local function getSnapshotWithSelector(): Selection
			return memoizedSelector(getSnapshot())
		end

		local getServerSnapshotWithSelector = if getServerSnapshot == nil
			then nil
			else function(): Selection
				return memoizedSelector(getServerSnapshot())
			end

		return getSnapshotWithSelector, getServerSnapshotWithSelector
	end, { getSnapshot, getServerSnapshot, selector, isEqual })

	local value = React.useSyncExternalStore(subscribe, getSelection, getServerSelection)
	React.useDebugValue(value)
	return value
end

return {
	useSyncExternalStoreWithSelector = useSyncExternalStoreWithSelector,
}
