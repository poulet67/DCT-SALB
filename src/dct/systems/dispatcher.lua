--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Handles all logic required to dispatch command units 
--
--
--
--
)
--]]

local class  = require("libs.namedclass")
local Logger = require("dct.libs.Logger").getByName("UI")
local enum        = require("dct.enum")
local Command     = require("dct.Command")
local dctutils   = require("dct.utils")
local utils      = require("libs.utils")
local settings    = _G.dct.settings

local Dispatcher = class("Dispatcher")
function Dispatcher:__init(cmdr, theater)

	self._theater = theater
	self._cmdr = cmdr
	self.ActiveUnits = {}
	
	for k, v in pairs(enum.commandUnitTypes) do
	
		self.ActiveUnits[k] = {} -- a table of the active "names" for a unit type.
								 -- todo: clear this entry when unit despawned
	end
	
end

function Dispatcher:fixedWing_dispatch(point, altitude, speed, commandUnitType, commandUnitSelection)

	Logger:debug("DISPATCHER ==== Dispatch===")
	Logger:debug("CommandUnit: "..commandUnitType)
	Logger:debug("Type: "..commandUnitSelection)
	
	asset_template = self._cmdr.Command_Units[commandUnitType][commandUnitSelection][next(self._cmdr.Command_Units[commandUnitType][commandUnitSelection])] -- Should only ever be 1 entry in this table, next will bring us to it anyhow
	template = utils.deepcopy(asset_template)	
	
	if(altitude == nil) then
	
		altitude = settings.gameplay["COMMAND_UNIT_DEFAULT_ALTITUDE"]
		
	end	
	
	if(speed == nil) then
	
		speed = settings.gameplay["COMMAND_UNIT_DEFAULT_SPEED"]
		
	end
	
	WP1 = dctutils.fixedWing.buildWP(point, self._cmdr.owner, 'takeoff', 0, 0, 'agl')
	WP2 = dctutils.fixedWing.buildWP(point, self._cmdr.owner, 'orbit', 250, altitude, 'agl')

	--self:defaultTasks(template)

	Logger:debug("WP1 dump")
	utils.tprint(WP1) 
	Logger:debug("WP2 dump")
	utils.tprint(WP2) 

	-- This makes sense in ED land	
	template.tpldata[1]["data"]["x"] = point.x 
	template.tpldata[1]["data"]["y"] = point.z -- ED can't figure out what X,Y and Z are leading to barbaric code like this
	
	template.tpldata[1]["data"]["route"]["points"][1] = WP1
	template.tpldata[1]["data"]["route"]["points"][2] = WP2
			
	for k,v in ipairs(template.tpldata[1]["data"]["units"]) do
		
	  v.x = point.x
	  v.y = point.z
		
	end
	
	callsign = self:assignCallsign(template.CU_Type)
	
	if(callsign) then
	
		name = enum.coalitionMap[self._cmdr.owner].." "..template.CU_Type.." "..callsign	
		template.tpldata[1]["data"]["name"]	= name
		template.name = name
		template.dispatch_callsign = callsign
		
		for k,v in ipairs(template.tpldata[1]["data"]["units"]) do
			Logger:debug(k)
			v["name"] = callsign.."-"..k 
		
		end
	
	end
	
	Logger:debug("DISPATCHER: -- TEMPLATE DUMP")
	utils.tprint(template) 
	
	self._cmdr.Command_Units["ACTIVE"][commandUnitType][template.dispatch_callsign] = {}
	self._cmdr.Command_Units["ACTIVE"][commandUnitType][template.dispatch_callsign]["DCS_group_name"] = template.name -- The DCS group name
	self._cmdr.Command_Units["ACTIVE"][commandUnitType][template.dispatch_callsign]["altitude"] = altitude
	self._cmdr.Command_Units["ACTIVE"][commandUnitType][template.dispatch_callsign]["speed"] = speed
	self._cmdr.Command_Units["ACTIVE"][commandUnitType][template.dispatch_callsign]["display_name"] = template.display_name --for display in F10 menu
	
	asset_manager = require("dct.Theater").singleton():getAssetMgr()
	asset = asset_manager:factory(template.objtype)(template)
	asset_manager:add(asset)	
	asset:generate(asset_manager, self)
	asset:spawn()
	
	dspch_msg = dctutils.printTabular("DISPATCHING "..commandUnitType.." GROUP: "..template.dispatch_callsign, 65, "-")
	
	trigger.action.outTextForCoalition(self._cmdr.owner, dspch_msg, 45)
	--Logger:debug("TEMPLATE DUMP")
	--utils.tprint(template) 
		

