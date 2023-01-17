--!strict
-- ROBLOX upstream: https://github.com/facebook/react/blob/17f582e0453b808860be59ed3437c6a426ae52de/packages/react-reconciler/src/ReactFiberLazyComponent.new.js
--[[*
 * Copyright (c) Facebook, Inc. and its affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *
 * @flow
]]

type Object = { [any]: any }

local function resolveDefaultProps(Component: any, baseProps: Object): Object
	-- ROBLOX deviation: check if type is table before checking defaultProps to prevent non-table index
	if Component and typeof(Component) == "table" and Component.defaultProps then
		-- Resolve default props. Taken from ReactElement
		-- ROBLOX FIXME Luau: hard cast to object until we can model this better in Luau. avoids Expected type table, got 'Object & any & any & { [any]: any }' instead
		local props = table.clone(baseProps) :: Object
		local defaultProps = Component.defaultProps
		for propName, _ in defaultProps do
			if props[propName] == nil then
				props[propName] = defaultProps[propName]
			end
		end
		return props
	end
	return baseProps
end

return {
	resolveDefaultProps = resolveDefaultProps,
}
