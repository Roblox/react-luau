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
--[[
	ROBLOX deviation: ReactFiberHostConfig captures singleton state across the
	whole workspace. This file and the modules it requires were moved from React
	to untangle a cyclic workspace member dependency.

	Before:
	* ReactFiberHostConfig (and the 5 associated modules) lived in React
	* React had a dependency on Shared
	* Shared reached into React source to re-export ReactFiberHostConfig (cycle)

	After:
	* ReactFiberHostConfig (and the 5 associated modules) live in Shared
	* React depends on Shared
	* Shared has no intra-workspace dependencies (no cycles)
]]

-- types that are common across ReactFiberHostConfig files, moved here to avoid circular deps
type Object = { [string]: any }
export type OpaqueIDType = string | Object

return {
	WithNoHydration = require(script.WithNoHydration),
	WithNoPersistence = require(script.WithNoPersistence),
	WithNoTestSelectors = require(script.WithNoTestSelectors),
}
