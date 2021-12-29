--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Provides config facilities.
--]]

local utils      = require("libs.utils")
local enum       = require("dct.enum")
local dctutils   = require("dct.utils")

local function validate_weapon_restrictions(cfgdata, tbl)
	local path = cfgdata.file
	local keys = {
		[1] = {
			["name"] = "cost",
			["type"] = "number",
		},
		[2] = {
			["name"] = "category",
			["type"] = "string",
			["check"] = function (keydata, t)
		if enum.weaponCategory[string.upper(t[keydata.name])] ~= nil then
			t[keydata.name] =
				enum.weaponCategory[string.upper(t[keydata.name])]
			return true
		end
		return false
	end,
		},
	}
	for _, wpndata in pairs(tbl) do
		wpndata.path = path
		utils.checkkeys(keys, wpndata)
		wpndata.path = nil
	end
	return tbl
end

local function checkgreaterthanzero(keydata, t)

	if t[keydata.name] > 0 then	
	
		return true 
	
	else
		
		return false 
	end 

end

local function checkpercentage(keydata, t)

	if t[keydata.name] >= 0 and t[keydata.name] <= 1 then	
	
		return true 
	
	else
		
		return false 
	end 

end

local function checkfreqsteps(keydata, t)

	if (t[keydata.name] % 0.250) == 0 then	
	
		return true 
	
	else
		
		return false 
	end 

end
--[[
local function checkrebroadcast(keydata, t)
	
	if(t[keydata.name]) then
		
		UHF_Band = t.UHF_MAX - t.UHF_MIN
		VHF_Band = t.VHF_MAX - t.VHF_MIN
		FM_Band = t.FM_MAX - t.FM_MIN
		
		res1 = UHF_Band == VHF_Band 
		res2 = VHF_Band == FM_Band 
		
		if(res1 and res2) then
			return true
		else
			return false
		end
	
	else
		
		return true
	
	end

end
--]]
local function checkfreqarray(keydata, t)
	
	for k,v in pairs(t[keydata.name]) do
	
		--env.info("freq table v: "..v)
		--env.info("freq table k: "..k)
		
		if(type(v) ~= "number") then
		
			return false
			
		elseif(v < 0) then
		
			return false
			
		end	

	end
	
	return true

end

