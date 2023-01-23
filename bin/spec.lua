--[[
	* Copyright (c) Roblox Corporation. All rights reserved.
	* Licensed under the MIT License (the "License");
	* you may not use this file except in compliance with the License.
	* You may obtain a copy of the License at
	*
	*     https://opensource.org/licenses/MIT
	*
	* Unless required by applicable law or agreed to in writing, software
	* distributed under the License is distributed on an "AS IS" BASIS,
	* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
	* See the License for the specific language governing permissions and
	* limitations under the License.
]]
local Workspace = script.Parent.RoactAlignment._Workspace
local runCLI = require(Workspace.TestRunner.Dev.Jest).runCLI

local processServiceExists, ProcessService = pcall(function()
	return game:GetService("ProcessService")
end)

local status, result = runCLI(Workspace, {
	verbose = if _G.verbose == "true" then true else nil,
	ci = _G.CI == "true",
	updateSnapshot = _G.UPDATESNAPSHOT == "true",
}, { Workspace }):awaitStatus()

if status == "Rejected" then
	print(result)
end

if
	status == "Resolved"
	and result.results.numFailedTestSuites == 0
	and result.results.numFailedTests == 0
then
	if processServiceExists then
		ProcessService:ExitAsync(0)
	end
end

if processServiceExists then
	ProcessService:ExitAsync(1)
end

return nil
