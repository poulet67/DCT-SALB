--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Name lists for various asset types
--]]

local gameplay = {
--performance
["MAX_MOVING_CONVOYS"] = 3,
["BATTLE_SIZE_BASE"] = 50,
["MAX_FOBS_TOTAL"] = 20,


--battles
["BATTLE_NUMBER_OF_ROUNDS"] = 2,

--votes
["VOTING_TIME"] = 120, --seconds
["VOTE_PLAYER_COOLDOWN"] = 300, -- 5 mins
["VOTE_PERCENTAGE_REQUIRED"] = 0.75,

--difficulty/gameplay (tuning)
--recon
["RECON_COVERAGE_RADIUS"] = 10000, --meters
["RECOND_RADIUS_DETECTION"] = 2000, --meters
["RECON_MISSION_ALTITUDE"] = 2000, --~5k feet
["RECON_MISSION_ALLOWABLE_ALTITUDE_ERROR"] = 200, --m
["RECON_MISSION_ACTIVATION_TIME"] = 60, --s

["RECON_MISSION_RANGE"] = 2000, --how far away from the node can they get
["RECON_MISSION_DETECTION"] = 12000, 

--fobs
["FOBS_PER_REGION_BASE"] = 3,
["FOBS_PER_REGION_MAX"] = 6, -- maybe 8 for a challenge?

["CHALLENEGE_TIMER"] = 30, --seconds

--deliveries
["OFF_MAP_DELIVERY_DELAY"] = 15, -- if you want to simulate flight time from a real airbase... might annoy a lot of players

-- RECALL_TIMER (?)
--

--inventories
["AIRBASE_INVENTORY_TRANSFER_ON_CAPTURE"] = false,

--command units
["COMMAND_UNIT_AIRCRAFT_START_FROM_RAMP"] = true,
["COMMAND_UNIT_DEFAULT_ALTITUDE"] = 6000, --m (20 000 ft)
["COMMAND_UNIT_DEFAULT_SPEED"] = 123.46, --m/s
--
["COMMANDER_PUBLIC_BY_DEFAULT"] = true,


--Command points
["CP_RED_START"] = 100000,
["CP_BLUE_START"] = 67, --lul
["CP_COST_MORE_FOBS"] = 5000,
["CP_COST_INTEL_REPORT"] = 5000,
["CP_COST_TARGET_PRECISION"] = 5000,
["TARGET_PRECISION_TIMER"] = 3600,
["CP_COST_TACTICAL_RETREAT"] = 5000,
["CP_COST_CREATE_BATTLE_PLANS"] = 5000,
["CP_COST_PREPARE_OFFENSIVE"] = 5000,
}

return gameplay