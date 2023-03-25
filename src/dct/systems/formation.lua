--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Formation class
--
--
--
--]]


local dctutils   = require("dct.utils")
local utils   = require("libs.utils")
local JSON   = require("libs.JSON")
local class  = require("libs.namedclass")
local Logger = require("dct.libs.Logger").getByName("Formation")
local enum        = require("dct.enum")
local settings    = _G.dct.settings

-- GLOBALS

Formation_Table = {}
Formation_Table.Master = {}
Formation_Table.Master.Ground = {}
Formation_Table.Master.Air = {}
Formation_Table.Ground = {}
Formation_Table.Ground.BLUE = {}
Formation_Table.Ground.RED = {}

types_Brigade = {"Combined Arms"} -- just a lazy way for me to do this

types_Battalion = {"Combined Arms", "Armored", "Anti-Air", "Artillery", "Support"} 

types_Battery = {"Anti-Air", "Artillery",} 

types_Company = {"Armored", "Anti-Air", "Support", "Mechanized", "Motorized"}	

types_Platoon = {"Armored", "Anti-Air", "Support", "Mechanized", "Motorized"}	

types_Squad = {"Marines", "Airborne", "Mortar", "Rifle", "Engineer"}	

types_Team = {"JTAC", "Engineer", "Recon"} 

Formation_Table.Master.Ground.BLUE = {["Brigade"] = {--["Top"] = true,
									["CP Reward"] = 5000,
									["Types"] = types_Brigade,									
									["Batallion"] = {["Min"] = 3,
													 ["Max"] = 8,
													 ["CP Reward"] = 1000,
													 ["Types"] = types_Battalion,
													 ["Company"] = {
																	["Min"] = 3,
																	["Max"] = 6,
																	["CP Reward"] = 300,
																	["Types"] = types_Company,
																	["Platoon"] = {["CP Reward"] = 100,
																				   ["Min"] = 3,
																				   ["Max"] = 4,
																				   ["Types"] = types_Platoon,
																				   ["Squad"] = {["Min"] = 3,
																								 ["Max"] = 3,
																								 ["CP Reward"] = 0,
																								 ["Infantry"] = true,
																								 ["Types"] = types_Squad,
																								 ["Team"] = {
																												["Min"] = 2,
																												["Max"] = 3,
																												["CP Reward"] = 0,
																												["Types"] = types_Team,
																												["Infantry"] = true,
																											}
																								},
																				 }
																		
																	}
													   },
													   
										 ["Battery"] = {["Min"] = 0,
														["Max"] = 2,
														["CP Reward"] = 500
													   }
									
									
									
													}
									}
		
function get_ground_types(table_in, table_out, prev_form)
		
	local string_table = {}
	
	local formation_string = {};
		
	local lot_queue = {}
	
	for k,v in pairs(table_in) do		
		if type(v) == "table" and k ~= "Types" then
			table_out[k] = {}
			table.insert(string_table, k)
			table.insert(lot_queue, v)
		elseif k == "Types" then
			assert(prev_form, "error in formation table structure")
			table_out[prev_form] = v
		end
	
	end
	
	table_out[formation_string] = values
		
	for i,subtable in ipairs(lot_queue) do		
		env.info("Deeper...")
		table_out = get_ground_types(subtable, table_out, string_table[i])
				
	end
	
	return table_out
	
end

Formation_Table.Ground.BLUE.Types = get_ground_types(Formation_Table.Master.Ground.BLUE, {})


function Formation_Table.Ground.BLUE.matchTypes(string_in)
	
	Logger:debug("in match types BLUE: "..string_in)
	
	for k,v in pairs(Formation_Table.Ground.BLUE.Types) do
		Logger:debug(k)
		if string.match(string.upper(string_in), string.upper(k)) then
		
			Logger:debug("match found! "..k)
			return k
			
		end
	
	end
	
	return nil
	
end

	
Formation_Table.Master.Air.BLUE = {
									["Air Group"] = {["CP Reward"] = 3000,
													 ["Wing"] = {
																	["Min"] = 3,
																	["Max"] = 4,
																	["CP Reward"] = 2000,
																	["Squadron"] = {["CP Reward"] = 1000,
																				    ["Min"] = 3,
																				    ["Max"] = 4,
																				    ["Flight"] = {["Min"] = 3,
																								 ["Max"] = 6,
																								 ["CP Reward"] = 100,
																								 ["Ship"] = {
																												["Min"] = 2,
																												["Max"] = 4,
																												["CP Reward"] = 0,
																											}
																								},
																				 }
																		
																	}
													   }
									
									
									
								}
						
						
