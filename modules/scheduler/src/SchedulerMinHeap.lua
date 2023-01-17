-- ROBLOX upstream: https://github.com/facebook/react/blob/e706721490e50d0bd6af2cd933dbf857fd8b61ed/packages/scheduler/src/SchedulerMinHeap.js
--!strict
--[[*
* Copyright (c) Facebook, Inc. and its affiliates.
*
* This source code is licensed under the MIT license found in the
* LICENSE file in the root directory of this source tree.
*
* @flow
]]

type Heap = { [number]: Node? }
type Node = {
	id: number,
	sortIndex: number,
}

local exports = {}
-- ROBLOX deviation: This file contains several workarounds for Luau analysis issues by using the `::` operator
local compare, siftUp, siftDown

exports.push = function(heap: Heap, node: Node): ()
	local index = #heap + 1
	heap[index] = node

	siftUp(heap, node, index)
end

exports.peek = function(heap: Heap): Node?
	return heap[1]
end

exports.pop = function(heap: Heap): Node?
	local first = heap[1]
	if first ~= nil then
		local last = heap[#heap]
		heap[#heap] = nil

		if last :: Node ~= first :: Node then
			heap[1] = last
			siftDown(heap, last :: Node, 1)
		end
		return first
	else
		return nil
	end
end

siftUp = function(heap: Heap, node: Node, index: number): ()
	while true do
		local parentIndex = math.floor(index / 2)
		local parent = heap[parentIndex]
		if parent ~= nil and compare(parent :: Node, node :: Node) > 0 then
			-- The parent is larger. Swap positions.
			heap[parentIndex] = node
			heap[index] = parent
			index = parentIndex
		else
			-- The parent is smaller. Exit.
			return
		end
	end
end

siftDown = function(heap: Heap, node: Node, index: number): ()
	local length = #heap
	while index < length do
		local leftIndex = index * 2
		local left = heap[leftIndex]
		local rightIndex = leftIndex + 1
		local right = heap[rightIndex]

		-- If the left or right node is smaller, swap with the smaller of those.
		if left ~= nil and compare(left :: Node, node) < 0 then
			if right ~= nil and compare(right :: Node, left :: Node) < 0 then
				heap[index] = right
				heap[rightIndex] = node
				index = rightIndex
			else
				heap[index] = left
				heap[leftIndex] = node
				index = leftIndex
			end
		elseif right ~= nil and compare(right :: Node, node :: Node) < 0 then
			heap[index] = right
			heap[rightIndex] = node
			index = rightIndex
		else
			-- Neither child is smaller. Exit.
			return
		end
	end
end

compare = function(a: Node, b: Node): number
	-- Compare sort index first, then task id.
	local diff = a.sortIndex - b.sortIndex

	if diff == 0 then
		return a.id - b.id
	end

	return diff
end

return exports
