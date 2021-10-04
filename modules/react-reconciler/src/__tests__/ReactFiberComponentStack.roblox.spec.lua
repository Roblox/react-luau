return function()
	local Packages = script.Parent.Parent.Parent
    local LuauPolyfill = require(Packages.LuauPolyfill)
    local Error = LuauPolyfill.Error
	local jestExpect = require(Packages.Dev.JestGlobals).expect
	local RobloxJest = require(Packages.Dev.RobloxJest)
    local ReactInternalTypes = require(script.Parent.Parent.ReactInternalTypes)
    type Fiber = ReactInternalTypes.Fiber


	local ReactFiberComponentStack

	describe("ReactFiberComponentStack", function()
		beforeEach(function()
			RobloxJest.resetModules()
			ReactFiberComponentStack = require(script.Parent.Parent.ReactFiberComponentStack)
		end)

		it("given a nil fiber then it gives correct error message", function()
            local message = ReactFiberComponentStack.getStackByFiberInDevAndProd((nil :: any) :: Fiber)
            jestExpect(message).toContain("attempt to index nil")
		end)

        it("given a fiber that throws Error then it gives correct error message", function()
            local throwingFiber = {}
            setmetatable(throwingFiber, {
                __index = function(t, k)
                    if k == "tag" then
                        error(Error.new("this was an error object in a spec file"))
                    end
                    return nil
                end
            })

            local message = ReactFiberComponentStack.getStackByFiberInDevAndProd((throwingFiber :: any) :: Fiber)
            jestExpect(message).toContain("this was an error object in a spec file")
		end)

        it("given a fiber that throws a non-Error table then it gives correct error message", function()
            local customErrorTable = {}
            setmetatable(customErrorTable, {
                __tostring = function(t, k)
                     return "this was a custom __tostring"
                end
            })

            local throwingFiber = {}
            setmetatable(throwingFiber, {
                __index = function(t, k)
                    if k == "tag" then
                        error(customErrorTable)
                    end
                    return nil
                end
            })

            local message = ReactFiberComponentStack.getStackByFiberInDevAndProd((throwingFiber :: any) :: Fiber)
            jestExpect(message).toContain("this was a custom __tostring")
		end)

    end)
end
