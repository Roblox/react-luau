local Packages = script.Parent.Parent.Parent.Parent

local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local jest = JestGlobals.jest
local expect = jestExpect
local beforeEach = JestGlobals.beforeEach
local it = JestGlobals.it
local describe = JestGlobals.describe

local React
local ReactRoblox
local reactRobloxRoot
local Scheduler
local parent

beforeEach(function()
	jest.resetModules()
	jest.useFakeTimers()

	React = require(Packages.React)
	ReactRoblox = require(Packages.ReactRoblox)
	parent = Instance.new("Folder")
	reactRobloxRoot = ReactRoblox.createRoot(parent)
	Scheduler = require(Packages.Scheduler)
end)

describe("mounting instances", function()
	it("should create instances with correct props", function()
		local value = "Hello!"
		local key = "Some Key"

		local element = React.createElement("StringValue", {
			Name = key,
			Value = value,
		})

		reactRobloxRoot:render(element)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#parent:GetChildren()).toBe(1)

		local rootInstance = parent:GetChildren()[1]

		jestExpect(rootInstance.ClassName).toBe("StringValue")
		jestExpect(rootInstance.Value).toBe(value)
		jestExpect(rootInstance.Name).toBe(key)
	end)

	it("names instances with their key value using legacy key syntax", function()
		local key = "Some Key"

		local element = React.createElement("Folder", {}, {
			[key] = React.createElement("BoolValue"),
		})

		reactRobloxRoot:render(element)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#parent:GetChildren()).toBe(1)

		local rootInstance = parent:GetChildren()[1]
		jestExpect(rootInstance.ClassName).toBe("Folder")

		local boolValueInstance = rootInstance:FindFirstChildOfClass("BoolValue")
		jestExpect(boolValueInstance).toBeDefined()
		jestExpect(boolValueInstance.Name).toEqual(key)
	end)

	it("names instances with their key value (using props)", function()
		local key = "Some Key"

		local element = React.createElement(
			"Folder",
			{},
			React.createElement("BoolValue", {
				key = key,
			})
		)

		reactRobloxRoot:render(element)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#parent:GetChildren()).toBe(1)

		local rootInstance = parent:GetChildren()[1]
		jestExpect(rootInstance.ClassName).toBe("Folder")

		local boolValueInstance = rootInstance:FindFirstChildOfClass("BoolValue")
		jestExpect(boolValueInstance).toBeDefined()
		jestExpect(boolValueInstance.Name).toEqual(key)
	end)

	it(
		"names instances with their key value using legacy key syntax and updates them",
		function()
			local key = "Some Key"
			local fnMock = jest.fn()
			local ref = function(...)
				return fnMock(...)
			end

			local element = React.createElement("Folder", {}, {
				[key] = React.createElement("BoolValue", {
					ref = ref,
				}),
			})

			reactRobloxRoot:render(element)
			Scheduler.unstable_flushAllWithoutAsserting()

			jestExpect(fnMock).toHaveBeenCalledTimes(1)
			local refValue = fnMock.mock.calls[1][1]
			jestExpect(refValue.Name).toEqual(key)

			local updatedKey = "Some other key"
			local updatedElement = React.createElement("Folder", {}, {
				[updatedKey] = React.createElement("BoolValue", {
					ref = ref,
				}),
			})
			reactRobloxRoot:render(updatedElement)
			Scheduler.unstable_flushAllWithoutAsserting()

			jestExpect(fnMock).toHaveBeenCalledTimes(3)
			-- ROBLOX FIXME: jest mocks should be able to handle explicit
			-- trailing nils, but do not appear to do so
			jestExpect(fnMock).toHaveBeenNthCalledWith(2 --[[, nil ]])

			local lastRefValue = fnMock.mock.calls[3][1]
			jestExpect(lastRefValue.Name).toEqual(updatedKey)
		end
	)

	it("should create children with correct names and props", function()
		local rootValue = "Hey there!"
		local childValue = 173
		local key = "Some Key"

		local element = React.createElement("StringValue", {
			key = key,
			Value = rootValue,
		}, {
			ChildA = React.createElement("IntValue", {
				Value = childValue,
			}),

			ChildB = React.createElement("Folder"),
		})

		reactRobloxRoot:render(element)
		Scheduler.unstable_flushAllWithoutAsserting()

		expect(#parent:GetChildren()).toEqual(1)

		local rootInstance = parent:GetChildren()[1]

		expect(rootInstance.ClassName).toEqual("StringValue")
		expect(rootInstance.Value).toEqual(rootValue)
		expect(rootInstance.Name).toEqual(key)

		expect(#rootInstance:GetChildren()).toEqual(2)

		local childA = rootInstance.ChildA
		local childB = rootInstance.ChildB

		expect(childA).toBeTruthy()
		expect(childB).toBeTruthy()

		expect(childA.ClassName).toEqual("IntValue")
		expect(childA.Value).toEqual(childValue)

		expect(childB.ClassName).toEqual("Folder")
	end)

	it(
		"names instances with their key value using legacy key syntax through function component",
		function()
			local key = "Some Key"

			local function Foo()
				return React.createElement("BoolValue")
			end

			local element = React.createElement("Folder", {}, {
				[key] = React.createElement(Foo),
			})

			reactRobloxRoot:render(element)
			Scheduler.unstable_flushAllWithoutAsserting()

			jestExpect(#parent:GetChildren()).toBe(1)

			local rootInstance = parent:GetChildren()[1]
			jestExpect(rootInstance.ClassName).toBe("Folder")

			local boolValueInstance = rootInstance:FindFirstChildOfClass("BoolValue")
			jestExpect(boolValueInstance).toBeDefined()
			jestExpect(boolValueInstance.Name).toEqual(key)
		end
	)

	-- it("should attach Bindings to Roblox properties", function()
	-- 	local parent = Instance.new("Folder")
	-- 	local key = "Some Key"

	-- 	local binding, update = Binding.create(10)
	-- 	local element = createElement("IntValue", {
	-- 		Value = binding,
	-- 	})

	-- 	local node = reconciler.createVirtualNode(element, parent, key)

	-- 	RobloxRenderer.mountHostNode(reconciler, node)

	-- 	expect(#parent:GetChildren()).toEqual(1)

	-- 	local instance = parent:GetChildren()[1]

	-- 	expect(instance.ClassName).toEqual("IntValue")
	-- 	expect(instance.Value).toEqual(10)

	-- 	update(20)

	-- 	expect(instance.Value).toEqual(20)

	-- 	RobloxRenderer.unmountHostNode(reconciler, node)
	-- end)

	-- it("should connect Binding refs", function()
	-- 	local parent = Instance.new("Folder")
	-- 	local key = "Some Key"

	-- 	local ref = createRef()
	-- 	local element = createElement("Frame", {
	-- 		[Ref] = ref,
	-- 	})

	-- 	local node = reconciler.createVirtualNode(element, parent, key)

	-- 	RobloxRenderer.mountHostNode(reconciler, node)

	-- 	expect(#parent:GetChildren()).toEqual(1)

	-- 	local instance = parent:GetChildren()[1]

	-- 	expect(ref.current).toBeTruthy()
	-- 	expect(ref.current).toEqual(instance)

	-- 	RobloxRenderer.unmountHostNode(reconciler, node)
	-- end)

	-- it("should call function refs", function()
	-- 	local parent = Instance.new("Folder")
	-- 	local key = "Some Key"

	-- 	local spyRef = createSpy()
	-- 	local element = createElement("Frame", {
	-- 		[Ref] = spyRef.value,
	-- 	})

	-- 	local node = reconciler.createVirtualNode(element, parent, key)

	-- 	RobloxRenderer.mountHostNode(reconciler, node)

	-- 	expect(#parent:GetChildren()).toEqual(1)

	-- 	local instance = parent:GetChildren()[1]

	-- 	expect(spyRef.callCount).toEqual(1)
	-- 	spyRef:assertCalledWith(instance)

	-- 	RobloxRenderer.unmountHostNode(reconciler, node)
	-- end)

	-- it("should throw if setting invalid instance properties", function()
	-- 	local configValues = {
	-- 		elementTracing = true,
	-- 	}

	-- 	GlobalConfig.scoped(configValues, function()
	-- 		local parent = Instance.new("Folder")
	-- 		local key = "Some Key"

	-- 		local element = createElement("Frame", {
	-- 			Frob = 6,
	-- 		})

	-- 		local node = reconciler.createVirtualNode(element, parent, key)

	-- 		local success, message = pcall(RobloxRenderer.mountHostNode, reconciler, node)
	-- 		assert(not success, "Expected call to fail")

	-- 		expect(string.find(message, "Frob")).toBeTruthy()
	-- 		expect(string.find(message, "Frame")).toBeTruthy()
	-- 		expect(string.find(message, "RobloxRenderer%.spec")).toBeTruthy()
	-- 	end)
	-- end)
end)

describe("updating instances", function()
	it("should update node props and children", function()
		local key = "updateHostNodeTest"
		local firstValue = "foo"
		local newValue = "bar"

		local defaultStringValue = Instance.new("StringValue").Value

		local element = React.createElement("StringValue", {
			Name = key,
			Value = firstValue,
		}, {
			ChildA = React.createElement("IntValue", {
				Name = "ChildA",
				Value = 1,
			}),
			ChildB = React.createElement("BoolValue", {
				Name = "ChildB",
				Value = true,
			}),
			ChildC = React.createElement("StringValue", {
				Name = "ChildC",
				Value = "test",
			}),
			ChildD = React.createElement("StringValue", {
				Name = "ChildD",
				Value = "test",
			}),
		})

		reactRobloxRoot:render(element)
		Scheduler.unstable_flushAllWithoutAsserting()

		-- Not testing mountHostNode's work here, only testing that the
		-- node is properly updated.

		local newElement = React.createElement("StringValue", {
			Name = key,
			Value = newValue,
		}, {
			-- ChildA changes element type.
			ChildA = React.createElement("StringValue", {
				Name = "ChildA",
				Value = "test",
			}),
			-- ChildB changes child properties.
			ChildB = React.createElement("BoolValue", {
				Name = "ChildB",
				Value = false,
			}),
			-- ChildC should reset its Value property back to the default.
			ChildC = React.createElement("StringValue", {
				Name = "ChildC",
			}),
			-- ChildD is deleted.
			-- ChildE is added.
			ChildE = React.createElement("Folder", {
				Name = "ChildE",
			}),
		})

		reactRobloxRoot:render(newElement)
		Scheduler.unstable_flushAllWithoutAsserting()

		local rootInstance = parent[key]
		jestExpect(rootInstance.ClassName).toBe("StringValue")
		jestExpect(rootInstance.Value).toBe(newValue)
		jestExpect(#rootInstance:GetChildren()).toBe(4)

		local childA = rootInstance.ChildA
		jestExpect(childA.ClassName).toBe("StringValue")
		jestExpect(childA.Value).toBe("test")

		local childB = rootInstance.ChildB
		jestExpect(childB.ClassName).toBe("BoolValue")
		jestExpect(childB.Value).toBe(false)

		local childC = rootInstance.ChildC
		jestExpect(childC.ClassName).toBe("StringValue")
		jestExpect(childC.Value).toBe(defaultStringValue)

		local childE = rootInstance.ChildE
		jestExpect(childE.ClassName).toBe("Folder")
	end)

	-- it("should update Bindings", function()
	-- 	local parent = Instance.new("Folder")
	-- 	local key = "Some Key"

	-- 	local bindingA, updateA = Binding.create(10)
	-- 	local element = createElement("IntValue", {
	-- 		Value = bindingA,
	-- 	})

	-- 	local node = reconciler.createVirtualNode(element, parent, key)

	-- 	RobloxRenderer.mountHostNode(reconciler, node)

	-- 	local instance = parent:GetChildren()[1]

	-- 	expect(instance.Value).toEqual(10)

	-- 	local bindingB, updateB = Binding.create(99)
	-- 	local newElement = createElement("IntValue", {
	-- 		Value = bindingB,
	-- 	})

	-- 	RobloxRenderer.updateHostNode(reconciler, node, newElement)

	-- 	expect(instance.Value).toEqual(99)

	-- 	updateA(123)

	-- 	expect(instance.Value).toEqual(99)

	-- 	updateB(123)

	-- 	expect(instance.Value).toEqual(123)

	-- 	RobloxRenderer.unmountHostNode(reconciler, node)
	-- end)

	-- it("should update Binding refs", function()
	-- 	local parent = Instance.new("Folder")
	-- 	local key = "Some Key"

	-- 	local refA = createRef()
	-- 	local refB = createRef()

	-- 	local element = createElement("Frame", {
	-- 		[Ref] = refA,
	-- 	})

	-- 	local node = reconciler.createVirtualNode(element, parent, key)

	-- 	RobloxRenderer.mountHostNode(reconciler, node)

	-- 	expect(#parent:GetChildren()).toEqual(1)

	-- 	local instance = parent:GetChildren()[1]

	-- 	expect(refA.current).toEqual(instance)
	-- 	expect(refB.current).never.toBeTruthy()

	-- 	local newElement = createElement("Frame", {
	-- 		[Ref] = refB,
	-- 	})

	-- 	RobloxRenderer.updateHostNode(reconciler, node, newElement)

	-- 	expect(refA.current).never.toBeTruthy()
	-- 	expect(refB.current).toEqual(instance)

	-- 	RobloxRenderer.unmountHostNode(reconciler, node)
	-- end)

	-- it("should call old function refs with nil and new function refs with a valid rbx", function()
	-- 	local parent = Instance.new("Folder")
	-- 	local key = "Some Key"

	-- 	local spyRefA = createSpy()
	-- 	local spyRefB = createSpy()

	-- 	local element = createElement("Frame", {
	-- 		[Ref] = spyRefA.value,
	-- 	})

	-- 	local node = reconciler.createVirtualNode(element, parent, key)

	-- 	RobloxRenderer.mountHostNode(reconciler, node)

	-- 	expect(#parent:GetChildren()).toEqual(1)

	-- 	local instance = parent:GetChildren()[1]

	-- 	expect(spyRefA.callCount).toEqual(1)
	-- 	spyRefA:assertCalledWith(instance)
	-- 	expect(spyRefB.callCount).toEqual(0)

	-- 	local newElement = createElement("Frame", {
	-- 		[Ref] = spyRefB.value,
	-- 	})

	-- 	RobloxRenderer.updateHostNode(reconciler, node, newElement)

	-- 	expect(spyRefA.callCount).toEqual(2)
	-- 	spyRefA:assertCalledWith(nil)
	-- 	expect(spyRefB.callCount).toEqual(1)
	-- 	spyRefB:assertCalledWith(instance)

	-- 	RobloxRenderer.unmountHostNode(reconciler, node)
	-- end)

	-- it("should not call function refs again if they didn't change", function()
	-- 	local parent = Instance.new("Folder")
	-- 	local key = "Some Key"

	-- 	local spyRef = createSpy()

	-- 	local element = createElement("Frame", {
	-- 		Size = UDim2.new(1, 0, 1, 0),
	-- 		[Ref] = spyRef.value,
	-- 	})

	-- 	local node = reconciler.createVirtualNode(element, parent, key)

	-- 	RobloxRenderer.mountHostNode(reconciler, node)

	-- 	expect(#parent:GetChildren()).toEqual(1)

	-- 	local instance = parent:GetChildren()[1]

	-- 	expect(spyRef.callCount).toEqual(1)
	-- 	spyRef:assertCalledWith(instance)

	-- 	local newElement = createElement("Frame", {
	-- 		Size = UDim2.new(0.5, 0, 0.5, 0),
	-- 		[Ref] = spyRef.value,
	-- 	})

	-- 	RobloxRenderer.updateHostNode(reconciler, node, newElement)

	-- 	-- Not called again
	-- 	expect(spyRef.callCount).toEqual(1)
	-- end)

	-- it("should throw if setting invalid instance properties", function()
	-- 	local configValues = {
	-- 		elementTracing = true,
	-- 	}

	-- 	GlobalConfig.scoped(configValues, function()
	-- 		local parent = Instance.new("Folder")
	-- 		local key = "Some Key"

	-- 		local firstElement = createElement("Frame")
	-- 		local secondElement = createElement("Frame", {
	-- 			Frob = 6,
	-- 		})

	-- 		local node = reconciler.createVirtualNode(firstElement, parent, key)
	-- 		RobloxRenderer.mountHostNode(reconciler, node)

	-- 		local success, message = pcall(RobloxRenderer.updateHostNode, reconciler, node, secondElement)
	-- 		assert(not success, "Expected call to fail")

	-- 		expect(string.find(message, "Frob")).toBeTruthy()
	-- 		expect(string.find(message, "Frame")).toBeTruthy()
	-- 		expect(string.find(message, "RobloxRenderer%.spec")).toBeTruthy()
	-- 	end)
	-- end)

	-- it("should delete instances when reconciling to nil children", function()
	-- 	local parent = Instance.new("Folder")
	-- 	local key = "Some Key"

	-- 	local element = createElement("Frame", {
	-- 		Size = UDim2.new(1, 0, 1, 0),
	-- 	}, {
	-- 		child = createElement("Frame"),
	-- 	})

	-- 	local node = reconciler.createVirtualNode(element, parent, key)

	-- 	RobloxRenderer.mountHostNode(reconciler, node)

	-- 	expect(#parent:GetChildren()).toEqual(1)

	-- 	local instance = parent:GetChildren()[1]
	-- 	expect(#instance:GetChildren()).toEqual(1)

	-- 	local newElement = createElement("Frame", {
	-- 		Size = UDim2.new(0.5, 0, 0.5, 0),
	-- 	})

	-- 	RobloxRenderer.updateHostNode(reconciler, node, newElement)
	-- 	expect(#instance:GetChildren()).toEqual(0)
	-- end)
end)

-- describe("removing instances", function()
-- 	it("should delete instances from the inside-out", function()
-- 		local parent = Instance.new("Folder")
-- 		local key = "Root"
-- 		local element = createElement("Folder", nil, {
-- 			Child = createElement("Folder", nil, {
-- 				Grandchild = createElement("Folder"),
-- 			}),
-- 		})

-- 		local node = reconciler.mountVirtualNode(element, parent, key)

-- 		expect(#parent:GetChildren()).toEqual(1)

-- 		local root = parent:GetChildren()[1]
-- 		expect(#root:GetChildren()).toEqual(1)

-- 		local child = root:GetChildren()[1]
-- 		expect(#child:GetChildren()).toEqual(1)

-- 		local grandchild = child:GetChildren()[1]

-- 		RobloxRenderer.unmountHostNode(reconciler, node)

-- 		expect(grandchild.Parent).toEqual(nil)
-- 		expect(child.Parent).toEqual(nil)
-- 		expect(root.Parent).toEqual(nil)
-- 	end)

-- 	it("should unsubscribe from any Bindings", function()
-- 		local parent = Instance.new("Folder")
-- 		local key = "Some Key"

-- 		local binding, update = Binding.create(10)
-- 		local element = createElement("IntValue", {
-- 			Value = binding,
-- 		})

-- 		local node = reconciler.createVirtualNode(element, parent, key)

-- 		RobloxRenderer.mountHostNode(reconciler, node)

-- 		local instance = parent:GetChildren()[1]

-- 		expect(instance.Value).toEqual(10)

-- 		RobloxRenderer.unmountHostNode(reconciler, node)
-- 		update(56)

-- 		expect(instance.Value).toEqual(10)
-- 	end)

-- 	it("should clear Binding refs", function()
-- 		local parent = Instance.new("Folder")
-- 		local key = "Some Key"

-- 		local ref = createRef()
-- 		local element = createElement("Frame", {
-- 			[Ref] = ref,
-- 		})

-- 		local node = reconciler.createVirtualNode(element, parent, key)

-- 		RobloxRenderer.mountHostNode(reconciler, node)

-- 		expect(ref.current).toBeTruthy()

-- 		RobloxRenderer.unmountHostNode(reconciler, node)

-- 		expect(ref.current).never.toBeTruthy()
-- 	end)

-- 	it("should call function refs with nil", function()
-- 		local parent = Instance.new("Folder")
-- 		local key = "Some Key"

-- 		local spyRef = createSpy()
-- 		local element = createElement("Frame", {
-- 			[Ref] = spyRef.value,
-- 		})

-- 		local node = reconciler.createVirtualNode(element, parent, key)

-- 		RobloxRenderer.mountHostNode(reconciler, node)

-- 		expect(spyRef.callCount).toEqual(1)

-- 		RobloxRenderer.unmountHostNode(reconciler, node)

-- 		expect(spyRef.callCount).toEqual(2)
-- 		spyRef:assertCalledWith(nil)
-- 	end)
-- end)

describe("Portals", function()
	it("should create and destroy instances as children of `target`", function()
		local target = Instance.new("Folder")

		local function FunctionComponent(props)
			return React.createElement("IntValue", {
				Name = "intValueOne",
				Value = props.value,
			})
		end

		local element = ReactRoblox.createPortal({
			React.createElement("Folder", { key = "1", Name = "folderOne" }),
			React.createElement("Folder", { key = "2", Name = "folderTwo" }),
			React.createElement(FunctionComponent, {
				key = "3",
				value = 42,
			}),
		}, target)

		reactRobloxRoot:render(element)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#target:GetChildren()).toBe(3)
		jestExpect(target:FindFirstChild("folderOne")).toBeDefined()
		jestExpect(target:FindFirstChild("folderTwo")).toBeDefined()
		jestExpect(target:FindFirstChild("intValueOne")).toBeDefined()
		jestExpect(target:FindFirstChild("intValueOne").Value).toBe(42)

		reactRobloxRoot:unmount()
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#target:GetChildren()).toBe(0)
	end)

	it("should pass prop updates through to children", function()
		local target = Instance.new("Folder")

		local firstElement = ReactRoblox.createPortal({
			ChildValue = React.createElement("IntValue", { Value = 1 }),
		}, target)

		local secondElement = ReactRoblox.createPortal({
			ChildValue = React.createElement("IntValue", { Value = 2 }),
		}, target)

		reactRobloxRoot:render(firstElement)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#target:GetChildren()).toBe(1)
		jestExpect(target:GetChildren()[1].Value).toBe(1)

		reactRobloxRoot:render(secondElement)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#target:GetChildren()).toBe(1)
		jestExpect(target:GetChildren()[1].Value).toBe(2)

		reactRobloxRoot:unmount()
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#target:GetChildren()).toBe(0)
	end)

	-- ROBLOX TODO: Duplicated in ReactRobloxFiber. Should we delete here?
	it("should throw if `target` is nil", function()
		-- TODO: Relax this restriction?
		jestExpect(function()
			ReactRoblox.createPortal(React.createElement("IntValue", { Value = 1 }))
		end).toThrow()
	end)

	-- ROBLOX TODO: Duplicated in ReactRobloxFiber. Should we delete here?
	-- it("should throw if `target` is not a Roblox instance", function()
	-- 	local element = createElement(Portal, {
	-- 		target = {},
	-- 	})
	-- 	local hostParent = nil
	-- 	local hostKey = "Unleash the keys!"

	-- 	expect(function()
	-- 		reconciler.mountVirtualNode(element, hostParent, hostKey)
	-- 	end).to.throw()
	-- end)

	it("should recreate instances if `target` changes in an update", function()
		local firstTarget = Instance.new("Folder")
		local secondTarget = Instance.new("Folder")

		local firstElement = ReactRoblox.createPortal(
			React.createElement("IntValue", { Value = 1 }),
			firstTarget
		)

		local secondElement = ReactRoblox.createPortal(
			React.createElement("IntValue", { Value = 2 }),
			secondTarget
		)

		reactRobloxRoot:render(firstElement)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#firstTarget:GetChildren()).toBe(1)
		jestExpect(#secondTarget:GetChildren()).toBe(0)
		jestExpect(firstTarget:GetChildren()[1].Value).toBe(1)

		reactRobloxRoot:render(secondElement)
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#firstTarget:GetChildren()).toBe(0)
		jestExpect(#secondTarget:GetChildren()).toBe(1)
		jestExpect(secondTarget:GetChildren()[1].Value).toBe(2)

		reactRobloxRoot:unmount()
		Scheduler.unstable_flushAllWithoutAsserting()

		jestExpect(#firstTarget:GetChildren()).toBe(0)
		jestExpect(#secondTarget:GetChildren()).toBe(0)
	end)
end)

-- describe("Fragments", function()
-- 	it("should parent the fragment's elements into the fragment's parent", function()
-- 		local hostParent = Instance.new("Folder")

-- 		local fragment = createFragment({
-- 			key = createElement("IntValue", {
-- 				Value = 1,
-- 			}),
-- 			key2 = createElement("IntValue", {
-- 				Value = 2,
-- 			}),
-- 		})

-- 		local node = reconciler.mountVirtualNode(fragment, hostParent, "test")

-- 		expect(hostParent:FindFirstChild("key")).toBeTruthy()
-- 		expect(hostParent.key.ClassName).toEqual("IntValue")
-- 		expect(hostParent.key.Value).toEqual(1)

-- 		expect(hostParent:FindFirstChild("key2")).toBeTruthy()
-- 		expect(hostParent.key2.ClassName).toEqual("IntValue")
-- 		expect(hostParent.key2.Value).toEqual(2)

-- 		reconciler.unmountVirtualNode(node)

-- 		expect(#hostParent:GetChildren()).toEqual(0)
-- 	end)

-- 	it("should allow sibling fragment to have common keys", function()
-- 		local hostParent = Instance.new("Folder")
-- 		local hostKey = "Test"

-- 		local function parent(props)
-- 			return createElement("IntValue", {}, {
-- 				fragmentA = createFragment({
-- 					key = createElement("StringValue", {
-- 						Value = "A",
-- 					}),
-- 					key2 = createElement("StringValue", {
-- 						Value = "B",
-- 					}),
-- 				}),
-- 				fragmentB = createFragment({
-- 					key = createElement("StringValue", {
-- 						Value = "C",
-- 					}),
-- 					key2 = createElement("StringValue", {
-- 						Value = "D",
-- 					}),
-- 				}),
-- 			})
-- 		end

-- 		local node = reconciler.mountVirtualNode(createElement(parent), hostParent, hostKey)
-- 		local parentChildren = hostParent[hostKey]:GetChildren()

-- 		expect(#parentChildren).toEqual(4)

-- 		local childValues = {}

-- 		for _, child in parentChildren do
-- 			expect(child.ClassName).toEqual("StringValue")
-- 			childValues[child.Value] = 1 + (childValues[child.Value] or 0)
-- 		end

-- 		-- check if the StringValues have not collided
-- 		expect(childValues.A).toEqual(1)
-- 		expect(childValues.B).toEqual(1)
-- 		expect(childValues.C).toEqual(1)
-- 		expect(childValues.D).toEqual(1)

-- 		reconciler.unmountVirtualNode(node)

-- 		expect(#hostParent:GetChildren()).toEqual(0)
-- 	end)

-- 	it("should render nested fragments", function()
-- 		local hostParent = Instance.new("Folder")

-- 		local fragment = createFragment({
-- 			key = createFragment({
-- 				TheValue = createElement("IntValue", {
-- 					Value = 1,
-- 				}),
-- 				TheOtherValue = createElement("IntValue", {
-- 					Value = 2,
-- 				})
-- 			})
-- 		})

-- 		local node = reconciler.mountVirtualNode(fragment, hostParent, "Test")

-- 		expect(hostParent:FindFirstChild("TheValue")).toBeTruthy()
-- 		expect(hostParent.TheValue.ClassName).toEqual("IntValue")
-- 		expect(hostParent.TheValue.Value).toEqual(1)

-- 		expect(hostParent:FindFirstChild("TheOtherValue")).toBeTruthy()
-- 		expect(hostParent.TheOtherValue.ClassName).toEqual("IntValue")
-- 		expect(hostParent.TheOtherValue.Value).toEqual(2)

-- 		reconciler.unmountVirtualNode(node)

-- 		expect(#hostParent:GetChildren()).toEqual(0)
-- 	end)

-- 	it("should not add any instances if the fragment is empty", function()
-- 		local hostParent = Instance.new("Folder")

-- 		local node = reconciler.mountVirtualNode(createFragment({}), hostParent, "test")

-- 		expect(#hostParent:GetChildren()).toEqual(0)

-- 		reconciler.unmountVirtualNode(node)

-- 		expect(#hostParent:GetChildren()).toEqual(0)
-- 	end)
-- end)

describe("Context", function()
	-- it("should pass context values through Roblox host nodes", function()
	-- 	local Consumer = Component:extend("Consumer")

	-- 	local capturedContext
	-- 	function Consumer:init()
	-- 		capturedContext = {
	-- 			hello = self:__getContext("hello")
	-- 		}
	-- 	end

	-- 	function Consumer:render()
	-- 	end

	-- 	local element = createElement("Folder", nil, {
	-- 		Consumer = createElement(Consumer)
	-- 	})
	-- 	local hostParent = nil
	-- 	local hostKey = "Context Test"
	-- 	local context = {
	-- 		hello = "world",
	-- 	}
	-- 	local node = reconciler.mountVirtualNode(element, hostParent, hostKey, context)

	-- 	expect(capturedContext).never.toEqual(context)
	-- 	assertDeepEqual(capturedContext, context)

	-- 	reconciler.unmountVirtualNode(node)
	-- end)

	it("should pass context values through portal nodes", function()
		local target = Instance.new("Folder")
		local Context = React.createContext(1)

		local function App(props)
			return React.createElement(Context.Provider, {
				value = props.value,
			}, {
				Portal = ReactRoblox.createPortal({
					Consumer = React.createElement(Context.Consumer, nil, function(value)
						return React.createElement(
							"TextLabel",
							{ Text = "Result: " .. tostring(value) }
						)
					end),
				}, target),
			})
		end

		reactRobloxRoot:render(React.createElement(App, { value = 2 }))
		Scheduler.unstable_flushAllWithoutAsserting()
		jestExpect(#target:GetChildren()).toBe(1)
		jestExpect(target:GetChildren()[1].Text).toBe("Result: 2")

		reactRobloxRoot:render(React.createElement(App, { value = 3 }))
		Scheduler.unstable_flushAllWithoutAsserting()
		jestExpect(#target:GetChildren()).toBe(1)
		jestExpect(target:GetChildren()[1].Text).toBe("Result: 3")
	end)
end)

-- describe("Legacy context", function()
-- 	it("should pass context values through Roblox host nodes", function()
-- 		local Consumer = Component:extend("Consumer")

-- 		local capturedContext
-- 		function Consumer:init()
-- 			capturedContext = self._context
-- 		end

-- 		function Consumer:render()
-- 		end

-- 		local element = createElement("Folder", nil, {
-- 			Consumer = createElement(Consumer)
-- 		})
-- 		local hostParent = nil
-- 		local hostKey = "Context Test"
-- 		local context = {
-- 			hello = "world",
-- 		}
-- 		local node = reconciler.mountVirtualNode(element, hostParent, hostKey, nil, context)

-- 		expect(capturedContext).never.toEqual(context)
-- 		assertDeepEqual(capturedContext, context)

-- 		reconciler.unmountVirtualNode(node)
-- 	end)

-- 	it("should pass context values through portal nodes", function()
-- 		local target = Instance.new("Folder")

-- 		local Provider = Component:extend("Provider")

-- 		function Provider:init()
-- 			self._context.foo = "bar"
-- 		end

-- 		function Provider:render()
-- 			return createElement("Folder", nil, self.props[Children])
-- 		end

-- 		local Consumer = Component:extend("Consumer")

-- 		local capturedContext
-- 		function Consumer:init()
-- 			capturedContext = self._context
-- 		end

-- 		function Consumer:render()
-- 			return nil
-- 		end

-- 		local element = createElement(Provider, nil, {
-- 			Portal = createElement(Portal, {
-- 				target = target,
-- 			}, {
-- 				Consumer = createElement(Consumer),
-- 			})
-- 		})
-- 		local hostParent = nil
-- 		local hostKey = "Some Key"
-- 		reconciler.mountVirtualNode(element, hostParent, hostKey)

-- 		assertDeepEqual(capturedContext, {
-- 			foo = "bar"
-- 		})
-- 	end)
-- end)
