--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Represents a waypoint.
-- waypoint cannot die (i.e. be deleted), tell people or AI units where to go, and spawn nothing
--]]

local vector = require("dct.libs.vector")
local AssetBase = require("dct.assets.AssetBase")

local Waypoint = require("libs.namedclass")("Waypoint", AssetBase)
function Waypoint:__init(template)
	AssetBase.__init(self, template)
	self:_addMarshalNames({
		"_location",
	})
end

function Waypoint.assettypes()
	return {
		require("dct.enum").assetType.WAYPOINT,
		require("dct.enum").assetType.WEAPON
	}
end

function Waypoint:_completeinit(template)
	AssetBase._completeinit(self, template)
	assert(template.location ~= nil,
		"runtime error: Waypoint requires template to define a location")
	self._location = vector.Vector3D(template.location):raw()
end

return Waypoint
