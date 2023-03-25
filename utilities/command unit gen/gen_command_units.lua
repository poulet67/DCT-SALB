-- Forget .stm templates
-- Just add the units you want to a .miz file and run this script
-- will export it in DCT's native, flattened format
-- 
-- Could encapsulate this better, for now fuck it
--
-- JSON ified of course

local JSON = require("libs.JSON")
local utils = require("libs.utils")
local dctutils = require("dct.utils")
local Logger = require("dct.libs.Logger")
local Formation = require("dct.systems.formation")


thispath = lfs.writedir() .. "Mods\\tech\\DCT"
formation_path = thispath..utils.sep.."utilities"..utils.sep.."command unit gen"..utils.sep.."formation_rules.lua"

env.info("STARTING GEN COMMAND UNITS")
env.info(formation_path)	

env.info("----------------------- FORMATIONS ----------------")
--utils.tprint(Formation_Table.Master.Ground)
-- BLUEFOR -- 

blue_table = {}

--utils.tprint(DCS_ground_unit_table)

function empty_route()
			return {["spans"]= {
					     		}
					}

end						
					
function empty_task()
			return {
					["id"] = "ComboTask",
					["params"] = {
								["tasks"] = {},																					
								}
				  }
				  
end				  
																
function simple_point()
			return {[1]= {
															["alt"] = {},
															["type"] = "Turning Point",
															["ETA"] = 0,
															["ETA_locked"] = true,
															["speed"] = 0,
															["alt"] = {},
															["x"] = {},
															["y"] = {},
															["formation_template"] = {},
															["action"] = "",
															["task"] = empty_task(),
															["alt_type"] = "BARO",
															}
																
																}

end

function empty_template()
		return {[1] = {
								countryid = {},
								category = {},
								data = {
										["visible"] = false,
										["points"] = simple_point(), 
										["route"] = empty_route(),			
										["groupID"] = 0, --??? Might be important
										["tasks"] = {},
										["hidden"] = false,
										["units"] = {},
										["x"] = {},
										["y"] = {},
										["uncontrollable"] = {},
										["name"] = {},
										["start_time"] = 0,
										["task"] = "Ground Nothing",
										}
							}
					}

end


--blue_flat = 6returnFlatTable("BLUE")

--finds keyword in formation defs

function find_keyword(word, table_in)
	env.info("In search, word:"..word)
	local lot_queue = {}
	
	for k,v in pairs(table_in) do
		--env.info(k)
		if type(v) == "table" then
			--env.info("Compare: "..string.upper(k).." with: "..word)
			if string.match(string.upper(word), string.upper(k)) then				
				env.info("Returning:"..k)
				return k
			else
				table.insert(lot_queue, v)
			end	
		
		end
	
	end
	
	--env.info("LOT Queue:")
	--utils.tprint(lot_queue)
	
	for k,v in ipairs(lot_queue) do
		
		--env.info("Deeper...")
		x = find_keyword(word, v)
		
		if(x) then
			return x			
		end
		
	end
	
	return nil
	
end

--*******************************************************BLUEFOR*******************************************************

DCS_airframe_table = coalition.getGroups(2 , 0) 
DCS_helo_table = coalition.getGroups(2 , 1)
DCS_ground_unit_table = coalition.getGroups(2 , 2)
DCS_ship_table = coalition.getGroups(2 , 3)
train_table = coalition.getGroups(2 , 4) -- maybe might be useful in future?

--******************************************************GROUND FORMATIONS *****************************
blue_table = {}
blue_table["GROUND"] = {}
blue_table["HELOS"] = {}
blue_table["AIR"] = {}

for key, value in pairs(DCS_ground_unit_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = find_keyword(name, Formation_Table.Master.Ground.BLUE)
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.Ground_Unit -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)
		if(blue_table["GROUND"][formString] == nil) then
			blue_table["GROUND"][formString] = {}
		end
	
		table.insert(blue_table["GROUND"][formString], a)	
		
	end
	

	
	
end

--******************************************************HELICOPTER FORMATIONS *****************************

for key, value in pairs(DCS_helo_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = find_keyword(name, Formation_Table.Master.Air.BLUE)
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
		
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.HELICOPTER     -- 1
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)
		
		if(blue_table["HELOS"][formString] == nil) then
			blue_table["HELOS"][formString] = {}
		end
	
		table.insert(blue_table["HELOS"][formString], a)	
		
		
	end
	
end

for key, value in pairs(DCS_airframe_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = find_keyword(name, Formation_Table.Master.Air.BLUE)
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.AIRPLANE -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)
		if(blue_table["AIR"][formString] == nil) then
			blue_table["AIR"][formString] = {}
		end
	
		table.insert(blue_table["AIR"][formString], a)	
		
	end
	

	
	
end

--env.info("------------------------->      Ground table complete:")

utils.tprint(blue_table)
	
filename = thispath..utils.sep.."utilities"..utils.sep.."command unit gen"..utils.sep.."output"..utils.sep.."blue_formations.JSON"
	
file = io.open(filename, "w+")
file:write(JSON:encode_pretty(blue_table))
file:close()

--************************************************LOGI units*********************************************************

blue_table = {}
blue_table["GROUND"] = {}
blue_table["HELOS"] = {}

