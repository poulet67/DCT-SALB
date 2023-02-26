--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Define some basic global enumerations for DCT.
--]]

local enum = {}

enum.assetType = {
	-- control zones
	["KEEPOUT"]     = 1, 

	-- "Objectives" 
	["AMMODUMP"]    = 2,
	["FUELDUMP"]    = 3,
	["C2"]          = 4,
	["EWR"]         = 5,
	["MISSILE"]     = 6,
	["OCA"]         = 7,
	["PORT"]        = 8,
	["SAM"]         = 9,
	["BUNKER"]      = 10,
	["CHECKPOINT"]  = 11,

	-- "Infrastructure"
	["SEA"]         = 12, --Static naval like oil platforms and the like	
	["FACILITY"]    = 13,
	["FACTORY"]     = 14,
	
	-- Bases
	["BASEDEFENSE"] = 15,
	["FOB"] = 16,
	["FARP"] = 17,
	["FIREBASE"] = 18,
	["FOB"] = 19,
	["AIRBASE"]  = 20,
	
	-- tactical
	["JTAC"]        = 21,
	-- mobile &
	--logistical	
	["LOGISTICS"]   = 22,	
	["CONVOY"]         = 23,
	-- mobile
	["NAVAL"]         = 24,
	-- Commandable units
	["DISPATCHABLE"]         = 25,

	-- extended type set
	["AIRSPACE"]    = 26,
	["WAYPOINT"]    = 27,
	["WEAPON"]    = 28,
	["SHORAD"]      = 29,
	["PLAYERGROUP"] = 30,
	["SPECIALFORCES"] = 31,
	
	-- Mission not assigned to an asset
	["NOMISSION"] = 32, -- not actually implemented at the moment
}

enum.commandUnitTypes = {
	["AWACS"] = 1, 
	["TANKER"] = 2, 
	["CAP"] = 3,
	["SEAD"] = 4, --["AI"] = 36, -- still just a concept
	["STRIKE"] = 5, --["AI"] = 36, -- still just a concept
	["CAS"] = 6, --["AI"] = 36, -- still just a concept
	["ANTISHIP"] = 7, --["AI"] = 36, -- still just a concept
}

enum.offensiveUnits = { -- units that partake in offensive missions (a permissive for the attack command)
	[enum.commandUnitTypes["CAP"]] = true, 
	[enum.commandUnitTypes["SEAD"]] = true, 
	[enum.commandUnitTypes["STRIKE"]] = true, 
	[enum.commandUnitTypes["CAS"]] = true, 
	[enum.commandUnitTypes["ANTISHIP"]] = true, 
}

 
enum.airbaseTakeoffBlocked = { -- DCS is dumb and will allow some units to take off from airbases they shouldn't (like an E-3 AWACS on the LHA Tarawa) this list is to prevent that from happening (add more as required)
	["LHA_Tarawa"] = {
		["FA-18C_hornet"] = true, 
		["E-2C"] = true,
		["S-3B Tanker"] = true,		  
	}
			  
}
	
--[[
-- We use a min-heap so priority is in reverse numerical order,
-- a higher number is lower priority
--]]


--POULET: My version of DCT will create missions for assets as they are "discovered" or "spotted"
--This means that the priority system is no longer needed.
--This may result in a massive mission board, but that is okay
--[[
enum.assetTypePriority = {
	[enum.assetType.AIRSPACE]    = 10,
	[enum.assetType.JTAC]        = 3,
	[enum.assetType.EWR]         = 4,
	[enum.assetType.SAM]         = 3,
	[enum.assetType.C2]          = 3,
	[enum.assetType.AMMODUMP]    = 5,
	[enum.assetType.FUELDUMP]    = 5,
	[enum.assetType.MISSILE]     = 5,
	[enum.assetType.SEA]         = 1,
	[enum.assetType.BASEDEFENSE] = 60,
	[enum.assetType.OCA]         = 70,
	[enum.assetType.PORT]        = 70,
	[enum.assetType.LOGISTICS]   = 70,
	[enum.assetType.AIRBASE]     = 70,
	[enum.assetType.SHORAD]      = 5,
	[enum.assetType.FACILITY]    = 5,
	[enum.assetType.BUNKER]      = 5,
	[enum.assetType.CHECKPOINT]  = 5,
	[enum.assetType.SPECIALFORCES] = 5,
	[enum.assetType.FOB]         = 10,
	[enum.assetType.FACTORY]     = 5,
	[enum.assetType.KEEPOUT]     = 10000,
}
--]]

enum.missionInvalidID = 0

