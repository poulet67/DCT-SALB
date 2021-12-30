--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Handles raw player input via a "scratchpad" system. The
-- addition of the F10 menu is handled outside this module.
--]]

local class  = require("libs.namedclass")
local Logger = require("dct.libs.Logger").getByName("UI")
local enum    = require("dct.enum")
local uicmds      = require("dct.ui.cmds")

local function sanitize(txt)
	if type(txt) ~= "string" then
		return nil
	end
	-- only allow: alphanumeric characters, period, hyphen, underscore,
	-- colon, and space
	return txt:gsub('[^%w%.%-_: ]', '')
end

local ScratchPad = class("ScratchPad")
function ScratchPad:__init(theater)
	self._scratchpad = {}
	self._theater = theater
	theater:addObserver(self.event, self, self.__clsname)
	Logger:debug("init "..self.__clsname)
end

function ScratchPad:get(id)
	return self._scratchpad[id]
end

function ScratchPad:set(id, data)
	self._scratchpad[id] = data
end

function ScratchPad:event(event)
	if event.id ~= world.event.S_EVENT_MARK_CHANGE then
		return
	end
	
	
	Logger:debug("SCRATCHPAD: ----------------------------------- DING ")
	
	local name = self:get(event.idx)
	if name == nil then -- no scratchpad for current user
		
		--N.B I am pretty sure this will run for _every_ server user when a map mark changes making it a bit
		-- clunky. 
		
		--I am planning on adding a similar sort of "scratch pad" which is really more like a "map marker sniffer"
		--for each of the commanders. This functionality could be ported over there so it doesn't have to execute
		--every single time a command is executed.
		
		-- I also may just rename ScratchPad to "UserInput" because that's what it really is, now that I've chopped all the other bits out
		-- Still debating what to do with it
		
		
		if(string.match(event.text,"^%d%d%d%d$")) then-- strictly 4 digits from start to end of string
			
			name = event.initiator:getGroup():getName()				

			Logger:debug("SCRATCHPAD: name" .. name)
			
			data = {
					["name"]   = name,
					["type"]   = enum.uiRequestType.MISSIONJOIN, --que mission join
				}
				
			local cmd = uicmds[data.type](self._theater, data)
			
			local playerasset = self._theater:getAssetMgr():getAsset(name)
			playerasset.scratchpad = event.text
			--self:set(event.idx, self.asset.name)
			trigger.action.removeMark(event.idx)
			
			self._theater:queueCommand(0.5, cmd)	
			
			--require("dct.Theater").singleton().playerRequest(data)
			
			--self._theater.singleton():playerRequest(data) -- not sure why it doesn't work?
		
		end
	
		return
	end

	local playerasset = self._theater:getAssetMgr():getAsset(name)
	playerasset.scratchpad = sanitize(event.text)
	self:set(event.idx, nil)
	trigger.action.removeMark(event.idx)
	
	if(string.match(event.text,"^%d%d%d%d$")) then-- strictly 4 digits from start to end of string
		
		data = {
				["name"]   = name,
				["type"]   = enum.uiRequestType.MISSIONJOIN, --que mission join
			}
			
		local cmd = uicmds[data.type](self._theater, data)
		
		self._theater:queueCommand(0.5, cmd)	
		
		--require("dct.Theater").singleton().playerRequest(data)
		
		--self._theater.singleton():playerRequest(data) -- not sure why it doesn't work?
		
	else -- TODO: ask kukiric if DCT has a convenient way to send outtext to group (so I can indicate error message here)
	
		
	
	end
end

function ScratchPad:parse(text, initiator, idx)

--    if event.id == world.event.S_EVENT_MARK_REMOVE then
--       Mark_Obj:remove(event.idx)
--    elseif event.id == world.event.S_EVENT_MARK_CHANGE then
--       	Mark_Obj:modify(event.idx, event.text, event.pos)
--    elseif event.id == world.event.S_EVENT_MARK_ADDED then
--       	Mark_Obj:modify(event.idx, event.text, event.pos)		
--    end
	self._counter = 0 -- gonna need a system to prevent map mark spam shutting down the server

-- this is going to be ugly af
	--txt:gsub('[^%w%.%-_: ]', '')
	
	
	
	Logger:debug("SCRATCHPAD: ----------------------------------- INSIDE PARSE ")



end

function ScratchPad:removeMark(id)

	trigger.action.removeMark(event.idx)
	
end

return ScratchPad
