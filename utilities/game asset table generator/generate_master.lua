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

function read_lua_file(filename)
	
	file = io.open(filename, "r")
	
	if(file) then
		print("file found: " .. filename)
		fstring = file:read("*all")
		file:close()
		
		return assert(loadstring(fstring)())
	
	else
		
		return nil
	
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
local dctutils = require("dct.utils")

DCS_airframe_table = coalition.getGroups(2 , 0) 
DCS_helo_table = coalition.getGroups(2 , 1)
DCS_ground_unit_table = coalition.getGroups(2 , 2)
DCS_ship_table = coalition.getGroups(2 , 3)
train_table = coalition.getGroups(2 , 4) -- maybe might be useful in future?

env.info("----------------------- GET ASSETS ----------------&&& ")


for key, value in pairs(DCS_airframe_table) do
	
	local groupObj = value
	local unit = groupObj:getUnit(1)
	local name = unit:getTypeName()
	local desc = unit:getDesc()
	
	--DISPLAY NAMES: DCS, as you may know, is a pile of spaghetti.
	-- some things have displayNames, some don't.
	-- Some things have typeNames which are awful and not really suitable for display. 
	-- some of these do not have a displayName either. 
	-- 
	-- To deal with this we will leave the field, incase users want to fill these ones in with displayNames that DCT can use that don't suck
	--
	-- It is anticipated that with some use these fields will be filled in. 
	
	
	
	master_table["airframes"][name] = {}	
	master_table["airframes"][name]["displayName"] = desc.displayName or false
	template_table["airframes"][name] = 0
	
	local ammo_tbl = unit:getAmmo()
	
	for k,v in pairs(ammo_tbl or {}) do
		name = v.desc.typeName
		displayName = v.desc.displayName
		master_table["munitions"][name] = {}
		master_table["munitions"][name]["displayName"] = displayName or false --these display names however, for the most part, appear to be solid.		
		template_table["munitions"][displayName] = 0
	end
	
end

for key, value in pairs(DCS_helo_table) do
	
	local groupObj = value
	local unit = groupObj:getUnit(1)
	local name = unit:getTypeName()
	local desc = unit:getDesc()
	--displayName = unit:getName() --A lot of DCS typeNames are... Bad. This will add a field for them with their display name so they can at least be used within DCT
	master_table["airframes"][name] = {}
	master_table["airframes"][name]["displayName"] = desc.displayName or false	
	template_table["airframes"][name] = 0
	
	local ammo_tbl = unit:getAmmo()
	
	for k,v in pairs(ammo_tbl or {}) do
		name = v.desc.typeName
		displayName = v.desc.displayName
		master_table["munitions"][name] = {}
		master_table["munitions"][name]["displayName"] = displayName or false
		template_table["munitions"][displayName] = 0
	end
	
	
end

for key, value in pairs(DCS_ground_unit_table) do
	
	local groupObj = value
	local unit = groupObj:getUnit(1)
	local unit_name = unit:getTypeName()
	local desc = unit:getDesc()
	--displayName = unit:getName() --A lot of DCS typeNames are... Bad. This will add a field for them with their display name so they can at least be used within DCT
	master_table["ground units"][unit_name] = {}
	master_table["ground units"][unit_name]["displayName"] = desc.displayName or false
	template_table["ground units"][unit_name] = 0
	
	local ammo_tbl = unit:getAmmo()
	
	for k,v in pairs(ammo_tbl or {}) do -- as of 03/22 ground units and ships have no ammo tables

		name = v.desc.typeName
		displayName = v.desc.displayName
		env.info("AMMO FOUND: " .. name)
		master_table["munitions"][name] = {}
		master_table["munitions"][name]["displayName"] = displayName or false
		template_table["munitions"][displayName] = 0
		
		master_table["ammo_users"][unit_name] = master_table["ammo_users"][unit_name] or {}
		master_table["ammo_users"][unit_name][name] = true
		
	end	
	
	
end

for key, value in pairs(DCS_ship_table) do
	
	local groupObj = value
	local unit = groupObj:getUnit(1)
	local unit_name = unit:getTypeName()-- for Aircraft, Naval and ground, this gives the group name rather than the displayName (maybe it doesn't exist... god DCS is such a mess)
	local desc = unit:getDesc()
	--displayName = unit:getName() --A lot of DCS typeNames are... Bad. This will add a field for them with their display name so they can at least be used within DCT
	master_table["naval"][unit_name] = {}
	master_table["naval"][unit_name]["displayName"] = desc.displayName or false
	template_table["naval"][unit_name] = 0

	local ammo_tbl = unit:getAmmo()
	
	for k,v in pairs(ammo_tbl or {}) do -- as of 03/22 ground units and ships have no ammo tables
		name = v.desc.typeName
		displayName = v.desc.displayName
		env.info("AMMO FOUND: " .. name)
		master_table["munitions"][name] = {}
		master_table["munitions"][name]["displayName"] = displayName or false
		
		master_table["ammo_users"][unit_name] = master_table["ammo_users"][unit_name] or {}
		master_table["ammo_users"][unit_name][name] = true		
		
		template_table["munitions"][displayName] = 0
		
	end
	
	
end

-- Append the game assets from options table to the template
options_path = modpath..utils.sep.."utilities"..utils.sep.."inventory generator"..utils.sep.."options"..utils.sep.."options.tbl"
game_assets = utils.readlua(options_path, "game_assets")

for k, v in pairs(game_assets) do
	template_table["other"][k] = 0
end

-- SAVE the master table into the inventory generator master folder


local tablepath = modpath..utils.sep.."utilities"..utils.sep.."inventory generator"..utils.sep --saves and overwrites the inventory generator master
master_filename = tablepath..utils.sep.."master"..utils.sep.."master.JSON"
template_filename = tablepath..utils.sep.."template.JSON"

copy_filename = modpath..utils.sep.."utilities"..utils.sep.."game asset table generator"..utils.sep.."output"..utils.sep.."master.JSON" -- and also saves a copy to the "output" folder

file = io.open(master_filename, "w+")
file:write(JSON:encode_pretty(master_table))
file:close()

file = io.open(template_filename, "w+")
file:write(JSON:encode_pretty(template_table))
file:close()

file = io.open(copy_filename, "w+")
file:write(JSON:encode_pretty(master_table))
file:close()
