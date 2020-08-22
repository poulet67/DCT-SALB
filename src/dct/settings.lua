--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Provides config facilities.
--]]

require("lfs")
local utils      = require("libs.utils")
local dctutils   = require("dct.utils")
local enum       = require("dct.enum")
local codenamedb = require("dct.data.codenamedb")
local config     = nil

--[[
-- We have 3 levels of config,
-- 	* mission defined configs
-- 	* server defined config file
-- 	* default config values
-- simple algorithm; assign the defaults, then apply the server, then
-- any mission level configs
--]]
local function settings(missioncfg)
	if config ~= nil then
		return config
	end

	local path = lfs.writedir()..utils.sep.."Config"..utils.sep.."dct.cfg"
	local attr = lfs.attributes(path)

	config = {
	-- ["luapath"] = lfs.writedir() .. "Scripts\\?.lua"
	--[[
	-- Note: Can't provide a server level package path as to require
	-- dct would require the package path to already be set. Nor can
	-- we provide a useful default because the package.path needs to
	-- be set before we get here.
	--]]
		["theaterpath"] = lfs.tempdir() .. utils.sep .. "theater",
		["debug"]       = false,
		["profile"]     = false,
		["statepath"]   = lfs.writedir()..utils.sep..env.mission.theatre..
			"_"..env.getValueDictByKey(env.mission.sortie)..".state",
		["acgridfmt"] = {
			["Ka-50"]         = dctutils.posfmt.DDM,
			["M-2000C"]       = dctutils.posfmt.DDM,
			["A-10C"]         = dctutils.posfmt.MGRS,
			["AJS37"]         = dctutils.posfmt.DMS,
			["F-14B"]         = dctutils.posfmt.DDM,
			["FA-18C_hornet"] = dctutils.posfmt.DDM,
			["F-16C_50"]      = dctutils.posfmt.DDM,
			["UH-1H"]         = dctutils.posfmt.DDM,
			["Mi-8MT"]        = dctutils.posfmt.DDM,
			["F-5E-3"]        = dctutils.posfmt.DDM,
			["AV8BNA"]        = dctutils.posfmt.DDM,
			["SA342M"]        = dctutils.posfmt.DDM,
			["SA342L"]        = dctutils.posfmt.DDM,
			["A-10C_2"]       = dctutils.posfmt.MGRS,
		},
		["codenamedb"] = codenamedb,
		["atorestrictions"] = {
			[coalition.side.RED]  = {},
			[coalition.side.BLUE] = {
				["A-10C"] = {
					["CAS"]    = enum.missionType.CAS,
					["BAI"]    = enum.missionType.BAI,
					["STRIKE"] = enum.missionType.STRIKE,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["A-10C_2"] = {
					["CAS"]    = enum.missionType.CAS,
					["BAI"]    = enum.missionType.BAI,
					["STRIKE"] = enum.missionType.STRIKE,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
                                },
				["A-10A"] = {
					["CAS"]    = enum.missionType.CAS,
					["BAI"]    = enum.missionType.BAI,
					["STRIKE"] = enum.missionType.STRIKE,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["F-15C"] = {
					["CAP"] = enum.missionType.CAP,
				},
				["F-5E-3"] = {
					["STRIKE"] = enum.missionType.STRIKE,
					["BAI"]    = enum.missionType.BAI,
					["CAS"]    = enum.missionType.CAS,
					["OCA"]    = enum.missionType.OCA,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["M-2000C"] = {
					["STRIKE"] = enum.missionType.STRIKE,
					["BAI"]    = enum.missionType.BAI,
					["OCA"]    = enum.missionType.OCA,
					["CAP"]    = enum.missionType.CAP,
				},
				["AV8BNA"] = {
					["STRIKE"] = enum.missionType.STRIKE,
					["BAI"]    = enum.missionType.BAI,
					["OCA"]    = enum.missionType.OCA,
					["SEAD"]   = enum.missionType.SEAD,
					["CAS"]    = enum.missionType.CAS,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["AJS37"] = {
					["STRIKE"] = enum.missionType.STRIKE,
					["OCA"]    = enum.missionType.OCA,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["Ka-50"] = {
					["STRIKE"] = enum.missionType.STRIKE,
					["BAI"] = enum.missionType.BAI,
					["CAS"] = enum.missionType.CAS,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["UH-1H"] = {
					["CAS"]        = enum.missionType.CAS,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["Mi-8MT"] = {
					["CAS"]        = enum.missionType.CAS,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["SA342M"] = {
					["CAS"]        = enum.missionType.CAS,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["SA342L"] = {
					["CAS"]        = enum.missionType.CAS,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["Su-25T"] = {
					["STRIKE"] = enum.missionType.STRIKE,
					["BAI"]    = enum.missionType.BAI,
					["OCA"]    = enum.missionType.OCA,
					["SEAD"]   = enum.missionType.SEAD,
					["CAS"]    = enum.missionType.CAS,
					["ARMEDRECON"] = enum.missionType.ARMEDRECON,
				},
				["FA-18C_Hornet"] = {
					["OCA"]    = enum.missionType.OCA,
					["BAI"]    = enum.missionType.BAI,
					["CAP"]    = enum.missionType.CAP,
					["STRIKE"] = enum.missionType.STRIKE,
					["SEAD"]   = enum.missionType.SEAD,
					["CAS"]    = enum.missionType.CAS,
				},
				["F-16C_50"] = {
					["OCA"]    = enum.missionType.OCA,
					["BAI"]    = enum.missionType.BAI,
					["CAP"]    = enum.missionType.CAP,
					["STRIKE"] = enum.missionType.STRIKE,
					["SEAD"]   = enum.missionType.SEAD,
					["CAS"]    = enum.missionType.CAS,
				},
			},
		},
		["schedfreq"] = 2, -- hertz
		["tgtfps"] = 75,
		["percentTimeAllowed"] = .3,
	}

	if attr ~= nil then
		local rc = pcall(dofile, path)
		assert(rc, "failed to parse: "..path)
		assert(dctserverconfig ~= nil, "no dctserverconfig structure defined")
		utils.mergetables(config, dctserverconfig)
		dctserverconfig = nil
	end

	utils.mergetables(config, missioncfg)
	return config
end

return settings
