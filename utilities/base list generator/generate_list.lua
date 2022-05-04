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


local JSON = require("libs.JSON")
local utils = require("libs.utils")
local dctutils = require("dct.utils")

-- first get all airbases on map
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

--Now append any bases

map = string.lower(env.mission.theatre)

local tablepath = modpath..utils.sep.."utilities"..utils.sep.."base list generator"..utils.sep.."bases"..utils.sep

for filename in lfs.dir(tablepath) do
	if string.match(filename, ".tbl") then
				
		Logger:debug("Generate List, filename: "..filename)	
				
		bases = dctutils.read_JSON_file(tablepath..filename)
		
		for k,v in pairs(bases) do
			table.insert(myBaseTbl,v)
		end
	end
	
end



-- Now save to output and inventory generator

local outputpath = modpath..utils.sep.."utilities"..utils.sep.."base list generator"..utils.sep.."output"..utils.sep.."bases.JSON"
local invpath = modpath..utils.sep.."utilities"..utils.sep.."inventory generator"..utils.sep..map..utils.sep.."bases.JSON"

file = io.open(outputpath, "w+")
file:write(JSON:encode_pretty(myBaseTbl))
file:close()

file = io.open(invpath, "w+")
file:write(JSON:encode_pretty(myBaseTbl))
file:close()