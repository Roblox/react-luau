-- ROBLOX upstream: https://github.com/facebook/react/blob/12adaffef7105e2714f82651ea51936c563fe15c/packages/react-devtools/index.js

local Packages = script.Parent
local ReactDevtoolsCore = require(Packages.ReactDevtoolsCore)

local connectToDevtools = ReactDevtoolsCore.backend.connectToDevtools

-- Connect immediately with default options.
-- If you need more control, use `react-devtools-core` directly instead of `react-devtools`.
connectToDevtools()
