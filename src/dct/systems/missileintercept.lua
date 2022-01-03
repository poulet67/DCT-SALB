--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Automatically creates an intercept mission if certain types of missiles are fired (intended for anti-ship and cruise)
--
--
--]]

local class    = require("libs.namedclass")
local dctutils = require("dct.utils")
local vector   = require("dct.libs.vector")
local Logger   = require("dct.libs.Logger").getByName("System")
local DCTWeapon   = require("dct.assets.DCTWeapon")
local Mission    = require("dct.ai.Mission")
local dctutils    = require("dct.utils")
local Template    = require("dct.templates.Template")
local Command     = require("dct.Command")

-- Only units that are not air defence and are firing
-- weapons with HE warheads are considered
local function isWpnValid(event)
	if event.initiator:hasAttribute("Air Defence") then --or event.weapon:getCategory() ~= Weapon.Category.MISSILE then
		return false
	end

	local wpndesc = event.weapon:getDesc()
	
	local activetable = { --which missiles this will apply for (requires the eddie type name)
						  --add any additional desired here
		["P_500"] = true,
		["P_700"] =  true,
		["X_22"] =  false,
		["X-31A"] =  false,
		["X-35"] =  false,
	}
	
	Logger:debug("-- MT UPDATE --")
	
	
	if activetable[wpndesc.typeName] then	
	   Logger:debug("-- TRACKER DING --")
	   return true
	end

	return false
end

local MissileTracker = class("MissileTracker")
function MissileTracker:__init(theater)
	self.updatefreq = 5
	self.lifetime = 600 --how long the "asset" will live 10 minutes in this case
	self.trackedwpns = nil
	self.trackedsets = nil
	self._theater = theater
	theater:addObserver(self.event, self, self.__clsname..".event")
--	timer.scheduleFunction(self.update, self,
--		timer.getTime() + self.updatefreq)
end

function MissileTracker:inRange(wpn)	

	--create a set of missiles that will get missions
	
	if(self.trackedwpns == nil) then -- nothing being tracked
	
		return false
	
	end


	for key, val in pairs(self.trackedwpns) do
					
		if(self:outside_set_range(val, wpn:getPosition().p)) then -- only make missions for missiles within X distance from arbitrary "first" missile

			return false
			
		end
			
	end
	
	return true
	
end


function MissileTracker:outside_set_range(p1, p2)
	
	Logger:debug("-- MISSILE TRACKER RANGE CALC --")
	local setrange = 10000 --meters, or 5 NM todo: make this a setting
	
	for k, v in pairs(p1) do
		Logger:debug(k.."   "..v)
	end
	
	v1 = vector.Vector3D(p1)
	v2 = vector.Vector3D(p2)
	
	dist = vector.distance(v1,v2)
	Logger:debug("-- MISSILE TRACKER DISTANCE --")
	Logger:debug(dist)
	
	--if(vector.distance(p1,p2) < setrange)
	if(dist > setrange) then

		return true
	
	else
	
	return false
	
	end

end

function MissileTracker:newmission(wpn)
		
	wpnloc = wpn:getPosition().p

	heading = dctutils.getHeading(wpn:getVelocity())
	
	--Logger:debug("Heading:".. heading)
	desctbl = wpn:getDesc()
	
	--Logger:debug(wpn:getName().."FUCKING WAYPOINT"..wpn:getCoalition())
	
	wpntpl = Template({

		["objtype"]    = "WEAPON",		
		["name"] = "obj"..wpn:getName(),		
		["regionname"] = "N/A",
		["desc"]       = desctbl.displayName.." launch has been detected! Scramble any available fighters to intercept!",
		["location"]       = wpnloc,
		["heading"]       = heading,
		["coalition"]       = wpn:getCoalition(),
		
		
	})
	wpnid = wpn:getName(),
	Logger:debug("Adding asset and mission")
	asset = self._theater:getAssetMgr():factory(wpntpl.objtype)(wpntpl)
	ass_manager:add(asset)		
	self._theater:getCommander(dctutils.getenemy(asset.owner)).known[asset.name] = true
	self._theater:queueCommand(self.lifetime, Command("MissileTracker cleanup asset:"..asset.name, self.kill, self, asset, wpnid))

end

function MissileTracker:kill(asset, wpnid)

	asset:setDead(true)
	
	Logger:debug("KILL")	
	Logger:debug(wpnid)

	self.trackedwpns[wpnid] = nil

end

--[[
function MissileTracker:update(time)
	local errhandler = function(err)
		Logger:error("protected call - "..tostring(err).."\n"..
			debug.traceback())
	end
	local pcallfunc = function()
		self:_update(time)
	end

	xpcall(pcallfunc, errhandler)
	return time + self.updatefreq
end
]]--
function MissileTracker:event(event)
	if not (event.id == world.event.S_EVENT_SHOT and
	   event.weapon and event.initiator) then
		return
	end

	if not isWpnValid(event) then
		Logger:debug(string.format("%s - weapon not valid "..
			"typename: %s; initiator: ", self.__clsname,
			event.weapon:getTypeName(),
			event.initiator:getName()))
		return
	end
		
	if self:inRange(event.weapon) then -- in range of other missile fired locations
		return
	end
	
	Logger:debug("No missile in range")

	if(self.trackedwpns == nil) then
		self.trackedwpns = {}
	end

	self.trackedwpns[event.weapon:getName()] = event.weapon:getPosition().p
	
	self:newmission(event.weapon)
	
	
end

return MissileTracker