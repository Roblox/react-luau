local Incrementor = require(script.Parent.Incrementor)

return function()
	return Incrementor.get()
end
