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
	
	---------------------------------------------------------------MISSIONS
	
	local msnmenu = addmenu(gid, "Missions", nil)
	
	addcmd(gid, "Theater Update", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.THEATERSTATUS,
		})	
	addcmd(gid, "Mission Type Info", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONTYPEINFO,
		})
		-- TO DO: Add comms plan
	addcmd(gid, "Mission Board", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONBOARD,
		})
		
	addcmd(gid, "Join Mission", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONJOIN,
		})

	addcmd(gid, "Mission Briefing", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONBRIEF,
		})
	addcmd(gid, "Mission Status", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONSTATUS,
		})
	addcmd(gid, "Abort Mission", msnmenu, Theater.playerRequest,
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.MISSIONABORT,
			["value"]  = enum.missionAbortType.ABORT,
		})
	
	
	---------------------------------------------------------------VOTES
	
	local votemenu = addmenu(gid, "Vote", nil)
	
	addcmd(gid, "Current Vote", votemenu, Theater.playerRequest,     
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.CURRENTVOTE
		})

	local callvotemenu = addmenu(gid, "Call Vote", votemenu)
	
		for k, v in pairs(enum.voteType["PUBLIC"]) do		
			addcmd(gid, k, callvotemenu, Theater.playerRequest,
			{
				["name"]   = name,
				["type"]   = enum.uiRequestType.CALLVOTE,
				["voteType"]   = v,
			})
		
		
		end
		
	addcmd(gid, "Vote Yes", votemenu, Theater.playerRequest,     
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.VOTE,
			["value"]  = true
		})
		
	addcmd(gid, "Vote No", votemenu, Theater.playerRequest,     
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.VOTE,
			["value"]  = false
		})
	
	
	--to command certain areas of code be executed in game, comment out for release/production
	
	addcmd(gid, "Debugging", nil, Theater.playerRequest,     
		{
			["name"]   = name,
			["type"]   = enum.uiRequestType.DEBUGGING,
			["value"]  = false
		})
	
	
	
--	for k, v in pairs({
--		["DISPLAY"] = enum.uiRequestType.SCRATCHPADGET,
--		["SET"] = enum.uiRequestType.SCRATCHPADSET}) do
--		addcmd(gid, k, padmenu, Theater.playerRequest,
--			{
--				["name"]   = name,
--				["type"]   = v,
--			})
--	end	


--	local padmenu = addmenu(gid, "Scratch Pad", nil)
--	for k, v in pairs({
--		["DISPLAY"] = enum.uiRequestType.SCRATCHPADGET,
--		["SET"] = enum.uiRequestType.SCRATCHPADSET}) do
--		addcmd(gid, k, padmenu, Theater.playerRequest,
--			{
--				["name"]   = name,
--				["type"]   = v,
--			})
--	end
	
	loadout.addmenu(asset, nil, Theater.playerRequest)
	
-- Copied from OD design doc:
	
--------------------------------------------------
-- F10 Menus:
--------------------------------------------------
--
--

-- If I have enough menus:
--
-- Theater - Theater Update (in it's own)
-- Communications -- Comms Plan 
--
--
--
-- Missions   -- Theater Update, Show Mission Board, Join, Abort, Briefing, Status, Type Info, Comms Plan
--																	   -- 
--
-- Base Command -- FOB ---> Create, Select ---> Delete, View Invenvory, Recall, Fire mission, Deploy, Dispatch, Next, Previous ----  Units, SAM, 
--				   Airbase	  			      		 
--	   (the same as FOB, except for Delete)
--				  Logistics -- Air, Ground --> Dispatch Convoy, View , Info, ? --- From --- To --- Type --- Size --- Cargo (if appplicable) (yeah this could be complicated)
--															 		   --  Essentials --> (Manpower, Amenities, Ammo) <-- Add x Kg, Add y Kg, Add...		
--				
-- Region Info -- Info, Next, Prev, Frontlines ---> Info, Next, Prev, Command Options ---> Change Posture, Tactical retreat, Create battle plans, Coordinate offensive
--
-- 
-- Load/Unload - (have to get this stuff on the helos somehow)
--			
-- 
-- Commander --> Store ---> Print Price list --> Airframes, Aircraft Weaponry, Essentials, Ground Units, Logi Vehicles, etc,
--				 Intelligence		   	Buy --> Aircraft Weaponry, Essentials, Ground Units, Logi Vehicles --> Buy 1, 2, x
-- 				 Request Command
--				 Vote kick Commander
--
-- Votes    ---> Current Vote --> (info)
--               Vote yes 
--               Vote no 
--
--
--
--
--
--

	
end

return menus
