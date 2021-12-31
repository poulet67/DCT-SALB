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
	
	
	
	
	MUST BE COMMANDER, OR COMMANDER MUST BE PUBLIC IN ORDER TO USE THESE:
	
	COMMANDS AVAILABLE:
	parenthesis
	()
	
	SHIPMOVE:(groupname)
	speed?
		
	
	move a ship
	
	MOVE:(groupname)
	
	move the group to the location
	
	FM:(fobname)
	unit name? shorthand? string match?
	number?
	
	
	fire mission, spawn n artillery assets at FOB (fobname) with fire at point waypoint task on this point

	
	--maybe
	SHIPMOVE:(groupname)
	
	
	--maybe
	CONVOY:
	
	--DISPATCH:()
	
	--big maybe
	
	--BAI:()
	--CAP:()
	--SEAD:() 
		
	--maybe
	
	
	
	--]]
	
	--first check valid
			
	valid = string.match(text, "^%d%d%d%d$") or string.match(text, "%a+:%a+")
	
	
	if(valid and initiator) then -- can not run commands for players not in a slot on F10 map
	
		first = string.match(text, "%a+") -- returns everything up to the :
		second = string.match(text, "%p.+") -- returns everything after the :
		
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
		
		-- check if commander is public, if not, check player is commander
		
		if(					false					) then
			
			
			if(					false				) then
			
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
