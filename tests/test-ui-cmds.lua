#!/usr/bin/lua

require("math")
math.randomseed(50)
require("dcttestlibs")
require("dct")
local enum   = require("dct.enum")
local uicmds = require("dct.ui.cmds")

-- create a player group
local grp = Group(4, {
	["id"] = 9,
	["name"] = "VMFA251 - Enfield 1-1",
	["coalition"] = coalition.side.BLUE,
	["exists"] = true,
})

local unit1 = Unit({
	["name"] = "pilot1",
	["exists"] = true,
	["desc"] = {
		["typeName"] = "FA-18C_hornet",
		["attributes"] = {},
	},
}, grp, "bobplayer")

local briefingtxt = "Package: #5720\n"..
			"IFF Codes: M1(05), M3(5720)\n"..
			"Target AO: 88°07.38'N 063°27.36'W (LONDON)\n"..
			"Briefing:\n"..
			"Aerial photography shows that there is"..
			" a fuel storage facility at 88°07.38'N 063°27.36'W,"..
			" East of Krasnodar-Center.\n\n"..
			"Primary Objectives: Destroy the fuel tanks embedded in "..
			"the ground at the facility.\n\n"..
			"Secondary Objectives: Destroy the white storage hangars.\n\n"..
			"Recommended Pilots: 2\n\n"..
			"Recommended Ordnance: Pilot discretion."

local testcmds = {
	{
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.THEATERSTATUS,
		},
		["assert"]     = true,
		["expected"]   = "== Theater Threat Status ==\n"..
			"  Force Str: Nominal\n  Sea:    medium\n"..
			"  Air:    parity\n  ELINT:  medium\n  SAM:    medium\n\n"..
			"== Friendly Force Info ==\n  Force Str: Nominal\n\n"..
			"== Current Active Air Missions ==\n  No Active Missions\n\n"..
			"Recommended Mission Type: SEAD\n",
	}, {
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.MISSIONREQUEST,
			["value"]  = enum.missionType.STRIKE,
		},
		["assert"]     = true,
		["expected"]   = "Mission 5720 assigned, use F10 menu to "..
			"see this briefing again\n"..briefingtxt,
	}, {
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.THEATERSTATUS,
		},
		["assert"]     = true,
		["expected"]   = "== Theater Threat Status ==\n"..
			"  Force Str: Nominal\n  Sea:    medium\n"..
			"  Air:    parity\n  ELINT:  medium\n  SAM:    medium\n\n"..
			"== Friendly Force Info ==\n  Force Str: Nominal\n\n"..
			"== Current Active Air Missions ==\n  STRIKE:   1\n\n"..
			"Recommended Mission Type: SEAD\n",
	}, {
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.MISSIONBRIEF,
		},
		["assert"]     = true,
		["expected"]   = briefingtxt,
	}, {
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.MISSIONSTATUS,
		},
		["assert"]     = true,
		["expected"]   = "Mission State: Preparing\n"..
			"Package: 5720\n"..
			"Timeout: 2016-06-21 12:30z (in 90 mins)\n"..
			"BDA: 0% complete\n",
	}, {
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.MISSIONROLEX,
			["value"]  = 120,
		},
		["assert"]     = true,
		["expected"]   = "+2 mins added to mission timeout",
		--[[
	}, {
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.MISSIONCHECKIN,
		},
		["assert"]     = true,
		["expected"]   = "on-station received",
	}, {
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.MISSIONCHECKOUT,
		},
		["assert"]     = true,
		["expected"]   = "off-station received, vul time: 0",
		--]]
	}, {
		-- Test 2 min rolex and 5 min delay
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.MISSIONSTATUS,
		},
		["modelTime"]  = 300,
		["assert"]     = true,
		["expected"]   = "Mission State: Preparing\n"..
			"Package: 5720\n"..
			"Timeout: 2016-06-21 12:32z (in 87 mins)\n"..
			"BDA: 0% complete\n",
	}, {
		["data"] = {
			["name"]   = grp:getName(),
			["type"]   = enum.uiRequestType.MISSIONABORT,
			["value"]  = enum.missionAbortType.ABORT,
		},
		["assert"]     = true,
		["expected"]   = "Mission 5720 aborted",
	},
}

local function main()
	local theater = dct.Theater()
	_G.dct.theater = theater
	theater:exec(50)
	theater:onEvent({
		["id"]        = world.event.S_EVENT_BIRTH,
		["initiator"] = unit1,
	})

	for _, v in ipairs(testcmds) do
		if v.modelTime ~= nil then
			timer.stub_setTime(v.modelTime)
		end
		trigger.action.setassert(v.assert)
		trigger.action.setmsgbuffer(v.expected)
		local cmd = uicmds[v.data.type](theater, v.data)
		cmd:execute(400)
	end
	trigger.action.setassert(false)

	local data = {
		["name"]   = grp:getName(),
		["type"]   = enum.uiRequestType.MISSIONREQUEST,
		["value"]  = enum.missionType.STRIKE,
	}

	for _, v in pairs(enum.missionType) do
		data.value = v
		for _, s in pairs(coalition.side) do
			data.side = s
			local cmd = uicmds[data.type](theater, data)
			cmd:execute(500)
		end
	end
	return 0
end

os.exit(main())
