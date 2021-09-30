--!strict
local Packages = script.Parent

local React = require(Packages.React)
local ReactRoblox = require(Packages.ReactRoblox)

local RoactTree = require(script.RoactTree)

return {
	-- Overlapping contents of public `React` interface
	Component = React.Component,
	PureComponent = React.PureComponent,
	createElement = React.createElement,
	createRef = React.createRef,
	forwardRef = React.forwardRef,
	createContext = React.createContext,

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
	None = require(script.None),

	-- Event/Change keys for Roact-specific event subscription behavior
	Event = ReactRoblox.Event,
	Change = ReactRoblox.Change,

	-- Binding interface entry-point for Roact-specific 'bindings' feature
	createBinding = React.createBinding,
	joinBindings = React.joinBindings,

	act = ReactRoblox.act,
}
