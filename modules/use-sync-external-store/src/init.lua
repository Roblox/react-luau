--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/ae74234eae6ebd62f19190731278e20bc1c37d51/packages/use-sync-external-store/src/useSyncExternalStoreWithSelector.js#L13-L132

local Packages = script.Parent
local React = require(Packages.React)
local is = require(Packages.Shared).objectIs

type Inst<Selection> = {
	hasValue: boolean,
	value: Selection?,
}

local function useSyncExternalStoreWithSelector<Snapshot, Selection>(
	subscribe: (() -> ()) -> () -> (),
	getSnapshot: () -> Snapshot,
	getServerSnapshot: (() -> Snapshot)?,
	selector: (Snapshot) -> Selection,
	isEqual: ((Selection, Selection) -> boolean)?
): Selection
	local instRef = React.useRef(nil :: Inst<Selection>?)
	local inst = instRef.current
	if inst == nil then
		inst = {
			hasValue = false,
			value = nil,
		}
		instRef.current = inst
	end

	local getSelection, getServerSelection = React.useMemo(function()
		local hasMemo = false
		local memoizedSnapshot: Snapshot
		local memoizedSelection: Selection

		local function memoizedSelector(nextSnapshot: Snapshot): Selection
			if not hasMemo then
				hasMemo = true
				memoizedSnapshot = nextSnapshot
				local nextSelection = selector(nextSnapshot)
				if isEqual ~= nil and inst.hasValue then
					local currentSelection = inst.value :: Selection
					if isEqual(currentSelection, nextSelection) then
						memoizedSelection = currentSelection
						return currentSelection
					end
				end
				memoizedSelection = nextSelection
				return nextSelection
			end

			if is(memoizedSnapshot, nextSnapshot) then
				return memoizedSelection
			end

			local nextSelection = selector(nextSnapshot)
			if isEqual ~= nil and isEqual(memoizedSelection, nextSelection) then
				memoizedSnapshot = nextSnapshot
				return memoizedSelection
			end

			memoizedSnapshot = nextSnapshot
			memoizedSelection = nextSelection
			return nextSelection
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
	React.useEffect(function()
		inst.hasValue = true
		inst.value = value
	end, { value })
	React.useDebugValue(value)
	return value
end

return {
	useSyncExternalStoreWithSelector = useSyncExternalStoreWithSelector,
}
