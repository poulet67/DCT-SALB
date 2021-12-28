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
local Template    = require("dct.templates.Template")
local Logger     = dct.Logger.getByName("Commander")
local settings    = _G.dct.settings
--local settings = _G.dct.settings.server



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
	self.missionboard     = {} --a printable board displaying all missions
	self.freqs_in_use = self:init_freqs() --frequencies currently assigned to a mission
	self.aifreq       = 15  -- 2 minutes in seconds
	self.known = {}
	self.CommandPoints = 0
	

	theater:queueCommand(120, Command(
		"Commander.startIADS:"..tostring(self.owner),
		self.startIADS, self))
--	theater:queueCommand(0, Command( 
--		"Commander.startperiodicMission:"..tostring(self.owner),
--		self.startperiodicMission, self, theater))
	theater:queueCommand(8, Command(                        --- WARNING: this must be larger than the time (first argument) specified in theater's delayed init!
		"Commander.getKnownTables:"..tostring(self.owner),
		self.getKnownTables, self, theater))
	theater:queueCommand(self.aifreq, Command(
		"Commander.update:"..tostring(self.owner),
		self.update, self))
	theater:queueCommand(7, Command(
		"Commander.init_persistent_missions:"..tostring(self.owner),
		self.init_persistent_missions, self))
end

function Commander:getKnownTables(theater)

	self.known = theater:getAssetMgr():getKnownTables(self.owner)
	
end

function freq_num_to_string(freqnum)

	return string.format("%.3f",freqnum)	
	
end

function Commander:init_freqs()
	
	--Frequencies shall be stored as numbers when value and string when key
	
	self.freqs_in_use = {["UHF"] = {},
						 ["VHF"] = {},
						 ["FM"] = {},
						 ["UNAVAILABLE"] = {},}
	
	for k, v in pairs(settings.radios["FREQ_UNAVAILABLE"]) do
	
		Logger:debug("COMMANDER: FREQ_ INIT:" .. k) 
		Logger:debug("COMMANDER: FREQ_ INIT:" .. v) 
		table.insert(self.freqs_in_use["UNAVAILABLE"], {[freq_num_to_string(v)] = true})
				
	end
	
end

function Commander:init_persistent_missions()

	for k,v in pairs(enum.persistentMissions) do
	
		local tTable = Template(
		{
			["objtype"]    = "WAYPOINT",
			["name"]       = k, -- needs to be unique ?
			["regionname"] = "WAYPOINT",
			["desc"]       = k,
			["coalition"]  = self.owner,
			["location"]   = { ["x"] = 0, ["y"] = 0, ["z"] = 0, },
		}
		)
		
		ass_manager = require("dct.Theater").singleton():getAssetMgr()
		asset = ass_manager:factory(tTable.objtype)(tTable)
		ass_manager:add(asset)
		
		mission = Mission(self, k, asset, {})
		self:addMission(mission)			
		Logger:debug("COMMANDER ==== PERSISTENT DONE ====  :"..mission.id)
		
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

	return self.missions
	
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

function checkFreqInUse(f_band, channel)

	if self.freqs_in_use[f_band][channel] and self.freqs_in_use["UNAVAILABLE"].channel then
		return true
	else
		return false
	end

end

function Commander:select_channel(f_band, band_start,band_end,step_size,band_start)

	-- TODO: only now just realized that these will need to be unique between commanders as well... 
	-- if the enemy commander is AI, we don't really need to do this.
	-- Could also expand the setting for both commanders (i.e require different blocks for blue and red)
	--

	band_width = settings.radios["UHF_MAX"] - settings.radios["UHF_MIN"]
	num_channels = U_band_width/step_size	
	selected_channel_index = math.random(0, num_channels)
	
	channel = string.format("%.3f",selected_channel_index*num_channels+band_start)
		
	Logger:debug("INSIDE pkg comms channel selected:" .. channel) 
	
	isInUse = self:checkFreqInUse(f_band, channel)
	
	if(isInUse) then --AKA unavailable
	
		return
		
	else 
	
		return channel, selected_channel_index
	
	end
	
end


