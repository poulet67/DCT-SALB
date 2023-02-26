--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Represents a Base.
--
-- AirbaseAsset<AssetBase, Subordinates>:
--
-- airbase events
-- * an object taken out, could effect;
--   - base resources
--   - runway operation
--
-- base has
--  - an inventory
--
--
--
-- Events:
--   * DCT_EVENT_HIT
--     An base has potentially been bombed and we need to check
--     for runway damage, ramp, etc damage.
--   * S_EVENT_HIT
--     Any action we need to take from getting a hit event from DCS?
--     Yes if the ship is damaged we should probably disable flight
--     operations for a period of time.
--   * S_EVENT_DEAD
--     Can an base even die? Yes if it is a ship.
--   * S_EVENT_BASE_CAPTURED
--     This event has problems should we listen to it?
--
Class Hierarchy:

							                       AssetBase----Airspace-----Waypoint
								                       |
	  Base---------------------------------------------+								
		|											   |
 FOB----+-- Airbase---City/POI--- Off_Map		     Static-----IAgent-----Player			DCTWeapon
			   |
			   |
			  FARP

--   determine if those events render the slot non-operational.
--]]

local class         = require("libs.namedclass")
local dctenum       = require("dct.enum")
local dctutils      = require("dct.utils")
local Subordinates  = require("dct.libs.Subordinates")
local AssetBase     = require("dct.assets.AssetBase")
local Marshallable  = require("dct.libs.Marshallable")
local State         = require("dct.libs.State")
local Logger   = dct.Logger.getByName("Base")

local statetypes = {
	["OPERATIONAL"] = 1,
	["REPAIRING"]   = 2,
	["CAPTURED"]    = 3,
}

--[[
-- CapturedState - terminal state
--  * enter: set Base dead
--]]
local CapturedState = class("Captured", State, Marshallable)
function CapturedState:__init()
	Marshallable.__init(self)
	self.type = statetypes.CAPTURED
	self:_addMarshalNames({"type",})
end

function CapturedState:enter(asset)
	asset._logger:debug("Base captured - entering captured state")
	asset:despawn()
	asset:setDead(true)
end

--[[
-- RepairingState - Base repairing
--  * enter: start repair timer
--  * transition: on timer expire move to Operational
--  * transition: on capture event move to Captured
--  * event: on DCT_EVENT_HIT extend repair timer (not implemented yet)
--]]
local OperationalState = class("Operational", State, Marshallable)
local RepairingState = class("Repairing", State, Marshallable)
function RepairingState:__init()
	Marshallable.__init(self)
	self.type = statetypes.REPAIRING
	self.timeout = 12*60*60 -- 12 hour repair time
	self.ctime   = timer.getAbsTime()	
	self:_addMarshalNames({"type", "timeout",})
end

-- TODO: if we want to make the repair timer variable we can do that
-- via the enter function and set the timeout based on a variable
-- stored in the Base asset

function RepairingState:update(_ --[[asset]])
	local time = timer.getAbsTimer()
	self.timeout = self.timeout - (time - self.ctime)
	self.ctime = time

	if self.timeout <= 0 then
		return OperationalState()
	end
	return nil
end

function RepairingState:onDCTEvent(asset, event)
	local state = nil
	if event.id == dctenum.event.DCT_EVENT_CAPTURED and
	   event.target.name == asset.name then
		state = CapturedState()
	end
	-- TODO: listen for hit events and extend the repair timer
	return state
end

--[[
-- OperationalState - Base does things
--  * enter: reset runway health
--  * enter: notify Base operational
--  * exit: notify Base not operational
--  * transition: to Repairing on runway hit
--  * transition: to Captured on DCT capture event
--  * update:
--    - do AI departures
--]]
function OperationalState:__init()
	Marshallable.__init(self)
	self.type = statetypes.OPERATIONAL
	self:_addMarshalNames({"type", })
end

function OperationalState:enter(asset)
	asset:resetDamage()
	if asset:isSpawned() then
		asset:notify(dctutils.buildevent.operational(asset, true))
	end
end

function OperationalState:exit(asset)
	asset:notify(dctutils.buildevent.operational(asset, false))
end

