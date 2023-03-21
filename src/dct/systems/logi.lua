--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Logi class
--
-- 
--
-- COMMANDER (calls) --> Formation (pulls templates and adds up unit requirements) --> LOGI (totals logistical requirements)
--								|
--								-
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

local logistics = {}

-- Logistics
-- Weights, volumes, capacity, fuel consumption, ammo requirements, etc
-- 
logistics = {}

logistics.FlightCrew = { -- all Flight Crew
-- 
	["C-130"] = 5, 
	["A-10A"] = 1,
	["A-10C"] = 1,
	["A-10C_2"] = 1,
	["A-20G"] = 5,
	["A-50"] = 15,
	["AH-1W"] = 2, 
	["AH-64A"] = 2,
	["AH-64D"] = 2,
	["AH-64D_BLK_II"] = 2,
	["AJS37"] = 1,
	["AV8BNA"] = 1,
	["An-26B"] = 5,
	["An-30M"] = 7,
	["B-1B"] = 4,
	["B-52H"] = 5,
	["Bf-109K-4"] = 1,
	["C-101CC"] = 2,
	["C-101EB"] = 2,
	["C-17A"] = 2,
	["C-101CC"] = 2,
	["CH-47D"] = 2,
	["CH-53E"] = 2, 
	["Christen Eagle II"] = 2,
	["E-2C"] = 5,
	["E-3A"] = 20,
	["F-117A"] = 1,
	["F-14A"] = 2,
	["F-14A-135-GR"] = 2,
	["F-15C"] = 1,
	["F-15E"] = 2,
	["F-16A"] = 1,
	["F-16A MLU"] = 1,
	["F-16C bl.50"] = 1,
	["F-16C bl.52d"] = 1,
	["F-16C_50"] = 1,
	["F-4E"] = 1,
	["F-5E"] = 1,
	["F-5E-3"] = 1,
	["F-16A"] = 1,
	["F-86F Sabre"] = 1,
	["F/A-18A"] = 1,
	["F/A-18C"] = 1,
	["FA-18C_hornet"] = 1,
	["FW-190A8"] = 1,
	["FW-190A8"] = 1,
	["H-6J"] = 4,
	["Hawk"] = 1,
	["I-16"] = 1,
	["IL-76MD"] = 5,
	["IL-78M"] = 6,
	["J-11A"] = 1,
	["JF-17"] = 1,
	["KC-135"] = 3,
	["KC130"] = 4,
	["KC135MPRS"] = 3,
	["KJ-2000"] = 15,
	["Ka-27"] = 6,
	["Ka-50"] = 1,
	["L-39C"] = 2,
	["L-39ZA"] = 2,
	["M-2000C"] = 1,
	["MQ-9 Reaper"] = 0,
	["Mi-24P"] = 2,
	["Mi-24V"] = 2,
	["Mi-28N"] = 2,
	["Mi-8MT"] = 3,
	["MiG-15bis"] = 1,
	["MiG-19P"] = 1,
	["MiG-21Bis"] = 1,
	["MiG-23MLD"] = 1,
	["MiG-25PD"] = 1,
	["MiG-25RBT"] = 1,
	["MiG-27K"] = 1,
	["MiG-29A"] = 1,
	["MiG-29G"] = 1,
	["MiG-29S"] = 1,
	["MiG-31"] = 1,
	["Mirage 2000-5"] = 1,
	["MosquitoFBMkVI"] = 2,
	["OH-58D"] = 2,
	["P-47D-30"] = 1,
	["P-47D-30bl1"] = 1,
	["P-47D-40"] = 1,
	["P-51D"] = 1,
	["P-51D-30-NA"] = 1,
	["RQ-1A Predator"] = 0,
	["S-3B Tanker"] = 4,
	["SA342L"] = 2,
	["SA342M"] = 2,
	["SA342Minigun"] = 2,
	["SA342Mistral"] = 2,
	["SH-60B"] = 4,
	["SpitfireLFMkIX"] = 1,
	["SpitfireLFMkIXCW"] = 1,
	["Su-17M4"] = 1,
	["Su-24M"] = 2,
	["Su-24MR"] = 2,
	["Su-24M"] = 2,
	["Su-25"] = 1,
	["Su-25T"] = 1,
	["Su-25TM"] = 1,
	["Su-27"] = 1,
	["Su-30"] = 2,
	["Su-33"] = 1,
	["Su-34"] = 2,
	["TF-51D"] = 1,
	["Tornado GR4"] = 2,
	["Tornado IDS"] = 2,
	["Tu-142"] = 12,
	["Tu-160"] = 4,
	["Tu-22M3"] = 4,
	["Tu-95MS"] = 6,
	["UH-1H"] = 2,
	["UH-60A"] = 4,
	["WingLoong-I"] = 0,
	["Yak-40"] = 3,
	["Yak-52"] = 2,
	
	
	
							
}

