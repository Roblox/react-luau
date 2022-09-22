Roact is a lua port of Facebook's [React](https://reactjs.org) UI library.

By and large, [React's documentation](https://reactjs.org/docs/getting-started.html) should be able to serve most Roact users' needs. This documentation site serves as a comprehensive guide to the _differences_ between Roact and React.

If you're new to the React library and want **to start learning the concepts of React**, begin with the [React JS documentation](https://reactjs.org/docs/getting-started.html).

If you want **to find out if a React feature is present in Roact (and if there are any differences to be aware of)**, check out the [API Reference](api-reference/react.md).

If you're familiar with React and want **to learn where Roact differs**, start with the [Deviations page](deviations.md).

And if you want **to migrate an existing project from Roact 1.x to Roact 17+**, check out the guide on [Migrating From Roact 1.x](migrating-from-1x/minimum-requirements.md).

### Which Part is "Roact"?

Previously, **Roact** was the name that referred to a single package. It implemented a similar API to that of React 15. This documentation refers to those older versions of Roact as **legacy Roact** or **Roact 1.x**.

Today, **Roact** is used as an umbrella term to describe the collection of packages that compose the Luau port of the React library. This collection of packages includes a few top-level ones, namely `React`, `ReactRoblox`, and `RoactCompat`. This documentation refers to the initial release of this version of Roact as **Roact 17** (because it aligns its implementation to React JS version 17.0.1) or **Roact 17+** (to include future releases).

The originating React UI library, written in JavaScript, is referred to in this documentation as **React JS** in order to clearly disambiguate it from Roact and from the top-level package called `React`. In can be considered an umbrella term for the collection of packages, similar to "Roact".

This documentation endeavors to use these terms consistently throughout to avoid confusion.
