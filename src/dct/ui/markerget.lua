--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Map marker sniffer - 
-- 
-- queues up text from any map marker post for parsing
-- 
--]]

local class  = require("libs.namedclass")
local Logger = require("dct.libs.Logger").getByName("UI")
local enum    = require("dct.enum")
local uicmds      = require("dct.ui.cmds")
local Command     = require("dct.Command")
local CLI     = require("dct.ui.CLI")
local dctutils   = require("dct.utils") 
local settings    = _G.dct.settings

local function sanitize(txt)
	if type(txt) ~= "string" then
		return nil
	end
	-- only allow: alphanumeric characters, period, hyphen, underscore,
	-- colon, and space
	return txt:gsub('[^%w%.%-_: ]', '')
end

local MarkerGet = class("MarkerGet")
function MarkerGet:__init(theater)
	self.parse_delay = 0.5 -- might want to build a "command pending" type system like the F10 menu has to prevent map menu spam exploits
	self._MarkerGet = {}
	self._theater = theater
	theater:addObserver(self.event, self, self.__clsname)
	Logger:debug("init "..self.__clsname)
end

--[[

function MarkerGet:get(id)
	return self._MarkerGet[id]
end

function MarkerGet:set(id, data)
	self._MarkerGet[id] = data
end
]]--

function MarkerGet:event(event)

	if event.id ~= world.event.S_EVENT_MARK_CHANGE then
		return
	else	
	
		self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: parse",
			self.parse, self, event.text, event.initiator, event.idx, event.pos))				

	end


end

