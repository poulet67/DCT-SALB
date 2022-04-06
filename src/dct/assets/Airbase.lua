--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Represents an Airbase.
----
Class Hierarchy:

							                       AssetBase----Airspace-----Waypoint
								                       |
	  Base---------------------------------------------+								
		|											   |
 FOB----+-- Airbase-----FARP  					     Static-----IAgent-----Player			DCTWeapon
 
 
 
 
 
 
-- AirbaseAsset<AssetBase, Subordinates>:
--
-- airbase events
-- * an object taken out, could effect;
--   - parking
--   - base resources
--   - runway operation
--
-- airbase has;
--  - resources for aircraft weapons
--
-- MVP - Phase 1:
--  - enable/disable player slots
--  - parking in use by players
--
-- MVP - Phase 2:
--  - runway destruction
--  - parking in use by AI or players
--  - spawn AI flights
--
-- Events:
--   * DCT_EVENT_HIT
--     An airbase has potentially been bombed and we need to check
--     for runway damage, ramp, etc damage.
--   * S_EVENT_TAKEOFF
--     An aircraft has taken off from the airbase, we need to
--     remove parking reservations
--   * S_EVENT_LAND
--     An aircraft has landed at the base, no specific action we
--     need to take?
--   * S_EVENT_HIT
--     Any action we need to take from getting a hit event from DCS?
--     Yes if the ship is damaged we should probably disable flight
--     operations for a period of time.
--   * S_EVENT_DEAD
--     Can an airbase even die? Yes if it is a ship.
--   * S_EVENT_BASE_CAPTURED
--     This event has problems should we listen to it?
--
-- Emitted Events:
--   * DCT_EVENT_DEAD
--     Notify listeners when dead
--   * DCT_EVENT_OPERATIONAL
--     signals the base is in an operational state or not
--
-- Player Class and Hooks:
--    The player class and hooks will need to be modified so that a third
--    state is listened to, the states are;
--    spawned - the asset has been spawned, the owning airbase upon
--              despawning will despawn all player slots
--    kicked  - if a player in the slot should be kicked from the slot
--    oper    - if the slot is operational, meaning the slot has been
--              spawned but for some reason the slot cannot be spawned
--              into
--
--   The Player class will need to listen various events and then
--   determine if those events render the slot non-operational.
--]]

local class         = require("libs.namedclass")
local PriorityQueue = require("libs.containers.pqueue")
local dctenum       = require("dct.enum")
local dctutils      = require("dct.utils")
local Subordinates  = require("dct.libs.Subordinates")
local Base    		 = require("dct.assets.Base")
local State         = require("dct.libs.State")

local allowedtpltypes = {
	[dctenum.assetType.BASEDEFENSE]    = true
}

local function associate_slots(ab)
	local filter = function(a)
		if a.type == dctenum.assetType.PLAYERGROUP and
		   a.airbase == ab.name and a.owner == ab.owner then
			return true
		end
		return false
	end
	local assetmgr = dct.Theater.singleton():getAssetMgr()

	-- Associate player slots that cannot be autodetected by using
	-- a list provided by the campaign designer. First look up the
	-- template defining the airbase so that slots can be updated
	-- without resetting the campaign state.
	-- TODO: temp solution until a region manager is created
	
	
	local region = dct.Theater.singleton().regions[ab.rgnname]
	local tpl = region:getTemplateByName(ab.tplname)
	for _, name in ipairs(tpl.players) do
		local asset = assetmgr:getAsset(name)
		if asset and asset.airbase == nil then
			asset.airbase = ab.name
		end
	end

	for name, _ in pairs(assetmgr:filterAssets(filter)) do
		local asset = assetmgr:getAsset(name)
		if asset then
			ab:addSubordinate(asset)
			if asset.parking then
				ab._parking_occupied[asset.parking] = true
			end
		end
	end
end

local AirbaseAsset = class("Airbase", Base)
function AirbaseAsset:__init(template)	
	Base.__init(self, template)
	--Base.init_inventory(self)
	self._departures = PriorityQueue()
	self._parking_occupied = {}
	self:_addMarshalNames({
		"_tplnames",
		"takeofftype",
		"recoverytype",
	})
	self._eventhandlers = nil
end

function AirbaseAsset.assettypes()
	return {
		dctenum.assetType.AIRBASE,
	}
end

function AirbaseAsset:_completeinit(template)
	Base._completeinit(self, template)
	self._tplnames    = template.subordinates
	self.takeofftype  = template.takeofftype
	self.recoverytype = template.recoverytype
	self._tpldata = self._tpldata or {}
	self.state:enter(self)
	--associate_slots(self)  -- TEMPORARILY DISABLED - WILL FIX THIS WITH PLANNED REGIONS UPGRADE
end

function AirbaseAsset:_setup()
	local dcsab = Airbase.getByName(self.name)
	if dcsab == nil then
		self._logger:error("is not a DCS Airbase")
		self:setDead(true)
		return
	end
	self._abcategory = dcsab:getDesc().airbaseCategory
	self._location = dcsab:getPoint()
end

local function filterPlayerGroups(sublist)
	local subs = {}
	for subname, subtype in pairs(sublist) do
		if subtype ~= dctenum.assetType.PLAYERGROUP then
			subs[subname] = subtype
		end
	end
	return subs
end


function AirbaseAsset:resetDamage()
end

--[[
-- check if we have any departures to do, we only do one departure
-- per run of this function to allow for separation of flights.
function AirbaseAsset:_doOneDeparture()
	if self._departures:empty() then
		return
	end

	local time = timer.getAbsTime()
	local name, prio = self._departures:peek()
	if time < prio then
		return
	end

	self._departures:pop()
	local flight = dct.Theater.singleton():getAssetMgr():getAsset(name)
	-- TODO: need some way to spawn the flight with the data from the
	-- airbase
	local wpt1 = self:_buildWaypoint(flight:getAircraftType())
	flight:spawn(false, wpt1)
	self:addObserver(flight)
end

function AirbaseAsset:addFlight(flight, delay)
	assert(flight, self.__clsname..":addFlight - flight required")
	local delay = delay or 0
	self._departures:push(timer.getAbsTime() + delay, flight.name)
 end
--]]

function AirbaseAsset:generate(assetmgr, region)
	self._logger:debug("generate called")
	for _, tplname in ipairs(self._tplnames or {}) do
		self._logger:debug("subordinate template: "..tplname)
		local tpl = region:getTemplateByName(tplname)
		assert(tpl, string.format("runtime error: airbase(%s) defines "..
			"a subordinate template of name '%s', does not exist",
			self.name, tplname))
		assert(allowedtpltypes[tpl.objtype],
			string.format("runtime error: airbase(%s) defines "..
				"a subordinate template of name '%s' and type: %d ;"..
				"not supported type", self.name, tplname, tpl.objtype))
		if tpl.coalition == self.owner then
			tpl.airbase = self.name
			tpl.location = self:getLocation()
			local asset = assetmgr:factory(tpl.objtype)(tpl)
			assetmgr:add(asset)
			self:addSubordinate(asset)
		end
	end
end


return AirbaseAsset
