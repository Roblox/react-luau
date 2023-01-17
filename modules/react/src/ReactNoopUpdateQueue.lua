-- ROBLOX upstream: https://github.com/facebook/react/blob/0cf22a56a18790ef34c71bef14f64695c0498619/packages/react/src/ReactNoopUpdateQueue.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 ]]

local Packages = script.Parent.Parent
-- ROBLOX: use patched console from shared
local console = require(Packages.Shared).console

local didWarnStateUpdateForUnmountedComponent = {}

local function warnNoop(publicInstance: any, callerName: string)
	if _G.__DEV__ then
		-- local constructor = publicInstance.constructor
		-- local componentName = ((constructor and (constructor.displayName or constructor.name)) or 'ReactClass')
		-- deviation: For Lua Class components, the name comes from a property
		-- defined on the metatable
		local componentName = publicInstance.__componentName or "ReactClass"
		local warningKey = componentName .. "." .. callerName
		if didWarnStateUpdateForUnmountedComponent[warningKey] then
			return
		end
		-- ROBLOX deviation: message adjusted for accuracy with Lua class components
		console.error(
			"Can't call %s on a component that is not yet mounted. "
				.. "This is a no-op, but it might indicate a bug in your application. "
				.. "Instead, assign to `self.state` directly with the desired state in "
				.. "the %s component's `init` method.",
			callerName,
			componentName
		)
		didWarnStateUpdateForUnmountedComponent[warningKey] = true
	end
end

--[[*
 * This is the abstract API for an update queue.
 ]]
local ReactNoopUpdateQueue = {
	--[[*
   * Checks whether or not this composite component is mounted.
   * @param {ReactClass} publicInstance The instance we want to test.
   * @return {boolean} True if mounted, false otherwise.
   * @protected
   * @final
   ]]
	isMounted = function(publicInstance)
		return false
	end,
	--[[*
   * Forces an update. This should only be invoked when it is known with
   * certainty that we are **not** in a DOM transaction.
   *
   * You may want to call this when you know that some deeper aspect of the
   * component's state has changed but `setState` was not called.
   *
   * This will not invoke `shouldComponentUpdate`, but it will invoke
   * `componentWillUpdate` and `componentDidUpdate`.
   *
   * @param {ReactClass} publicInstance The instance that should rerender.
   * @param {?function} callback Called after component is updated.
   * @param {?string} callerName name of the calling function in the public API.
   * @internal
   ]]
	enqueueForceUpdate = function(publicInstance, callback, callerName)
		warnNoop(publicInstance, "forceUpdate")
	end,
	--[[*
   * Replaces all of the state. Always use this or `setState` to mutate state.
   * You should treat `this.state` as immutable.
   *
   * There is no guarantee that `this.state` will be immediately updated, so
   * accessing `this.state` after calling this method may return the old value.
   *
   * @param {ReactClass} publicInstance The instance that should rerender.
   * @param {object} completeState Next state.
   * @param {?function} callback Called after component is updated.
   * @param {?string} callerName name of the calling function in the public API.
   * @internal
   ]]
	enqueueReplaceState = function(publicInstance, completeState, callback, callerName)
		warnNoop(publicInstance, "replaceState")
	end,
	--[[*
   * Sets a subset of the state. This only exists because _pendingState is
   * internal. This provides a merging strategy that is not available to deep
   * properties which is confusing. TODO: Expose pendingState or don't use it
   * during the merge.
   *
   * @param {ReactClass} publicInstance The instance that should rerender.
   * @param {object} partialState Next partial state to be merged with state.
   * @param {?function} callback Called after component is updated.
   * @param {?string} Name of the calling function in the public API.
   * @internal
   ]]
	enqueueSetState = function(publicInstance, partialState, callback, callerName)
		warnNoop(publicInstance, "setState")
	end,
}

return ReactNoopUpdateQueue