Formation_Table.Master.Air.RED = {
									["Air Group"] = {["CP Reward"] = 3000,
													 ["Wing"] = {
																	["Min"] = 3,
																	["Max"] = 4,
																	["CP Reward"] = 2000,
																	["Squadron"] = {["CP Reward"] = 1000,
																				    ["Min"] = 3,
																				    ["Max"] = 4,
																				    ["Flight"] = {["Min"] = 3,
																								 ["Max"] = 6,
																								 ["CP Reward"] = 100,
																								 ["Ship"] = {
																												["Min"] = 2,
																												["Max"] = 4,
																												["CP Reward"] = 0,
																											}
																								},
																				 }
																		
																	}
													   }					
									
									
										}
						
Formation_Table.Master.Ground.RED = {["Regiment"] = {--["Top"] = true,
									["CP Reward"] = 5000,
									["Types"] = types_Brigade,	
									["Batallion"] = {["Min"] = 3,
													 ["Max"] = 5,
													 ["CP Reward"] = 1000,
													 ["Types"] = types_Battalion,	
													 ["Company"] = {
																	["Min"] = 3,
																	["Max"] = 6,
																	["CP Reward"] = 300,
																	["Types"] = types_Company,	
																	["Platoon"] = {["CP Reward"] = 100,
																				   ["Min"] = 3,
																				   ["Max"] = 4,
																				   ["Types"] = types_Platoon,	
																				   ["Squad"] = {["Min"] = 3,
																								 ["Max"] = 3,
																								 ["CP Reward"] = 0,
																								 ["Types"] = types_Squad,	
																								 ["Infantry"] = true,
																								 ["Team"] = {
																												["Min"] = 2,
																												["Max"] = 3,
																												["CP Reward"] = 0,
																												["Types"] = types_Team,	
																												["Infantry"] = true,
																											}
																								},
																				 }
																		
																	}
													   },
													   
										 ["Battery"] = {["Min"] = 0,
														["Max"] = 2,
														["CP Reward"] = 500,
														["Types"] = types_Battery,	
													   }
									
									
									
										}
									}
									
Formation_Table.Ground.RED.Types = get_ground_types(Formation_Table.Master.Ground.RED, {})


function Formation_Table.Ground.RED.matchTypes(string_in)
	
	Logger:debug("in match types: "..string_in)
	
	for k,v in pairs(Formation_Table.Ground.RED.Types) do
		Logger:debug(k)
		if string.match(string.upper(string_in),string.upper(k)) then
		
			Logger:debug("match found! "..k)
			return k
			
		end
	
	end
	
	return nil
	
end
function Formation_Table.Ground.BLUE.matchTypes(string_in)
	
	Logger:debug("in match types: "..string_in)
	
	for k,v in pairs(Formation_Table.Ground.BLUE.Types) do
		Logger:debug(k)
		if string.match(string.upper(string_in), string.upper(k)) then
		
			Logger:debug("match found! "..k)
			return k
			
		end
	
	end
	
	return nil
	
end

		
Formation_Table.Restrictions = {}
Formation_Table.Restrictions.BLUE = {["Batallion"] = {["Combined Arms"] = {}, -- no restrictions
										   ["Armored"] = "Armored",
										   ["Anti-Air"] = "Anti-Air",
										   ["Artillery"] = "Artillery",
										   ["Support"] = {"Mechanized",
													      "Motorized"}
									}
						}
						
Formation_Table.Restrictions = {}
Formation_Table.Restrictions.RED = {["Batallion"] = {["Combined Arms"] = {}, -- no restrictions
										   ["Armored"] = "Armored",
										   ["Anti-Air"] = "Anti-Air",
										   ["Artillery"] =  "Artillery",
										   ["Support"] = {"Mechanized",
													      "Motorized"}
									}
						}


								