end

function Dispatcher:fixedWing_move(commandUnitType, name, point, altitude, speed)
	
	DCS_group_name = self._cmdr.Command_Units["ACTIVE"][commandUnitType][name]["DCS_group_name"] -- The DCS group name 
		
	if(DCS_group_name) then
	
		Logger:debug(DCS_group_name)
		CU_Group = Group.getByName(DCS_group_name)
		
		if(CU_Group) then
			
			
			if(altitude == nil) then
				
				altitude = self._cmdr.Command_Units["ACTIVE"][commandUnitType][name]["altitude"]
				Logger:debug("ALTITUDE: "..altitude)		

			end		
			
			if(speed == nil) then
			
				speed = self._cmdr.Command_Units["ACTIVE"][commandUnitType][name]["speed"]
				Logger:debug("SPEED: "..speed)
				
			end
			
			Logger:debug("DISPATCHER ==== MOVE===")		
			Logger:debug("commandUnitType: " .. commandUnitType)	
			Logger:debug("altitude: " .. altitude)
			Logger:debug("speed: " .. speed)
				
			myMission = dctutils.fixedWing.defaultMissionTask()		
			myMission.params.route.points[1]["x"] = point.x
			myMission.params.route.points[1]["y"] = point.z
			myMission.params.route.points[1]["alt"] = altitude
			myMission.params.route.points[1]["alt_type"] = "BARO"
			myMission.params.route.points[1]["speed"] = speed
			myMission.params.route.points[1]["type"] = "Turning Point"
			myMission.params.route.points[1]["action"] = "Turning Point"
			
			task_tbl = dctutils.fixedWing.OrbitTask()
			
			Logger:debug("TASK DUMP")
			utils.tprint(task_tbl)
			
			myMission.params.route.points[1]["task"] = task_tbl
			
			Logger:debug("MISSION DUMP")
			--utils.tprint(myMission)
	
			CU_Group:getController():setTask(myMission) 		
			--ROE ------------
			CU_Group:getController():setOption(AI.Option.Air.id.ROE, 5) --Do not engage
			CU_Group:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT, 0) -- No reactiong
			-- These settings will (or should) ensure the unit goes directly where it is commanded at the altitude and speed set with no AI shennanigans			
			
		else
		
			Logger:debug("DISPATCHER: -- move_command: invalid name")
		
		end
	
	else
	
		Logger:debug("DISPATCHER: -- move_command: invalid name")
		
	end
	
end