function OperationalState:update(asset)
	-- TODO: create departures
	asset._logger:warn("operational state: update called")
end

function OperationalState:onDCTEvent(asset, event)
	--[[
	-- TODO: write this event handler
	-- events to handle:
	--  * DCT_EVENT_HIT - call Base:checkHit(); returns: bool, func
	--    - track if runway hit; 50% of the runway must be hit w/
	--      500lb bombs or larger to knock it out, we can track this
	--      by splitting the runway up into 10 smaller rectangles,
	--      then keep a list of which sections have been hit
	--  * S_EVENT_TAKEOFF - call Base:processDeparture(); returns: none
	--  * S_EVENT_LAND - no need to handle
	--  * S_EVENT_HIT - no need to handle at this time
	--  * S_EVENT_DEAD - no need to handle at this time
	--]]
	
	--inventory handler
	Logger:debug("OP STATE DCT EVENT")
	
	local inventory_relevents = {
		[world.event.S_EVENT_TAKEOFF]                = asset.Inventory.handleTakeoff,
		[world.event.S_EVENT_LAND]                = asset.Inventory.handleLanding,
	}
	if inventory_relevents[event.id] == nil then
		Logger:debug("base: "..asset.name.." - not relevent event: "..
		tostring(event.id))
		return
	else	
		inventory_relevents[event.id](asset.Inventory, event)
		return
	end
	
	asset._logger:warn("operational state: onDCTEvent called event.id"..
		event.id)
end

local statemap = {
	[statetypes.OPERATIONAL] = OperationalState,
	[statetypes.REPAIRING]   = RepairingState,
	[statetypes.CAPTURED]    = CapturedState,
}

local Base = class("Base", AssetBase, Subordinates)
function Base:__init(template, region)
	AssetBase.__init(self, template)
	self.Inventory = require("dct.systems.inventory")(self)
	Subordinates.__init(self)
	self:_addMarshalNames({
		"_subordinates",
	})
	self.region = region;
	self._eventhandlers = nil
end

function Base:_completeinit(template)
	AssetBase._completeinit(self, template)	
	self.state = OperationalState()
end

--function Base.assettypes() -- for now there is now actual 'base' asset - this is just a higher class that other base types inherit from (for inventories and state changing logic)
--	return {
--		dctenum.assetType.AIRBASE,
--	}
--end

function Base:resetDamage()
end


function Base:update()
	local newstate = self.state:update(self)
	if newstate ~= nil then
		self.state:exit(self)
		self.state = newstate
		self.state:enter(self)
	end
end

function Base:onDCTEvent(event)
	Logger:debug("--IN DCT EVENT. State: "..tostring(Base:isOperational()))
	local newstate = self.state:onDCTEvent(self, event)
	if newstate ~= nil then
		self.state:exit(self)
		self.state = newstate
		self.state:enter(self)
	end
end

function Base:isOperational()
	return self:isSpawned() and self.state.type == statetypes.OPERATIONAL
end

function Base:getStatus()
	local g = 0
	if self:isOperational() then
		g = 1
	end
	return math.floor((1 - g) * 100)
end

function Base:marshal()
	local tbl = Base.marshal(self)
	if tbl == nil then
		return nil
	end

	tbl._subordinates = filterPlayerGroups(self._subordinates)
	tbl.state = self.state:marshal()
	return tbl
end

function Base:unmarshal(data)
	AssetBase.unmarshal(self, data)

	-- We must unmarshal the state object after the base asset has
	-- unmarshaled due to how the Marshallable object works
	self.state = State.factory(statemap, data.state.type)
	self.state:unmarshal(data.state)

	-- do not call the state's enter function because we are not
	-- entering the state we are just restoring the object
	associate_slots(self)
end

function Base:spawn(ignore)
	self._logger:debug("spawn called")
	if not ignore and self:isSpawned() then
		self._logger:error("runtime bug - already spawned")
		return
	end
	self:spawn_despawn("spawn")
	AssetBase.spawn(self)

	if self:isOperational() then
		self:notify(dctutils.buildevent.operational(self, true))
	end
end

function Base:despawn()
	self:spawn_despawn(self, "despawn")
	AssetBase.despawn(self)
end

function Base:getObjectNames()
	return {self.name}
end
return Base
