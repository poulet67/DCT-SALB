--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Dispatchable asset, represents assets that can be dispatched and ordered with commander system.
--
-- Dispatchable<AssetBase>:

Class Hierarchy:

							                       AssetBase----Airspace-----Waypoint
								                       |
		    +------------------------------------------+------------------------------------------------+
		    |										   |												|
		   Base								Static-----IAgent-----Player							  Mobile
 		    |																				  			|
FOB----- Airbase-----FARP														   				   Dispatchable
			|																																
		  Naval (to do)
		  
--]]								

require("math")
local utils    = require("libs.utils")
local enum     = require("dct.enum")
local dctutils = require("dct.utils")
local vector   = require("dct.libs.vector")
local Goal     = require("dct.Goal")
local MobileAsset= require("dct.assets.MobileAsset")

local Dispatchable = require("libs.namedclass")("", MobileAsset)
function Dispatchable:__init(template)
	self.cmdr = require("dct.Theater").singleton():getCommander(template.coalition)
	self.assetmgr = require("dct.Theater").singleton():getAssetMgr()
	self._eventhandlers = {
		[world.event.S_EVENT_LAND] = self.handleLanding, -- 
	}
	MobileAsset.__init(self, template)

end

function Dispatchable.assettypes() --note add any new assetTypes here as well as in enums
	return {
		enum.assetType.DISPATCHABLE		
	}
end

function Dispatchable:_completeinit(template)
	MobileAsset._completeinit(self, template)
end

function Dispatchable:handleLanding(event)	
	self._logger:debug("Dispatchable: handle landing")	
	asset = self.assetmgr:getByName(event.initiator:getGroup():getName())	
	self.cmdr:deactivateCommandUnit(asset)
	self.assetmgr:remove(self)	 --inventories will handle asset transfer.
	self:despawn()	
end


return Dispatchable
