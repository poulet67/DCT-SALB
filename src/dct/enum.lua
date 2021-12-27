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
	-- mobile
	--logistical	
	["LOGISTICS"]   = 22,	
	["CONVOY"]         = 23,
	["NAVAL"]         = 24,
	["MOBILE"]         = 25,

	-- extended type set
	["AIRSPACE"]    = 26,
	["SHORAD"]      = 27,
	["PLAYERGROUP"] = 28,
	["SPECIALFORCES"] = 29,
	
	-- Mission not assigned to an asset
	["NOMISSION"] = 31,
	["FRIENDLY"] = 32,
	
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
	["RECON TRANSPORT"] = 8,
	["ANTI SHIP"] = 9,	
	["ESCORT"] = 10,	
	["INTERCEPT"] = 11,	
	["CONVOY RAID"] = 12,	
	["LOGISTICS"] = 13,
	["CSAR"] = 14,		
}

enum.missionTypePriority = {
	["CAS"]      = 2,
	["CAP"]      = 2,
	["STRIKE"]   = 2,
	["SEAD"]     = 2,
	["BAI"]      = 2,
	["OCA"]      = 3,
	["RECON"] = 2,
	["RECON TRANSPORT"] = 2,
	["ANTI SHIP"] = 1,	
	["ESCORT"] = 2,	
	["INTERCEPT"] = 1,	
	["CONVOY RAID"] = 4,	
	["CSAR"] = 2,		
}

enum.persistentMissions = {
	["CAP"]      = true,
	["RECON"] = true,
	["RECON TRANSPORT"] = true,
	["INTERCEPT"] = true,
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
	[enum.missionType["ANTI SHIP"]]--[[ = true,
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
	[enum.missionType["ANTI SHIP"]]--[[ = true,
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
		[enum.assetType.FRIENDLY]     = true,
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
	[enum.missionType["ANTI SHIP"]] = {
		[enum.assetType.NAVAL]       = true,
	},
	[enum.missionType.CAP] = {
		[enum.assetType.AIRSPACE]   = true,
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
	["MISSIONBRIEF"]    = 2,
	["MISSIONBOARD"]   = 3,
	["MISSIONSTATUS"]   = 4,
	["MISSIONABORT"]    = 5,
	["MISSIONROLEX"]    = 6,
	["MISSIONCHECKIN"]  = 7,
	["MISSIONCHECKOUT"] = 8,
	["SCRATCHPADGET"]   = 9,
	["SCRATCHPADSET"]   = 10,
	["CHECKPAYLOAD"]    = 11,
	["MISSIONJOIN"]     = 12,
	["SPAWN"]     = 13,

}

enum.weaponCategory = {
	["AA"] = 1,
	["AG"] = 2,
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

return enum