function MarkerGet:parse(text, initiator, idx, point)
	
	Logger:debug("MarkerGet: ----------------------------------- INSIDE PARSE ")
	--
	-- TODO: use lummander instead... This is pretty hacky 
	
	--[[
	MAP MARKER COMMANDS
	-------------------------
	
	Publicly available:
	
	HELP
	
	explains the F10 marker command system and lists all available commands
	
	--------------------------------------

	MISSION SYSTEM:
	=============
	
	#### (a 4 didgit number, and nothing else)
	-------------------
	Join mission ####
	
	MISSION:ABORT
	
	
		Squadron Leader Commands:
		
		
	
	
	RECON SYSTEM:
	============
	SPOTTED:TEXT
	Looks for enemy ground near 
	Allows a user to spot an enemy unit and have it added to the commander's known list
	Needs a minimum range requirement.
	Optional: a cooldown between spots
	Optional & Recommended: a penalty if player 'cries wolf'
		
	
	
	

	
	-------------------

	
	
	--]]
	
	--first check valid
			
	valid = string.match(text, "^%d%d%d%d$") or string.match(text, "%a+:%a+")
	
	Logger:debug("MarkerGet : Valid Command: "..tostring(valid))
	
	if(valid and initiator) then -- can not run commands for players not in a slot on F10 map
	
		first = string.match(text, "%a+") -- returns everything up to the :
		second = string.match(text, ":%w+") -- returns everything after the :
		second = second:sub(2)
		
		
		if(string.match(valid, "^%d%d%d%d$")) then
			
			--MISSION Join
			
			name = initiator:getGroup():getName()				

			Logger:debug("MarkerGet : MISSION JOIN " .. tostring(name))

			
			data = {
					["name"]   = name,
					["type"]   = enum.uiRequestType.MISSIONJOIN, --que mission join
				}
				
			local cmd = uicmds[data.type](self._theater, data)
			
			local playerasset = self._theater:getAssetMgr():getAsset(name)
			playerasset.cmddata = {["MSN"] = text}
			
			trigger.action.removeMark(idx)
			
			self._theater:queueCommand(0.5, cmd)	
			
		elseif(string.match(valid, "^MISSION:BOARD$")) then
			
			--SHOW missionboard (for convenience)
			
			name = initiator:getGroup():getName()				

			Logger:debug("MarkerGet : MISSION BOARD " .. tostring(name))

			
			data = {
					["name"]   = name,
					["type"]   = enum.uiRequestType.MISSIONBOARD, --queue mission join
				}
				
			local cmd = uicmds[data.type](self._theater, data)
			
			local playerasset = self._theater:getAssetMgr():getAsset(name)
			--playerasset.cmddata = {["MSN"] = text}
			trigger.action.removeMark(idx)
			
			self._theater:queueCommand(0.5, cmd)	
			
		elseif(string.match(valid, "^MISSION:ABORT$")) then
			
			--ABORT (for convenience)
			
			name = initiator:getGroup():getName()				

			Logger:debug("MarkerGet : MISSION BOARD " .. tostring(name))

			
			data = {
					["name"]   = name,
					["type"]   = enum.uiRequestType.MISSIONABORT, 
					["value"]  = enum.missionAbortType.ABORT,
				}
				
			local cmd = uicmds[data.type](self._theater, data)
			
			local playerasset = self._theater:getAssetMgr():getAsset(name)
			--playerasset.cmddata = {["MSN"] = text}
			trigger.action.removeMark(idx)
			
			self._theater:queueCommand(0.5, cmd)	
			

			
		end
		

	
		--[[
		COMMANDER SYSTEM
		================
		
		Mission Control:
		
		MISSION
		
		
		
		===================
		AI Unit Commands:
		
		Note: All units will remember their specified ALT and SPD, so if specified once, will not need to specify on future commands
		
		Works on 
		
		MOVE
			GROUP:MOVE
			"name" 
				Looks for the active command unit matching Name and issues an orbit pushtask to move it to marker position N.B <--- Must be given an orbit task or will immediatley RTB.
			
		DISPATCH
			(only works for defined AI groups)
			required:
			TYPE: #			<-------- the number selection based on the list command
			
			
			eg:
			
			AWACS:DISPATCH
			TYPE: 4  					
			
			TANKER:DISPATCH
			CAP:DISPATCH
			ANTISHIP:DISPATCH
		
			dispatches the current AI type from airbase nearest map marker to the map marker
						
			
			
		RACETRACK
				
			required:
			#			<-------- the number selection based on the list command
			optional:
			HDG:#		<-------- numerical bearing (0-360) along which the racetrack major axis will be flown
								  default: 000
			
			(only works for defined AI groups)
			
			E.G:
			TANKER:RACETRACK
			TYPE: 1
			HDG:90
			
			
		LAND
						
			required:
			"NAME"		<----- the quick reference name given to the AI group
			
			
			(only works for defined AI groups)
			AWACS:LAND
			TANKER:LAND
			CAP:LAND
			
		LIST
			(only works for defined AI groups)
						
			AWACS:LIST
			CAP:LIST
			TANKER:LIST
			
			
		ACTIVE
			(only works for defined AI groups)
						
			AWACS:ACTIVE
			CAP:ACTIVE
			TANKER:ACTIVE
			
		ATTACK
			(only works for defined AI groups)
						
			CAP:ATTACK
			ANTISHIP:ATTACK
			SEAD:ATTACK
			
		
		===================
		
		===================
		FOB Commands:
		
		FOB:NEW
		
		================
		
		===================
		SAM Commands:
		
		SAM:NEW
		
		================
		
		===================
		FARP Commands:
		
		FARP:NEW
		
		================
		
		===================
		FSB Commands:
		
		FSB:NEW
				
		
		================
		
		
		
		--]]
		
		local playerasset = self._theater:getAssetMgr():getAsset(initiator:getGroup():getName())
		
		Logger:debug("MarkerGet : COMMAND "..first)
		
		validUnitType = enum.commandUnitTypes[first] ~= nil
		
		Logger:debug("MarkerGet : COMMAND "..tostring(validUnitType))				
				
		if((self._theater:getCommander(playerasset.owner):isCommander(playerasset) or self._theater:getCommander(playerasset.owner):isPublic()) and validUnitType) then	-- check player is commander
			
			Logger:debug("MarkerGet : INSIDE")	
			Logger:debug("MarkerGet : second: ".. second)	
			
			remainder = string.match(text, "\n.+$") -- returns everything on the next lines			
			
			-- COMMANDER COMMANDS _---------------------------------------------------------------------------------------------------------
			
			if(second == "DISPATCH" and remainder) then
				
				unitType = first
				sel = string.match(remainder, "TYPE:%d+")
				alt = string.match(remainder, "ALT:%w+")
				spd = string.match(remainder, "SPD:%w+")
				
				if sel then
				
					unitSelection = tonumber(string.sub(sel, 6)) --returns number after "TYPE:" works even with \n inside remainder
					
				else
				
					trigger.action.outTextForGroup(playerasset.groupId, "Unit selection invalid. Try UnitType:List to see all available unit types\n Type HELP into an F10 marker for info on the command system", 30)
					
				end
				
				if alt then
				
					altitude = tonumber(string.sub(alt, 5)) --returns number after "TYPE:" works even with \n inside remainder
								
				end
				
				if spd then
				
					speed = tonumber(string.sub(spd, 5)) --returns number after "TYPE:" works even with \n inside remainder
					
				end
				
				
				if(unitSelection) then --valid input
				
					Logger:debug("MarkerGet : DISPATCH")
					Logger:debug("Unit Selection: " .. unitSelection)
					Logger:debug("Unit Type: " .. unitType)
					Logger:debug("value: " .. enum.commandUnitTypes[unitType])
				
					local cmdr = self._theater:getCommander(playerasset.owner)
					
					--for k,v in pairs(cmdr.Command_Units) do					
					--	Logger:debug("Command Unit: " .. k)					
					--end					
					--for k,v in pairs(cmdr.Command_Units[enum.commandUnitTypes[unitType]]) do					
					--	Logger:debug("Command Unit 2: " .. k)					
					--end					
					--for k,v in pairs(cmdr.Command_Units[enum.commandUnitTypes[unitType]][unitSelection]) do					
					--	Logger:debug("Command Unit 3: " .. k)					
					--end
 					
					Logger:debug("Type: " .. type(cmdr.Command_Units[unitType][tonumber(unitSelection)]))
					
					if cmdr.Command_Units[unitType][unitSelection] then -- valid selection
					
						Logger:debug("MarkerGet : VALID UNIT")
						self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: DISPATCH", cmdr.dispatch, cmdr, unitType, unitSelection, point, altitude, speed))				
						trigger.action.removeMark(idx)
						
					else
					
						trigger.action.outTextForGroup(playerasset.groupId, "Unit type or unit selection invalid. Try UnitType:List to see all available unit types type HELP into an F10 marker for info on the command system", 30)
					
					end
				
				else
				
					trigger.action.outTextForGroup(playerasset.groupId, "Unit type or unit selection invalid. Try UnitType:List to see all available unit types type HELP into an F10 marker for info on the command system", 30)
					
				end
			
			elseif(second == "MOVE" and remainder) then
				
				Logger:debug("MOVE COMMAND")
				unitType = first
				Logger:debug(remainder)
				name = string.match(remainder, "\"%a+\"") -- returns anything inside double quotes "" 
				alt = string.match(remainder, "ALT:%w+")
				spd = string.match(remainder, "SPD:%w+")
								
				if alt then
				
					Logger:debug("ALTITUDE")
					
					alt = string.sub(alt, 5) --returns number after "ALT:" works even with \n inside remainder
					altitude = tonumber(string.match(alt, "%d+"))
					units = string.match(alt, "%a+")
					
					if units then
					
						altitude = dctutils.convertDistance(altitude, units, "m")
					
					else
					
						altitude = dctutils.convertDistance(altitude, "ft", "m")
						
					end
				
				
				end
				
				if spd then
				
					Logger:debug("SPEED")
					
					spd = string.sub(spd, 5) --returns number after "SPD:" works even with \n inside remainder
					speed = tonumber(string.match(spd, "%d+"))
					units = string.match(spd, "%a+")
					
					if units then
					
						speed = dctutils.convertSpeed(speed, units, "ms")
					
					else	
					
						speed = dctutils.convertSpeed(speed, "kn", "ms")
						
					end
					
				end		
				
				local cmdr = self._theater:getCommander(playerasset.owner)
				
				if(unitType and name) then

					name = name:sub(2,name:len()-1) --removes the double quotes "
													
					Logger:debug("name: " .. name)
					Logger:debug("altitude: " .. altitude)
					Logger:debug("speed: " .. speed)
					
					if(cmdr.Command_Units["ACTIVE"][unitType][name]) then
					
						self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.move_command, cmdr, unitType, name, point, altitude, speed))				
						trigger.action.removeMark(idx)
						
					else
					
						trigger.action.outTextForGroup(playerasset.groupId, "Invalid unit name. This name is the last word or word combination in the group field when selected on a an F10 map marker. They must be passed in quotes, ex: \"ALPHA\"", 30)
					
					end
					
				else				
					
					trigger.action.outTextForGroup(playerasset.groupId, "Unit type or callsign/name or speed or altitude units are invalid. Try UnitType:List to see all available unit types or type HELP into an F10 marker for info on the command system. Callsigns/names are the last word or word combination in the group field when selected ona an F10 map marker. They must be passed in quotes, ex: \"ALPHA\"", 30)
					
				end	

			elseif(second == "ATTACK" and remainder) then
				
				Logger:debug("MOVE COMMAND")
				unitType = first
				Logger:debug(remainder)
				name = string.match(remainder, "\"%a+\"") -- returns anything inside double quotes "" 
				alt = string.match(remainder, "ALT:%w+")
				spd = string.match(remainder, "SPD:%w+")
								
				if alt then
				
					Logger:debug("ALTITUDE")
					
					alt = string.sub(alt, 5) --returns number after "ALT:" works even with \n inside remainder
					altitude = tonumber(string.match(alt, "%d+"))
					units = string.match(alt, "%a+")
					
					if units then
					
						altitude = dctutils.convertDistance(altitude, units, "m")
					
					else
					
						altitude = dctutils.convertDistance(altitude, "ft", "m")
						
					end
				
				
				end
				
				if spd then
				
					Logger:debug("SPEED")
					
					spd = string.sub(spd, 5) --returns number after "SPD:" works even with \n inside remainder
					speed = tonumber(string.match(spd, "%d+"))
					units = string.match(spd, "%a+")
					
					if units then
					
						speed = dctutils.convertSpeed(speed, units, "ms")
					
					else	
					
						speed = dctutils.convertSpeed(speed, "kn", "ms")
						
					end
					
				end		
				
				local cmdr = self._theater:getCommander(playerasset.owner)
				
				if(unitType and name) then

					name = name:sub(2,name:len()-1) --removes the double quotes "
													
					Logger:debug("name: " .. name)
					Logger:debug("altitude: " .. altitude)
					Logger:debug("speed: " .. speed)
					
					if(cmdr.Command_Units["ACTIVE"][unitType][name]) then
					
						self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: ATTACK", cmdr.attack_command, cmdr, unitType, name, point, altitude, speed))
						trigger.action.removeMark(idx)
						
					else
					
						trigger.action.outTextForGroup(playerasset.groupId, "Invalid unit name. This name is the last word or word combination in the group field when selected on a an F10 map marker. They must be passed in quotes, ex: \"ALPHA\"", 30)
					
					end
					
				else				
					
					trigger.action.outTextForGroup(playerasset.groupId, "Unit type or callsign/name or speed or altitude units are invalid. Try UnitType:List to see all available unit types or type HELP into an F10 marker for info on the command system. Callsigns/names are the last word or word combination in the group field when selected ona an F10 map marker. They must be passed in quotes, ex: \"ALPHA\"", 30)
					
				end
			
			-- OBSOLETE: MOVE command will be given this behavior and ATTACK command till replace MOVE for units that have an offensive capability.
			--[[
			elseif(second == "ORBIT" and remainder) then
			
				Logger:debug("ORBIT COMMAND")
				unitType = first
				name = string.match(remainder, "\"%a+\"") -- returns anything inside double quotes "" 
				alt = string.match(remainder, "ALT:%w+")
				spd = string.match(remainder, "SPD:%w+")
								
				if alt then
				
					alt = string.sub(alt, 5) --returns number after "ALT:" works even with \n inside remainder
					altitude = tonumber(string.match(alt, "%d+"))
					units = string.match(alt, "%a+")
					
					if units then
					
						altitude = dctutils.convertDistance(altitude, units, "m")
					
					else
					
						altitude = dctutils.convertDistance(altitude, "ft", "m")
						
					end
				else
				
					altitude = settings.gameplay["COMMAND_UNIT_DEFAULT_ALTITUDE"]
					
				end
				
				if spd then
				
					spd = string.sub(spd, 5) --returns number after "SPD:" works even with \n inside remainder
					speed = tonumber(string.match(spd, "%d+"))
					units = string.match(spd, "%a+")
					
					if units then
					
						speed = dctutils.convertSpeed(speed, units, "ms")
					
					else	
					
						speed = dctutils.convertSpeed(speed, "kn", "ms")
						
					end
					
				else
				
					speed = settings.gameplay["COMMAND_UNIT_DEFAULT_SPEED"]					
					
				end				
				
				Logger:debug("type: " .. unitType)
				Logger:debug("name: " .. name)
				
				if(unitType and name) then
				
					name = name:sub(2,name:len()-1) --removes the double quotes "
					local cmdr = self._theater:getCommander(playerasset.owner)
					self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.orbit_command, cmdr, unitType, name, point, altitude, speed))				
					trigger.action.removeMark(idx)
					
				else				
					
					trigger.action.outTextForGroup(playerasset.groupId, "Unit type or callsign/name is invalid. Try UnitType:List to see all available unit types or type HELP into an F10 marker for info on the command system. Callsigns/names are the last word or word combination in the group field when selected ona an F10 map marker. They must be passed in quotes, ex: \"ALPHA\"", 30)
					
				end
				--]]
				
			elseif(second == "RACETRACK" and remainder) then
			
				Logger:debug("RACETRACK COMMAND")
				unitType = first
				name = string.match(remainder, "\"%a+\"") -- returns anything inside double quotes "" 
				alt = string.match(remainder, "ALT:%w+")
				spd = string.match(remainder, "SPD:%w+")
				hdg = string.match(remainder, "HDG:%d+")
				leg = string.match(remainder, "LEG:%d+")
												
				if alt then
				
					alt = string.sub(alt, 5) --returns number after "ALT:" works even with \n inside remainder
					altitude = tonumber(string.match(alt, "%d+"))
					units = string.match(alt, "%a+")
					
					if units then
					
						altitude = dctutils.convertDistance(altitude, units, "m")
					
					else
					
						altitude = dctutils.convertDistance(altitude, "ft", "m")
						
					end
					
				end
				
				if spd then
				
					spd = string.sub(spd, 5) --returns number after "SPD:" works even with \n inside remainder
					speed = tonumber(string.match(spd, "%d+"))
					units = string.match(spd, "%a+")
					
					if units then
					
						speed = dctutils.convertSpeed(speed, units, "ms")
					
					else	
					
						speed = dctutils.convertSpeed(speed, "kn", "ms")
						
					end			
					
				end	
				
				if hdg then
				
					hdg = string.sub(hdg, 5) --returns number after "HDG:" works even with \n inside remainder
					hdg = tonumber(string.match(hdg, "%d+"))
					
				else
				
					hdg = 0; -- North
					
				end	
				
				if leg then
				
					leg = string.sub(leg, 5) --returns number after "HDG:" works even with \n inside remainder
					leg = tonumber(string.match(leg, "%d+"))
					units = string.match(spd, "%a+")
					
					if units then
					
						leg = dctutils.convertDistance(leg, units, "m")
					
					else
					
						leg = dctutils.convertDistance(leg, "nm", "m")
						
					end
				
				else
				
					leg = 74080 --40 nm
					
				end			
				
				if(unitType and name) then
				
					Logger:debug("type: " .. unitType)
					Logger:debug("name: " .. name)
					
					name = name:sub(2,name:len()-1) --removes the double quotes "
					local cmdr = self._theater:getCommander(playerasset.owner)	
					self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.racetrack_command, cmdr, unitType, name, point, altitude, speed, hdg, leg))	
					trigger.action.removeMark(idx)
					
				else				
					
					trigger.action.outTextForGroup(playerasset.groupId, "Unit type or callsign/name is invalid. Try UnitType:List to see all available unit types or type HELP into an F10 marker for info on the command system. Callsigns/names are the last word or word combination in the group field when selected ona an F10 map marker. They must be passed in quotes, ex: \"ALPHA\"", 30)
					
				end
				
			
			elseif(second == "LAND" and remainder) then
				
				Logger:debug("LAND COMMAND")
				unitType = first
				name = string.match(remainder, "\"%a+\"") -- returns anything inside double quotes "" 
				
				Logger:debug("type: " .. unitType)
				Logger:debug("name: " .. name)
				
				if(unitType and name) then
				
					name = name:sub(2,name:len()-1) --removes the double quotes "
					local cmdr = self._theater:getCommander(playerasset.owner)	
					self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: LAND", cmdr.landing_command, cmdr, unitType, name, point))	
					trigger.action.removeMark(idx)
					
				else				
					
					trigger.action.outTextForGroup(playerasset.groupId, "Unit type or callsign/name is invalid. Try UnitType:List to see all available unit types or type HELP into an F10 marker for info on the command system. Callsigns/names are the last word or word combination in the group field when selected ona an F10 map marker. They must be passed in quotes, ex: \"ALPHA\"", 30)
					
				end
				
			
			elseif(second == "LIST") then
							
				unitType = first
								
				--Logger:debug("Unit Selection: " .. unitName)
				
				local cmdr = self._theater:getCommander(playerasset.owner)
				
				--self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.getUnitList, cmdr, unitType))			
				
				Logger:debug("MarkerGet : COMMAND LIST")
			
				local msg = cmdr:getUnitList(unitType)
				
				trigger.action.removeMark(idx)				
				trigger.action.outTextForGroup(playerasset.groupId, msg, 30)
				
				
				--self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.dispatch, cmdr, unitType))				

			
			elseif(second == "ACTIVE") then
							
				unitType = first
								
				--Logger:debug("Unit Selection: " .. unitName)
				
				local cmdr = self._theater:getCommander(playerasset.owner)
				
				--self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.getUnitList, cmdr, unitType))			
				
				Logger:debug("MarkerGet : COMMAND LIST")
			
				local msg = cmdr:getActiveUnits(unitType)
				
				trigger.action.removeMark(idx)				
				trigger.action.outTextForGroup(playerasset.groupId, msg, 30)
				
				
				--self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.dispatch, cmdr, unitType))				

				
			elseif(first == "COMMAND" and second == "LIST") then --list available command units
			
			elseif(first == "MISSION" and second == "TOT") then
			
			elseif(first == "MISSION" and second == "BRIEFING") then
			
			elseif(first == "MISSION" and second == "") then
			
			elseif(first == "MISSION" and second == "TOT") then
			
			elseif(first == "MISSION" and second == "TOT") then
			
			elseif(				false					) then
			
			elseif(				false					) then
			
			elseif(				false					) then
			
			elseif(				false					) then
			
			elseif(				false					) then
			
			elseif(				false					) then
			
			elseif(				false					) then
			
			elseif(				false					) then
			
			end
			
		end
	
	end
	
end

function MarkerGet:removeMark(id)

	trigger.action.removeMark(event.idx)
	
end

return MarkerGet