function Commander:assignPackageComms(msntype)
	
	-- Probably a more elegant solution to this, but so long as enough bandwidth is provided this should work for most users
	-- One possible optimization is to keep a list of "tried" frequencies/indexes and skip if 
	
	Logger:debug("INSIDE pkg comms") 
	Logger:debug(settings.radios["UHF_MAX"]) 
	Logger:debug("INSIDE pkg comms") 

	
	if(settings.radios["REBROADCAST"]) then -- channels must mirror 1 for 1 with their VHF and FM counterparts (and not collide with any frequencies already in use)
							
		tries = 0
		tried_indexes = {["n"] = 0} -- number of tried (thanks for not having any way of determining the number of keys in a table lua!
		n_channels = (settings.radios["VHF_MAX"]-settings.radios["VHF_MIN"])/settings.radios["FREQ_STEPS"]
		
		while(package_comms == nil or tries < n_channels*1.2) do 

			UHF, index = Commander:select_channel("UHF", settings.radios["UHF_MAX"], settings.radios["UHF_MIN"], settings.radios["FREQ_STEPS"])
			
			if(index == nil) then
				tried_indexes[index] = true --tried UHF and it was in use
				tried_indexes["n"] = tried_indexes["n"]+1 
			end
						
			Logger:debug("UHF ASSIGNED: " .. UHF) 
			
			if(UHF and tried_indexes[index] == nil) then
				
				tried_indexes[index] = true	-- now we try the rest of the bands
				tried_indexes["n"] = tried_indexes["n"]+1	-- now we try the rest of the bands
				
				VHF = string.format("%.3f",index*n_channels+settings.radios["VHF_MIN"])							
				Logger:debug("VHF ASSIGNED: " .. UHF) 
				
				if(self:checkFreqInUse("VHF", VHF)) then
				
					
					FM = string.format("%.3f",index*n_channels+settings.radios["FM_MIN"])
					Logger:debug("FM ASSIGNED: " .. UHF) 
					
					if(self:checkFreqInUse("FM", FM)) then
						
						package_comms = {["UHF"] = UHF, 
										 ["VHF"] = VHF,
										 ["FM"] = FM
										 }				 
						self.freqs_in_use["UHF"][UHF] = true
						self.freqs_in_use["VHF"][VHF] = true
						self.freqs_in_use["FM"][FM] = true
						
					end
				end
			
			else
				
				if(tried_indexes["n"] == n_channels*0.8) then -- something else that can be a setting
				
					tries = tries + 1 --80% of the bandwidth has been tried
				
				else
				
					tries = tries - 1 -- don't count this one (n.b - may result in huge execution times if comms channels crowded...)
					
				end
				
				
			end
						
			tries = tries + 1
			
		end
		
		if(package_comms == nil) then -- couldn't find an available channel
		
			Logger:warn("Not enough comms bandwidth alloted for mission size! This can be configured in theater/settings/radios.cfg") 
			return "Comms channels crowded, frequency at pilot discretion"
		
		end
		
	else -- channels assigned pseudo randomly
	
		while(package_comms == nil or tries < 20) do -- might make this a setting
		
			UHF, _ = Commander:select_channel("UHF", settings.radios[UHF_MAX], settings.radios[UHF_MIN], settings.radios[FREQ_STEPS])
		
			if(UHF) then
				
				VHF, _ = Commander:select_channel("VHF", settings.radios[VHF_MAX], settings.radios[VHF_MIN], settings.radios[FREQ_STEPS])
				
				if(VHF) then
				
					FM, _ = Commander:select_channel("FM", settings.radios[FM_MIN], settings.radios[FM_MAX], settings.radios[FREQ_STEPS])
					
					if(FM) then
					
						package_comms = {["UHF"] = UHF, 
										 ["VHF"] = VHF,
										 ["FM"] = FM
										 }
						self.freqs_in_use["UHF"][UHF] = true
						self.freqs_in_use["VHF"][VHF] = true
						self.freqs_in_use["FM"][FM] = true
					
					end
				
				
				end
				
			end
			
		end
		
		if(package_comms == nil) then -- couldn't find an available channel
		
			Logger:warn("Not enough comms bandwidth alloted for mission size! This can be configured in theater/settings/radios.cfg") 
			return "Comms channels crowded, frequency at pilot discretion"
		
		end
		
		
	end
	
	return package_comms
	
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

--[[
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
--]]

-- Go through known table, create appropriate mission type
function Commander:assignMissionsToTargets()

	if(self.known ~= nil) then
		--Self.known is in form:
		--"NAME" = true,
		--"NAME" = true,
		--"NAME" = true,
		--"NAME" = true,
		--
		for k, v in pairs(self.known) do
			
			target = self:getAsset(k)		
			missiontype = dctutils.assettype2mission(target.type)
			Logger:debug("COMMANDER ==== ASSIGN MISSION ====  :"..k)
			local plan = { require("dct.ai.actions.KillTarget")(target) }
			
			local mission = Mission(self, missiontype, target, plan)
			self:addMission(mission)			
			Logger:debug("COMMANDER ==== DONE ====  :"..mission.id)
			self.known[k] = nil;
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
