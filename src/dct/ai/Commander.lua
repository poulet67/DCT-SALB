--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Defines a side's strategic theater commander.
--]]

local utils      = require("libs.utils")
local containers = require("libs.containers")
local enum       = require("dct.enum")
local dctutils   = require("dct.utils")
local Mission    = require("dct.ai.Mission")
local Stats      = require("dct.libs.Stats")
local Command    = require("dct.Command")
local Logger     = dct.Logger.getByName("Commander")



local function heapsort_tgtlist(assetmgr, owner, filterlist)
	local tgtlist = assetmgr:getTargets(owner, filterlist)
	local pq = containers.PriorityQueue()

	-- priority sort target list
	for tgtname, _ in pairs(tgtlist) do
		local tgt = assetmgr:getAsset(tgtname)
		if tgt ~= nil and not tgt:isDead() and not tgt:isTargeted(owner) then
			pq:push(tgt:getPriority(owner), tgt)
		end
	end

	return pq
end

local function genStatIds()
	local tbl = {}

	for k,v in pairs(enum.missionType) do
		table.insert(tbl, {v, 0, k})
	end
	return tbl
end

--[[
-- For now the commander is only concerned with flight missions
--]]
local Commander = require("libs.namedclass")("Commander")

function Commander:__init(theater, side)
	self.owner        = side
	self.missionstats = Stats(genStatIds())
	self.missions     = {}
	self.aifreq       = 15  -- 2 minutes in seconds
	
	self.CommandPoints = 0;
	self.known 			= {}; -- A table for assets that the Commander 'knows' exists
	
	self:initKnownTable()
	

	theater:queueCommand(120, Command(
		"Commander.startIADS:"..tostring(self.owner),
		self.startIADS, self))
--	theater:queueCommand(0, Command( 
--		"Commander.startperiodicMission:"..tostring(self.owner),
--		self.startperiodicMission, self, theater))
	theater:queueCommand(self.aifreq, Command(
		"Commander.update:"..tostring(self.owner),
		self.update, self))
end

function Commander:initKnownTable()

	known = dct.Theater.singleton():getAssetMgr():getKnownTables()
	 
	for k,v in pairs(known) do
	
		

	end
	
end

function Commander:startIADS()
	self.IADS = require("dct.systems.IADS")(self)
end

--[[
function Commander:startperiodicMission(theater)
	
	Logger:debug("INSIDE INIT") 
	test = enum.missionType["NAVAL STRIKE"]
	Logger:debug("enum: "..test) 	
	local periodicMission = require("dct.systems.periodicMission")
	missionid = periodicMission["startperiodicMission"](self, self.owner, enum.missionType["NAVAL STRIKE"])	
	
	theater:queueCommand(1800, Command( -- 1800s = 30 mins
		"Commander.endperiodicMission:"..tostring(self.owner),
		self.endperiodicMission, self, missionid))
	
	return 1800 --will re-run this command in 1800s (30 mins)
	
end
--]]

--[[
function Commander:endperiodicMission(id)
	
	local mission = self.missions[id]
	mission:forceEnd()
	
end
--]]
function Commander:update(time)
	for _, mission in pairs(self.missions) do
		mission:update(time)
	end
	
	self:assignMissionsToTargets()
	
	return self.aifreq
end

--[[
-- TODO: complete this
-- see UI command for required table fields
--]]


function Commander:getTheaterUpdate()
	local theater = dct.Theater.singleton()
	local theaterUpdate = {}
 
	-- Need to rethink this function entirely for 0.67
	
	--theaterUpdate.friendly = {}
	--tks, start = theater:getTickets():get(self.owner)
	--theaterUpdate.friendly.str = math.floor((tks / start)*100)
	--theaterUpdate.enemy = {}
	--theaterUpdate.enemy.sea = 50
	--theaterUpdate.enemy.air = 50
	--theaterUpdate.enemy.elint = 50
	--theaterUpdate.enemy.sam = 50
	--tks, start = theater:getTickets():get(dctutils.getenemy(self.owner))
	--theaterUpdate.enemy.str = math.floor((tks / start)*100)
	--theaterUpdate.missions = self.missionstats:getStats()
	
	theaterUpdate.enemy_losses = 0;
	theaterUpdate.friendly_losses = 0;
	theaterUpdate.nregions_friendly = 0;
	theaterUpdate.nregions_enemy = 0;
	theaterUpdate.friendly_CP = 0;
	theaterUpdate.enemy_losses = 0;
	theaterUpdate.victory_condition_readable = "Capture: "; -- finish these
	
	return theaterUpdate
	
end

function Commander:getMissionBoard()
	local theater = dct.Theater.singleton()
	local mtable = {}
 
	for k,v in pairs(self.missions) do
	
		mtable.missions[k] = v.type 
		theaterUpdate.missions[k].n_assigned = #self.assigned		
		--theaterUpdate.missions[k].n_max = self.max_assigned -- may add this functionality later on
		theaterUpdate.missions[k].priority = 0 -- still need to deal with this
	end
	
	return theaterUpdate
	
end

