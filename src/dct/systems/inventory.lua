--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Inventory class
--
--
--
--]]

-- TO DO:
-- Figure out front end architecture
-- Turn all the outText into individual messages
-- Set up a scheduled function to check for deliveries
-- When delivery detected schedule function to spawn appropriate flight
-- Check coalition of airfield (for that matter, have a means to deal with captured airfields
-- Deal with multicrew somehow

local dctutils   = require("dct.utils")
local utils   = require("libs.utils")
local JSON   = require("libs.JSON")
local class  = require("libs.namedclass")
local Logger = require("dct.libs.Logger").getByName("Inventory")
local enum        = require("dct.enum")
local Command     = require("dct.Command")
local settings    = _G.dct.settings

local Inventory = class("Inventory")
function Inventory:__init(base)
	
	--utils.tprint(base) 
	Logger:debug("INVENTORY: "..base.name)
	self._inventory = self:init_inv(base.name) -- the actual 'inventory table'
	
	self.base = base
	
	--self.inventory_tables_path = settings.theaterpath..utils.sep.."tables"..utils.sep.."inventories"
	--self._theater = theater might be useful to have these (n.b might also be able to just grab these with requires, no need to pass anything
	--self._cmdr = cmdr


	
	
end

function Inventory.singleton()
	if _G.dct.theater ~= nil then
		return _G.dct.theater
	end
	_G.dct.theater = Theater()
	return _G.dct.theater
end

function Inventory:init_inv(name)

	if(master_table[name]) then
		
		Logger:debug("INVENTORY FOUND: "..name)
		
		
		
		
	else
	
		local empty_table = { 	
								["airframes"] = {},
								["munitions"] = {},
								["ground units"] = {},
								["naval"] = {},
								["trains"] = {},
								["other"] = {},
							}
							
		master_table[name] = empty_table
		
		Logger:debug("NEW INVENTORY: "..name)
		
		return master_table[name]
	
	end

	--add event handlers
	--
	
	-- below: old style
	-- Use DCT events for this now
end

function generate_master()

	path = settings.server.theaterpath..utils.sep.."tables"..utils.sep.."inventories"..utils.sep.."inventory.JSON"
	inv_table = dctutils.read_JSON_file(path)
	
	path = settings.server.theaterpath..utils.sep.."tables"..utils.sep.."inventories"..utils.sep.."link.tbl"
	lnk_table = dctutils.read_lua_file(path)
	
	path = settings.server.theaterpath..utils.sep.."tables"..utils.sep.."inventories"..utils.sep.."display_names.tbl"
	dn_table = dctutils.read_lua_file(path)

	path = settings.server.theaterpath..utils.sep.."tables"..utils.sep.."inventories"..utils.sep.."master.JSON"
	master_table = dctutils.read_JSON_file(path)

	for k,v in pairs(dn_table) do
	
		for key, value in pairs(dn_table[k]) do
			
			if(master_table[k][key]) then
			
				master_table[k][key]["displayName"] = dn_table[k][key]
			
			end
	
		end
		
	end
		
	for k,v in pairs(lnk_table) do
					
		for key, value in pairs(lnk_table[k]) do
		
			if(master_table[k][key]) then
				
				master_table[k][key]["link"] = master_table[k][lnk_table[k][key]]
			
			end
			
		end
		
	end
		
	inv_table["master"] = master_table --to do: make sure this field can't be chosen as a base name
		
	--Logger:debug("INVENTORY: -- MASTER DUMP")
	--utils.tprint(inv_table.master) 
	
	return inv_table
	
end

local master_table = generate_master()


--[[
function EventHandler:onEvent(event)
  onTakeoffEvent(event)
  onLandingEvent(event)
  onBirthEvent(event)  
end

function onTakeoffEvent(event)
  
	if event.id == world.event.S_EVENT_TAKEOFF then
		--trigger.action.outText("takeoff", 30)
		
		local departingAirbase = event.place:getName()		
		--trigger.action.outText(departingAirbase, 30)
		--test_ammoTable = event.initiator:getAmmo()
		--trigger.action.outText(event.initiator, 30)	
		
		
		if(Inventory_Check(event.initiator, event.place:getName())) then --Unit has a valid loadout
		
			Inventory_Checkout(event.initiator, departingAirbase)
		
		else	
		
			trigger.action.outText("Temporal anomaly detected! You will phase into nullspace in "..explode_delay.." seconds", 30)	
			timer.scheduleFunction(explode_player, event.initiator, timer.getTime() + explode_delay) -- seconds mission time required


		end
		
	end
	
  
end

function onLandingEvent(event)
  
	if event.id == world.event.S_EVENT_LAND then
	
		trigger.action.outText("Landing ------------- Inventory Transfer:", 30)
		trigger.action.outText(event.initiator:getName(), 30)
		arrivingAirbase = event.place:getName()
		
		--trigger.action.outText(arrivingAirbase, 30)
		--test_ammoTable = event.initiator:getAmmo()
		--trigger.action.outText(event.initiator, 30)	
		
		--Check if landing aircraft has any deliveries
		
		for k, v in pairs(deliveries) do
		
			if(deliveries[k].UnitAttachedto == event.initiator:getName()) then
			
				trigger.action.outText("Delivery Detected!", 30)				
				Delivery_Handoff(arrivingAirbase, event.initiator:getName())
				deliveries[k] = nil --clear this entry from the table
				break -- not sure if we will ever want multiple deliveries attached to 1 unit. Can't think of a use case, but if that happens this like will need to be removed. As is it will slightly improve performance				
				
			end
		
		end
		
	
		--if(Inventory_Check(event.initiator, event.place:getName())) then --Unit has a valid loadout not sure if we need to check anything really?
		
		Inventory_Handoff(event.initiator, arrivingAirbase) -- going to need to think a bit about how to deal with logistics aircraft comming and going, especially things like the C-130 having 4 crew members...
		
		--else		
		--	trigger.action.outText("Boom!", 30)	
		--	trigger.action.explosion(event.initiator:getPoint(), 50)

		--end
		
	end
	
  
end

function onBirthEvent(event)
  
	if event.id == world.event.S_EVENT_BIRTH then
		--trigger.action.outText("inside birth event", 30)		
		local position = event.initiator:getPoint()
		local CurrentAirbase = getCurrentAirbase(position.x, position.y, position.z)	
		
		missionCommands.addCommandForGroup(event.initiator:getGroup():getID(), "Check Loadout vs. Inventory", nil, Inventory_Manual_Check_Loadout, event.initiator) -- Submenus: List available weapons at current airbase, list available airframs at air base (something else?)
	
		
	--playerLocationTable[event.initiator] = 
	
	end	
  
end
		
	
end

deliveries = {}
inventories = {}
EventHandler = {}
explode_delay = 5
--playerLocationTable = {}


--Might want an entirely seperate system for deliveries
function Inventory:delivery(arrivingAirbase, UnitAttachedto)

--trigger.action.outText("DING DING DING  -------  ", 30)
--trigger.action.outText("DING DING DING  -------  "..deliveries[1].UnitAttachedto, 30)
--trigger.action.outText("DING DING DING  -------  "..deliveries[1].Cargo.PilotLives, 30)
--trigger.action.outText("DING DING DING  -------  "..deliveries[1].Cargo.Weapons[1].quantity, 30)


	for k, v in pairs(deliveries) do
			
		if(deliveries[k].UnitAttachedto == UnitAttachedto) then
		
				PilotsDelivered = deliveries[k].Cargo.PilotLives				
				trigger.action.outText("PilotLives"..PilotsDelivered, 30)				
				FuelDelivered = deliveries[k].Cargo.Fuel				
				WeaponsDelivered = deliveries[k].Cargo.Weapons
				--GroundUnitsDelivered = deliveries[k].Cargo.GroundUnits
				Inventory_Add_Pilots(arrivingAirbase, PilotsDelivered)
				Inventory_Add_Fuel(arrivingAirbase, FuelDelivered)
				
				for key, value in pairs(WeaponsDelivered) do
				
					Inventory_Add_Weapon(WeaponsDelivered[key].displayName, arrivingAirbase, WeaponsDelivered[key].quantity)
				
				end	
				
				break
	
		end
		
	end
end
			
function Inventory:check_loadout(playerUnit)

	trigger.action.outText("INVENTORY CHECK:", 30) --TO do: Make this a message to group only
	
	currentAirbase = getCurrentAirbase(playerUnit:getPoint().x,playerUnit:getPoint().y,playerUnit:getPoint().z)
	
	local valid = Inventory_Check(playerUnit, currentAirbase)
	
	if(valid) then
		
		trigger.action.outText("Your loadout is approved, you may proceed.", 30)	
		
	elseif(not(valid)) then
		
		trigger.action.outText("You currently in an airframe or have weapons equipped that do not exist at this airbase. This temporal paradox will cause you to implode upon takeoff. Please change your loadout if you wish to remain in this dimension.", 30)	
		
	end

end

function Inventory:checkout(playerUnit, currentAirbase)

	trigger.action.outText("INVENTORY CHECKOUT REPORT:", 30)
	
	descTable = playerUnit:getDesc()
	
	currentFuelPct = playerUnit:getFuel()	
	fuelMassMax = descTable.fuelMassMax	
	myFuel = fuelMassMax*currentFuelPct	
	
	--First Level stuff
	
	for k, v in pairs(inventories) do
	
		if(inventories[k].Airbase == currentAirbase) then			
	
		--PilotLives
		
			inventories[k].PilotLives = inventories[k].PilotLives - 1 -- Ways this can break: Multicrew
			trigger.action.outText("1 Pilot withdrawn from "..currentAirbase.." "..inventories[k].PilotLives.." remain", 30)
			--Fuel
			inventories[k].Fuel = inventories[k].Fuel-myFuel
			trigger.action.outText(myFuel.." kg of fuel withdrawn from "..currentAirbase.." "..inventories[k].Fuel.." kg remain", 30)
			
		end
		
		
	end
	
	
	AirframeName = descTable.displayName		

	for key, value in pairs(inventories) do
	
		if(inventories[key].Airbase == currentAirbase) then				-- might have to think about this a bit in the case of multiple inventories that are assigned to the same airbase...
			
			for Key, Value in pairs(inventories[key].Airframes) do
			
				if(inventories[key].Airframes[Key].displayName == AirframeName) then
					--trigger.action.outText("Airframes ding", 30)
					inventories[key].Airframes[Key].quantity = inventories[key].Airframes[Key].quantity - 1
					trigger.action.outText("1 Airframe of type "..AirframeName.." withdrawn from "..currentAirbase.." "..inventories[key].Airframes[Key].quantity.." remain", 30)
					break
					
				end
			end
			
			break
			
		end
	end	
	
	-- Weapons
	ammoTable = playerUnit:getAmmo()
	
	if(ammoTable ~= nil) then	
	
		for k,v in pairs(ammoTable) do
		
			number = v.count
			WeaponName = v.desc.displayName
			
			--trigger.action.outText(number, 30)
			--trigger.action.outText(WeaponName, 30)
			--trigger.action.outText(currentAirbase, 30)
			
			for key, value in pairs(inventories) do
			
				if(inventories[key].Airbase == currentAirbase) then				.
					
					for Key, Value in pairs(inventories[key].Weapons) do
					
						if(inventories[key].Weapons[Key].displayName == WeaponName) then
							--trigger.action.outText("DING DING DING:", 30)
							inventories[key].Weapons[Key].quantity = inventories[key].Weapons[Key].quantity - number
							trigger.action.outText(number.." weapons of type "..WeaponName.." withdrawn "..inventories[key].Weapons[Key].quantity.." remain", 30)
							break
							
						end
					end
					
					break
					
				end
			end
		end
	end
	

end

function Inventory:handoff(playerUnit, currentAirbase)
	
	--To do: include fuel, airframes and pilots.

	trigger.action.outText("ITEMS DELIVERED:", 30)
	
	
	descTable = playerUnit:getDesc()
	
	currentFuelPct = playerUnit:getFuel()	
	fuelMassMax = descTable.fuelMassMax	
	myFuel = fuelMassMax*currentFuelPct	
	
	--First Level stuff
	
	for k, v in pairs(inventories) do
	
		if(inventories[k].Airbase == currentAirbase) then			
	
		--PilotLives
		
			inventories[k].PilotLives = inventories[k].PilotLives + 1 -- Ways this can break: Multicrew
			trigger.action.outText("1 Pilot transferred to "..currentAirbase.." "..inventories[k].PilotLives.." now in stock", 30)
			--Fuel
			inventories[k].Fuel = inventories[k].Fuel+myFuel
			trigger.action.outText(myFuel.." kg of fuel transferred to "..currentAirbase.." "..inventories[k].Fuel.." kg now in stock", 30)
			
		end
		
		
	end
	
	
	AirframeName = descTable.displayName		

	for key, value in pairs(inventories) do
	
		if(inventories[key].Airbase == currentAirbase) then				-- might have to think about this a bit in the case of multiple inventories that are assigned to the same airbase...
			
			for Key, Value in pairs(inventories[key].Airframes) do
			
				if(inventories[key].Airframes[Key].displayName == AirframeName) then
					--trigger.action.outText("Airframes ding", 30)
					inventories[key].Airframes[Key].quantity = inventories[key].Airframes[Key].quantity + 1
					trigger.action.outText("1 Airframe of type "..AirframeName.." transferred to "..currentAirbase.." "..inventories[key].Airframes[Key].quantity.." now in stock", 30)
					break
					
				end
			end
			
			break
			
		end
	end	
	
	AirframeName = descTable.displayName		


	-- Weapons
	
	ammoTable = playerUnit:getAmmo()
	
	
	if(ammoTable ~= nil) then	
	
		for k,v in pairs(ammoTable) do
		
			number = v.count
			WeaponName = v.desc.displayName
			
			--trigger.action.outText(number, 30)
			--trigger.action.outText(WeaponName, 30)
			--trigger.action.outText(currentAirbase, 30)
			
			for key, value in pairs(inventories) do
			
				if(inventories[key].Airbase == currentAirbase) then				-- might have to think about this a bit in the case of multiple inventories that are assigned to the same airbase...
					
					for Key, Value in pairs(inventories[key].Weapons) do
					
						if(inventories[key].Weapons[Key].displayName == WeaponName) then
							--trigger.action.outText("DING DING DING:", 30)
							inventories[key].Weapons[Key].quantity = inventories[key].Weapons[Key].quantity + number
							trigger.action.outText("There are now"..inventories[key].Weapons[Key].quantity.." "..WeaponName.." at "..currentAirbase, 30)
							break
							
						end
					end
					
					break
					
				end
			end
		end
	end
	

end

function Inventory:Add_Weapon(WeaponName, InvAirbase, quantitytoAdd)

	for key, value in pairs(inventories) do
	
		if(inventories[key].Airbase == InvAirbase) then				-- might have to think about this a bit in the case of multiple inventories that are assigned to the same airbase...
			
			for Key, Value in pairs(inventories[key].Weapons) do
			
				if(inventories[key].Weapons[Key].displayName == WeaponName) then

					inventories[key].Weapons[Key].quantity = inventories[key].Weapons[Key].quantity + quantitytoAdd
					
					trigger.action.outText("There are now"..inventories[key].Weapons[Key].quantity.." "..WeaponName.." at "..InvAirbase, 30)
					
					break
					
				end
			end
			
			break
			
		end
	end


end

function Inventory:Add_Fuel(InvAirbase, quantitytoAdd)

	for key, value in pairs(inventories) do
	
		if(inventories[key].Airbase == InvAirbase) then				

			inventories[key].Fuel = inventories[key].Fuel + quantitytoAdd
			
			trigger.action.outText("There is now"..inventories[key].Fuel.." kg of Fuel at"..InvAirbase, 30)
					
			break
					
		end


	end


end

function Inventory:Add_Pilots(InvAirbase, quantitytoAdd)


	for key, value in pairs(inventories) do
	
		if(inventories[key].Airbase == InvAirbase) then				

			inventories[key].PilotLives = inventories[key].PilotLives + quantitytoAdd
			
			trigger.action.outText("There is now"..inventories[key].PilotLives.." kg of Fuel at"..InvAirbase, 30)
					
			break
					
		end


	end


end

function Inventory:Add_GroundUnit(UnitName, InvAirbase, quantitytoAdd)

-- not yet implemented

end

function Inventory:Check(playerUnit, currentAirbase)

	--will probably fail for empty loadouts
	local ValidLoadout = true

	--CHECK Airframe
	descTable = playerUnit:getDesc()
	
	AirframeName = descTable.displayName
	
	--trigger.action.outText("DisplayName:"..AirframeName, 30)

	qty_airframes_available = Inventory_Find_Airframe_Qty(AirframeName, currentAirbase)

	if(qty_airframes_available < 1) then--will probably need to subtract this on birth and release it if player drops out... somehow...
		ValidLoadout = false
	end

	--CHECK PilotLives

	pilot_lives_available = Inventory_Find_PilotLives_Qty(currentAirbase)

	if(pilot_lives_available < 1) then--will probably need to subtract this on birth and release it if player drops out... somehow...
		ValidLoadout = false
	end
	
	--CHECK Fuel
	
	fuel_available = Inventory_Find_Fuel_Qty(currentAirbase)
	
	currentFuelPct = playerUnit:getFuel()
	
	fuelMassMax = descTable.fuelMassMax
	
	myFuel = fuelMassMax*currentFuelPct
	
	trigger.action.outText("There is "..fuel_available.." kg of Fuel at "..currentAirbase.." you currently have "..myFuel.." kg loaded.", 30)
	
	trigger.action.outText("WEAPON CHECK:", 30)

	--CHECK Weapons

	for k, v in pairs(playerUnit:getAmmo()) do
	
		number = v.count
		WeaponName = v.desc.displayName
		
		if(WeaponName ~= nil) then
		
			qty_weap_vailable = Inventory_Find_Weapon_Qty(WeaponName, currentAirbase) 		
			--trigger.action.outText("number:"..number, 30)
			--trigger.action.outText("qty:"..qty_weap_vailable, 30)
			
			if(number > qty_weap_vailable) then
				ValidLoadout = false		
			end
		
		end
			
			
	end

	return ValidLoadout
	
end

function Inventory:get_weapon_qty(WeaponName, currentAirbase)
	
	local num_weapons = 0;
	
	for k, v in pairs(inventories) do

		--trigger.action.outText("QTY CHECK:", 30)
		--trigger.action.outText("key:"..k, 30)
		--trigger.action.outText("airbase"..currentAirbase, 30)
		--trigger.action.outText("test"..inventories[k].Airbase, 30)
		
		if(inventories[k].Airbase == currentAirbase) then
			
		 	for key, value in pairs(inventories[k].Weapons) do
				
				if(inventories[k].Weapons[key].displayName == WeaponName) then
					num_weapons = num_weapons + inventories[k].Weapons[key].quantity
					break
				end
			
			end
		end
	end
	
	trigger.action.outText("There are "..num_weapons.." weapons of type "..WeaponName.." at "..currentAirbase, 30)
	
	return num_weapons
			
end

function Inventory_Find_Airframe_Qty(AirframeName, currentAirbase)
	
	local num_airframes = 0;
	
	for k, v in pairs(inventories) do

		if(inventories[k].Airbase == currentAirbase) then
			
		 	for key, value in pairs(inventories[k].Airframes) do
				
				if(inventories[k].Airframes[key].displayName == AirframeName) then

					num_airframes = num_airframes + inventories[k].Airframes[key].quantity
					--trigger.action.outText("count"..num_airframes, 30)
					break
				end
			
			end
		end
	end
	
	trigger.action.outText("There are "..num_airframes.." airframes of type "..AirframeName.." at "..currentAirbase, 30)
	
	return num_airframes
			
end

function Inventory_Find_PilotLives_Qty(currentAirbase)
	
	local PilotLives = 0;
	
	for k, v in pairs(inventories) do

		if(inventories[k].Airbase == currentAirbase) then
				
			PilotLives = inventories[k].PilotLives
				
		end
	end
	
	trigger.action.outText("There are "..PilotLives.." pilots available at "..currentAirbase, 30)
	
	return PilotLives
			
end

function Inventory_Find_Fuel_Qty(currentAirbase)
		
	local FuelQty = 0;
	
	for k, v in pairs(inventories) do

		if(inventories[k].Airbase == currentAirbase) then
				
			FuelQty = inventories[k].Fuel
				
		end
	end
	
	trigger.action.outText("There is "..FuelQty.." kg of fuel at "..currentAirbase, 30)
	
	return FuelQty
			
end


--in utils now 

function getCurrentAirbase(x_current,y_current,z_current) --Gets the closest airbase to a set of x y z coordinates
	
	
	local base = world.getAirbases()
	local lowestValue = math.huge -- I am an utter amateur to lua, if there is a better/smarter/faster way to do this I am all ears
	
	for i = 1, #base do
		desc = Airbase.getCallsign(base[i])
		point = Airbase.getPoint(base[i])
		
		--trigger.action.outText("\nXcur: "..x_current.."\nYcur:"..y_current.."\nZcur: "..x_current.."\nYcur:".., 120)
	
		diffx = x_current - point.x
		diffy = y_current - point.y
		diffz = z_current - point.z
		
		mag = diffx^2 + diffy^2 + diffz^2 -- don't even need to do sqrt
		
		if(mag < lowestValue) then
		
			lowestValue = mag
			closestAirbase = desc
			--trigger.action.outText("inside getCurrent Airbase.\ndistance: "..lowestValue.."\nairbase:"..closestAirbase, 30)
			
		end		
	   	   
	end
	
	trigger.action.outText("CLOSEST AIRBASE: "..closestAirbase, 30)
	
	return closestAirbase
   
end
]]--


function check_for_deliveries() --TBC

    trigger.action.outText("Checking for deliveries", 30)	
	
 	file = io.open("", "w+") 
	file:write(JSON:encode_pretty(inventories))
	file:close()  

	
end

--[[
function explode_player(playerUnit)

    trigger.action.outText("KABOOM!", 30)	
	trigger.action.explosion(playerUnit:getPoint(), 100)
	
end

function init_inventories_from_master_tables()  --master table constructor. any structural changes should be made here

	INITIALWEAPONQUANTITY = 4
	INITIALAIRCRAFTQUANTITY = 0

	weapon_entry_table = {}
	airframes_entry_table = {}

	function deepcopy(orig)
		local orig_type = type(orig)
		local copy
		if orig_type == 'table' then
			copy = {}
			for orig_key, orig_value in next, orig, nil do
				copy[deepcopy(orig_key)] = deepcopy(orig_value)
			end
			setmetatable(copy, deepcopy(getmetatable(orig)))
		else -- number, string, boolean, etc
			copy = orig
		end
		return copy
	end

	for k, v in pairs(master_displayNames_table) do

		weapon_entry_table[k] = {displayName = v,
								 quantity = INITIALWEAPONQUANTITY,
								 hidden = false, --will likely make use of this for web app plans
								 authorized = true --more grand plans?							 
								}
		
	end

	for k, v in pairs(master_airframes_table) do

		airframes_entry_table[k] = {displayName = v,
									quantity = INITIALAIRCRAFTQUANTITY,
									hidden = false, --will likely make use of this for web app plans						 
									}
		
	end

	for k, v in pairs(syria_master_Airbase_name_table) do

		inventories[k] = {Airbase = v,
						  Weapons = deepcopy(weapon_entry_table),
						  Airframes = deepcopy(airframes_entry_table),
						  Fuel = 1000000,
						  PilotLives = 500,
						  GroundWeapons = 1000				  
						  }
						  
	end
	
end
]]--

function init_tables_from_JSON() --load from a JSON file

    trigger.action.outText("JSON read", 30)	
	
	file = io.open(lfs.writedir().."\\Scripts\\Inventories System\\Inventory\\inventories_init.JSON", "r")
	JSONString = file:read("*all") 
	inventories = JSON:decode(JSONString)
	file:close()
	
	--file = io.open(lfs.writedir().."\\Scripts\\Inventories System\\Economy\\economy_init.JSON", "r")
	--JSONString = file:read("*all") 
	--economy = JSON:decode(JSONString)
	--file:close()

	--file = io.open(lfs.writedir().."\\Scripts\\Inventories System\\Deliveries\\deliveries_init.JSON", "r")
	--JSONString = file:read("*all") 
	--deliveries = JSON:decode(JSONString)
	--file:close()

end

--init_inventories_from_master_tables()
--init_tables_from_JSON()
--world.addEventHandler(EventHandler)
--timer.scheduleFunction(print_to_JSON, {}, timer.getTime() + 120) -- mins mission time required
--timer.scheduleFunction(check_for_deliveries, {}, timer.getTime() + 15) -- mins mission time required

return Inventory