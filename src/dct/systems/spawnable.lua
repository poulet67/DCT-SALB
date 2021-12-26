--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Assets with spawnable property are spawnable from the F10 menu
-- 
--]]

local enum     = require("dct.enum")
local dctutils = require("dct.utils")
local settings = _G.dct.settings
local Theater = require("dct.Theater")
local class    = require("libs.class")
local Marshallable = require("dct.libs.Marshallable")

local addcmd  = missionCommands.addCommandForGroup

local spawnable = class(Marshallable)
function spawnable:__init() 

	self.CP_cost = 0
	self.cooldown = 0
	self.delay = 0	
	
end

function spawnable:addmenu(asset, menu, handler) -- asset = group to add menu to
	local gid  = asset.groupId
	local name = asset.name
	
	for k, v in pairs(asset.ato) do
		addcmd(gid, k, rqstmenu, Theater.playerRequest,
			{
				["name"]   = name,
				["type"]   = enum.uiRequestType.MISSIONREQUEST,
				["value"]  = v,
			})
	end
	
	
	
end

function spawnable:getUnitTable() -- asset = group to add menu to
	
	return nil	
	
end

return spawnable
