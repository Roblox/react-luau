--!strict
--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]
local Packages = script.Parent

local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)
local Shared = require(Packages.Shared)

local RoactTree = require(script.RoactTree)

return {
	-- Overlapping contents of public `React` interface
	Component = React.Component,
	PureComponent = React.PureComponent,
	createElement = React.createElement,
	createRef = React.createRef,
	forwardRef = React.forwardRef,
	createContext = React.createContext,
	-- This public interface is aligned but is a deviation in React. It's
	-- necessary to accommodate lua table semantics when merging state
	None = React.None,

	-- Compatibility layer for top-level interface, stands in for `createRoot`
	-- and similar APIs
	mount = RoactTree.mount,
	update = RoactTree.update,
	unmount = RoactTree.unmount,

	-- API compatibility layers to accommodate old interfaces
	createFragment = require(script.createFragment),
	oneChild = require(script.oneChild),
	setGlobalConfig = require(script.setGlobalConfig),
	Portal = require(script.Portal),

	-- Compatibility layer for special symbol keys which will be replaced with
	-- reserved prop names in Roact 17
	Ref = "ref",
	-- FIXME: React actually _does_ have a `.Children`, which has different
	-- behavior (none of which overlaps with Roact). Should we keep this as is
	-- and accept that React.Children and RoactCompat.Children will be totally
	-- different things?
	Children = "children",

	-- Event/Change keys for Roact-specific event subscription behavior
	Event = Shared.Event,
	Change = Shared.Change,

	-- Binding interface entry-point for Roact-specific 'bindings' feature
	createBinding = React.createBinding,
	joinBindings = React.joinBindings,

	act = ReactRoblox.act,
}
