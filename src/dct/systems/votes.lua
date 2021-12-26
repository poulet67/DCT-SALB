--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Allows for votes to be called among server participants for:
--	-- Theater choices 
--	-- Approve current commander 
-- 	-- Kick current commander
--	-- Surrender (reset mission
--  -- Skip current day/night cycle (coming soon)
)
--]]

local class  = require("libs.namedclass")
local Logger = require("dct.libs.Logger").getByName("UI")

local Vote = class("Vote")
function Vote:__init(theater)
	--votingfor: what is the purpose of this vote?
	self._theater = theater
	self.votes = {}
	self.participants = {}
	self.action = {}
	
end

function Vote:tally()

	
end

function Vote:addVote()

	
end

function Vote:checkUnique()

	
end



return Vote
