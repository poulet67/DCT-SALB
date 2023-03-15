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

local Formation_Table = {}
Formation_Table.Master = {}
Formation_Table.Master.Ground = {}
Formation_Table.Master.Air = {}
Formation_Table.Air = {}


Formation_Table.Master.Ground.BLUE = {["Brigade"] = {--["Top"] = true,
									["CP Reward"] = 5000,
									["Batallion"] = {["Min"] = 3,
													 ["Max"] = 8,
													 ["CP Reward"] = 1000,
													 ["Company"] = {
																	["Min"] = 3,
																	["Max"] = 6,
																	["CP Reward"] = 300,
																	["Platoon"] = {["CP Reward"] = 100,
																				   ["Min"] = 3,
																				   ["Max"] = 4,
																				   ["Squad"] = {["Min"] = 3,
																								 ["Max"] = 3,
																								 ["CP Reward"] = 0,
																								 ["Infantry"] = true,
																								 ["Team"] = {
																												["Min"] = 2,
																												["Max"] = 3,
																												["CP Reward"] = 0,
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
													   },
													   
										 ["Battery"] = {["Min"] = 0,
														["Max"] = 2,
														["CP Reward"] = 500
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
													   },
													   
										 ["Battery"] = {["Min"] = 0,
														["Max"] = 2,
														["CP Reward"] = 500
													   }
									
									
									
										}
						
						
Formation_Table.Master.Ground.RED = {["Regiment"] = {--["Top"] = true,
									["CP Reward"] = 5000,
									["Batallion"] = {["Min"] = 3,
													 ["Max"] = 5,
													 ["CP Reward"] = 1000,
													 ["Company"] = {
																	["Min"] = 3,
																	["Max"] = 6,
																	["CP Reward"] = 300,
																	["Platoon"] = {["CP Reward"] = 100,
																				   ["Min"] = 3,
																				   ["Max"] = 4,
																				   ["Squad"] = {["Min"] = 3,
																								 ["Max"] = 3,
																								 ["CP Reward"] = 0,
																								 ["Infantry"] = true,
																								 ["Team"] = {
																												["Min"] = 2,
																												["Max"] = 3,
																												["CP Reward"] = 0,
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
		
Formation_Table.Restrictions = {}
Formation_Table.Restrictions.BLUE = {["Batallion"] = {["Combined Arms"] = {}, -- no restrictions
										   ["Armored"] = "Armored",
										   ["Anti-Air"] = "Anti-Air",
										   ["Artillery"] =  "Artillery",
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

Formation_Table.Air.Types = {
	["CAP"] = true,
	["CAS"] = true,
    ["BOMBER"] = true,
    ["ANTISHIP"] = true,
    ["AWACS"] = true,	
    ["TANKER"] = true,
    ["RECON"] = true,
    ["SEAD"] = true,
}
			
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
						}	

function returnFlatTable(table_in)
	
	flat = {}
	values = {}
	
	key = ""
	
	local lot_queue = {}
	
	for k,v in pairs(table_in) do
		
		if type(v) == "table" then
			flat[k] = {}			
			table.insert(lot_queue, v)
			key = k
		else
			table.insert(values, v)
		end
	
	end
	
	flat[key] = values
	
	--env.info("LOT Queue:")
	--utils.tprint(lot_queue)
	
	for k,v in ipairs(lot_queue) do
		
		env.info("Deeper...")
		returnFlatTable(v)
				
	end
	
	return flat
	
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
	
	self.flat_table["GROUND"] = returnFlatTable(Formation_Table.Master.Ground[enum.coalitionMap[self._cmdr.owner]])
	self.flat_table["HELO"] = returnFlatTable(Formation_Table.Master.Air[enum.coalitionMap[self._cmdr.owner]])
	self.flat_table["AIR"] = returnFlatTable(Formation_Table.Master.Air[enum.coalitionMap[self._cmdr.owner]])

	self:init_units()

	Logger:debug("FORMATIONS:")
	utils.tprint(flat_table)
	
end

function Formation:init_units()

	local side = string.lower(enum.coalitionMap[self._cmdr.owner])
	local path = settings.server.theaterpath..utils.sep.."tables"..utils.sep.."formations"..utils.sep..side..utils.sep..side.."_formations.JSON"
	
	Logger:debug("Reading JSON file: "..path)
	
	self.unit_table = dctutils.read_JSON_file(path)
	
	assert(self.unit_table, "Formation table not found")
	
end	

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

return Formation