Formation_Table.Restrictions.Transports = {["Rifle"] = {"Mechanized",
							   "Motorized"
							  },
				  ["Anti-Air"] = {"Mechanized",
								  "Motorized"
								 },
				  ["Marines"] = {"Mechanized",
								 "Motorized",
								 "Amphibious"
								},
				  ["Airborne"] = {"Mechanized",
								  "Motorized"
								 },
				  ["Mortar"] = {"Mechanized",
								"Motorized"
							   },
				  ["Recon"]  = {"Mechanized",
								"Motorized"
							   },
				  ["Engineer"] = {"Mechanized",
								  "Motorized"
								 },
				  ["JTAC"]  = {"Mechanized",
							   "Motorized"
							  }
				}			

Formation_Table.Air = {}
Formation_Table.Air.BLUE = {} 
Formation_Table.Air.BLUE.Types = {
	["CAP"] = true,
	["CAS"] = true,
    ["BOMBER"] = true,
    ["ANTISHIP"] = true,
    ["AWACS"] = true,	
    ["TANKER"] = true,
    ["RECON"] = true,
    ["SEAD"] = true,
}
Formation_Table.Air.RED = {}
Formation_Table.Air.RED.Types = {
	["CAP"] = true,
	["CAS"] = true,
    ["BOMBER"] = true,
    ["ANTISHIP"] = true,
    ["AWACS"] = true,	
    ["TANKER"] = true,
    ["RECON"] = true,
    ["SEAD"] = true,
}

function Formation_Table.Air.BLUE.matchTypes(string_in)
		
	for k,v in pairs(Formation_Table.Air.RED.Types) do
		Logger:debug(k)
		if string.match(string.upper(string_in),string.upper(k)) then
		
			Logger:debug("match found! "..k)
			return k
			
		end
	
	end
	
	return nil
end

function Formation_Table.Air.RED.matchTypes(string_in)
		
	for k,v in pairs(Formation_Table.Air.RED.Types) do
		Logger:debug(k)
		if string.match(string.upper(string_in),string.upper(k)) then
		
			Logger:debug("match found! "..k)
			return k
			
		end
	
	end
	
	return nil
	
end

Formation_Table.Not_Mobile = { --These will be trucks while mobile and need to be deployed
	["Hawk cwar"] = true,
	["Hawk ln"] = true,
    ["Hawk pcp"] = true,
    ["Hawk sr"] = true,
    ["Hawk tr"] = true,	
    ["S-300PS 40B6M tr"] = true,
    ["S-300PS 40B6MD sr"] = true,
    ["S-300PS 54K6 cp"] = true,
    ["S-300PS 5P85C ln"] = true,
    ["S-300PS 5P85D ln"] = true,
    ["S-300PS 64H6E sr"] = true,
    ["Patriot AMG"] = true,
    ["Patriot ECS"] = true,
    ["Patriot EPP"] = true,
    ["Patriot cp"] = true,
    ["Patriot ln"] = true,    
    ["Patriot str"] = true,
    ["RLS_19J6"] = true,
    ["RPC_5N62V"] = true,
    ["S-200_Launcher"] = true,
    ["SNR_75V"] = true,
    ["S_75M_Volhov"] = true,
	["5p73 s-125 ln"] = true,	

}			

Formation_Table.Mobile_Substitute = {}
Formation_Table.Mobile_Substitute.RED = "Ural-375"
Formation_Table.Mobile_Substitute.BLUE = "M 818" -- what will actually substitute the SAM sites
		

Formation_Table.Special = { 							
				  ["Recon"] = true,		
				  ["Engineer"] = true,
				  ["Support"] = true,
						}	

function returnFlatTable(table_in, table_out)
	
	values = {}
	
	key = "";
	
	local lot_queue = {}
	
	for k,v in pairs(table_in) do
		
		if type(v) == "table" and k ~= "Types" then
			table_out[k] = {}			
			table.insert(lot_queue, v)
			key = k
		else
			table.insert(values, {[k] = v})
		end
	
	end
	
	table_out[key] = values
	
	env.info("LOT Queue:")
	utils.tprint(lot_queue)
	
	env.info("Table_Out:")
	utils.tprint(table_out)
	
	for k,v in ipairs(lot_queue) do
		
		env.info("Deeper...")
		table_out = returnFlatTable(v, table_out)
				
	end
	
	return table_out
	
end

