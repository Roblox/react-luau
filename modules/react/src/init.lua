--!strict
-- ROBLOX deviation: simulates `index.js` and exports React's public interface
local React = require(script.React)

local ReactLazy = require(script.ReactLazy)
export type LazyComponent<T, P> = ReactLazy.LazyComponent<T, P>

local Packages = script.Parent
local SharedModule = require(Packages.Shared)
export type StatelessFunctionalComponent<P> = SharedModule.React_StatelessFunctionalComponent<P>
export type Node = SharedModule.React_Node
export type ComponentClass<P> = SharedModule.React_ComponentType<P>
export type ComponentType<P> = ComponentClass<P> | FC<P>
export type Ref<ElementType> = SharedModule.React_Ref<ElementType>
export type PureComponent<Props, State = nil> = React.PureComponent<Props, State>
export type Context<T> = SharedModule.ReactContext<T>


-- ROBLOX deviation START: definitelytyped typescript exports
type ReactElement<P, T> = SharedModule.ReactElement<P, T>
-- we don't include ReactText in ReactChild since roblox renderer doesn't support raw text nodes
export type ReactChild = SharedModule.ReactElement<any, string> | string | number
export type FC<P> = SharedModule.React_StatelessFunctionalComponent<P>
export type ReactNode = SharedModule.React_Node
-- ROBLOX deviation END


return React
