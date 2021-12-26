--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Defines victory conditions
--]]

require("math")
local class    = require("libs.class")
local utils    = require("libs.utils")
local Marshallable = require("dct.libs.Marshallable")
local Command  = require("dct.Command")

local function checkvalue(keydata, tbl)
	if tbl[keydata.name] >= 0 then
		return true
	end
	return false
end

local function checklogical(keydata, tbl)
	if tbl[keydata.name] == "and" or tbl[keydata.name] == "or" then
		return true
	end
	return false
end

local Victory = class(Marshallable)
function Victory:__init(theater)
	Marshallable.__init(self)
	
	self.vic_conds = {}
	
	self.cfgfile = dct.settings.server.theaterpath..utils.sep..
		"theater.goals"

	self.timeout = {
		["enabled"] = false,
		["ctime"] = timer.getAbsTime(),
		["period"] = 120,
	}
	
	self:_addMarshalNames({
		"vic_conds",
		"timeout",
		"complete"})
		
	self.complete = false
	self:readconfig()
	
	if self.timeout.enabled then
		theater:queueCommand(self.timeout.period, Command(
			"Victory.timer", self.timer, self))
	end
	

	
	--theater:queueCommand(self.timeout.period, Command(
	--		"Victory.checkConditions", self.timer, self))
end

function Victory:readconfig()
	local goals = utils.readlua(self.cfgfile)
	local keys = {
		{
			["name"]    = "time",
			["type"]    = "number",
			["check"]   = checkvalue,
			["default"] = -1
		}, {
			["name"]    = "red",
			["type"]    = "table",
			["check"]   = checkside,
		}, {
			["name"]    = "blue",
			["type"]    = "table",
			["check"]   = checkside,
		}, {
			["name"]    = "neutral",
			["type"]    = "table",
			["check"]   = checkside,
			["default"] = nil
		}
	}

	goals.path = self.cfgfile
	utils.checkkeys(keys, goals)
	goals.path = nil

	if goals.time > 0 then
		self.timeout.timeleft = goals.time
		self.timeout.enabled = true
	end
	
	for _, val in ipairs({"red", "blue", "neutral"}) do
		local s = coalition.side[string.upper(val)]
		self.vic_conds[s] = goals[val]
	end

	assert(self.vic_conds ~= nil,
		string.format("Theater Goals: Red or Blue coalitions must be "..
			"defined and have valid values; %s", self.cfgfile))
end


local function checkside(keydata, tbl)
	local keys = {
		{
			["name"]    = "capture_region", -- Which region must be captured for victory
			["type"]    = "number",
			["check"]   = checkvalue,			

		},{
			["name"]    = "enemy_losses",
			["type"]    = "number",
			["check"]   = checkvalue,

		},{
			["name"]    = "command_points",
			["type"]    = "number",
			["check"]   = checkvalue,

		},{
			["name"]    = "logical",
			["type"]    = "string",
			["check"]   = checklogical,
		}
	}

	tbl[keydata.name].path = tbl.path
	utils.checkkeys(keys, tbl[keydata.name])
	tbl[keydata.name].path = nil
	
	return true
	
end

--function Tickets:getConfig(side)
--	return self.tickets[side]
--end

--function Tickets:getPlayerCost(side)
--	assert(side == coalition.side.RED or side == coalition.side.BLUE,
--		string.format("value error: side(%d) is not red or blue", side))
--	return self.tickets[side]["player_cost"]
--end

--function Tickets:_add(side, cost, mod)
--	local t = self.tickets[side]
--	assert(t, string.format("value error: side(%d) not valid, resulted in"..
--		" nil ticket table", side))
--	local v = cost
--	if mod ~= nil then
--		v = v * t[mod]
--	end
--	t.tickets = t.tickets + v
--end

--function Tickets:reward(side, cost, mod)
--	local op = nil
--	if mod == true then
		--op = "modifier_reward"
--	end
--	self:_add(side, math.abs(cost), op)
--end

