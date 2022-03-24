-- built-in flowtypes reverse engineered based on usage and enabling strict type checking on test suites
--!strict
local Packages = script.Parent.Parent
local LuauPolyfill = require(Packages.LuauPolyfill)
type Error = LuauPolyfill.Error
type Array<T> = LuauPolyfill.Array<T>
type Object = { [string]: any }
-- duplicated from ReactElementType to avoid circular dep
type Source = {
	fileName: string,
	lineNumber: number,
}

-- ROBLOX deviation: alias for internal React$ flow types
export type React_Node =
	nil
	| boolean
	| number
	| string
	| React_Element<any>
	-- ROBLOX TODO: only include this once it's more specific than `any`
	-- | React_Portal
	| Array<React_Node?>
	-- ROBLOX TODO Luau: this more closely matches the upstream Iterable<>, hypothetically the UNIQUE_TAG field makes it so we don't unify with other tables and squad field resolution
	| { [string]: React_Node?, UNIQUE_TAG: any? }

export type React_Element<ElementType> = {
	type: ElementType,
	props: React_ElementProps<ElementType>?,
	key: React_Key | nil,
	ref: any,
}

export type React_PureComponent<Props, State = nil> = React_Component<Props, State>

-- ROBLOX note: this flowtype built-in is derived from the object shape returned by forwardRef
export type React_AbstractComponent<Config, Instance> = {
	["$$typeof"]: number,
	render: (props: Config, ref: React_Ref<Instance>) -> React_Node,
	displayName: string?,
	defaultProps: Config?,
	-- not in React flowtype, but is in definitelytyped and is used in ReactElement
	name: string?,
	-- allows methods to be hung on a component, used in forwardRef.spec regression test we added
	[string]: any,
}

-- ROBLOX TODO: ElementConfig: something like export type React_ElementConfig<React_Component<P>> = P
export type React_ElementConfig<C> = Object

-- ROBLOX deviation: this is a class export upstream, so optional overrides are nil-able, and it's extensible by default
export type React_Component<Props, State = nil> = {
	-- fields
	props: Props,
	state: State,

	-- action methods

	setState: (
		self: React_Component<Props, State>,
		partialState: State | ((State, Props) -> State?),
		callback: (() -> any)?
	) -> (),

	forceUpdate: (callback: ((() -> ())?)) -> (),

	-- lifecycle methods

	init: ((props: Props?, context: any?) -> ())?,
	render: (self: React_Component<Props, State>) -> React_Node,
	componentWillMount: ((self: React_Component<Props, State>) -> any)?,
	UNSAFE_componentWillMount: ((self: React_Component<Props, State>) -> any)?,
	componentDidMount: ((self: React_Component<Props, State>) -> any)?,
	componentWillReceiveProps: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextContext: any
	) -> any)?,
	UNSAFE_componentWillReceiveProps: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextContext: any
	) -> any)?,
	shouldComponentUpdate: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextState: State,
		nextContext: any
	) -> boolean)?,
	componentWillUpdate: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextState: State,
		nextContext: any
	) -> any)?,
	UNSAFE_componentWillUpdate: ((
		self: React_Component<Props, State>,
		nextProps: Props,
		nextState: State,
		nextContext: any
	) -> any)?,
	componentDidUpdate: ((
		self: React_Component<Props, State>,
		prevProps: Props,
		prevState: State,
		prevContext: any
	) -> any)?,
	componentWillUnmount: ((self: React_Component<Props, State>) -> any)?,
	componentDidCatch: ((
		self: React_Component<Props, State>,
		error: Error,
		info: {
			componentStack: string,
		}
	) -> any)?,

	-- long tail of other stuff not modeled very well

	-- ROBLOX deviation: this field is only used in relation to string refs, which we do not support
	-- refs: any,
	-- context: any,
	getChildContext: (self: React_Component<Props, State>) -> any,
	-- statics
	displayName: string?,
	childContextTypes: any?,
	contextTypes: any?,
	propTypes: any?,

	-- ROBLOX FIXME: this is a legacy Roact field and should be removed in React 18 Lua
	validateProps: (Props) -> (boolean, string?)?,

	-- We don't add a type for `defaultProps` so that its type may be entirely
	-- inferred when we diff the type for `defaultProps` with `Props`. Otherwise
	-- the user would need to define a type (which would be redundant) to override
	-- the type we provide here in the base class.
	-- ROBLOX deviation: Luau doesn't do the inference above
	defaultProps: Props?,
	-- ROBLOX deviation: class export allows assigning additional custom instance fields
	[string]: any,
}

-- ROBLOX deviation: Lua doesn't allow fields on functions, and we haven't implemented callable tables as "function" components
export type React_StatelessFunctionalComponent<Props> = (
	props: Props,
	context: any
) -> React_Node
export type React_ComponentType<Config> = React_AbstractComponent<Config, any>

export type React_ElementType = string | React_AbstractComponent<any, any>

-- This was reverse engineered from usage, no specific flowtype or TS artifact
export type React_ElementProps<ElementType> = {
	ref: React_Ref<ElementType>?,
	key: React_Key?,
	__source: Source?,
	children: any?,
}

-- ROBLOX deviation: this is a built-in flow type, and very complex. we fudge this with `any`
-- type ElementRef<
--   C extends keyof JSX.IntrinsicElements
--   | React.ForwardRefExoticComponent<any>
--   | (new (props: any) -> React.Component<any, {}, any>)
--   | ((props: any, context?: any) -> ReactElement | null)
--   > = "ref" extends keyof ComponentPropsWithRef<C>
--     ? NonNullable<ComponentPropsWithRef<C>["ref"]> extends Ref<infer Instance>
--       ? Instance
--       : never
--     : never

-- ROBLOX TODO: Not sure how to model this, upstream: https://github.com/facebook/flow/blob/main/tests/react_instance/class.js#L10
-- ROBLOX FIXME Luau: if I make this Object, we run into normalization issues: '{| current: React_ElementRef<any>? |}' could not be converted into '(((?) -> any) | {| current: ? |})?
export type React_ElementRef<C> = any

export type React_Ref<ElementType> =
	{ current: React_ElementRef<ElementType> | nil }
	| ((React_ElementRef<ElementType> | nil) -> any)
-- ROBLOX deviation: we don't support string refs, and this is unsound flowtype when used with ref param of useImperativeHandle
-- | string

export type React_Context<T> = {
	Provider: React_ComponentType<{ value: T, children: React_Node? }>,
	Consumer: React_ComponentType<{ children: (value: T) -> React_Node? }>,
}

-- ROBLOX TODO: declared as an opaque type in flowtype: https://github.com/facebook/flow/blob/422821fd42c09c3ef609c60516fe754b601ea205/lib/react.js#L182
export type React_Portal = any
export type React_Key = string | number

return {}
