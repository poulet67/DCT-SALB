-- SPDX-License-Identifier: LGPL-3.0
--[[
-- A min-heap priority queue implementation
-- API:
--   push(prio, val)
--   val, prio = pop()
--   val, prio = peek()
--   size()
--   empty()
--   remove(itemindex)
--   increase(itemindex, deltaprio)
--   decrease(itemindex, deltaprio)
--]]

local function leftchild(i)
	return 2*i
end

--[[
local function rightchild(i)
	return 2*i+1
end
--]]

local function parent(i)
	return math.floor(i/2)
end

local PriorityQueue = {
	__index = {
		_swap = function(self, i, j)
			local a = self[i]
			self[i] = self[j]
			self[j] = a
		end,

		_siftup   = function(self, i)
			while i > 1 and self[parent(i)].prio > self[i].prio do
				self:_swap(i, parent(i))
				i = parent(i)
			end
		end,

		_siftdown = function(self, i)
			while leftchild(i) <= self:size() do
				local m = leftchild(i)

				if m ~= self:size() and
					self[m+1].prio < self[m].prio then
					m = m + 1
				end
				if self[m].prio < self[i].prio then
					self:_swap(i, m)
				else
					break
				end
				i = m
			end
		end,

		size = function(self)
			return #self
		end,

		empty = function(self)
			if next(self) == nil then
				return true
			end
			return false
		end,

		push = function(self, p, v)
			local d = {prio = p, data = v}
			local i = self:size()+1

			self[i] = d
			self:_siftup(i)
		end,

		pop = function(self)
			if self:empty() then
				return nil
			end
			local sz = self:size()
			local data = self[1].data
			local prio = self[1].prio

			self[1] = self[sz]
			self[sz] = nil
			self:_siftdown(1)
			return data, prio
		end,


		peek = function(self)
			if self:empty() then
				return nil
			end

			return self[1].data, self[1].prio
		end,

		remove = function(_--[[self, i]])
			assert(false, "Not supported yet")
		end,

		increase = function(_ --[[self, i, deltap]])
			assert(false, "Not supported yet")
		end,

		decrease = function(_ --[[self, i, deltap]])
			assert(false, "Not supported yet")
		end,
	},

	__call = function(cls)
		return setmetatable({}, cls)
	end
}

setmetatable(PriorityQueue, PriorityQueue)
return PriorityQueue
