# react
A Roblox Lua port of the `react` package from React. This is the main React package

Status: 🔨 Port in progress

Source: https://github.com/facebook/react/tree/master/packages/react

---

### ✏️ Notes
* Includes some relatively significant deviations in `ReactBaseClasses.lua` to accommodate Lua idioms for objects, constructors, and inheritance.
* Exports React-related type definitions from DefinitelyTyped, like `ReactElement<Props>`, used by Apollo GraphQL and jest. These are the types users of the library should prefer to use.
* Exports React-related type definitions that are built-in to flowtype. Only used by the framework internals itself, and some sibling projects like VirtualizedList. It is not recommended to use these types in application code.

### ❌ Excluded
