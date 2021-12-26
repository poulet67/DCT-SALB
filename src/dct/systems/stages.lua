--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- A Stage class to handle stage transitions in a mission
--]]

require("math")
local class    = require("libs.class")
local utils    = require("libs.utils")
local Marshallable = require("dct.libs.Marshallable")
local Command  = require("dct.Command")

local Stages = class(Marshallable)
function Stages:__init(theater)
	self._theater = theater
	Marshallable.__init(self)
	self.current = theater.stage
	
end

function Stages:nextStage()

	self.current = self.current
	
	
--	theater:queueCommand(10, Command("iads.populateLists", --que RegionManager:generateStagedTemplates somehow
--		self.populateLists, self))	 

end



return Stages
