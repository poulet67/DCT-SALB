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
local enum        = require("dct.enum")
local Command     = require("dct.Command")

local Vote = class("Vote")
function Vote:__init(cmdr, theater)

	self._theater = theater
	self._cmdr = cmdr
	self.currentvote = "No active votes currently"
	self.votes = {} --True == yes, false == no
	self.action = {}
	self.cd_table = {} -- who is on cooldown from vote calling
		
	Logger:debug("Vote init: ")
	
	self.action = {

		[enum.voteType["PUBLIC"]["Request Command"]] = Command("Vote result: request command default", nothing),
		[enum.voteType["PUBLIC"]["Kick Commander"]] = true,
		[enum.voteType["PUBLIC"]["Surrender"]] = true,
		[enum.voteType["PRIVATE"]["Other"]] = Command("Vote result: Other, Default", nothing), -- externally sestable, default to nothing
		--enum.voteType["PRIVATE"]["Decision"] = false,
	}	
	
	self.message = {
		
		[enum.voteType["PUBLIC"]["Request Command"]] = "Vote: Give command",
		[enum.voteType["PUBLIC"]["Kick Commander"]] = "Vote: Kick current commander",
		[enum.voteType["PUBLIC"]["Surrender"]] =  "Vote: Surrender",
		[enum.voteType["PRIVATE"]["Other"]] = "Vote:", -- externally setable, default to nothing
		--enum.voteType["PRIVATE"]["Decision"] = false,
		
	}
	
end

function nothing() 

end

function Vote:tally(voteType)
		
	local percent = dct.settings.gameplay["VOTE_PERCENTAGE_REQUIRED"]
	local numbervotes = 0
	
	
	for k,v in pairs(self.votes) do
		
		if(v) then
		
			numberyes = numberyes + 1
			
		end
		
		numbervotes = numbervotes+1
		
	end
	
	if(numberyes/numbervotes > percent) then
	
		trigger.OutTextForCoalition(self.cmdr.owner, "VOTE PASSED!")
		self._theater.singleton():queueCommand(1, self.action[voteType])
		self.votes = {}		
		self.currentvote = "No active votes currently"	
	
	else
	
		trigger.OutTextForCoalition(self.cmdr.owner, "VOTE DEFEATED!")
		self.votes = {}		
		self.currentvote = "No active votes currently"	
		
	end
	
	
end

function Vote:addVote(voter, voteVal)
	
	if(self.votes[voter] ~= nil) then
	
		return "You have already voted!"
	
	else
		
		self.votes[voter] = voteVal
		
		return "Your vote has been added" 
	
	end

end


function Vote:playerassetToUcid(player)

	return get_player_info(vote_initiator.id, "ucid")

end

function Vote:cooldown(ucid)
	
	self.cd_table[ucid] = true
	self._theater:queueCommand(dct.settings.gameplay["VOTE_PLAYER_COOLDOWN"],
		Command("VOTE-- cooldown player" .. ucid, self.cold, self, player))	
	
end

function Vote:cold(ucid)
	
	self.cd_table[ucid] = nil
	
end

function Vote:callVote(voteType, vote_initiator)
	
	Logger:debug("Vote called, type: %d ", voteType)
	
	if(net == nil) then --SP or MP?		
		
		Logger:debug("Single Player?")
		
	else
		
		Logger:debug("-- MULTI-PLAYER! --")
		init_ucid = net.get_player_info(vote_initiator.id, 'ucid')
		Logger:debug("-- UCID --"..init_ucid)
		
	end
	
	if(self.cd_table[init_ucid]) then -- check if on cooldown -- go off ucid maybe?
			
		Logger:debug("Player on cooldown")
		
		return "You have already called a vote recently and may not call aother vote for a while"
		
	else
	
		self:cooldown(init_ucid)		
		
	end
	
	if(self.currentvote ~= "No active votes currently") then
	
		return "A vote is already in progress"
	
	end
	
	msg = vote_initiator.name.."has called a vote!/n"
	
	if(voteType == enum.voteType["PUBLIC"]["Request Command"]) then
		
		self.action[enum.voteType["PUBLIC"]["Request Command"]] = Command("Vote result: request command player"..vote_initiator.name, self._cmdr.assignCommander(), vote_initiator.name)
		
		self._theater:queueCommand(dct.settings.gameplay["VOTE_TIME"],
			Command("VOTE-- vote type, player ".. voteType .. vote_initiator.name, self.tally, self, voteType))
		
		self.currentvote = msg..self.message[voteType]
		
		trigger.OutTextForCoalition(vote_initiator.owner, self.currentvote)
		
		return "Vote Started!"
		
	elseif(voteType == enum.voteType["PUBLIC"]["Kick Commander"]) then
	
		self.action[enum.voteType["PUBLIC"]["Request Command"]] = Command("Vote result: request command player"..vote_initiator.name, self._cmdr.kickCommander())
		
		self._theater:queueCommand(dct.settings.gameplay["VOTE_TIME"],
			Command("VOTE-- vote type, player ".. voteType .. player, self.tally, self, voteType))
			
		self.currentvote = msg..self.message[voteType]
		
		trigger.OutTextForCoalition(vote_initiator.owner, self.currentvote)
		
		return "Vote Started!"
		
	elseif(voteType == enum.voteType["PUBLIC"]["Surrender"]) then
		Logger:debug("-- surrender monkey --")
		self.action[enum.voteType["PUBLIC"]["Request Command"]] = Command("Vote result: surrender"..vote_initiator.name, self._cmdr.surrender(), self._cmdr)
		Logger:debug("-- wut --")
		
		self._theater:queueCommand(dct.settings.gameplay["VOTE_TIME"],
			Command("VOTE-- vote type, player ".. voteType .. player, self.tally, self, voteType))
		
		self.currentvote = msg..self.message[voteType]
		
		trigger.OutTextForCoalition(vote_initiator.owner, self.currentvote)
		
		return "Vote Started!"
		
	elseif(voteType == enum.voteType["PRIVATE"]["Other"]) then
		
		--actions needs to be filled in (by whatever external source is summoning it) before vote is tallied or nothing will happen
				
		self._theater:queueCommand(dct.settings.gameplay["VOTE_TIME"],
			Command("VOTE-- vote type, player ".. voteType .. vote_initiator.name, self.tally, self, voteType))
		
		self.currentvote = msg..self.message[voteType]
		
		trigger.OutTextForCoalition(player.coalition, self.currentvote)
		
		return "Vote Started!"
		
	else
		
		return nil
	
	end
	
end

return Vote
