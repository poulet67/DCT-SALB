 --[[
-- SPDX-License-Identifier: LGPL-3.0
--
--
--]]

-- I did not realize how god damned awful ugly dragging this thing half assedly through the asset classes was going to make it.
-- I ended up making a "franken asset".. don't want it to touch the marshal system, but still want to be able to assign a mission to it...
-- What I got is kind of goddamn godawful ugly.
-- I will have to come back here with a flamethrower and re-build anew at some point.

--[[

local class    = require("libs.namedclass")
local dctutils = require("dct.utils")
local vector   = require("dct.libs.vector")
local Logger   = require("dct.libs.Logger").getByName("System")
local Observable   = require("dct.libs.Observable")
local enum       = require("dct.enum")
local settings = _G.dct.settings

local DCTWeapon = class("DCTWeapon", Observable)
function DCTWeapon:__init(template)--(wpn, initiator, updaterate)

	Observable.__init(self)
	
	self.objtype 	 = template.objtype
	self.name		 = template.name --for uniqueness
	self.regionname  = template.nam
	self.start_time  = timer.getTime()
	self.timeout     = false
	self.lifetime    = template.lifetime -- 10 minutes
	self.weapon      = template.weapon
	self.owner	 	 = template.owner
	--self.type        = dctutils.trimTypeName(wpn:getTypeName())
	--self.shootername = initiator:getName()
	self.desc        = template.desc -- not the same as DCS desc - this is for mission text
	self.impactpt    = nil
	
	self.type    = enum.assetType["WEAPON"] --required for DCT
	self.codename    = "*"
	self.location    = template.weapon:getPosition()
	self:update(self.start_time, template.updaterate)
	
	
	
end

function DCTWeapon.assettypes()
	return {
		require("dct.enum").assetType.WEAPON
	}
end

function DCTWeapon:exist()
	Logger:debug("weapon exist:"..tostring(self.weapon:isExist()))
	Logger:debug("weapon timeout:"..tostring(self.timeout))
	return self.weapon:isExist() and not self.timeout
end

function DCTWeapon:isDead() --required for AssetManager
	return not self:exist()
end

function DCTWeapon:getObjectNames() --required for AssetManager -_-
	return {}
end

function DCTWeapon:setTargeted() --required for AssetManager -_-
	return {}
end

function DCTWeapon:getLocation() --required for AssetManager -_-
	return self.location
end

function DCTWeapon:getStatus() --required for AssetManager -_-
	if(DCTWeapon:isDead()) then
		g = 1
	else
		g = 0
	end
	
	return	g
end

function DCTWeapon:getIntel(_) --required for AssetManager/Mission -_-
	return 4
end

function DCTWeapon:hasImpacted()
	return self.impactpt ~= nil
end

function DCTWeapon:getDesc()
	return self.desc
end

function DCTWeapon:getImpactPoint()
	return self.impactpt
end

function DCTWeapon:update(time, lookahead)
	assert(time, "value error: time must be a non-nil value")
	if not self:exist() then
		return
	end

	local pos = self.weapon:getPosition()
	
	self.location = pos.p
	
	if time - self.start_time > self.lifetime then
		self.timeout = true
	end

	self.pos  = vector.Vector3D(pos.p)
	self.dir  = vector.Vector3D(pos.x)
	self.vel  = vector.Vector3D(self.weapon:getVelocity())
		-- search lookahead seconds into the future
	self.impactpt = land.getIP(self.pos:raw(),
	                           self.dir:raw(),
	                           self.vel:magnitude() * lookahead)
							   
end


return DCTWeapon

--]]