local Formation = class("Formation")
function Formation:__init(cmdr, theater)

	self._theater = theater
	self._cmdr = cmdr
	self.GROUND = {}
	self.HELO = {}
	self.AIR = {}
	self.flat_table = {}	
	
	Logger:debug("OWNER --->:"..enum.coalitionMap[self._cmdr.owner])
	
	self.flat_table["GROUND"] = returnFlatTable(Formation_Table.Master.Ground[enum.coalitionMap[self._cmdr.owner]], {})
	self.flat_table["HELO"] = returnFlatTable(Formation_Table.Master.Air[enum.coalitionMap[self._cmdr.owner]], {})
	self.flat_table["AIR"] = returnFlatTable(Formation_Table.Master.Air[enum.coalitionMap[self._cmdr.owner]],{})

	self:init_units()

	Logger:debug("FORMATIONS:")
	utils.tprint(self.flat_table)
	
end

function Formation:init_units()

	local side = string.lower(enum.coalitionMap[self._cmdr.owner])
	local path = settings.server.theaterpath..utils.sep.."tables"..utils.sep.."formations"..utils.sep..side..utils.sep..side.."_formations.JSON"
	
	Logger:debug("Reading JSON file: "..path)
	
	self.unit_table = dctutils.read_JSON_file(path)
	
	assert(self.unit_table, "Formation table not found")
	
	self:process_types_GROUND(self.unit_table.GROUND)
	self:process_types_HELO(self.unit_table.HELO)
	self:process_types_AIR(self.unit_table.AIR)

end	

function Formation:process_types_GROUND()
	
	Logger:debug("Processing JSON file: ")
	
	Logger:debug("Type table: ")
	--utils.tprint(Formation_Table.Ground.BLUE.Types)
	
	local side_str = enum.coalitionMap[self._cmdr.owner]
	
	--utils.tprint(self.unit_table.GROUND)
	
	for k, form in pairs(self.unit_table.GROUND) do
	
		Logger:debug("k: "..k)
		for n, templ in ipairs(form) do
			Logger:debug("n: "..n)
			--utils.tprint(templ)
			
			name_str = templ[1]["name"]
			match_str = string.match(name_str, "Name=\"(.*)\"")
			if(match_str) then -- special name
				match_str:sub(5)		
				Logger:debug("Name found: "..match_str)
			end
			
			t_string = Formation_Table.Ground[side_str]["matchTypes"](name_str) --string with the type of unit
			--yes we are going to gloss over the fact the the line of code above looks like a function and a table
			--had the most unholiest of offspring
			--welcome to lua motherfucker
			
			if(t_string) then -- 
				Logger:debug("Type found: "..t_string)
			else				
				Logger:debug("Type not found!: "..name_str)
			end
			
			--todo: now that we can match individual templates to types... something
			--put them in the flat table?
			--I.E:
			--Ground
			-- --Squad
			--    --Airborne
			--      --1 name: ?
			--      --2 
			--      --3 
			--todo
			--clean up the names (?) or wait till created?
			-- maybe I can clean them up now so we can use them to display in f10 menu...
			-- after deploy, give callsign and unique values. 
		end
	end	
	
end

function Formation:process_types_HELO()
		
	Logger:debug("Processing JSON file: ")
	
	Logger:debug("Type table: ")
	--utils.tprint(Formation_Table.Air.BLUE.Types)
	
	local side_str = enum.coalitionMap[self._cmdr.owner]
	
	--utils.tprint(self.unit_table.HELOS)
	
	for k, form in pairs(self.unit_table.HELOS) do
	
		Logger:debug("k: "..k)
		for n, templ in ipairs(form) do
			Logger:debug("n: "..n)
			--utils.tprint(templ)
			
			name_str = templ[1]["name"]
			match_str = string.match(name_str, "Name=\"(.*)\"")
			if(match_str) then -- special name
				match_str:sub(5)		
				Logger:debug("Name found: "..match_str)
				templ[1]["name"] = name_str
			end
			
			t_string = Formation_Table.Air[side_str]["matchTypes"](name_str) --string with the type of unit
			--yes we are going to gloss over the fact the the line of code above looks like a function and a table
			--had the most unholiest of offspring
			--welcome to lua motherfucker
			
			if(t_string) then -- 
				Logger:debug("Type found: "..t_string)
			else				
				Logger:debug("Type not found!: "..name_str)
			end
			
			--todo: now that we can match individual templates to types... something
			--put them in the flat table?
			--I.E:
			--Ground
			-- --Squad
			--    --Airborne
			--      --1 name: ?
			--      --2 
			--      --3 
			--todo
			--clean up the names (?) or wait till created?
			-- maybe I can clean them up now so we can use them to display in f10 menu...
			-- after deploy, give callsign and unique values. 
		end
	end	
	
	
