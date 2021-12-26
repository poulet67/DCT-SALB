--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Library for checking input values
--]]

local utils = require("libs.utils")

local check = {}
function check.type(val, typestr, lvl)
	lvl = lvl or 0
	if type(val) ~= typestr then
		error("value error: must be of type "..typestr, lvl+1)
	end
	return val
end

function check.bool(val, lvl)
	lvl = lvl or 0
	return check.type(val, "boolean", lvl+1)
end

function check.number(num, lvl)
	lvl = lvl or 0
	return check.type(num, "number", lvl+1)
end

function check.string(str, lvl)
	lvl = lvl or 0
	return check.type(str, "string", lvl+1)
end

function check.table(t, lvl)
	lvl = lvl or 0
	return check.type(t, "table", lvl+1)
end

function check.func(f, lvl)
	lvl = lvl or 0
	return check.type(f, "function", lvl+1)
end

function check.range(val, min, max, lvl)
	lvl = lvl or 0
	check.number(val, lvl+1)
	if not (val >= min and val <= max) then
		error(string.format("value error: value not in range [%f,%f]",
			min, max), lvl+1)
	end
	return val
end

function check.tblkey(val, tbl, tblstr, lvl)
	lvl = lvl or 0
	if utils.getkey(tbl, val) == nil then
		error("value error: must be a value from "..tblstr, lvl+1)
	end
	return val
end

return check
