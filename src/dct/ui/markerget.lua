--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Like the scratch-pad but intended to be initialized only once
-- 
-- queues up text from any map marker post for parsing
-- 
--]]

local class  = require("libs.namedclass")
local Logger = require("dct.libs.Logger").getByName("UI")
local enum    = require("dct.enum")
local uicmds      = require("dct.ui.cmds")
local Command     = require("dct.Command")

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
			self.parse, self, event.text, event.initiator, event.idx))				

	end


end

function MarkerGet:parse(text, initiator, idx)
	Logger:debug("MarkerGet: ----------------------------------- INSIDE PARSE ")
	--[[
	MAP MARKER COMMANDS
	-------------------------
	
	Publicly available:
	
	#### (a 4 didgit number, and nothing else)
	
	Join mission ####
	
	--maybe... debatable value
	abort
	
	--maybe... for recon system
	SPOTTED:(groupname)
	
	-------------------

	
	
	--]]
	
	--first check valid
			
	valid = string.match(text, "^%d%d%d%d$") or string.match(text, "%a+:%a+")
	
	
	if(valid and initiator) then -- can not run commands for players not in a slot on F10 map
	
		first = string.match(text, "%a+") -- returns everything up to the :
		second = string.match(text, "%p.+") -- returns everything after the :
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
		COMMANDER COMMANDS
		-------------------------
		
		MUST BE COMMANDER, OR COMMANDER MUST BE PUBLIC IN ORDER TO USE THESE:
		
		COMMANDS AVAILABLE:
		
		MOVE:
			GROUP:MOVE
			"name" 
				Looks for the nearest DCT asset matching Name and issues a waypoint pushtask to move it to marker position
			
		DISPATCH:
			(only works for defined AI groups)
			required:
			#			<-------- the number selection based on the list command
			
			
			eg:
			
			AWACS:DISPATCH
			4  					
			
			TANKER:DISPATCH
			CAP:DISPATCH
			GROUNDATTACK:DISPATCH
		
			dispatches the current AI type from airbase nearest map marker to the map marker
			
		ORBIT
		
			required:
			#			<-------- the number selection based on the list command
			
			(only works for defined AI groups)
			AWACS:DISPATCH
			
			defaults to 20,000 ft alt.
			
			
			
		RACETRACK
				
			required:
			#			<-------- the number selection based on the list command
			optional:
			HDG:#		<-------- numerical bearing (0-360) along which the racetrack major axis will be flown
								  default: 000
			
			(only works for defined AI groups)
			
			E.G:
			TANKER:RACETRACK
			1
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
			
		
		
		
		
		
		--]]
		
		local playerasset = self._theater:getAssetMgr():getAsset(initiator:getGroup():getName())
		
		Logger:debug("MarkerGet : COMMAND "..first)
		
		validUnitType = enum.commandUnitTypes[first] ~= nil
		
		Logger:debug("MarkerGet : COMMAND "..tostring(validUnitType))				
				
		if((self._theater:getCommander(playerasset.owner):isCommander(playerasset) or self._theater:getCommander(playerasset.owner):isPublic()) and validUnitType) then	-- check player is commander
			
			Logger:debug("MarkerGet : INSIDE")	
			Logger:debug("MarkerGet : second: ".. second)	
			Logger:debug("MarkerGet : second: ".. second)	
			
			remainder = string.match(text, "\n.+$") -- returns everything on the next lines			
			
			if(second == "MOVE") then
			
				unitType = first
				unitSelection = string.sub(string.match(remainder, "type:%d+"), 6) --returns number after "type:" works even with \n inside remainder
				Logger:debug("Unit Selection: " .. unitSelection)
				
				local cmdr = self._theater.getCommander(playerasset.owner)
				
				--self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.dispatch, cmdr, unitType))				

				
				Logger:debug("MarkerGet : COMMAND MOVE ")
				
			elseif(second == "DISPATCH") then
				
				unitType = first
				unitSelection = string.sub(string.match(remainder, "type:%d+"), 6) --returns number after "type:" works even with \n inside remainder
				Logger:debug("Unit Selection: " .. unitSelection)
				
				local cmdr = self._theater.getCommander(playerasset.owner)
				
				self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.dispatch, cmdr, unitType))				
				
				Logger:debug("MarkerGet : COMMAND DISPATCH ")
			
			elseif(second == "ORBIT") then
			
				unitType = first
				unitName = string.sub(string.match(remainder, "name:.+"), 6) --returns number after "name:" works even with \n inside remainder
				
				Logger:debug("Unit Selection: " .. unitName)
				
				local cmdr = self._theater.getCommander(playerasset.owner)
				
				self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.dispatch, cmdr, unitType))				
				
				Logger:debug("MarkerGet : COMMAND ORBIT ")
				
			elseif(second == "RACETRACK") then
			
				unitType = first
				unitName = string.sub(string.match(remainder, "name:.+"), 6) --returns number after "name:" works even with \n inside remainder
				
				Logger:debug("Unit Selection: " .. unitName)
				
				local cmdr = self._theater.getCommander(playerasset.owner)
				
				self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.dispatch, cmdr, unitType))			
				
				Logger:debug("MarkerGet : COMMAND RACETRACK ")
			
			elseif(second == "LAND") then
						
				unitType = first
				unitName = string.sub(string.match(remainder, "name:.+"), 6) --returns number after "name:" works even with \n inside remainder
				
				Logger:debug("Unit Selection: " .. unitName)
				
				local cmdr = self._theater.getCommander(playerasset.owner)
				
				self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.dispatch, cmdr, unitType))			
				
				Logger:debug("MarkerGet : COMMAND LAND")
				
			
			elseif(second == "LIST") then
							
				unitType = first
								
				--Logger:debug("Unit Selection: " .. unitName)
				
				local cmdr = self._theater:getCommander(playerasset.owner)
				
				--self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.getUnitList, cmdr, unitType))			
				
				Logger:debug("MarkerGet : COMMAND LIST")
			
				local msg = cmdr:getUnitList(unitType)
				
				trigger.action.outTextForGroup(playerasset.groupId, msg, 30)
				
				
				--self._theater:queueCommand(self.parse_delay,  Command("MarkerGet: MOVE", cmdr.dispatch, cmdr, unitType))				

				
			elseif(				false					) then
			
			elseif(				false					) then
			
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