logistics.capacity = {
["airframes"] = {
				["C-130"] = {
							["weight"] = 4000, --kg
							["volume"] = 50 --cubic m
				
				
				
							},
				["default"] = {
							["weight"] = 4000, --kg
							["volume"] = 50 --cubic m
				
				
				
							},


				},
["ground_units"] = {
				["default"] = {
							["weight"] = 4000, --kg
							["volume"] = 50 --cubic m				
							},


				},



}

logistics.payload = {
["munitions"] = {
				["AIM-120C"] = {
							["weight"] = 200, --kg
							["volume"] = 1 --cubic m				
							},
				},
				
["other"] = {		-- some of these may be a bit controversial
					-- all are approximate
				["Manpower"] = {
							["weight"] = 90, --kg -- decent average, including kit
							["volume"] = 0.3 --cubic m
							},
				["ammo"] = { --needs to be generic. According to marinecft.com
							-- normal USMC ammo boxes weigh 30 lbs appx 1934 cu in = 0.03 cu m
							["weight"] = 13.6078, --kg -- 1 crate o
							["volume"] = 0.03185645 --cubic m				
							},
				["food"] = { --one U.S ration is 18 - 26 ounces. 24 ounces = 0.68 kg, 3 in x 12 in x 8 in
							["weight"] = 0.680389, --kg -- 1 crate o
							["volume"] = 0.00471947443 --cubic m				
							},
				["ammenities"] = { --very, very broad category, but generally light compared to military hardware. Think, first aid kits, radios,
								   --books/magazines, rations, etc. Infact, we are going to use the weight and volume of a first aid kit for this
							-- normal USMC ammo boxes weigh 30 lbs appx 1934 cu in = 0.03 cu m
							["weight"] = 1.36, --kg -- 1 crate o
							["volume"] = 0.02079 --cubic m				
							},
				["mail"] = { --not sure how to measure this one really
				
							["weight"] = 1.36, --kg -- 1 crate o
							["volume"] = 0.02079 --cubic m				
							},			
				["Casualty"] = {
							["weight"] = 90, --kg -- decent average, including litter, medical equipment
							["volume"] = 0.5 --cubic m
							},
			}




}
logistics.discrete = { -- A discrete value is 1 per unit.
									 -- A non discrete value is weight/volume (or volume/weight)
									 -- 1 person vs. 100 kg of diesel
	["Manpower"] = true,
	["casualties"] = true,
	["ammo"] = false,
	["diesel"] = false,
	["aviation fuel"] = false,
	["Amenities"] = false,
	["mail"] = false,
}



logistics.fuel_consumption = {
--in m/cu m (a bit of a weird unit, but saves a calculation at run time)

["ground_units"] = {


				},


}

logistics.ammo_consumption = {
--amount of ammo to go from empty to reloaded (again controversial and approximate)
["ground_units"] = {
				["TRUCCCK"] = {
							["weight"] = 4000, --kg
							["volume"] = 50 --cubic m				
							},


				},


}


local Logi = class("Logi")
function Logi:__init(cmdr, theater)

	self._theater = theater
	self._cmdr = cmdr	
	
	Logi:init_units()
	
end

function Logi:init_units()

	local side = string.lower(enum.coalitionMap[self._cmdr.owner])
	local path = settings.server.theaterpath..utils.sep.."tables"..utils.sep.."logi"..utils.sep..side..utils.sep..side.."_formations.JSON"
	
	Logger:debug("Reading JSON file: "..path)
	
	self.unit_table = dctutils.read_JSON_file(path)
	
	assert(self.unit_table, "Logi table not found")
	
end	

return Logi