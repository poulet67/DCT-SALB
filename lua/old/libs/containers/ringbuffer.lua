-- SPDX-License-Identifier: LGPL-3.0
--[[
-- Implements a standard fixed size ringbuffer
-- API:
--   push(item)
--   pop()
--   empty()
--   full()
--   size()
--   peek()
--]]

local RingBuffer = {
	__index = {
		push = function(self, v)
			if self:size() == self.capacity then
				self.tail = self.tail + 1
			end
			self[self.head % self.capacity] = v
			self.head = self.head + 1
		end,

		pop = function(self)
			if self:empty() then
				return nil
			end
			local v = self[self.tail % self.capacity]
			self.tail = self.tail + 1
			return v
		end,

		empty = function(self)
			return self.head == self.tail
		end,

		full = function(self)
			return self:size() == self.capacity
		end,

		peek = function(self)
			if self:empty() then
				return nil
			end
			return self[self.tail % self.capacity]
		end,

		size = function(self)
			return self.head - self.tail
		end,
	},

	__call = function(cls, max)
		local m = max or 10
		return setmetatable({capacity = m, head = 1, tail = 1}, cls)
	end
}

setmetatable(RingBuffer, RingBuffer)
return RingBuffer