local MISSION_ID = math.random(1,63) 
local invalidXpdrTbl = {
	["7700"] = true,
	["7600"] = true,
	["7500"] = true,
	["7400"] = true,
}

local squawkMissionType = {
	["SAR"]  = 0,
	["SUPT"] = 1,
	["A2A"]  = 2,
	["SEAD"] = 3,
	["SEA"]  = 4,
	["A2G"]  = 5,
}

local function map_mission_type(msntype)
	local sqwkcode
	if msntype == enum.missionType.CAP then
		sqwkcode = squawkMissionType.A2A
	--elseif msntype == enum.missionType.SAR then
	--	sqwkcode = squawkMissionType.SAR
	--elseif msntype == enum.missionType.SUPPORT then
	--	sqwkcode = squawkMissionType.SUPT
	elseif msntype == enum.missionType.SEAD then
		sqwkcode = squawkMissionType.SEAD
	else
		sqwkcode = squawkMissionType.A2G
	end
	return sqwkcode
end

--[[
-- Generates a mission id as well as generating IFF codes for the
-- mission.
--
-- Returns: a table with the following:
--   * id (string): is the mission ID
--   * m1 (number): is the mode 1 IFF code
--   * m3 (number): is the mode 3 IFF code
--  If 'nil' is returned no valid mission id could be generated.
--]]
function Commander:genMissionCodes(msntype)
	local id
	local m1 = map_mission_type(msntype)
	while true do
		MISSION_ID = (MISSION_ID + 1) % 64
		id = string.format("%01o%02o0", m1, MISSION_ID)
		if invalidXpdrTbl[id] == nil and
			self:getMission(id) == nil then
			break
		end
	end
	local m3 = (512*m1)+(MISSION_ID*8)
	return { ["id"] = id, ["m1"] = m1, ["m3"] = m3, }
end

--[[
-- recommendMission - recommend a mission type given a unit type
-- unittype - (string) the type of unit making request requesting
-- return: mission type value
--]]

--[[

function Commander:recommendMissionType(allowedmissions)
	local assetfilter = {}

	for _, v in pairs(allowedmissions) do
		utils.mergetables(assetfilter, enum.missionTypeMap[v])
	end

	local pq = heapsort_tgtlist(
		require("dct.Theater").singleton():getAssetMgr(),
		self.owner, assetfilter)

	local tgt = pq:pop()
	if tgt == nil then
		return nil
	end
	return dctutils.assettype2mission(tgt.type)
end

]]--

--[[
-- requestMission - get a new mission
--
-- Creates a new mission where the target conforms to the mission type
-- specified and is of the highest priority. The Commander will track
-- the mission and handling tracking which asset is assigned to the
-- mission.
--
-- grpname - the name of the commander's asset that is assigned to take
--   out the target.
-- missiontype - the type of mission which defines the type of target
--   that will be looked for.
--
-- return: a Mission object or nil if no target can be found which
--   meets the mission criteria
--]]


--from old DCT, can be removed

function Commander:requestMission(grpname, missiontype)
	local assetmgr = dct.Theater.singleton():getAssetMgr()
	local pq = heapsort_tgtlist(assetmgr, self.owner, enum.missionTypeMap[missiontype])

	-- if no target, there is no mission to assign so return back
	-- a nil object
	local tgt = pq:pop()
	if tgt == nil then
		return nil
	end
	Logger:debug(string.format("requestMission() - tgt name: '%s'; "..
		"isTargeted: %s", tgt.name, tostring(tgt:isTargeted())))

	local plan = { require("dct.ai.actions.KillTarget")(tgt) }
	local mission = Mission(self, missiontype, tgt, plan)
	mission:addAssigned(assetmgr:getAsset(grpname))
	self:addMission(mission)
	return mission
end


-- Go through known table, create appropriate mission type
function Commander:assignMissionsToTargets()

	if(self.known ~= nil) then
		
		for k, v in pairs(self.known) do
			
			target = v
			
			Logger:debug("COMMANDER ==== DISCOVERY ====")
			local plan = { require("dct.ai.actions.KillTarget")(target) }		
			local mission = Mission(self, missiontype, target, plan)
			self:addMission(mission)
			
		end
	end

	
end

--[[
-- return the Mission object identified by the id supplied.
--]]
function Commander:getMission(id)
	return self.missions[id]
end

function Commander:addMission(mission)
	self.missions[mission:getID()] = mission
	self.missionstats:inc(mission.type)
end

--[[
-- remove the mission identified by id from the commander's tracking
--]]
function Commander:removeMission(id)
	local mission = self.missions[id]
	self.missions[id] = nil
	self.missionstats:dec(mission.type)
end

function Commander:getAssigned(asset)
	local msn = self.missions[asset.missionid]

	if msn == nil then
		asset.missionid = enum.misisonInvalidID
		return nil
	end

	local member = msn:isMember(asset.name)
	if not member then
		asset.missionid = enum.misisonInvalidID
		return nil
	end
	return msn
end

function Commander:getAsset(name)
	return require("dct.Theater").singleton():getAssetMgr():getAsset(name)
end

return Commander
