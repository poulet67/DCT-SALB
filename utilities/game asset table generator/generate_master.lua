-- Setup package path so we can require DCT utils
do
	if not lfs or not io or not require then
		local assertmsg = "DCT requires DCS mission scripting environment"..
			" to be modified, the file needing to be changed can be found"..
			" at $DCS_ROOT\\Scripts\\MissionScripting.lua. Comment out"..
			" the removal of lfs and io and the setting of 'require' to"..
			" nil."
		assert(false, assertmsg)
	end

	-- Check that DCT mod is installed
	modpath = lfs.writedir() .. "Mods\\tech\\DCT"
	if lfs.attributes(modpath) == nil then
		local errmsg = "DCT: module not installed, mission not DCT enabled"
		if dctsettings.nomodlog then
			env.error(errmsg)
		else
			assert(false, errmsg)
		end
	else
		package.path = package.path .. ";" .. modpath .. "\\lua\\?.lua;"
		
	end
end
--
-- _Important_ INVENTORY TABLE DEFINITION HERE:
--
--	THIS WILL DEFINE THE "MASTER" TABLE USED BY THE INVENTORY TABLE GENERATOR
--	ALL POSSIBLE UNIT TYPES AND ARMAMENTS THAT MAY (OR MAY NOT) BE USED BY THE 
--	INVENTORY AND/OR DCT SPAWN SYSTEM WILL BE ENUMERATED IN THIS TABLE--	

master_table = {}
master_table["airframes"] = {}
master_table["munitions"] = {}
master_table["ground units"] = {}
master_table["naval"] = {}
--master_table["trains"] = {}
master_table["other"] = {}
master_table["ammo_users"] = {}

template_table = {} -- for ease of editing
template_table["airframes"] = {}
template_table["munitions"] = {}
template_table["ground units"] = {}
template_table["naval"] = {}
--template_table["trains"] = {}
template_table["other"] = {}
--ground_unit_ammo_users = {}

local JSON = require("libs.JSON")
local utils = require("libs.utils")

DCS_airframe_table = coalition.getGroups(2 , 0) 
DCS_helo_table = coalition.getGroups(2 , 1)
DCS_ground_unit_table = coalition.getGroups(2 , 2)
DCS_ship_table = coalition.getGroups(2 , 3)
train_table = coalition.getGroups(2 , 4) -- maybe might be useful in future?

env.info("----------------------- GET ASSETS ----------------&&& ")


for key, value in pairs(DCS_airframe_table) do
	
	groupObj = value
	unit = groupObj:getUnit(1)
	name = unit:getTypeName()
	
	--DISPLAY NAMES: DCS, as you may know, is a pile of spaghetti.
	-- some things have displayNames, some don't.
	-- Some things have typeNames which are awful and not really suitable for display. 
	-- some of these do not have a displayName either. 
	-- 
	-- To deal with this we will leave the field, incase users want to fill these ones in with displayNames that DCT can use that don't suck
	--
	-- It is anticipated that with some use these fields will be filled in. 
	
	master_table["airframes"][name] = {}
	master_table["airframes"][name]["displayName"] = false
	template_table["airframes"][name] = 0
	
	ammo_tbl = unit:getAmmo()
	
	for k,v in pairs(ammo_tbl or {}) do
		name = v.desc.typeName
		displayName = v.desc.displayName
		master_table["munitions"][name] = {}
		master_table["munitions"][name]["displayName"] = displayName --these display names however, for the most part, appear to be solid.		
		template_table["munitions"][displayName] = 0
	end
	
end

for key, value in pairs(DCS_helo_table) do
	
	groupObj = value
	unit = groupObj:getUnit(1)
	name = unit:getTypeName()
	--displayName = unit:getName() --A lot of DCS typeNames are... Bad. This will add a field for them with their display name so they can at least be used within DCT
	master_table["airframes"][name] = {}
	master_table["airframes"][name]["displayName"] = false	
	template_table["airframes"][name] = 0
	
	ammo_tbl = unit:getAmmo()
	
	for k,v in pairs(ammo_tbl or {}) do
		name = v.desc.typeName
		displayName = v.desc.displayName
		master_table["munitions"][name] = {}
		master_table["munitions"][name]["displayName"] = displayName
		template_table["munitions"][displayName] = 0
	end
	
	
end

