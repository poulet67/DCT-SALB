--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Represents a Mission within the game and this associates an
-- Objective to as assigned group of units responsible for
-- completing the Objective.
--]]

require("os")
require("math")
local utils    = require("libs.utils")
local class    = require("libs.namedclass")
local enum     = require("dct.enum")
local dctutils = require("dct.utils")
local uicmds   = require("dct.ui.cmds")
local State    = require("dct.libs.State")
local Timer    = require("dct.libs.Timer")
local Logger   = require("dct.libs.Logger").getByName("Mission")
local human    = require("dct.ui.human")
local Command    = require("dct.Command")

local function createPlanQ(plan)
	local Q = require("libs.containers.queue")()
	for _, v in ipairs(plan) do
		Q:pushtail(v)
	end
	return Q
end


local Mission = class("Mission")
function Mission:__init(cmdr, missiontype, tgt, plan)
	self.cmdr      = cmdr
	self.type      = missiontype
	self.target    = tgt.name
	self.cp_reward = tgt.cp_reward
	self.plan      = createPlanQ(plan) -- if no plan is passed this will just be an empty queue
	self.iffcodes  = cmdr:genMissionCodes(missiontype)
	self.packagecomms  = cmdr:assignPackageComms()
	self.id        = self.iffcodes.id
	self.next_stage = tgt.next_stage --A successful completion will trigger a stage transition in Theater
	self.priority = enum.missionTypePriority[utils.getkey(enum.missionType, missiontype)] -- need to assign defaults...
	self.starttime = timer.getAbsTime()
	self.rolex = 0 -- commander can optionally increase or decrease push time 
	-- all optional mission parameters:
		
	if(tgt.marshal_point) then -- marshal point
		self.marshal_point = tgt.marshal_point 
		Logger:debug("-- MARSHAL POINT FOUND --")
	end
	
	if(tgt.period) then -- periodic mission
		Logger:debug("-- DING --")
		self.period = tgt.period
		self.pushtime = os.date("%Rz", dctutils.zulutime(self.starttime + self.period))
		self.dormanttime = 900 -- how long the mission will stay alive after period has been reached (15 minutes seems reasonable, could make this a setting) (TODO)
		Logger:debug("-- queueing --")
		dct.Theater.singleton():queueCommand(self.period, Command("COMMANDER--- RESETTING PERIODIC MISSION : "..self.id, cmdr.newPeriodic, cmdr, self))
		dct.Theater.singleton():queueCommand(self.period+self.dormanttime, Command("COMMANDER--- CLOSING PERIODIC MISSION: "..self.id, cmdr.removeMission, cmdr, self.id))
	end


	self.assigned  = {}
	self:_setComplete(false)

			
	self.orders  = "No current orders" -- Commander can set this field to communicate priorities (for non-standard missions)
	tgt:setTargeted(self.cmdr.owner, true)
	
	self.briefing = tgt.briefing
	
	self.tgtinfo = {}
	self.tgtinfo.location = tgt:getLocation()
	self.tgtinfo.callsign = tgt.codename
	self.tgtinfo.status   = tgt:getStatus()
	self.tgtinfo.intellvl = tgt:getIntel(self.cmdr.owner)
	self:init_readable() -- human readable table to be printed on F10 map (minus location info, which is calculated when briefing is called)
	
end


--[[
function Mission:getStateName()
	return self.state.__clsname
end
--]]

function Mission:getID()
	return self.id
end

function Mission:isMember(name)
	local i = utils.getkey(self.assigned, name)
	if i then
		return true, i
	end
	return false
end

function Mission:getAssigned()
	return utils.shallowclone(self.assigned)
end

function Mission:addAssigned(asset)
	if self:isMember(asset.name) then
		return
	end
	table.insert(self.assigned, asset.name)
	asset.missionid = self:getID()
end

function Mission:removeAssigned(asset)
	local member, i = self:isMember(asset.name)
	if not member then
		return
	end
	table.remove(self.assigned, i)
	asset.missionid = enum.misisonInvalidID
end

--[[
-- Abort - aborts a mission for etiher a single group or
--   completely terminating the mission for everyone assigned.
--
-- Things that need to be managed;
--  * remove requesting group from the assigned list
--  * if assigned list is empty or we need to force terminate the
--    mission
--    - remove the mission from the owning commander's mission list(s)
--    - release the targeted asset by resetting the asset's targeted
--      bit
--]]
function Mission:abort(asset)

	Logger:debug(self.__clsname..":abort()")
	
	self:removeAssigned(asset)

	return self.id
end

function Mission:queueabort(reason)
	Logger:debug(self.__clsname..":queueabort()")
	self:_setComplete(true)
	local theater = dct.Theater.singleton()
	for _, name in ipairs(self.assigned) do
		local request = {
			["type"]   = enum.uiRequestType.MISSIONABORT,
			["name"]   = name,
			["value"]  = reason,
		}
		-- We have to use theater:queueCommand() to bypass the
		-- limiting of players sending too many commands
		theater:queueCommand(10, uicmds[request.type](theater, request))
	end
end



function Mission:update()
	
	Logger:debug("update() called") --for state: "..self.state.__clsname)
		
		
			
		--should update target location
		
		--old stuff, will probably remove
		
