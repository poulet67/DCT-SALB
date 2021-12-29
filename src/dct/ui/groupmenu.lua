--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Handles applying a F10 menu UI to player groups
--]]

--[[
-- Assumptions:
-- It is assumed each player group consists of a single player
-- aircraft due to issues with the game.
--
-- Notes:
--   Once a menu is added to a group it does not need to be added
--   again, which is why we need to track which group ids have had
--   a menu added. The reason why this cannot be done up front on
--   mission start is because the the group does not exist until at
--   least one player occupies a slot. We must add the menu upon
--   object creation.
--]]

local enum    = require("dct.enum")
local Logger  = dct.Logger.getByName("UI")
local loadout = require("dct.systems.loadouts")
local Theater = require("dct.Theater")
local addmenu = missionCommands.addSubMenuForGroup
local addcmd  = missionCommands.addCommandForGroup

local menus = {}
function menus.createMenu(asset)
	local gid  = asset.groupId
	local name = asset.name

	if asset.uimenus ~= nil then
		Logger:debug("createMenu - group("..name..") already had menu added")
		return
	end

	Logger:debug("createMenu - adding menu for group: "..tostring(name))

	asset.uimenus = {}

	local padmenu = addmenu(gid, "Scratch Pad", nil)
	for k, v in pairs({
		["DISPLAY"] = enum.uiRequestType.SCRATCHPADGET,
		["SET"] = enum.uiRequestType.SCRATCHPADSET}) do
		addcmd(gid, k, padmenu, Theater.playerRequest,
			{
				["name"]   = name,
				["type"]   = v,
			})
	end



	local thtrmenu = addmenu(gid, "Theater", nil)
	
	addcmd(gid, "Theater Update", thtrmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.THEATERSTATUS,
		})	
	addcmd(gid, "Mission Type Info", thtrmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONTYPEINFO,
		})
		
	addcmd(gid, "Mission Board", thtrmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONBOARD,
		})
		
	addcmd(gid, "Join Mission", thtrmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONJOIN,
		})

	addcmd(gid, "Mission Briefing", thtrmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONBRIEF,
		})
	addcmd(gid, "Mission Status", thtrmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONSTATUS,
		})
	addcmd(gid, "Abort Mission", thtrmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONABORT,
			["value"]  = enum.missionAbortType.ABORT,
		})

	loadout.addmenu(asset, nil, Theater.playerRequest)

	
end

return menus