function Dispatcher:fixedWing_attack(commandUnitType, name, point, altitude, speed)

	DCS_group_name = self._cmdr.Command_Units["ACTIVE"][commandUnitType][name]["DCS_group_name"] -- The DCS group name 
		
	if(DCS_group_name and enum.offensiveUnits[enum.commandUnitTypes[commandUnitType]]) then -- group name exists and this is an offensive type unit
	
		Logger:debug(DCS_group_name)
		CU_Group = Group.getByName(DCS_group_name)
		
		if(CU_Group) then
			
			
			if(altitude == nil) then
				
				altitude = self._cmdr.Command_Units["ACTIVE"][commandUnitType][name]["altitude"]
				Logger:debug("ALTITUDE: "..altitude)		

			end		
			
			if(speed == nil) then
			
				speed = self._cmdr.Command_Units["ACTIVE"][commandUnitType][name]["speed"]
				Logger:debug("SPEED: "..speed)
				
			end
			
			Logger:debug("DISPATCHER ==== MOVE===")		
			Logger:debug("commandUnitType: " .. commandUnitType)	
			Logger:debug("altitude: " .. altitude)
			Logger:debug("speed: " .. speed)
			
			if(commandUnitType == "CAP" or commandUnitType == "SEAD" or commandUnitType == "ANTISHIP") then
				
				myMission = dctutils.fixedWing.defaultMissionTask()		
				myMission.params.route.points[1]["x"] = point.x
				myMission.params.route.points[1]["y"] = point.z
				myMission.params.route.points[1]["alt"] = altitude
				myMission.params.route.points[1]["alt_type"] = "BARO"
				myMission.params.route.points[1]["speed"] = speed
				myMission.params.route.points[1]["type"] = "Turning Point"
				myMission.params.route.points[1]["action"] = "Turning Point"
				
				task_tbl = dctutils.fixedWing.DefaultTask(commandUnitType)
				utils.tprint(task_tbl)
				orbit_tsk = dctutils.fixedWing.OrbitTask() -- without an orbit task the unit will just RTB upon arrive (with no way to cancel).
				utils.tprint(orbit_tsk)
				
				task_tbl.params.tasks[#task_tbl.params.tasks+1] = orbit_tsk
				--table.insert(task_tbl.params.tasks, Task)
				
				Logger:debug("TASK DUMP")
				utils.tprint(task_tbl)
				
				myMission.params.route.points[1]["task"] = task_tbl
				
				Logger:debug("MISSION DUMP")
				--utils.tprint(myMission)
			
			elseif(commandUnitType == "CAS") then	-- t.b.c
			
			
			end


			CU_Group:getController():setTask(myMission)
			--ROE ------------
			CU_Group:getController():setOption(AI.Option.Air.id.ROE, 0) -- Weapons free - engage at will
			CU_Group:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT, 3) -- Allow evasion, avoidance, will keep any engaged targets from basically being a sitting duck. No kamikaze here.

		else
		
			Logger:debug("DISPATCHER: -- attack_command: invalid name")
		
		end
	
	else
	
		Logger:debug("DISPATCHER: -- attack_command: invalid name")
		
	end
	
end

