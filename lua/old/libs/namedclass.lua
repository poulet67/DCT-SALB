-- SPDX-License-Identifier: LGPL-3.0

local class = require("libs.class")

local function namedclass(name, base, ...)
	local newcls = class(base, ...)
	newcls.__clsname = name or "Unknown Class"
	return newcls
end

return namedclass
