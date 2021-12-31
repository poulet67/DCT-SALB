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
	self.missionorder     = {} -- just an array like table, so we can sort by priority
	self.freqs_in_use = self:init_freqs() --frequencies currently assigned to a mission
	self.isAI = self:getAIstatus()
	self.aifreq       = 15  -- 2 minutes in seconds
	--we have known knowns and known unknowns -- Dick Cheney
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

function Commander:getAIstatus()
	
	keyval = enum.coalitionMap[self.owner] .. "_AI"
	
	return settings.gameplay[keyval]

end

function freq_num_to_string(freqnum)

	return string.format("%.3f",freqnum)	
	
end

function Commander:init_freqs()

	
	Logger:debug("COMMANDER ==== SIDE ====  :"..self.owner)
	Logger:debug("COMMANDER ==== ENUM ====  :"..enum.coalitionMap[self.owner])
	
	coalition_string = enum.coalitionMap[self.owner]
	
	if(coalition_string == "NEUTRAL") then -- don't bother for neutral commander
	  
		return {}
		
	end
	
	Logger:debug("COMMANDER ==== COAL STRING ====  :"..coalition_string)
	
	freq_settings_tbl = settings.radios["_FREQS"]
	
	--Frequencies shall be stored as numbers when value and string when key
	
	freq_table = {["UHF"] = {},
						 ["VHF"] = {},
						 ["FM"] = {},
						 ["UNAVAILABLE"] = {},}
	
	for k, v in pairs(settings.radios["FREQ_UNAVAILABLE"]) do
	
		--Logger:debug("COMMANDER: FREQ_ INIT:" .. k) 
		--Logger:debug("COMMANDER: FREQ_ INIT:" .. v) 
		table.insert(freq_table["UNAVAILABLE"], {[freq_num_to_string(v)] = true})
		
		
		
	end
	
	return freq_table
	
end

function Commander:init_persistent_missions()

	if(self.owner ~= coalition.side.NEUTRAL) then -- don't bother for neutral commander
		
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
			
			mission = Mission(self, enum.missionType[k], asset, {})
			self:addMission(mission)			
			Logger:debug("COMMANDER ==== PERSISTENT DONE ====  :"..mission.id)
			
		end	
	end
	
end

function Commander:startIADS()
	self.IADS = require("dct.systems.IADS")(self)
end

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
		
	-- TODO
	
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

function Commander:checkFreqInUse(f_band, channel)

	Logger:debug("CHECKING:" .. f_band) 
	Logger:debug("CHECKING:" .. channel) 
	
	if self.freqs_in_use[f_band][channel] and self.freqs_in_use["UNAVAILABLE"][channel] then
		return true
	else
		return false
	end

end

function Commander:select_channel(f_band, band_start, band_end, step_size)

	-- TODO: only now just realized that these will need to be unique between commanders as well... 
	-- if the enemy commander is AI, we don't really need to do this.
	-- Could also expand the setting for both commanders (i.e require different blocks for blue and red)
	--

	band_width = band_start - band_end
	num_channels = band_width/step_size	
	selected_channel_index = math.random(0, num_channels)
	
	Logger:debug("INSIDE pkg comms channel index:" .. selected_channel_index) 
	Logger:debug("INSIDE pkg comms channel:" .. num_channels) 
	
	channel = string.format("%.3f",selected_channel_index*step_size+band_start)
		
	Logger:debug("INSIDE pkg comms channel selected:" .. channel) 
	
	isInUse = self:checkFreqInUse(f_band, channel)
	
	if(isInUse) then --AKA unavailable
	
		Logger:debug("IN USE") 
		
		return
		
	else 
	
		Logger:debug("RETURNING"..channel) 
		
		return channel, selected_channel_index
	
	end
	
end


