-- ROBLOX upstream: https://github.com/facebook/react/blob/v17.0.1/packages/react-devtools-shared/src/backend/NativeStyleEditor/types.js
-- /**
--  * Copyright (c) Facebook, Inc. and its affiliates.
--  *
--  * This source code is licensed under the MIT license found in the
--  * LICENSE file in the root directory of this source tree.
--  *
--  * @flow
--  */
type Object = { [string]: any }

export type BoxStyle = { bottom: number, left: number, right: number, top: number }

export type Layout = {
	x: number,
	y: number,
	width: number,
	height: number,
	left: number,
	top: number,
	margin: BoxStyle,
	padding: BoxStyle,
}

export type Style = Object

export type StyleAndLayout = { id: number, style: Style | nil, layout: Layout | nil }

return {}