enum.missionType = {
	["CAS"]      = 1,
	["CAP"]      = 2,
	["STRIKE"]   = 3,
	["SEAD"]     = 4,
	["BAI"]      = 5,
	["OCA"]      = 6,
	["RECON"] = 7,
	["TRANSPORT"] = 8,
	["ASUW"] = 9,	
	["ESCORT"] = 10,	
	["INTERCEPT"] = 11,	
	["CONVOY RAID"] = 12,	
	["LOGISTICS"] = 13,
	["CSAR"] = 14,		
	["FERRY"] = 15,	
}

enum.missionTypePriority = {
	["CAS"]      = 2,
	["CAP"]      = 2,
	["STRIKE"]   = 4,
	["SEAD"]     = 3,
	["BAI"]      = 2,
	["OCA"]      = 3,
	["RECON"] = 3,
	["TRANSPORT"] = 2,
	["ASUW"] = 1,	
	["ESCORT"] = 2,	
	["INTERCEPT"] = 1,	
	["CONVOY RAID"] = 4,	
	["CSAR"] = 2,		
	["LOGISTICS"] = 2,
	["FERRY"] = 10,		
}

enum.locationMethod = {
	["GENERIC1"]      = "Reconnaissance elements have located",
	["GENERIC2"]      = "Intelligence has informed us that there is",
	["GENERIC3"]   = "We have reason to believe there is",
	["SATELLITE"]     = "Satellite imaging has found",
	["GROUNDSPOT"] = "Ground units operating in the area have informed us of",
	["RECONFLIGHT"] = "A recon flight earlier today discovered",
	["PLAYERSPOT"] = "A friendly unit spotted",
}

enum.persistentMissions = {
	["CAP"]      = 1,
	["RECON"] = 2,
	["TRANSPORT"] = 3,
	["LOGISTICS"] = 4,
	["FERRY"] = 5,
}

enum.briefingType = { -- some missions don't fit the "standard" mould. we will deal with them seperately
	["STANDARD"] = {
		[enum.missionType.CAS] = true,
		[enum.missionType.CAP] = true,
		[enum.missionType.STRIKE] = true,
		[enum.missionType.SEAD] = true,
		[enum.missionType.BAI] = true,
		[enum.missionType.OCA] = true,
		[enum.missionType.ASUW] = true,
		[enum.missionType.ESCORT] = true,
		[enum.missionType.INTERCEPT] = true,
		[enum.missionType["CONVOY RAID"]] = true,
		[enum.missionType.CSAR] = true,
	},	
	["RECON"] = {
		[enum.missionType.RECON] = true,
	},
	["NONCOMBAT"] = {	
		[enum.missionType.TRANSPORT] = true,
		[enum.missionType.FERRY] = true,
		[enum.missionType.LOGISTICS] = true,

	}
}

enum.briefingKeys = { --so we can iterate through the briefing (order matters here)

	[1] = "PackageHeader",
	[2] = "IFF",
	[3] = "PackageComms",
	[4] = "MarshalPoint",
	[5] = "PushTime",
	[6] = "TimeOnTarget",
	[7] = "TargetLocation",
	[8] = "Briefing",
	[9] = "Orders",
	[10] = "Information",	
	
}

enum.voteType = {
	
	["PUBLIC"] = {-- will show up in the F10 menu
		["Request Command"]      = 1,
		["Kick Commander"]      = 2,
		["Surrender"]      = 3,	
	},
	["PRIVATE"] = {
		["Other"]      = 4,
		["Decision"]      = 5,
	}

}

