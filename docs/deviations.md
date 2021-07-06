# Deviations
**This is a work in progress! Most of these notes are old!**

The Roact alignment effort aims to map as closely to React's API as possible, but there are a few places where language deviations require us to omit functionality or deviate our approach.

## Class Components
Lua does not have ES6's `class` semantics. For class components, Roact will expose `Component:extend(name: string) -> Component` to bridge this gap. Equivalently, `PureComponent:extend` is used to define PureComponents.

### Constructors
Because of the lack of class semantics, there are also no inheritable constructors; instead, Roact provides a lifecycle method called `init` that takes the place of the constructor, running immediately after an instance is created for that class.

For all intents and purposes, this should function exactly like a constructor for a class component in React, except that there is no need to call `super`.

## Function Components
JavaScript Functions are also objects, which means that they can have member fields defined on them. Lua/Luau does not allow this.

### defaultProps
For the time being, function components do not support the `defaultProps` feature. In the future, we may want to re-implement it in terms of hooks to make sure that function components with hooks are as appealing and feature-rich as possible.

### propTypes
For the time being, function components do not support the `propTypes` feature. While propTypes is less often used and can in many cases be superseded by static type checking, we may want to, in the future, re-implement it in terms of hooks to make sure that function components with hooks are as appealing and feature-rich as possible.

### contextTypes
For the time being, function components do not support the `contextTypes` feature. While contextTypes is less often used and can in many cases be superseded by static type checking, we may want to, in the future, re-implement it in terms of hooks to make sure that function components with hooks are as appealing and feature-rich as possible.