local function validate_gameplay_configs(cfgdata, tbl)

	if tbl == nil then
		return {}
	end
	
	local path = cfgdata.file
	local keys = {
		[1] = {
			["name"] = "MAX_MOVING_CONVOYS",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 3
		},
		[2] = {
			["name"] = "BATTLE_SIZE_BASE",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 50
		},
		[3] = {
			["name"] = "MAX_FOBS_TOTAL",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 20
		},
		[4] = {
			["name"] = "BATTLE_NUMBER_OF_ROUNDS",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 2
		},
		[5] = {
			["name"] = "VOTE_TIME",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 120
		},
		[6] = {
			["name"] = "VOTE_PLAYER_COOLDOWN",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 300
		},
		[7] = {
			["name"] = "VOTE_PERCENTAGE_REQUIRED",
			["type"] = "number",
			["check"] = checkpercentage,
			["default"] = 0.75 
		},
		[8] = {
			["name"] = "RECON_COVERAGE_RADIUS",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 300
		},
		[9] = {
			["name"] = "RECOND_RADIUS_DETECTION",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 300
		},
		[10] = {
			["name"] = "RECON_MISSION_ALTITUDE",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 300
		},
		[11] = {
			["name"] = "RECON_MISSION_ALLOWABLE_ALTITUDE_ERROR",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 300
		},
		[12] = {
			["name"] = "RECON_MISSION_RANGE",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 300
		},
		[13] = {
			["name"] = "RECON_MISSION_DETECTION",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 300
		},
		[14] = {
			["name"] = "FOBS_PER_REGION_BASE",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 3
		},
		[15] = {
			["name"] = "FOBS_PER_REGION_MAX",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 6
		},
		[16] = {
			["name"] = "CHALLENEGE_TIMER",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 30
		},
		[17] = {
			["name"] = "OFF_MAP_DELIVERY_DELAY",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 15
		},
		[18] = {
			["name"] = "AIRBASE_INVENTORY_TRANSFER_ON_CAPTURE",
			["type"] = "boolean",
			["default"] = false
		},
		[19] = {
			["name"] = "CP_RED_START",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 100000
		},
		[20] = {
			["name"] = "CP_BLUE_START",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 100000
		},
		[21] = {
			["name"] = "CP_COST_MORE_FOBS",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 5000
		},
		[22] = {
			["name"] = "CP_COST_INTEL_REPORT",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 5000
		},
		[23] = {
			["name"] = "CP_COST_TARGET_PRECISION",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 5000
		},
		[24] = {
			["name"] = "TARGET_PRECISION_TIMER",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 3600
		},
		[25] = {
			["name"] = "CP_COST_TACTICAL_RETREAT",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 5000
		},
		[26] = {
			["name"] = "CP_COST_CREATE_BATTLE_PLANS",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 5000
		},
		[27] = {
			["name"] = "CP_COST_PREPARE_OFFENSIVE",
			["type"] = "number",
			["check"] = checkgreaterthanzero,
			["default"] = 5000
		},
		[28] = {
			["name"] = "BLUE_AI",
			["type"] = "boolean",
			["default"] = false
		},
		[29] = {
			["name"] = "RED_AI",
			["type"] = "boolean",
			["default"] = false
		},
	}
	
	tbl.path = path
	utils.checkkeys(keys, tbl)
	tbl.path = nil
	
	return tbl
end

local function validate_radio_settings(cfgdata, tbl)

	if tbl == nil then
		return {}
	end
	
	local path = cfgdata.file
	local keys = 
	{
		[1] = {
			["name"] = "ASSIGN_TO_AI",
			["type"] = "boolean",
			["default"] = false
		},
		[2] = {
			["name"] = "BLUE_FREQS",
			["type"] = "table",
			["check"] = checkfreqtable,
			["default"] = {}
		},
		[3] = {
			["name"] = "RED_FREQS",
			["type"] = "table",
			["check"] = checkfreqtable,
			["default"] = {}
		},
		[4] = {
			["name"] = "FREQ_STEPS",
			["type"] = "number",
			["check"] = checkfreqsteps,
			["default"] = 0.250
		},
		[5] = {
			["name"] = "FREQ_UNAVAILABLE",
			["type"] = "table",
			["check"] = checkfreqarray,
			["default"] = {121.500, 243.000, 249.500, 250.000,}
		},
		[6] = {
			["name"] = "REBROADCAST",
			["type"] = "boolean",
			["check"] = checkrebroadcast,
			["default"] = true
		},
		[7] = {
			["name"] = "COMMS_PLAN",
			["type"] = "table",
			["check"] = checkcommsplan,
			["default"] = {}
		},
	}
						
	tbl.path = path
	utils.checkkeys(keys, tbl)
	tbl.path = nil
	
	return tbl
end

local function checkrebroadcast(keydata, t)
	
	-- requires exactly equal bandwidth in UHF VHF AND FM
	if t[keydata.name] then
	
		bluebandwidth = t["BLUE_FREQS"]["UHF_Max"]-t["BLUE_FREQS"]["UHF_Min"]
		
		areEqual1 = bluebandwidth == (t["BLUE_FREQS"]["VHF_Max"]-t["BLUE_FREQS"]["VHF_Min"]) == (t["BLUE_FREQS"]["FM_Max"]-t["BLUE_FREQS"]["FM_Min"])
		
		redbandwidth = t["RED_FREQS"]["UHF_Max"]-t["RED_FREQS"]["UHF_Min"]
		
		areEqual2 = redbandwidth == (t["RED_FREQS"]["VHF_Max"]-t["RED_FREQS"]["VHF_Min"]) == (t["RED_FREQS"]["FM_Max"]-t["RED_FREQS"]["FM_Min"])
		
		assert(areEqual1 and areEqual2, "Rebroadcast option requires all channels be of equal bandwidth for a given coalition")
		
		if(areEqual1 and areEqual2) then
		
			return true
			
		else
		
			return false
			
		end	
		


	else
	
		return true
	
	end