--This is from an old implementation, I must delete
--[[
enum.periodicMissions = { 
	[enum.missionType.CAS]     = false,
	[enum.missionType.CAP]      = false,
	[enum.missionType.STRIKE]   = false,
	[enum.missionType.SEAD]     = false,
	[enum.missionType.BAI]      = false,
	[enum.missionType.OCA]      = false,
	[enum.missionType["ASuW"]]--[[ = true,
	[enum.missionType.ESCORT] = false,
	[enum.missionType.INTERCEPT] = false,	
}

enum.availableMissions = {
	[enum.missionType.CAS]     = false,
	[enum.missionType.CAP]      = true,
	[enum.missionType.STRIKE]   = false,
	[enum.missionType.SEAD]     = false,
	[enum.missionType.BAI]      = false,
	[enum.missionType.OCA]      = false,
	[enum.missionType["ASuW"]]--[[ = true,
	[enum.missionType.ESCORT] = false,
	[enum.missionType.INTERCEPT] = false,	
}
--]]


enum.assetClass = {
	["INITIALIZE"] = {
		[enum.assetType.AMMODUMP]    = true,
		[enum.assetType.FUELDUMP]    = true,
		[enum.assetType.C2]          = true,
		[enum.assetType.EWR]         = true,
		[enum.assetType.MISSILE]     = true,
		[enum.assetType.OCA]         = true,
		[enum.assetType.PORT]        = true,
		[enum.assetType.SAM]         = true,
		[enum.assetType.FACILITY]    = true,
		[enum.assetType.BUNKER]      = true,
		[enum.assetType.CHECKPOINT]  = true,
		[enum.assetType.FACTORY]     = true,
		[enum.assetType.SHORAD]      = true,
		[enum.assetType.AIRBASE]     = true,
		[enum.assetType.SPECIALFORCES] = true,
		[enum.assetType.AIRSPACE]      = true,
		[enum.assetType.LOGISTICS]     = true,
		[enum.assetType.SEA]      		= true,
		[enum.assetType.NAVAL]      		= true,
		[enum.assetType.NOMISSION]      = true,
	},
	-- strategic list is used in calculating ownership of a region
	-- among other things
	["STRATEGIC"] = {
		[enum.assetType.AMMODUMP]    = true,
		[enum.assetType.FUELDUMP]    = true,
		[enum.assetType.C2]          = true,
		[enum.assetType.EWR]         = true,
		[enum.assetType.MISSILE]     = true,
		[enum.assetType.PORT]        = true,
		[enum.assetType.SAM]         = true,
		[enum.assetType.FACILITY]    = true,
		[enum.assetType.BUNKER]      = true,
		[enum.assetType.CHECKPOINT]  = true,
		[enum.assetType.FACTORY]     = true,
		[enum.assetType.AIRBASE]     = true,
	},
	-- agents never get serialized to the state file
	["AGENTS"] = {
		[enum.assetType.PLAYERGROUP] = true,
		[enum.assetType.WEAPON] = true,
	}
}

enum.missionTypeMap = {
	[enum.missionType.STRIKE] = {
		[enum.assetType.AMMODUMP]   = true,
		[enum.assetType.FUELDUMP]   = true,
		[enum.assetType.C2]         = true,
		[enum.assetType.MISSILE]    = true,
		[enum.assetType.PORT]       = true,
		[enum.assetType.FACILITY]   = true,
		[enum.assetType.BUNKER]     = true,
		[enum.assetType.CHECKPOINT] = true,
		[enum.assetType.FACTORY]    = true,		
		[enum.assetType.SEA]       = true,
	},
	[enum.missionType.SEAD] = {
		[enum.assetType.EWR]        = true,
		[enum.assetType.SAM]        = true,
	},
	[enum.missionType.OCA] = {
		[enum.assetType.OCA]        = true,
		[enum.assetType.AIRBASE]    = true,
	},
	[enum.missionType.BAI] = {
		[enum.assetType.LOGISTICS]  = true,
	},
	[enum.missionType.CAS] = {
		[enum.assetType.JTAC]       = true,
	},
	[enum.missionType["ASUW"]] = {
		[enum.assetType.NAVAL]       = true,
	},
	[enum.missionType.CAP] = {
		[enum.assetType.AIRSPACE]   = true,
	},
	[enum.missionType.INTERCEPT] = {
		[enum.assetType.WEAPON]   = true,
	},
}

enum.missionAbortType = {
	["ABORT"]    = 0,
	["COMPLETE"] = 1,
	["TIMEOUT"]  = 2,
	["PERIODIC"]  = 3, -- 
}

enum.uiRequestType = { 
	["THEATERSTATUS"]   = 1,
	["MISSIONTYPEINFO"]    = 2,
	["MISSIONBRIEF"]    = 3,
	["MISSIONBOARD"]   = 4,
	["MISSIONSTATUS"]   = 5,
	["MISSIONABORT"]    = 6,
--	["MISSIONROLEX"]    = 7,
	["MISSIONCHECKIN"]  = 8,
	["MISSIONCHECKOUT"] = 9,
--	["SCRATCHPADGET"]   = 10,
--	["SCRATCHPADSET"]   = 11,
	["CHECKPAYLOAD"]    = 12,
	["MISSIONJOIN"]     = 13,
	["CURRENTVOTE"]     = 14,
	["CALLVOTE"]     = 15,
	["VOTE"]     = 16,
	["SPAWN"]     = 17,
	["DEBUGGING"]     = 18,
	["CHECKLOADOUT"]     = 19,
	["LISTINVENTORY"]     = 20,
	["LOADOUTINFO"]     = 21,

}

enum.weaponCategory = {
	["AA"] = 1,
	["AG"] = 2,
}

enum.InventoryCategories = {
	["airframes"] = 1,
	["munitions"] = 2,
	["ground units"] = 3,
	["other"] = 4,
}

enum.coalitionMap = {
	[coalition.side.NEUTRAL] = "NEUTRAL",
	[coalition.side.RED] = "RED",
	[coalition.side.BLUE] = "BLUE",
}

enum.WPNINFCOST = 5000
enum.UNIT_CAT_SCENERY = Unit.Category.STRUCTURE + 1

local eventbase = world.event.S_EVENT_MAX + 2000
enum.event = {
	["DCT_EVENT_DEAD"] = eventbase + 1,
		--[[
		-- DEAD definition:
		--   id = id of this event
		--   initiator = asset sending the death notification
		--]]
	["DCT_EVENT_HIT"]  = eventbase + 2,
		--[[
		-- HIT definition:
		--   id = id of this event
		--   initiator = DCT asset that was hit
		--   weapon = DCTWeapon object
		--]]
	["DCT_EVENT_OPERATIONAL"] = eventbase + 3,
		--[[
		-- OPERATIONAL definition:
		--   id = id of this event
		--   initiator = base sending the operational notification
		--   state = of the base, true == operational
		--]]
	["DCT_EVENT_CAPTURED"] = eventbase + 4,
		--[[
		-- CAPTURED definition:
		--   id = id of this event
		--   initiator = object that initiated the capture
		--   target = the base that has been captured
		--]]
	["DCT_EVENT_IMPACT"] = eventbase + 5,
		--[[
		-- IMPACT definition:
		--   id = id of the event
		--   initiator = DCTWeapon class causing the impact
		--   point = impact point
		--]]
	["DCT_EVENT_ADD_ASSET"] = eventbase + 6,
		--[[
		-- ADD_ASSET definition:
		--  A new asset was added to the asset manager.
		--   id = id of this event
		--   initiator = asset being added
		--]]		

}

enum.kickCode = require("dct.libs.kickinfo").kickCode

-- GAMEPLAY ENUMS
-- These can be considered somewhere between a "setting" and a "tunable gampeplay/balance variable"
-- 
--
--
-- Essentially, creating a setting for every single gameplay variable I might want to affect was
-- getting way too onerous. 


-- RECON
-- Define different ranges for which certain aircraft will detect enemy units and make them known to
-- the commander


enum.markShape = {
		
		 ["Line"] = 1,
		 ["Circle"] = 2,
		 ["Rect"] = 3,
		 ["Arrow"] = 4,
		 ["Text"] = 5,
		 ["Quad"] = 6,
		 ["Freeform"] = 7,
			
}	
		
		
enum.lineType = {		
		
		 ["NoLine"] = 0,
		 ["Solid"] = 1,
		 ["Dashed"] = 2,
		 ["Dotted"] = 3,
		 ["DotDash"] = 4,
		 ["LongDash"] = 5,
		 ["TwoDash"] = 6,

		}
enum.gameplay = {}

enum.gameplay.ReconRange = {








}


-- ELINT
-- Define different ranges for which certain aircraft will detect enemy SAMs and make them known to
-- the commander


enum.gameplay.ElintRange = {








}

-- Logistics
-- Weights, volumes, capacity, fuel consumption, ammo requirements, etc
-- 
enum.gameplay.logistics = {}

enum.gameplay.logistics.FlightCrew = { -- all Flight Crew
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

enum.gameplay.logistics.capacity = {
["airframes"] = {
				["C-130"] = {
							["weight"] = 4000, --kg
							["volume"] = 50 --cubic m
				
				
				
							},


				},
["ground_units"] = {
				["TRUCCCK"] = {
							["weight"] = 4000, --kg
							["volume"] = 50 --cubic m				
							},


				},



}

enum.gameplay.logistics.payload = {
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
enum.gameplay.logistics.discrete = { -- A discrete value is 1 per unit.
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



enum.gameplay.logistics.fuel_consumption = {
--in m/cu m (a bit of a weird unit, but saves a calculation at run time)

["ground_units"] = {


				},


}

enum.gameplay.logistics.ammo_consumption = {
--amount of ammo to go from empty to reloaded (again controversial and approximate)
["ground_units"] = {
				["TRUCCCK"] = {
							["weight"] = 4000, --kg
							["volume"] = 50 --cubic m				
							},


				},


}




return enum