function Commander:assignPackageComms(msntype)
	
	-- Probably a more elegant solution to this, but so long as enough bandwidth is provided this should work for most users
	
	if(self.owner == coalition.side.NEUTRAL) then -- shouldn't be assigning missions to neutral anyhow...
	
		return
	
	end
	
	
	coalition_string = enum.coalitionMap[self.owner]	
	freq_settings_tbl = settings.radios[coalition_string.."_FREQS"]
	freq_steps = settings.radios["FREQ_STEPS"]
	rebroadcast = settings.radios["REBROADCAST"]
	
	--Logger:debug("INSIDE pkg comms") 
	
	if(not self.isAI or settings.radios["ASSIGN_TO_AI"]) then

		tries = 0
		if(rebroadcast) then -- channels must mirror 1 for 1 with their VHF and FM counterparts (and not collide with any frequencies already in use)
			
			n_channels = (freq_settings_tbl["VHF_MAX"]-freq_settings_tbl["VHF_MIN"])/freq_steps
			
			while(package_comms == nil or tries < 40) do 
				tries = tries + 1
			
				UHF, index = self:select_channel("UHF", freq_settings_tbl["UHF_MAX"], freq_settings_tbl["UHF_MIN"], freq_steps)
									
				--Logger:debug("UHF ASSIGNED: " .. UHF) 
				
				if(UHF) then
					
					VHF = string.format("%.3f",index*freq_steps+freq_settings_tbl["VHF_MIN"])							
					--Logger:debug("VHF ASSIGNED: " .. VHF) 
					
					if(not self:checkFreqInUse("VHF", VHF)) then
					
						
						FM = string.format("%.3f",index*freq_steps+freq_settings_tbl["FM_MIN"])
						--Logger:debug("FM ASSIGNED: " .. UHF) 
						
						if(not self:checkFreqInUse("FM", FM)) then
							
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
				
			else
				
				enemy_cmdr = require("dct.Theater").singleton():getCommander(dctutils.getenemy(self.owner)) -- MORE ONELINERS FOR THE ONELINER GOD
				
				if((enemy_cmdr.isAI and settings.radios["ASSIGN_TO_AI"]) or not enemy_cmdr.isAI) then
				
					table.insert(enemy_cmdr.freqs_in_use["UNAVAILABLE"], {[package_comms.UHF] = true})
					table.insert(enemy_cmdr.freqs_in_use["UNAVAILABLE"], {[package_comms.VHF] = true})
					table.insert(enemy_cmdr.freqs_in_use["UNAVAILABLE"], {[package_comms.FM] = true})
				
				end
				
			end
			
		else -- channels assigned pseudo randomly
		
			while(package_comms == nil or tries < 40) do -- might make this a setting
				tries = tries + 1
				
				--Logger:debug("why am I here? Just to suffer?") 
				
				UHF, _ = self:select_channel("UHF", freq_settings_tbl["UHF_MAX"], freq_settings_tbl["UHF_MIN"], freq_steps)
			
				if(UHF) then
					
					VHF, _ = self:select_channel("VHF", freq_settings_tbl["VHF_MAX"], freq_settings_tbl["VHF_MIN"], freq_steps)
					
					if(VHF) then
					
						FM, _ = self:select_channel("FM", freq_settings_tbl["FM_MIN"], freq_settings_tbl["FM_MAX"], freq_steps)
						
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
			
			else
				
				enemy_cmdr = require("dct.Theater").singleton():getCommander(dctutils.getenemy(self.owner)) -- MORE ONELINERS FOR THE ONELINER GOD
				
				if((enemy_cmdr.isAI and settings.radios["ASSIGN_TO_AI"]) or not enemy_cmdr.isAI) then
				
					table.insert(enemy_cmdr.freqs_in_use["UNAVAILABLE"], {[package_comms.UHF] = true})
					table.insert(enemy_cmdr.freqs_in_use["UNAVAILABLE"], {[package_comms.VHF] = true})
					table.insert(enemy_cmdr.freqs_in_use["UNAVAILABLE"], {[package_comms.FM] = true})
				
				end
				
			end
			
		end
		
	end
	
	--Logger:debug("RETURNING PACKAGE COMMS") 
	
	return package_comms
	
end

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

function Commander:newPeriodic(mission)
	
	newmiss = Mission(self, mission.type, mission.tgt, mission.plan)
	self.missions[newmiss:getID()] = newmiss
	self.missionstats:inc(mission.type)
	
end

function Commander:addMission(mission)
	self.missions[mission:getID()] = mission		
	self.missionstats:inc(mission.type)
end

--[[
-- remove the mission identified by id from the commander's tracking
--]]
function Commander:removeMission(id)
	period = self.missions[id].period
	local mission = self.missions[id]
	self.missions[id] = nil
	
	if(period == 0) then
		self.missionstats:dec(mission.type)
	end
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
