# `react-devtools-core`

A React DevTools bridge implementation for React Lua. The implementation of this package deviates heavily from the upstream version.

## API

Requiring this package is similar to requiring `react-devtools`, but provides several configurable options. Unlike `react-devtools`, requiring `react-devtools-core` doesn't connect immediately but instead exports a function:

```luau
local ReactDevtoolsCore = require(Packages.ReactDevtoolsCore)
local connectToDevtools = ReactDevtoolsCore.connectToDevtools
connectToDevTools(config)
```

Run `connectToDevTools()` in the same context as React to set up a connection to DevTools.
Be sure to run this function before importing *any* React package -- e.g. `react`, `react-roblox`.

The `config` object may contain:

- `host: string` (defaults to "localhost") - Websocket will connect to this host.
- `port: number` (defaults to `8097`) - Websocket will connect to this port.
- `useHttps: boolean` (defaults to `false`) - Websocket should use a secure protocol (wss).
- `resolveRNStyle: (style: number) => ?Object` - Used by the React Native style plug-in.
- `isAppActive: () => boolean` - If provided, DevTools will poll this method and wait until it returns true before connecting to React.
