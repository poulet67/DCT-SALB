-- SPDX-License-Identifier: LGPL-3.0

local utils = require("libs.utils")

local function class(base, ...)
	local newcls = utils.shallowclone(base or {})
	for i = 1, select('#', ...) do
		newcls = utils.mergetables(newcls,
			utils.shallowclone(select(i, ...) or {}))
	end
	local cls_mt = {
		__call = function(cls, ...)
			local c = utils.shallowclone(cls)
			if type(c.__init) == "function" then
				c.__init(c, ...)
			end
			return c
		end,
	}

	function newcls:super()
		return base
	end

	function newcls:isa(other)
		local b_isa = false
		local cur_class = newcls

		while nil ~= cur_class and false == b_isa do
			if cur_class == other then
				b_isa = true
			else
				cur_class = cur_class:super()
			end
		end
		return b_isa
	end

	setmetatable(newcls, cls_mt)
	return newcls
end

return class
