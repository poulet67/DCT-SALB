package.path = package.path .. ";../../lua/?.lua"

map = arg[1] -- which map

map = map:lower()

mapdir = "./"..map.."/"	
options_dir = "./"..map.."/options/"
init_dir = "./"..map.."/initial/"

valid = {
	["caucasus"] = true,
	["marianas"] = true,
	["nevada"] = true,
	["persian gulf"] = true,
	["syria"] = true,
}


inventories_table = {}

JSON = require("libs.JSON")
utils = require("libs.utils")

function empty_table(tbl)

	tbl["airframes"] = {}
	tbl["munitions"] = {}
	tbl["ground units"] = {}
	tbl["naval"] = {}
	--tbl["trains"] = {}
	tbl["other"] = {}

end

function fill_values(dest, source)

	for k, v in pairs(dest) do		
		print("k:" .. k)
		for key, value in pairs(source[k]) do			
			print("key:" .. key)
			if(value > 0) then
				print("value:" .. value)
				dest[k][key] = dest[k][key] or {}
				dest[k][key]["qty"] = value --quantity
			else
			
				dest[k][key] = nil --quantity
				
			end
		end
	
	end

end

function read_JSON_file(filename)
	
	file = io.open(filename, "r")
	
	if(file) then
		JSONString = file:read("*all")
		file:close()
		
		if(JSONString) then
			return JSON:decode(JSONString)
		else
			return nil	
		end
		
	
	else
		
		return nil
	
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
--[[
function read_lua_table(file, tblname)
	assert(file and type(file) == "string", "file path must be provided")
	
	local f = assert(loadfile(file))
	local config = {}
	setfenv(f, config)
	assert(pcall(f))
	local tbl = config
	
	if tblname ~= nil then
		tbl = config[tblname]
	end
	
	return tbl, file

end
]]--

function read_lua_tables(file)
	assert(file and type(file) == "string", "file path must be provided")
	
	local f = assert(loadfile(file))
	local config = {}
	setfenv(f, config)
	assert(pcall(f))
	
	return config

end


if(valid[map]) then
	
	------------- OPTIONS ---------------
	
	options_file = options_dir.."options.tbl"
	game_table = read_lua_tables(options_file) or empty_table
	inventories_table["info"] = game_table
	--empty table required for internal logic
	inventories_table["info"]["empty_table"] = {}
	empty_table(inventories_table["info"]["empty_table"])

	
	-- MASTER TABLE
	
	masterfile = "./master/master.JSON"
	m_table = read_JSON_file(masterfile)
	
	-- AIRBASE LIST
	
	airbase_file = mapdir.."bases.JSON"	
	AB_list = read_JSON_file(airbase_file)
		
	-- CONFIG TABLE
	
	cfg_file = mapdir..map..".cfg"
	cfg_tbl = read_lua_file(cfg_file)
		
	-- DEFAULT TABLE
	
	dft_file = mapdir.."default.JSON"
	df_tbl = read_JSON_file(dft_file) or empty_table
	
	
	-- PREAMBLE
	-- "make sure the table has all airbases"
	
	for k, v in ipairs(AB_list) do
		 
		 if(cfg_tbl[v] == nil) then -- make sure all airbases are present in cfg
		 
			cfg_tbl[v] = {}		
			print(v.." added to inventory list")
			
		 end
		 
	end
	
	-- MAIN 
	-- inventory master table generation

	
	for k, v in pairs(cfg_tbl) do
		
		print(k)
		
		local state = v["Initial State"] or "empty"
		local state = state:lower()
		
		inventories_table[k] = {}
		empty_table(inventories_table[k])
		
		if(state == "default") then
			
			print("default")
			
			--[[for key, value in pairs(inventories_table[k]) do
				print("k:" .. k)
				print("key:" .. key)
				for ky, vl in pairs(df_tbl[key]) do					
					print("ky:" .. ky)
					if(vl > 0) then
						
						inventories_table[k][key][ky] = {}
						inventories_table[k][key][ky]["qty"] = vl
						
					end
				
				end
			
			end--]]
			
			fill_values(inventories_table[k], df_tbl)
		
		elseif(state == "specific") then
			
			print("specific")
			
			inv_file = init_dir..k..".JSON"
			print(inv_file:lower())
			file = io.open(inv_file:lower(), "r")
			
			if(file) then
				print("file found: "..inv_file)
				JSONString = file:read("*all")			
				file:close()
				
				if(JSONString) then					
					print("JSON Read")
					inv_table = JSON:decode(JSONString)
					
					if(not inv_table) then
						
						print("JSON decode FAILED! Using empty table")
						inv_table = empty_table
					
					end
				else						
					print("JSON Read FAILED!")
					inv_table = empty_table
				end
				
				
			else	
				print("file not found!")
				inv_table = empty_table		
				
			end

				
		elseif(state == "value") then
		
			print("values")
			if(v["Values"]) then
				
				for keys, values in pairs(v["Values"]) do
					
					print(keys)
					
					for a, b in pairs(m_table[keys]) do
												
						inventories_table[k][keys][a] = inventories_table[k][keys][a] or {}
						inventories_table[k][keys][a]["qty"] = values 						
				
					end
				
				end
				
				
			else
				-- empty already, do nothing
			end
			
		elseif(state == "empty") then
			print("empty")
			
		end
		
		 
	end

	
	filename = mapdir.."output/inventory.JSON"
	copy_file = "../../theater/tables/inventories/inventory.JSON"
	
	file = io.open(filename, "w+")
	file:write(JSON:encode_pretty(inventories_table))
	file:close()
	
	file = io.open(copy_file, "w+")
	file:write(JSON:encode_pretty(inventories_table))
	file:close()
	
	print("done")
	
end