for key, value in pairs(DCS_ground_unit_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = string.match(name, "LOGI")
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.GROUND_UNIT -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() 
			a[1]["data"]["units"][k]["playerCanDrive"] = true 
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
	
		blue_table["GROUND"] = {}
	
		table.insert(blue_table["GROUND"], a)	
		
	end
	

	
	
end

for key, value in pairs(DCS_helo_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = string.match(name, "LOGI")
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.HELICOPTER     -- 1
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)

		blue_table["HELOS"] = {}
	
		table.insert(blue_table["HELOS"], a)	
		
	end
	
end

for key, value in pairs(DCS_airframe_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = string.match(name, "LOGI")
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.AIRPLANE -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)

		blue_table["AIR"] = {}
	
		table.insert(blue_table["AIR"], a)	
		
	end
	

	
	
end

--env.info("------------------------->      Ground table complete:")

--tils.tprint(blue_table)
	
filename = thispath..utils.sep.."utilities"..utils.sep.."command unit gen"..utils.sep.."output"..utils.sep.."blue_logi.JSON"
	
file = io.open(filename, "w+")
file:write(JSON:encode_pretty(blue_table))
file:close()


--***********************************************

--*******************************************************REDFOR*******************************************************

DCS_airframe_table = coalition.getGroups(1 , 0) 
DCS_helo_table = coalition.getGroups(1 , 1)
DCS_ground_unit_table = coalition.getGroups(1 , 2)
DCS_ship_table = coalition.getGroups(1 , 3)
train_table = coalition.getGroups(1 , 4) -- maybe might be useful in future?

red_table = {}
red_table["GROUND"] = {}
red_table["HELOS"] = {}
red_table["AIR"] = {}
--******************************************************FORMATIONS *****************************


for key, value in pairs(DCS_ground_unit_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = find_keyword(name, Formation_Table.Master.Ground.RED)
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.Ground_Unit -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)
		if(red_table["GROUND"][formString] == nil) then
			red_table["GROUND"][formString] = {}
		end
	
		table.insert(red_table["GROUND"][formString], a)	
		
	end
	

	
	
end

for key, value in pairs(DCS_helo_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = find_keyword(name, Formation_Table.Master.Air.RED)
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
		
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.HELICOPTER     -- 1
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)
		
		if(red_table["HELOS"][formString] == nil) then
			red_table["HELOS"][formString] = {}
		end
	
		table.insert(red_table["HELOS"][formString], a)	
		
		
	end
	
end

for key, value in pairs(DCS_airframe_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = find_keyword(name, Formation_Table.Master.Air.BLUE)
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.AIRPLANE -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)

		
		if(red_table["AIR"][formString] == nil) then
			red_table["AIR"][formString] = {}
		end
	
		table.insert(red_table["AIR"][formString], a)	
		
		
	end
	

	
	
end
--env.info("------------------------->      Ground table complete:")

utils.tprint(red_table)
	
filename = thispath..utils.sep.."utilities"..utils.sep.."command unit gen"..utils.sep.."output"..utils.sep.."red_formations.JSON"
	
file = io.open(filename, "w+")
file:write(JSON:encode_pretty(red_table))
file:close()

--************************************************LOGI units*********************************************************

red_table = {}
red_table["GROUND"] = {}
red_table["HELOS"] = {}
red_table["AIR"] = {}

for key, value in pairs(DCS_ground_unit_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = string.match(name, "LOGI")
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.Ground_Unit -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
	
		
	
		table.insert(red_table["GROUND"], a)	
		
	end
	

	
	
end

for key, value in pairs(DCS_helo_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = string.match(name, "LOGI")
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.HELICOPTER -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)
	
		table.insert(red_table["HELOS"], a)	
		
	end
	
end

for key, value in pairs(DCS_airframe_table) do
	
	-- read through each group in the table, if any of these match the formation table, save it as a template
	thisGroup = value
	name = thisGroup:getName()
	formString = string.match(name, "LOGI")
	countryId = thisGroup:getUnit(1):getCountry()
	unitTable = thisGroup:getUnits()
	g_pos = thisGroup:getUnit(1):getPoint()
	
	
	if formString then
		--env.info("Found: "..formString.." for: "..name)
		
		a = empty_template()
		--utils.tprint(a)
			
		a[1]["countryid"] = countryId
		a[1]["category"] = Unit.Category.AIRPLANE -- 2
		a[1]["name"] = name  
		a[1]["data"]["name"] = name  
		a[1]["x"] = g_pos.x  
		a[1]["y"] = g_pos.z  
		
		for k,v in pairs(unitTable) do
			a[1]["data"]["units"][k] = {}
			d_table = v:getDesc()
			u_pt = v:getPoint()
			--env.info("desc table")
			--utils.tprint(d_table)
			a[1]["data"]["units"][k]["type"] = v:getTypeName()
			a[1]["data"]["units"][k]["transportable"] = {["randomTransportable"] = false}
			a[1]["data"]["units"][k]["unitId"] = k
			a[1]["data"]["units"][k]["skill"] = "Average"
			a[1]["data"]["units"][k]["x"] = u_pt.x
			a[1]["data"]["units"][k]["y"] = u_pt.z --lmao dcs
			a[1]["data"]["units"][k]["name"] = v:getName() --lmao dcs
			a[1]["data"]["units"][k]["playerCanDrive"] = true --lmao dcs
			a[1]["data"]["units"][k]["heading"] = 0 --bit of a pain to determine, leaving 0 for now			
		
		end
		--x and y points are actually important, since they determine offset (or something idk.. might just spawn em in on one another)
	
		table.insert(red_table["AIR"], a)	
		
	end	
	
end

--env.info("------------------------->      Ground table complete:")

--tils.tprint(blue_table)
	
filename = thispath..utils.sep.."utilities"..utils.sep.."command unit gen"..utils.sep.."output"..utils.sep.."red_logi.JSON"
	
file = io.open(filename, "w+")
file:write(JSON:encode_pretty(red_table))
file:close()


--***********************************************