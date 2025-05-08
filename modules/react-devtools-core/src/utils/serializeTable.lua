local HttpService = game:GetService("HttpService")

type Record = { [string]: any }

local ENCODE_TO_NULL = newproxy()

--- Serializes a table such that it can be encoded as JSON via HttpService.
local function serializeTable(tbl: Record): Record
	local seen = {}

	local function visitPropsRecursive(parent: Record): any
		if type(parent) ~= "table" then
			return parent
		end

		-- Break cyclic references
		if seen[parent] then
			return nil
		end
		seen[parent] = true

		local newParent = {}
		for key, value in parent do
			if type(value) == "table" then
				local newValue = visitPropsRecursive(value)
				newParent[key] = newValue
			elseif typeof(value) == "UDim" then
				newParent[key] = `UDim({value.Scale}, {value.Offset})`
			elseif typeof(value) == "UDim2" then
				newParent[key] =
					`UDim2({value.X.Scale}, {value.X.Offset}, {value.Y.Scale}, {value.Y.Offset})`
			elseif typeof(value) == "Vector2" then
				newParent[key] = `Vector2({value.X}, {value.Y})`
			elseif typeof(value) == "Vector3" then
				newParent[key] = `Vector3({value.X}, {value.Y}, {value.Z})`
			elseif typeof(value) == "CFrame" then
				newParent[key] = `CFrame({tostring(value)})`
			elseif typeof(value) == "Color3" then
				newParent[key] = `Color3({value.R}, {value.G}, {value.B})`
			elseif typeof(value) == "Rect" then
				newParent[key] =
					`Rect({value.Min.X}, {value.Min.Y}, {value.Max.X}, {value.Max.Y})`
			elseif typeof(value) == "EnumItem" then
				newParent[key] = `EnumItem({value.EnumType}, {value.Name})`
			elseif typeof(value) == "Instance" then
				newParent[key] = `Instance({value:GetFullName()})`
			elseif typeof(value) == "BrickColor" then
				newParent[key] = `BrickColor({value.Name})`
			elseif typeof(value) == "NumberRange" then
				newParent[key] = `NumberRange({value.Min}, {value.Max})`
			elseif typeof(value) == "NumberSequence" then
				local keypoints = {}
				for _, kp in value.Keypoints do
					table.insert(
						keypoints,
						`NumberSequenceKeypoint({kp.Time}, {kp.Value}, {kp.Envelope})`
					)
				end
				newParent[key] = `NumberSequence({table.concat(keypoints, ", ")})`
			elseif typeof(value) == "ColorSequence" then
				local keypoints = {}
				for _, kp in ipairs(value.Keypoints) do
					table.insert(
						keypoints,
						`ColorSequenceKeypoint({kp.Time}, {kp.Value.R}, {kp.Value.G}, {kp.Value.B})`
					)
				end
				newParent[key] = `ColorSequence({table.concat(keypoints, ", ")})`
			elseif typeof(value) == "PhysicalProperties" then
				newParent[key] =
					`PhysicalProperties({value.Density}, {value.Friction}, {value.Elasticity}, {value.FrictionWeight}, {value.ElasticityWeight})`
			elseif typeof(value) == "Vector2int16" then
				newParent[key] = `Vector2int16({value.X}, {value.Y})`
			elseif typeof(value) == "Vector3int16" then
				newParent[key] = `Vector3int16({value.X}, {value.Y}, {value.Z})`
			elseif typeof(value) == "PathWaypoint" then
				newParent[key] =
					`PathWaypoint({value.Position.X}, {value.Position.Y}, {value.Position.Z}, {value.Action})`
			elseif typeof(value) == "OverlapParams" then
				newParent[key] =
					`OverlapParams({value.FilterDescendantsInstances}, {value.FilterType}, {value.MaxParts}, {value.CollisionGroup})`
			elseif typeof(value) == "RaycastParams" then
				newParent[key] =
					`RaycastParams({value.FilterDescendantsInstances}, {value.FilterType}, {value.IgnoreWater}, {value.CollisionGroup})`
			else
				local canSerialize = pcall(HttpService.JSONEncode, HttpService, { value })
				if canSerialize then
					newParent[key] = value
				else
					warn(
						`[React DevTools] Could not serialize value for key "{key}" (type '{typeof(
							value
						)}'):`,
						value
					)
					newParent[key] = ENCODE_TO_NULL
				end
			end
		end
		return newParent
	end

	return visitPropsRecursive(tbl)
end

return serializeTable
