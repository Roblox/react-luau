local Packages = script.Parent.Parent.Parent
local JestGlobals = require(Packages.Dev.JestGlobals)
local jestExpect = JestGlobals.expect
local describe = JestGlobals.describe
local it = JestGlobals.it
local Heap = require(script.Parent.Parent.SchedulerMinHeap)

local function verifyOrder(heap)
	for pos = 2, #heap do
		local parent = math.floor(pos / 2)
		jestExpect(heap[pos].sortIndex).toBeGreaterThan(heap[parent].sortIndex)
	end
end

local increment = 0
local function getIncrement()
	increment = increment + 1
	return increment
end

local function makeNode(sortIndex: number, id: number?)
	return {
		sortIndex = sortIndex,
		id = id or getIncrement(),
	}
end

describe("push", function()
	it("should add a value to the minHeap", function()
		local h = {}
		Heap.push(h, makeNode(42))
		verifyOrder(h)
	end)

	it("properly sort a minHeap each time", function()
		local h = {}
		Heap.push(h, makeNode(2))
		verifyOrder(h)
		Heap.push(h, makeNode(1))
		verifyOrder(h)
		Heap.push(h, makeNode(3))
		verifyOrder(h)
	end)
end)

describe("peek", function()
	it("should return nil from an empty minHeap", function()
		local h = {}
		jestExpect(Heap.peek(h)).never.toBeDefined()
		verifyOrder(h)
	end)

	it("return the only value on a minHeap of one element", function()
		local h = {}
		Heap.push(h, makeNode(42))
		verifyOrder(h)

		local node = Heap.peek(h)
		jestExpect(node.sortIndex).toBe(42)
	end)

	it("return the smaller value on a minHeap of two elements", function()
		local h = {}
		Heap.push(h, makeNode(42))
		verifyOrder(h)
		Heap.push(h, makeNode(1))
		verifyOrder(h)

		local node = Heap.peek(h)
		jestExpect(node.sortIndex).toBe(1)
	end)

	it("return the smallest value on a minHeap of 10 elements", function()
		local h = {}
		Heap.push(h, makeNode(10))
		Heap.push(h, makeNode(7))
		Heap.push(h, makeNode(1))
		Heap.push(h, makeNode(5))
		Heap.push(h, makeNode(6))
		Heap.push(h, makeNode(9))
		Heap.push(h, makeNode(8))
		Heap.push(h, makeNode(4))
		Heap.push(h, makeNode(2))
		Heap.push(h, makeNode(3))
		verifyOrder(h)

		local node = Heap.peek(h)
		jestExpect(node.sortIndex).toBe(1)
	end)
end)

describe("pop", function()
	it("remove the smallest element on a minHeap of 5 elements", function()
		local h = {}
		Heap.push(h, makeNode(1))
		Heap.push(h, makeNode(2))
		Heap.push(h, makeNode(3))
		Heap.push(h, makeNode(4))
		Heap.push(h, makeNode(5))

		local node = Heap.pop(h)
		verifyOrder(h)
		jestExpect(node.sortIndex).toBe(1)
		node = Heap.peek(h)
		jestExpect(node.sortIndex).toBe(2)
	end)
end)