end

function Mission:_setComplete(val)
	self._complete = val
end

function Mission:isComplete()
	return self._complete
end

--[[
-- getTargetInfo - provide target information
--
-- The target information supplied:
--   * location - centroid of the asset
--   * callsign - a short name the target area can be referenced by
--   * description - short two/three word description of the asset
--       like; factory, ammo bunker, etc.
--   * status - numercal value from 0 to 100 representing percentage
--       completion
--   * intellvl - numercal value representing the amount of 'intel'
--       gathered on the asset, dictates targeting coordinates
--       precision too
--]]

function Mission:getTargetInfo()
	local asset = dct.Theater.singleton():getAssetMgr():getAsset(self.target)
	if asset == nil then
		self.tgtinfo.status = 100
	else
		self.tgtinfo.status = asset:getStatus()
	end
	return utils.deepcopy(self.tgtinfo)
end

function Mission:init_readable()

	divider = "\n"..string.rep('-',60).."\n"
		
	Logger:debug("-- MISSION: INIT READABLE --")
		
	-- this may seem extremely complicated but:
	-- A) It is more efficient
	-- B) It allows us to modify the briefing even while the mission is in progress
		
	self.readable = {}
	
	self.readable["PackageHeader"] = {[1] = "Package:\n",
								 [2] = divider,
								 [3] = self.id,
								 [4] = divider
								}
	self.readable["IFF"] = 			{[1] = "IFF Codes: \n",
								 [2] = string.format("M1(%02o), M3(%04o)", self.iffcodes.m1, self.iffcodes.m3),
								 [3] = divider
								}
	self.readable["PackageComms"] = 	{[1] = "Package Comms: \n",
								 [2] = "UHF: "..self.packagecomms["UHF"].."/ VHF: "..self.packagecomms["VHF"].." / FM: " .. self.packagecomms["FM"] .."",
								 [3] = divider
								}
	if(self.marshal_point) then	
	
		self.readable["MarshalPoint"] = 	{[1] = "Marshal Point:\n",
									 [2] = "LOCATION",
									 [3] = divider
									}			
	end
	
	if(self.pushtime) then
	
		self.readable["PushTime"] = 		{[1] = "Push Time:\n",
									 [2] = self.pushtime,
									 [3] = divider
									}			

	end		
	
	if(self.ToT) then--not implemented
	
		self.readable["TimeOnTarget"] = 	{[1] = "Time on Target:\n",
									 [2] = "", --not implemented
									 [3] = divider
									}			

	end
	
	if(enum.briefingType["STANDARD"][self.type]) then -- standard briefing or not
	
		self.readable["TargetLocation"] = 	{[1] = human.locationhdr(self.type),
										[2] = "LOCATION", --we leave this one blank so we can fill in with whatever format the player requesting takes
										[3] = divider
										}
											
		self.readable["Briefing"] = 		{[1] = "Briefing:\n",
									 [2] = self.briefing, --we leave this one blank so we can fill in with whatever format the player requesting takes
									 [3] = divider
									}
	
	elseif(enum.briefingType["NONCOMBAT"][self.type]) then
	
		self.readable["Orders"] = 		{[1] = "Orders from Commander:\n",
									 [2] = "No current orders", -- default state
									 [3] = divider
									}
	
	elseif(enum.briefingType["RECON"][self.type]) then
	
		self.readable["Information"] = 	{[1] = "Info:\n",
									 [2] = "Plot your flight plan on the F10 map.\n", -- default state
									 [3] = "Each waypoint should be named RECON:# where number", -- default state
									 [4] = "indicates the waypoint of your flight plan\n", -- default state
									 [5] = "The waypoints should snap to a point.\n", -- default state
									 [6] = "You must fly an orbit around each waypoint at"..dct.settings.gameplay["RECON_MISSION_ALTITUDE"].. " m altitude for X seconds \n", -- TODO: add this setting
									 [7] = "to detect any enemy units nearby\n", -- default state
									 [8] = divider
									}
	
	end		
		
	
	Logger:debug("-- MISSION: DONE READABLE --")	
	Logger:debug("%s", self.readable["PackageHeader"][1])	
		
end

function Mission:getFullBriefing(player)

	Logger:debug("-- INSIDE GET FULL BRIEFING --")	
	Logger:debug("-- ID: %s", self.id)
	
	local output = {}
	
	for k,v in ipairs(enum.briefingKeys) do
	
		if(self.readable[v]) then
		

			for index, outline in ipairs(self.readable[v]) do
				
				--input any location info				
				if(k == 4  and  index == 2) then		--k = ["MarshalPoin"t]
					outline = string.format("%s", dctutils.fmtposition(self.marshal_point, 5, player.gridfmt)) --default LL
				end
				
				if(k == 7 and  index == 2) then -- k = ["TargetLocation"]				
					outline =  string.format("%s (%s)", dctutils.fmtposition(self.tgtinfo.location, self.tgtinfo.intellvl, player.gridfmt),	self.tgtinfo.callsign)
				end
				
				output[#output+1]  = outline

			end
			
		end	
	
	end	
	
	return table.concat(output)
	
end

return Mission
