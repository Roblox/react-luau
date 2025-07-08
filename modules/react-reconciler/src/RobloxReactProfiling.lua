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
-- Targeted performance insights for Roblox Microprofiler
local Packages = script.Parent.Parent
local getComponentName = require(Packages.Shared).getComponentName
local ReactWorkTags = require(script.Parent.ReactWorkTags)

local ReactInternalTypes = require(script.Parent.ReactInternalTypes)
type Fiber = ReactInternalTypes.Fiber
type FiberRoot = ReactInternalTypes.FiberRoot

-- ReactMicroprofilerLevel Levels --
local LEVEL_ROOTS_LOG_ONLY = 1 -- Level 1: Roots for Logging only
local LEVEL_ROOTS = 5 -- Level 5: Roots + Commit time in Microprofiler
local LEVEL_FIBERS = 10 -- Level 10: Individual Fiber "units of work" in Microprofiler

local loadedFlag, ReactMicroprofilerLevel = pcall(function()
	return game:DefineFastInt("ReactMicroprofilerLevel5", 0)
end)
if not loadedFlag then
	ReactMicroprofilerLevel = 0
end

export type Marker = {
	id: string,
	startTime: number,
	endTime: number,
}

export type SamplerCallback = (Marker) -> ()
function noop(...: unknown) end

local enableRootSampling = false
local timerSamplingCallback: SamplerCallback | nil = nil

-- used to inhibit profileend() calls that no longer match the originating profilebegin(...) frame
local numActiveProfilesInFrame = 0

if ReactMicroprofilerLevel >= LEVEL_ROOTS then
	game:GetService("RunService").Heartbeat:Connect(function()
		numActiveProfilesInFrame = 0
	end)
end

local microprofiler = if ReactMicroprofilerLevel >= LEVEL_ROOTS
	then {
		profilebegin = function(...)
			debug.profilebegin(...)
			numActiveProfilesInFrame += 1
		end,
		profileend = function()
			if numActiveProfilesInFrame > 0 then
				debug.profileend()
				numActiveProfilesInFrame -= 1
			end
		end,
	}
	else {
		profilebegin = noop,
		profileend = noop,
	}

function startTimerSampling(timerSamplingCallbackFn: SamplerCallback)
	if enableRootSampling then
		warn("RobloxReactProfiling Timer Sampling already running.")
	end
	enableRootSampling = true
	timerSamplingCallback = timerSamplingCallbackFn
end

function endTimerSampling()
	enableRootSampling = false
	timerSamplingCallback = nil
end

function getFirstStringKey(t: { any: any })
	for key, _ in t do
		if type(key) == "string" then
			return key
		end
	end
	return nil
end

function startTimer(marker: Marker)
	if enableRootSampling then
		marker.startTime = os.clock()
	end
end
function endTimer(marker: Marker)
	if enableRootSampling then
		marker.endTime = os.clock()
		if timerSamplingCallback then
			timerSamplingCallback(marker)
		end
	end
end

function profileRootBeforeUnitOfWork(root: FiberRoot): Marker?
	local rootFiber = root.current
	local profileId = nil

	if rootFiber then
		if rootFiber.memoizedProps then
			-- expecting props table with single item
			profileId = getFirstStringKey(rootFiber.memoizedProps)
		end

		if
			profileId == nil
			and rootFiber.stateNode
			and rootFiber.stateNode.containerInfo
		then
			profileId = rootFiber.stateNode.containerInfo.Name
		end
	end

	-- note: investigate HostRoot vs HostPortal for this condition
	if profileId == "Folder" and rootFiber.child then
		local fiber = rootFiber.child
		local folderProfileId = nil
		if fiber.memoizedProps then
			-- expecting props table with single item
			folderProfileId = getFirstStringKey(fiber.memoizedProps)
		end

		if
			folderProfileId == nil
			and fiber.stateNode
			and fiber.stateNode.containerInfo
		then
			folderProfileId = fiber.stateNode.containerInfo.Name
		end
		if folderProfileId ~= nil then
			profileId = folderProfileId
		end
	end

	if profileId ~= nil then
		local marker = {
			id = profileId,
			startTime = 0,
			endTime = 0,
		}
		startTimer(marker)
		microprofiler.profilebegin(profileId)
		return marker
	end

	return nil
end

function profileRootAfterYielding(marker: Marker?)
	if marker then
		endTimer(marker)
		microprofiler.profileend()
	end
end

function profileUnitOfWorkBefore(unitOfWork: Fiber)
	local profileId = getComponentName(unitOfWork.type)

	if unitOfWork.key then
		profileId = tostring(unitOfWork.key) .. "=" .. (profileId or "?")
	end

	local rootName = nil
	if unitOfWork.stateNode then
		if
			unitOfWork.tag == ReactWorkTags.HostComponent
			or unitOfWork.tag == ReactWorkTags.HostText
		then
			local layerCollector =
				unitOfWork.stateNode:FindFirstAncestorWhichIsA("LayerCollector")
			if layerCollector then
				rootName = "[" .. layerCollector:GetFullName() .. "] "
			end
		end
	end

	if rootName then
		profileId = rootName .. " : " .. (profileId or "?")
	end

	if profileId ~= nil then
		microprofiler.profilebegin(profileId)
		return true
	end

	return false
end

function profileUnitOfWorkAfter(profileRunning: boolean)
	if profileRunning then
		microprofiler.profileend()
	end
end

function profileCommitBefore()
	microprofiler.profilebegin("Commit")
end
function profileCommitAfter()
	microprofiler.profileend()
end

return {
	startTimerSampling = startTimerSampling,
	endTimerSampling = endTimerSampling,
	profileRootBeforeUnitOfWork = if ReactMicroprofilerLevel >= LEVEL_ROOTS_LOG_ONLY
		then profileRootBeforeUnitOfWork
		else noop,
	profileRootAfterYielding = if ReactMicroprofilerLevel >= LEVEL_ROOTS_LOG_ONLY
		then profileRootAfterYielding
		else noop,
	profileUnitOfWorkBefore = if ReactMicroprofilerLevel >= LEVEL_FIBERS
		then profileUnitOfWorkBefore
		else noop,
	profileUnitOfWorkAfter = if ReactMicroprofilerLevel >= LEVEL_FIBERS
		then profileUnitOfWorkAfter
		else noop,
	profileCommitBefore = if ReactMicroprofilerLevel >= LEVEL_ROOTS
		then profileCommitBefore
		else noop,
	profileCommitAfter = if ReactMicroprofilerLevel >= LEVEL_ROOTS
		then profileCommitAfter
		else noop,
}