end

local function checkfreqtable(keydata, t)
	
	local validkeys = {["UHF_MAX"] = true,
				       ["UHF_MIN"] = true,
					   ["VHF_MAX"] = true,
					   ["VHF_MIN"] = true,
					   ["FM_MAX"] = true,
					   ["FM_MIN"] = true,
					  }
	
	local isValid = true
	
	
	for k,v in pairs(t[keydata.name]) do
		
		if(validkeys[k] == nil or type(v) ~= "number" or v <0 or v > 400) then
			
			return false
					
		end	

	end
	
	
	local UHF_Start = t[keydata.name].UHF_MAX
	local UHF_End = t[keydata.name].UHF_MIN
	local UHF_Start = t[keydata.name].UHF_MAX
	local UHF_Start = t[keydata.name].UHF_MAX
	local UHF_Start = t[keydata.name].UHF_MAX
	local UHF_Start = t[keydata.name].UHF_MAX
	
	return true


end

local function checkcommsplan(keydata, t)
	
	for k,v in pairs(t[keydata.name]) do
		
		if(tonumber(k) == nil or type(v) ~= "string") then
			
			return false
					
		end	

	end
	
	return true


end

local function validate_payload_limits(cfgdata, tbl)
	local newlimits = {}
	for wpncat, val in pairs(tbl) do
		local w = enum.weaponCategory[string.upper(wpncat)]
		assert(w ~= nil,
			string.format("invalid weapon category '%s'; file: %s",
				wpncat, cfgdata.file))
		newlimits[w] = val
	end
	return newlimits
end

local function validate_codenamedb(cfgdata, tbl)
	local newtbl = {}
	for key, list in pairs(tbl) do
		local newkey
		assert(type(key) == "string",
			string.format("invalid codename category '%s'; file: %s",
			key, cfgdata.file))

		local k = enum.assetType[string.upper(key)]
		if k ~= nil then
			newkey = k
		elseif key == "default" then
			newkey = key
		else
			assert(nil,
				string.format("invalid codename category '%s'; file: %s",
				key, cfgdata.file))
		end
		assert(type(list) == "table",
			string.format("invalid codename value for category "..
				"'%s', must be a table; file: %s", key, cfgdata.file))
		newtbl[newkey] = list
	end
	return newtbl
end

local function gridfmt_transform(tbl)
	local ntbl = {}
	for k, v in pairs(tbl) do
		if type(v) == "number" then
			ntbl[k] = v
		else
			ntbl[k] = dctutils.posfmt[string.upper(v)]
			assert(ntbl[k] ~= nil, "invalid grid format for "..k)
		end
	end
	return ntbl
end

local function ato_transform(tbl)
	local ntbl = {}
	for ac, mlist in pairs(tbl) do
		ntbl[ac] = {}
		for _, v in pairs(mlist) do
			local mtype = string.upper(v)
			local mval  = enum.missionType[mtype]
			assert(mval ~= nil,
				string.format("invalid mission type: %s for ac: %s",
					v, ac))
			ntbl[ac][mtype] = mval
		end
	end
	return ntbl
end

local function validate_ui(cfgdata, tbl)
	local newtbl = {}
	utils.mergetables(newtbl, cfgdata.default)
	for k, v in pairs(tbl) do
		utils.mergetables(newtbl[k], v)
		if k == "gridfmt" then
			newtbl[k] = gridfmt_transform(newtbl[k])
		elseif k == "ato" then
			newtbl[k] = ato_transform(newtbl[k])
		end
	end
	return newtbl
