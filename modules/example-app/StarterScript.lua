local CorePackages = game:GetService("CorePackages")
local RunService = game:GetService("RunService")

if RunService:IsServer() then
	return
end

local ReactDevtoolsCore = require(CorePackages.ReactDevtoolsCore)

-- Set global flags and initialize devtools before React is ever used
_G.__DEV__ = true
_G.__PROFILE__ = true

ReactDevtoolsCore.backend.connectToDevtools()

require(CorePackages.ExampleApp)
