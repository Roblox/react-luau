-- ROBLOX note: no upstream
--!strict
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

local YIELD_ERROR =
	"Yielding is not currently supported inside components or hooks. Move this yield into a new thread with `task.spawn` or `task.defer`."

local function resultHandler(co: thread, ok: boolean, ...)
	if not ok then
		local err = (...)
		if typeof(err) == "string" then
			error(debug.traceback(co, err), 3)
		else
			-- If the error is not of type string, just assume it has some
			-- meaningful information and rethrow it so that top-level error
			-- handlers can process it.
			error(err, 3)
		end
	end

	if coroutine.status(co) ~= "dead" then
		error(debug.traceback(co, YIELD_ERROR), 3)
	end

	return ...
end

--[[
    Prevents a callback from yielding. If the callback yields, an error will be
    thrown.
]]
local function NoYield<A..., R...>(callback: (A...) -> R..., ...: A...): R...
	local co = coroutine.create(callback)
	return resultHandler(co, coroutine.resume(co, ...))
end

return NoYield