for key, value in pairs(DCS_ground_unit_table) do
	
	groupObj = value
	unit = groupObj:getUnit(1)
	unit_name = unit:getTypeName()
	--displayName = unit:getName() --A lot of DCS typeNames are... Bad. This will add a field for them with their display name so they can at least be used within DCT
	master_table["ground units"][unit_name] = {}
	master_table["ground units"][unit_name]["displayName"] = false
	template_table["ground units"][unit_name] = 0
	
	ammo_tbl = unit:getAmmo()
	
	for k,v in pairs(ammo_tbl or {}) do -- as of 03/22 ground units and ships have no ammo tables

		name = v.desc.typeName
		displayName = v.desc.displayName
		env.info("AMMO FOUND: " .. name)
		master_table["munitions"][name] = {}
		master_table["munitions"][name]["displayName"] = displayName
		template_table["munitions"][displayName] = 0
		
		master_table["ammo_users"][unit_name] = master_table["ammo_users"][unit_name] or {}
		master_table["ammo_users"][unit_name][name] = true
		
	end	
	
	
end

for key, value in pairs(DCS_ship_table) do
	
	groupObj = value
	unit = groupObj:getUnit(1)
	unit_name = unit:getTypeName()-- for Aircraft, Naval and ground, this gives the group name rather than the displayName (maybe it doesn't exist... god DCS is such a mess)
	--displayName = unit:getName() --A lot of DCS typeNames are... Bad. This will add a field for them with their display name so they can at least be used within DCT
	master_table["naval"][unit_name] = {}
	master_table["naval"][unit_name]["displayName"] = false
	template_table["naval"][unit_name] = 0

	ammo_tbl = unit:getAmmo()
	
	for k,v in pairs(ammo_tbl or {}) do -- as of 03/22 ground units and ships have no ammo tables
		name = v.desc.typeName
		displayName = v.desc.displayName
		env.info("AMMO FOUND: " .. name)
		master_table["munitions"][name] = {}
		master_table["munitions"][name]["displayName"] = displayName
		
		master_table["ammo_users"][unit_name] = master_table["ammo_users"][unit_name] or {}
		master_table["ammo_users"][unit_name][name] = true		
		
		template_table["munitions"][displayName] = 0
		
	end
	
	
end

--
-- NON DCS assets for DCT logistic system:
--
--

master_table["other"] =
{
   ["Pilots"] = {},
   ["Manpower"] = {},
   ["Diesel"] = {},
   ["Aviation Fuel"] = {},
   ["Amenities"] = {},
   ["Mail"] = {},
   ["Casualties"] = {},
  --["Transit"] = {}, -- need to think of a good term for this...
   ["Ammo"] = {},
   
}

for k, v in pairs(master_table["other"]) do

	template_table["other"][k] = 0;
	
end

-- load link table and write to master
--[[
local lt_file = modpath..utils.sep.."utilities"..utils.sep.."game asset table generator"..utils.sep.."link.tbl"
ln_table = utils.readlua(lt_file, "ln_table")
--ln_table = ln_table["ln_table"]

env.info(lt_file)
env.info(type(ln_table))
env.info("LOADING LINK TABLE")
utils.tprint(ln_table)

for k, v in pairs(ln_table) do
	
	env.info("COPY LINK TABLE")
	env.info(k)
	
	for key, value in pairs(v) do
		env.info("INSIDE")
		env.info("key"..key.." value"..value)
		master_table[k][key]["link"] = value
	end

end
]]--

-- load displayname table and insert into master
local dn_file = modpath..utils.sep.."utilities"..utils.sep.."game asset table generator"..utils.sep.."display_names.tbl"
dn_table = utils.readlua(dn_file, "dn_table")
--dn_table = dn_table["dn_table"] -- yeah this is a bit absurd

env.info(dn_file)
env.info("LOADING DISPLAY NAME TABLE")
env.info(type(dn_table))
utils.tprint(dn_table)

for k, v in pairs(dn_table) do

	env.info("COPY DISPLAY NAME TABLE")
	env.info(k)
	
	for key, value in pairs(v) do
	
		env.info(key)	
		master_table[k][v] = dn_table[k][v]	
		
	end

end

-- SAVE the master table into the tables folder
local tablepath = modpath..utils.sep.."theater"..utils.sep.."tables"..utils.sep.."inventories"..utils.sep
filename = tablepath.."master"..".JSON"


file = io.open(filename, "w+")
file:write(JSON:encode_pretty(master_table))
file:close()

-- SAVE the template table into the tables folder
local tablepath = modpath..utils.sep.."utilities"..utils.sep.."inventory generator"..utils.sep.."template.JSON"

file = io.open(tablepath, "w+")
env.info("TEMPLATE TABLE")

utils.tprint(template_table)
file:write(JSON:encode_pretty(template_table))
file:close()

--[[
-- SAVE the ground unit ammo user table
local tablepath = modpath..utils.sep.."theater"..utils.sep.."tables"..utils.sep.."inventories"..utils.sep
filename = tablepath.."ammo_users"..".JSON"


file = io.open(filename, "w+")
file:write(JSON:encode_pretty(ground_unit_ammo_users))
file:close()
]]--