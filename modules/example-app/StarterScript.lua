local CorePackages = game:GetService("CorePackages")
local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return
end

-- Set global flags and initialize devtools before React is ever used
local ReactGlobals = require(CorePackages.ReactGlobals)
ReactGlobals.__DEV__ = true
ReactGlobals.__PROFILE__ = true

local ReactDevtoolsCore = require(CorePackages.ReactDevtoolsCore)
ReactDevtoolsCore.backend.connectToDevtools()

require(CorePackages.ExampleApp)
