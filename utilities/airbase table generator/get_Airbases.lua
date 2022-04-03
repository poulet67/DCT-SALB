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


local utils = require("libs.utils")

local base = world.getAirbases()
local myBaseTbl = {}
for i = 1, #base do
   local info = {}
   --info.desc = Airbase.getDesc(base[i])
   --info.callsign = Airbase.getCallsign(base[i])
   --info.id = Airbase.getID(base[i])
   --info.cat = Airbase.getCategory(base[i])
   --info.point = Airbase.getPoint(base[i])
   info.name = Airbase.getName(base[i])
   
   if Airbase.getUnit(base[i]) then
	   info.unitId = Airbase.getUnit(base[i]):getID()
   end
   
   table.insert(myBaseTbl, info.name)
   
end

this_theater = env.mission.theatre
env.info("BING BING BING       "..this_theater)

local tablepath = modpath..utils.sep.."utilities"..utils.sep.."airbase table generator"..utils.sep..this_theater..utils.sep
filename = tablepath..this_theater..".tbl"

file = io.open(filename, "w+")
file:close()

utils.savetable(myBaseTbl,filename)