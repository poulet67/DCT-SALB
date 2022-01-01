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
	self.active = false
	self.votes = {} --True == yes, false == no
	self.n_yes = 0
	self.n_voted = 0
	self.cd_table = {} -- who is on cooldown from vote calling
		
	Logger:debug("Vote init: ")
	
	self.action = {

		[enum.voteType["PUBLIC"]["Request Command"]] = Command("Vote result: request command default", nothing),
		[enum.voteType["PUBLIC"]["Kick Commander"]] = true, -- we will fill in player info
		[enum.voteType["PUBLIC"]["Surrender"]] = true, -- we will fill in player info
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

	Logger:debug("VOTE: -------- TALLY")
	Logger:debug("voteType:  "..voteType)
	Logger:debug("voteType:  "..voteType)
	
	local percent = dct.settings.gameplay["VOTE_PERCENTAGE_REQUIRED"]

	if(self.n_yes/self.n_voted > percent) then
	
		trigger.action.outTextForCoalition(self._cmdr.owner, "VOTE PASSED!", 30)
		self._theater:queueCommand(1, self.action[voteType])
		self:reset()
	
	else
	
		trigger.action.outTextForCoalition(self.cmdr.owner, "VOTE DEFEATED!", 30)
		self:reset()	
		
	end
	
	
end

function Vote:reset()

	Logger:debug("VOTE: -------- Reset")
	self.votes = {}
	self.currentvote = "No active votes currently"	
	self.n_voted = 0
	self.n_yes = 0
	self.active = false
	
	
end

function Vote:addVote(voter, voteVal)
	
	player_ucid = net.get_player_info(voter.id, 'ucid')	
	
	if(self.votes[player_ucid] ~= nil) then
	
		self.votes[player_ucid] = voteVal	
		
		if(self.votes[player_ucid] == voteVal) then
		
			return "Your vote has not changed" 
		
		else
			
			if(voteVal == true) then
				self.n_yes = self.n_yes + 1
			else			
				self.n_yes = self.n_yes - 1
			end
			
			return "Your vote has been changed" 
		
		end
	
	else
		
		if(voteVal) then 
			self.n_yes = self.n_yes + 1
			self.n_voted = self.n_voted + 1
		else
			self.n_voted = self.n_voted + 1
		end		
			
		self.votes[player_ucid] = voteVal	
				
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
		ptable = net.get_player_info(vote_initiator.id)
		pname = ptable.name
		pucid = ptable.ucid
		pside = ptable.side
		Logger:debug("-- UCID --"..pucid)
		
	end
	
	if(self.cd_table[pucid]) then -- check if on cooldown -- go off ucid maybe?
			
		Logger:debug("Player on cooldown")
		
		return "You have already called a vote recently and may not call aother vote for a while"
		
	else
	
		self:cooldown(pucid)		
		
	end
	
	if(self.active) then
	
		return "A vote is already in progress"
	
	end
	
	msg = pname.." has called a vote!\n"
	
	if(voteType == enum.voteType["PUBLIC"]["Request Command"]) then
		
		self.action[enum.voteType["PUBLIC"]["Request Command"]] = Command("Vote result: request command player"..pname, self._cmdr.assignCommander, pname)
		
		self._theater:queueCommand(dct.settings.gameplay["VOTE_TIME"],
			Command("VOTE-- vote type, player ".. voteType .. pname, self.tally, self, voteType))
		
		self.currentvote = msg..self.message[voteType]
		self.active = true
		trigger.outTextForCoalition(self._cmdr.owner, self.currentvote, 30) --N.B despite not _seeming_ to output to coalition during testing, it does happen. it is just immediately overwritten when using the F10 command menu
		
		return "Vote Started!"
		
	elseif(voteType == enum.voteType["PUBLIC"]["Kick Commander"]) then
	
		self.action[enum.voteType["PUBLIC"]["Kick Commander"]] = Command("Vote result: request command player"..pname, self._cmdr.kickCommander)
		
		self._theater:queueCommand(dct.settings.gameplay["VOTE_TIME"],
			Command("VOTE-- vote type, player ".. voteType .. pname, self.tally, self, voteType))
			
		self.currentvote = msg..self.message[voteType]
		self.active = true
		trigger.action.outTextForCoalition(self._cmdr.owner, self.currentvote, 30)
		
		return "Vote Started!"
		
	elseif(voteType == enum.voteType["PUBLIC"]["Surrender"]) then
		Logger:debug("-- surrender monkey --")
		self.action[enum.voteType["PUBLIC"]["Surrender"]] = Command("Vote result: surrender"..pname, self._cmdr.surrender, self._cmdr)
		Logger:debug("-- wut --")
		
		self._theater:queueCommand(dct.settings.gameplay["VOTE_TIME"],
			Command("VOTE-- vote type, player ".. voteType .. pname, self.tally, self, voteType))
		
		self.currentvote = msg..self.message[voteType]
		self.active = true
		Logger:debug(self.currentvote)
		Logger:debug(self._cmdr.owner)
		
		trigger.action.outTextForCoalition(self._cmdr.owner, self.currentvote, 30)
		trigger.action.outTextForCoalition(1, self.currentvote, 30)
		
		return "Vote Started!"
		
	elseif(voteType == enum.voteType["PRIVATE"]["Other"]) then
		
		--actions needs to be filled in (by whatever external source is summoning it) before vote is tallied or nothing will happen
				
		self._theater:queueCommand(dct.settings.gameplay["VOTE_TIME"],
			Command("VOTE-- vote type, player ".. voteType .. pname, self.tally, self, voteType))
		
		self.currentvote = msg..self.message[voteType]
		self.active = true
		trigger.action.outTextForCoalition(self._cmdr.owner, self.currentvote, 30)
		
		return 
		
	else
		
		return nil
	
	end
	
	return "Vote Started!"
	
end

return Vote
