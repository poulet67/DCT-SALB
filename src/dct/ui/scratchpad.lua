--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Handles raw player input via a "scratchpad" system. The
-- addition of the F10 menu is handled outside this module.
--]]
--[[
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
		return
	end

	-- will usher players who click "join mission" while having no mission selected to the map marker
	-- Note: if, in the future any further functionality is added to the scratchpad, this will have to be 
	-- re thought a bit.

	local playerasset = self._theater:getAssetMgr():getAsset(name)
	playerasset.scratchpad = sanitize(event.text)
	self:set(event.idx, nil)
	trigger.action.removeMark(event.idx)
	
	if(string.match(event.text,"^%d%d%d%d$")) then-- strictly 4 digits from start to end of string
		
		return -- no action required - the map sniffer will pick it up
		
	else -- TODO: ask kukiric if DCT has a convenient way to send outtext to group (so I can indicate error message here)
	
		trigger.action.outTextForGroup(initiator:getID(),
			"INVALID INPUT: Must be in format #### where # are digits\n\n",
			30, false)
	
	end
end

function ScratchPad:removeMark(id)

	trigger.action.removeMark(event.idx)
	
end

return ScratchPad

--]]