local winnermap = {
	[coalition.side.RED] = coalition.side.BLUE,
	[coalition.side.BLUE] = coalition.side.RED,
	[coalition.side.NEUTRAL] = coalition.side.NEUTRAL,
}

function Victory:checkConditions()
	
	local vic_conds = self.vic_conds

	local blue_conds = self.vic_conds["BLUE"]
	local red_conds = self.vic_conds["RED"]
	local neut_conds = self.vic_conds["NEUTRAL"]
	
	if(blue_conds["logical"] ~= nil) then
	
		local logical = blue_conds["logical"]
	
	end

	for k,v in pairs(blue_conds) do -- yeah this could probably be a bit more elegant
	
		local win_cond = {}
		
		if(k == "capture_region") then
			
			local isCaptured = false
			
			-- check if region is owned by blue
			if(logical == nil) then
				blue_win = true;
				break
			else					
				table.insert(isCaptured, win_cond)			
			end
			
		elseif(k == "enemy_losses") then
		
			local isDepleted = false
			-- check sum total of enemy losses

			if(logical == nil) then
				blue_win = true;
				break
			else					
				table.insert(isDepleted, win_cond)		
			end		
	
			
		elseif(k == "command_points") then
			
			local isEnough = false			
				-- check current command point account

			if(logical == nil) then
				blue_win = true;				
				break

			else					
				table.insert(isEnough, win_cond)		
			end		

			
		end
	
	end
	
	if(blue_conds["logical"] ~= nil) then
	
		if(blue_conds["logical"] == "and") then
			
			blue_win = true;
			
			for k,v in pairs(win_cond) do
			
				blue_win = blue_win and win_cond[k]
			
			end
			
		elseif(blue_conds["logical"] == "or") then
		
			blue_win = false;
			
			for k,v in pairs(win_cond) do
			
				blue_win = blue_win or win_cond[k]
			
			end
			
		end
			
	end

	if(blue_win) then
		trigger.action.setUserFlag(flag, true) -- rewrite this with the new server control functions (ask kukiric)
		self:setComplete()
	
	else -- do it all for red now

		for k,v in pairs(red_conds) do
		
			local win_cond = {}
			
			if(k == "capture_region") then
				
				local isCaptured = false
				
				-- check if region is owned by blue
				if(logical == nil) then
					red_win = true;
					break
				else					
					table.insert(isCaptured, win_cond)			
				end
				
			elseif(k == "enemy_losses") then
			
				local isDepleted = false
				-- check sum total of enemy losses

				if(logical == nil) then
					red_win = true;
					break
				else					
					table.insert(isDepleted, win_cond)		
				end		
		
				
			elseif(k == "command_points") then
				
				local isEnough = false			
					-- check current command point account

				if(logical == nil) then
					red_win = true;				
					break

				else					
					table.insert(isEnough, win_cond)		
				end		

				
			end
		
		end
		
		if(blue_conds["logical"] ~= nil) then
		
			if(blue_conds["logical"] == "and") then
				
				red_win = true;
				
				for k,v in pairs(win_cond) do
				
					red_win = blue_win and win_cond[k]
				
				end
				
			elseif(blue_conds["logical"] == "or") then
			
				red_win = false;
				
				for k,v in pairs(win_cond) do
				
					red_win = blue_win or win_cond[k]
				
				end
				
			end
				
		end

		if(red_win) then
			trigger.action.setUserFlag(flag, true) -- rewrite this with the new server control functions (ask kukiric)
			self:setComplete()
		end
	
	end

	-- not even gonna bother for neutral

end

function Victory:setComplete()
	self.complete = true
end

function Victory:isComplete()
	return self.complete
end

function Victory:Timer()
	local ctime = timer.getAbsTime()
	local tdiff = ctime - self.timeout.ctime

	self.timeout.ctime = ctime
	self.timeout.timeleft = self.timeout.timeleft - tdiff
	if self.timeout.timeleft > 0 then
		return self.timeout.period
	end

	-- campaign timeout reached, determine the winner
	self:checkConditions()
	
	return nil
end

return Victory