end

local function validate_blast_effects(cfgdata, tbl)
	local newtbl = {}
	newtbl = utils.mergetables(newtbl, cfgdata.default)
	newtbl = utils.mergetables(newtbl, tbl)
	return newtbl
end

--[[
-- We have a few levels of configuration:
-- 	* server defined config file; <dcs-saved-games>/Config/dct.cfg
-- 	* theater defined configuration; <theater-path>/settings/<config-files>
-- 	* default config values
-- simple algorithm; assign the defaults, then apply the server and
-- theater configs
--]]
local function theatercfgs(config)
	local defaultpayload = {}
	for _,v in pairs(enum.weaponCategory) do
		defaultpayload[v] = enum.WPNINFCOST - 1
	end

	local cfgs = {
		{
			["name"] = "restrictedweapons",
			["file"] = config.server.theaterpath..utils.sep.."settings"..
				utils.sep.."restrictedweapons.cfg",
			["cfgtblname"] = "restrictedweapons",
			["validate"] = validate_weapon_restrictions,
			["default"] = {
				["RN-24"] = {
					["cost"]     = enum.WPNINFCOST,
					["category"] = enum.weaponCategory.AG,
				},
				["RN-28"] = {
					["cost"]     = enum.WPNINFCOST,
					["category"] = enum.weaponCategory.AG,
				},
			},
		},
		{
			["name"] = "payloadlimits",
			["file"] = config.server.theaterpath..utils.sep.."settings"..
				utils.sep.."payloadlimits.cfg",
			["validate"] = validate_payload_limits,
			["default"] = defaultpayload,
		}, 
		{
			["name"] = "codenamedb",
			["file"] = config.server.theaterpath..utils.sep.."settings"..
				utils.sep.."codenamedb.cfg",
			["validate"] = validate_codenamedb,
			["default"] = require("dct.data.codenamedb"),
		}, 
		{
			["name"] = "ui",
			["file"] = config.server.theaterpath..utils.sep.."settings"..
				utils.sep.."ui.cfg",
			["validate"] = validate_ui,
			["default"] = {
				["gridfmt"] = {
					-- default is DMS, no need to list
					["Ka-50"]         = dctutils.posfmt.DDM,
					["Mi-8MT"]        = dctutils.posfmt.DDM,
					["SA342M"]        = dctutils.posfmt.DDM,
					["SA342L"]        = dctutils.posfmt.DDM,
					["UH-1H"]         = dctutils.posfmt.DDM,
					["A-10A"]         = dctutils.posfmt.MGRS,
					["A-10C"]         = dctutils.posfmt.MGRS,
					["A-10C_2"]       = dctutils.posfmt.MGRS,
					["F-5E-3"]        = dctutils.posfmt.DDM,
					["F-16C_50"]      = dctutils.posfmt.DDM,
					["FA-18C_hornet"] = dctutils.posfmt.DDM,
					["M-2000C"]       = dctutils.posfmt.DDM,
				},
				["ato"] = {},
			},
		},

		
		{
			["name"] = "gameplay",
			["file"] = config.server.theaterpath..utils.sep.."settings"..
				utils.sep.."gameplay.cfg",
			["validate"] = validate_gameplay_configs,
			["default"] = require("dct.data.gameplay_settings"),
		}, 
		{
			["name"] = "radios",
			["file"] = config.server.theaterpath..utils.sep.."settings"..
				utils.sep.."radios.cfg",
			["validate"] = validate_radio_settings,
			["default"] = require("dct.data.radio_defaults"),
		},

		{
			["name"] = "blasteffects",
			["file"] = config.server.theaterpath..utils.sep.."settings"..
				utils.sep.."blasteffects.cfg",
			["validate"] = validate_blast_effects,
			["default"] = require("dct.data.blasteffects"),
		},
	}
	
	utils.readconfigs(cfgs, config)
	
	return config
end

return theatercfgs