end

function Formation:process_types_AIR()
		
	Logger:debug("Processing JSON file: ")
	
	Logger:debug("Type table: ")
	--utils.tprint(Formation_Table.Air.BLUE.Types)
	
	local side_str = enum.coalitionMap[self._cmdr.owner]
	
	--utils.tprint(self.unit_table.Air)
	
	for k, form in pairs(self.unit_table.AIR) do
	
		Logger:debug("k: "..k)
		for n, templ in ipairs(form) do
			Logger:debug("n: "..n)
			--utils.tprint(templ)
			
			name_str = templ[1]["name"]
			match_str = string.match(name_str, "Name=\"(.*)\"")
			if(match_str) then -- special name
				match_str:sub(5)		
				Logger:debug("Name found: "..match_str)
			end
			
			t_string = Formation_Table.Air[side_str]["matchTypes"](name_str) --string with the type of unit
			--yes we are going to gloss over the fact the the line of code above looks like a function and a table
			--had the most unholiest of offspring
			--welcome to lua motherfucker
			
			if(t_string) then -- 
				Logger:debug("Type found: "..t_string)
			else				
				Logger:debug("Type not found!: "..name_str)
			end
			
			--todo: now that we can match individual templates to types... something
			--put them in the flat table?
			--I.E:
			--Ground
			-- --Squad
			--    --Airborne
			--      --1 name: ?
			--      --2 
			--      --3 
			--todo
			--clean up the names (?) or wait till created?
			-- maybe I can clean them up now so we can use them to display in f10 menu...
			-- after deploy, give callsign and unique values. 
		end
	end	
	
end

function find_keyword(word, table_in)
	env.info("In search, word:"..word)
	local lot_queue = {}
	
	for k,v in pairs(table_in) do
		--env.info(k)
		if type(v) == "table" and k ~= "Types" then
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


function Formation:readble(typeString)

	Logger:debug("In Readable")
	
	local divider = "\n"..string.rep('-',60).."\n"
	
	if typeString == nil then

		output = {divider..
				  "\n Creatable Formations: \n"..
				  divider}
				  
		for k,v in pairs(self.flat_table) do
			table.insert(output,divider);	
			table.insert(output, k) -- Header, such as "Air" and "Ground"
			table.insert(output,divider);	
			if type(v) == "table" and k ~= "Types" then
			
				for key, value in pairs(v) do
					
					table.insert(output, key.."\n");	
					--todo: add in types available, how many make up each, etc.
				end
				
			
			end
					
		end
		
	else
	
	end
	
	return table.concat(output)
	
	--Logger:debug("-- MISSION: DONE READABLE --")	
		
end

function Formation:create()
	
		
end

function Formation:deploy()
	
end

--[[

function find_in_table(word, table_in)
	env.info("In type find, word:"..word)
	
	for k,v in pairs(table_in) do
		env.info(k)
		if string.match(string.upper(word), string.upper(k)) then
			
			return k
		
		end
	
	end
	
	return nil
	
end

FORMATION:CREATE (Form?)
-- This will create the formation from the nearest base's inventory of manpower, ground vehicles and fuel
-- maybe could just use "" quotes once created to indicate which formation... they will all be codenamed
FORMATION:DEPLOY
FORMATION:MOVE
FORMATION:PACK -- for A/D and the like - can't move them
FORMATION:UNGROUP (disband?)
FORMATION:GROUP
FORMATION:BUILD -- FSBs and such
FORMATION:DISMOUNT 
FORMATION:MOUNT 
FORMATION:COVER -- Enter bases, cities, POIs


BATTERY:ATTACK

LOGI:DEPLOY
LOGI:DELIVER
LOGI:LAND

CARGO:CREATE
CARGO:LOAD

2 special types:
RECON -- Has farther vision for spotting
ENGINEER -- Can build FOBs


--]]

-- Logistics
-- Weights, volumes, capacity, fuel consumption, ammo requirements, etc
-- 


return Formation