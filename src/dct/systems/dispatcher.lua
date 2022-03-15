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

function Dispatcher:dispatchFixedWing(template, point, altitude, speed)

	Logger:debug("DISPATCHER ==== Dispatch===")
	
	if(altitude == nil) then
	
		--altitude = settings.gameplay["COMMAND_UNIT_DEFAULT_ALTITUDE"]
		
		altitude = 6000
		
	end
	
	if(speed == nil) then
	
		speed = 100 -- ~= 200 kn 
		
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
	
	--Logger:debug("TEMPLATE DUMP")
	--utils.tprint(template) 
	
end

function Dispatcher:fixedWingmove(commandUnitType, point, altitude, speed)

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
	
	return myMission
	
end

function Dispatcher:fixedWingattack(commandUnitType, point, altitude, speed)

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
	
	return myMission
	
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
