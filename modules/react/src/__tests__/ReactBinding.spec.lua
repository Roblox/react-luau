return function()
	local Packages = script.Parent.Parent.Parent
	local jestModule = require(Packages.Dev.JestRoblox)
	local jestExpect = jestModule.Globals.expect
	local jest = jestModule.Globals.jest

	local Binding = require(script.Parent.Parent["ReactBinding.roblox"])
	local ReactCreateRef = require(script.Parent.Parent.ReactCreateRef)

	describe("Binding.create", function()
		it("should return a Binding object and an update function", function()
			local binding, update = Binding.create(1)

			jestExpect(typeof(binding)).toBe("table")
			jestExpect(update).toEqual(jestExpect.any("function"))
		end)

		it("should support tostring on bindings", function()
			local binding, update = Binding.create(1)
			jestExpect(tostring(binding)).toBe("RoactBinding(1)")

			update("foo")
			jestExpect(tostring(binding)).toBe("RoactBinding(foo)")
		end)
	end)

	describe("Binding object", function()
		it("should provide a getter and setter", function()
			local binding, update = Binding.create(1)

			jestExpect(binding:getValue()).toBe(1)

			update(3)

			jestExpect(binding:getValue()).toBe(3)
		end)

		it("should let users subscribe and unsubscribe to its updates", function()
			local binding, update = Binding.create(1)

			local spy = jest:fn()
			local disconnect = Binding.subscribe(
				binding,
				function(...) spy(...) end
			)

			jestExpect(spy).never.toBeCalled()
			update(2)

			jestExpect(spy).toHaveBeenCalledTimes(1)
			jestExpect(spy).toHaveBeenCalledWith(2)

			disconnect()
			update(3)

			jestExpect(spy).toHaveBeenCalledTimes(1)
		end)
	end)

	describe("Mapped bindings", function()
		it("should be composable", function()
			local word, updateWord = Binding.create("hi")

			local wordLength = word:map(string.len)
			local isEvenLength = wordLength:map(function(value)
				return value % 2 == 0
			end)

			jestExpect(word:getValue()).toBe("hi")
			jestExpect(wordLength:getValue()).toBe(2)
			jestExpect(isEvenLength:getValue()).toBe(true)

			updateWord("sup")

			jestExpect(word:getValue()).toBe("sup")
			jestExpect(wordLength:getValue()).toBe(3)
			jestExpect(isEvenLength:getValue()).toBe(false)
		end)

		it("should cascade updates when subscribed", function()
			-- base binding
			local word, updateWord = Binding.create("hi")

			local wordSpy = jest:fn()
			local disconnectWord = Binding.subscribe(
				word,
				function(...) wordSpy(...) end
			)

			-- binding -> base binding
			local length = word:map(string.len)

			local lengthSpy = jest:fn()
			local disconnectLength = Binding.subscribe(
				length,
				function(...) lengthSpy(...) end
			)

			-- binding -> binding -> base binding
			local isEvenLength = length:map(function(value)
				return value % 2 == 0
			end)

			local isEvenLengthSpy = jest:fn()
			local disconnectIsEvenLength = Binding.subscribe(
				isEvenLength,
				function(...) isEvenLengthSpy(...) end
			)

			jestExpect(wordSpy).never.toBeCalled()
			jestExpect(lengthSpy).never.toBeCalled()
			jestExpect(isEvenLengthSpy).never.toBeCalled()

			updateWord("nice")

			jestExpect(wordSpy).toBeCalledTimes(1)
			jestExpect(wordSpy).toBeCalledWith("nice")

			jestExpect(lengthSpy).toBeCalledTimes(1)
			jestExpect(lengthSpy).toBeCalledWith(4)

			jestExpect(isEvenLengthSpy).toBeCalledTimes(1)
			jestExpect(isEvenLengthSpy).toBeCalledWith(true)

			disconnectWord()
			disconnectLength()
			disconnectIsEvenLength()

			updateWord("goodbye")

			jestExpect(wordSpy).toBeCalledTimes(1)
			jestExpect(isEvenLengthSpy).toBeCalledTimes(1)
			jestExpect(lengthSpy).toBeCalledTimes(1)
		end)

		it("should throw when updated directly", function()
			local source = Binding.create(1)
			local mapped = source:map(function(v)
				return v
			end)

			jestExpect(function()
				Binding.update(mapped, 5)
			end).toThrow()
		end)
	end)

	describe("Binding.join", function()
		it("should have getValue", function()
			local binding1 = Binding.create(1)
			local binding2 = Binding.create(2)
			local binding3 = Binding.create(3)

			local joinedBinding = Binding.join({
				binding1,
				binding2,
				foo = binding3,
			})

			local bindingValue = joinedBinding:getValue()
			jestExpect(bindingValue).toEqual({
				[1] = 1,
				[2] = 2,
				foo = 3
			})
		end)

		it("should update when any one of the subscribed bindings updates", function()
			local binding1, update1 = Binding.create(1)
			local binding2, update2 = Binding.create(2)
			local binding3, update3 = Binding.create(3)

			local joinedBinding = Binding.join({
				binding1,
				binding2,
				foo = binding3,
			})

			local spy = jest:fn()
			Binding.subscribe(
				joinedBinding,
				function(...) spy(...) end
			)

			jestExpect(spy).never.toBeCalled()

			update1(3)
			jestExpect(spy).toBeCalledTimes(1)

			jestExpect(spy).toBeCalledWith({
				[1] = 3,
				[2] = 2,
				["foo"] = 3
			})

			update2(4)
			jestExpect(spy).toBeCalledTimes(2)

			jestExpect(spy).toBeCalledWith({
				[1] = 3,
				[2] = 4,
				["foo"] = 3
			})

			update3(8)
			jestExpect(spy).toBeCalledTimes(3)

			jestExpect(spy).toBeCalledWith({
				[1] = 3,
				[2] = 4,
				["foo"] = 8
			})
		end)

		it("should disconnect from all upstream bindings", function()
			local binding1, update1 = Binding.create(1)
			local binding2, update2 = Binding.create(2)

			local joined = Binding.join({binding1, binding2})

			local spy = jest:fn()
			local disconnect = Binding.subscribe(
				joined,
				function(...) spy(...) end
			)

			jestExpect(spy).never.toBeCalled()

			update1(3)
			jestExpect(spy).toBeCalledTimes(1)

			update2(3)
			jestExpect(spy).toBeCalledTimes(2)

			disconnect()
			update1(4)
			jestExpect(spy).toBeCalledTimes(2)

			update2(2)
			jestExpect(spy).toBeCalledTimes(2)

			jestExpect(joined:getValue()).toEqual({ 4, 2 })
		end)

		it("should be okay with calling disconnect multiple times", function()
			local joined = Binding.join({})

			local disconnect = Binding.subscribe(joined, function() end)

			disconnect()
			disconnect()
		end)

		it("should throw if updated directly", function()
			local joined = Binding.join({})

			jestExpect(function()
				Binding.update(joined, 0)
			end)
		end)

		if _G.__DEV__ then
			it("should throw when a non-table value is passed", function()
				jestExpect(function()
					Binding.join("hi")
				end).toThrow()
			end)

			it("should throw when a non-binding value is passed via table", function()
				jestExpect(function()
					local binding = Binding.create(123)

					Binding.join({
						binding,
						"abcde",
					})
				end).toThrow()
			end)
		end
	end)

	describe("createRef", function()
		it("should print the contained value when coerced to a string", function()
			local ref = ReactCreateRef.createRef()
			jestExpect(tostring(ref)).toBe("Ref(nil)")
			ref.current = "hello"
			jestExpect(tostring(ref)).toBe("Ref(hello)")
			ref.current = 123
			jestExpect(tostring(ref)).toBe("Ref(123)")
			ref.current = Instance.new("Folder")
			jestExpect(tostring(ref)).toBe("Ref(Folder)")
		end)
	end)
end