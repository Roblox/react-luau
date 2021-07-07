local value = 0

return {
	increment = function()
		value = value + 1
	end,
	get = function()
		return value
	end,
}
