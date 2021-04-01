--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Represents the action of defending the target.
-- As long as the target is alive and the timer has expired this action
-- has completed.
--]]

local dctenum = require("dct.enum")
local Action = require("dct.ai.actions.Action")

local DEFAULT_RADIUS  = 55560 -- 30 nautical miles
local DEFAULT_TIMEOUT = 60*90 -- 90 minutes

local DefendAir = require("libs.namedclass")("KillTarget", Action)
function DefendAir:__init(tgtasset, radius, timeout)
	assert(tgtasset ~= nil and tgtasset:isa(require("dct.assets.AssetBase")),
		"tgtasset is not a AssetBase")
	Action.__init(self, tgtasset)
	self.tgtname = tgtasset.name
	self._tgtdead = tgtasset:isDead()
	self.radius = radius or DEFAULT_RADIUS
	self.timer = require("dct.libs.Timer")(timeout or DEFAULT_TIMEOUT)
	tgtasset:addObserver(self.onDCTEvent, self,
		self.__clsname..".onDCTEvent")
end

function DefendAir:enter(msn)
	-- TODO: add mission specific commands; check-in, check-out
	-- and the associated handlers
end

function DefendAir:exit(msn)
	-- TODO: remove mission specific commands
end

function DefendAir:onDCTEvent(event)
	if event.id ~= dctenum.event.DCT_EVENT_DEAD then
		return
	end
	self._logger:debug(self.__clsname..".onDCTEvent: target dead")
	self._tgtdead = event.initiator:isDead()
	event.initiator:removeObserver(self)
	return nil
end

-- Perform check for action completion here
-- Examples: target death criteria, F10 command execution, etc
function DefendAir:complete()
	return (not self._tgtdead) and self.timer:expired()
end

return DefendAir