function Dispatcher:fixedWing_racetrack(commandUnitType, name, point, altitude, speed, heading, leg)
	
	DCS_group_name = self._cmdr.Command_Units["ACTIVE"][commandUnitType][name]["DCS_group_name"]
	Logger:debug(DCS_group_name)
	
	if(DCS_group_name and point and altitude and speed and heading and leg) then
	
		CU_Group = Group.getByName(DCS_group_name)
		
		if(CU_Group) then
		
			-- Race-track requires a 2nd waypoint after the one with the racetrack task
			-- in order to compute where this will be we have to do some trigonometry
			-- with the given heading and leg length.
			
			local angle = math.rad(heading)		
			
			--unit vectors of heading (x,y in mathematical terms, x, z in DCS terms)
			
			point2 = {["x"] = math.cos(angle)*leg + point.x,
					  ["y"] = math.sin(angle)*leg + point.z,
					 }
			
			

			myMission = dctutils.fixedWing.defaultMissionTask()
			myMission.params.route.points[1]["x"] = point.x
			myMission.params.route.points[1]["y"] = point.z
			myMission.params.route.points[1]["alt"] = altitude
			myMission.params.route.points[1]["alt_type"] = "BARO"
			myMission.params.route.points[1]["speed"] = speed
			myMission.params.route.points[1]["type"] = "Turning Point"
			myMission.params.route.points[1]["action"] = "Turning Point"
			myMission.params.route.points[1]["task"] = dctutils.fixedWing.DefaultTask(commandUnitType)

			tasknum = myMission.params.route.points[1]["task"]["params"]["tasks"]
			
			myMission.params.route.points[1]["task"]["params"]["tasks"][#tasknum+1] = dctutils.fixedWing.RacetrackTask(altitude, speed)

			
			myMission.params.route.points[2] = {}
			myMission.params.route.points[2]["x"] = point2.x
			myMission.params.route.points[2]["y"] = point2.y
			myMission.params.route.points[2]["alt"] = altitude
			myMission.params.route.points[2]["alt_type"] = "BARO"
			myMission.params.route.points[2]["speed"] = speed
			myMission.params.route.points[2]["type"] = "Turning Point"
			myMission.params.route.points[2]["action"] = "Turning Point"
			--if(commandUnitType == "Tanker") then
			myMission.params.route.points[2]["task"] = dctutils.fixedWing.EmptyTask()
			--else
			--myMission.params.route.points[2]["task"] = dctutils.fixedWing.DefaultTask(commandUnitType)
			--end
			--myMission.params.route.points[2]["task"]["params"]["tasks"][2] = nil; --don't need this part for 2nd task (kind of tanker specific, but will leave it be for now)

			Logger:debug("MISSION DUMP")
			utils.tprint(myMission)
			
			mytask = CU_Group:getController():setTask(myMission) 
			
		else
		
			Logger:debug("DISPATCHER: -- move_command: invalid name")
		
		end
		
	else
	
		Logger:debug("DISPATCHER: -- move_command: invalid name")
		
	end
end

function Dispatcher:fixedWing_land(commandUnitType, name, point, altitude, speed, heading, leg)
	
	DCS_group_name = self.Command_Units["ACTIVE"][commandUnitType][name]["DCS_group_name"]
	Logger:debug(DCS_group_name)
	
	if(DCS_group_name) then
	
		CU_Group = Group.getByName(DCS_group_name)		

		if(CU_Group) then
		
		myMission = dctutils.fixedWing.defaultMissionTask()		
		myMission.params.route.points[1]["x"] = point.x
		myMission.params.route.points[1]["y"] = point.z
		myMission.params.route.points[1]["type"] = "Land"
		myMission.params.route.points[1]["action"] = "Landing"
		myMission.params.route.points[1]["task"] = {} --dctutils.fixedWing.DefaultTask(commandUnitType) --might need an empty task
		
		nearest_AB = dctutils.getNearestAirbase(point, self.owner)			
		myMission.params.route.points[1]["airdromeId"] = Airbase.getID(nearest_AB)
		
		Logger:debug("MISSION DUMP")
		utils.tprint(myMission)
		
		mytask = CU_Group:getController():setTask(myMission) 		
		CU_Group:getController():setOption(AI.Option.Air.id.REACTION_ON_THREAT, 0) -- Go directly home, do not stop
		CU_Group:getController():setOption(AI.Option.Ground.id.REACTION_ON_THREAT, 0) -- Go directly home, do not stop
		CU_Group:getController():setOption(AI.Option.Naval.id.REACTION_ON_THREAT, 0) -- Go directly home, do not stop
		
		else
		
		Logger:debug("COMMANDER: -- move_command: invalid name")
		
		end
		
	else
		Logger:debug("COMMANDER: -- move_command: invalid name")
	end
	
end



local codenames = { --for naming AI command groups
	"ALPHA",
	"BRAVO",
	"CHARLIE",
	"DELTA",
	"ECHO",
	"FOXTROT",
	"GOLF",
	"HOTEL",
	"INDIA",
	"JULIETT",
	"KILO",
	"LIMA",
	"MIKE",
	"NOVEMBER",
	"OSCAR",
	"PAPA",
	"QUEBEC",
	"ROMEO",
	"SIERRA",
	"TANGO",
	"UNIFORM",
	"VICTOR",
	"WHISKEY",
	"XRAY",
	"YANKEE",
	"ZULU",
}

function Dispatcher:assignCallsign(CUType)
	
	-- Tries names from codenames table until an unused one is found (up to 4)
	-- If no available names, will compound two names at random (e.g: Alpha-Papa) if this one is unavailable
	-- will compound a random number at the end over and over until something is available. e.g (Alpha-Papa-1)(Alpha-Papa-1-2-3-4)
	
	tries = 0
	
	while(true) do
	
		callsign_selected = codenames[math.random(0, #codenames)]
		Logger:debug(callsign_selected)
		
		if(self.ActiveUnits[CUType][callsign_selected] == nil) then
		
			self.ActiveUnits[CUType][callsign_selected] = true;
			
			return callsign_selected
			
		elseif(tries == 4) then-- so many names in use we can't get a free one with 5 random tries
			
			tries = 0
			callsign_selected = codenames[math.random(0, #codenames)].."-"..math.random(0, 9)
				
			while(true) do
				
				if(self.ActiveUnits[CUType][callsign_selected] == nil) then -- very unlikely with a large enough codename base
		
					self.ActiveUnits[CUType][callsign_selected] = true;
					return callsign_selected
								
				else
				
					callsign_selected = callsign_selected.."-"..math.random(0, 9) -- very very unlikely, but will repeat until something unique is formed			
				
				end
				
			end	


			
			
		
		else
		
			tries = tries+1
			
		end
		
	end	

	
end


function Dispatcher:dispatchHelo(template, point, altitude, speed)


end

function Dispatcher:dispatchGround(template, point, altitude, speed)


end

return Dispatcher
