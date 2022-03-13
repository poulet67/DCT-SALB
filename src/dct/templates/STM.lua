--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Handles transforming an STM structure to a structure the Template
-- class knows how to deal with.
--]]

local utils = require("libs.utils")

local categorymap = {
	["HELICOPTER"] = 'HELICOPTER',
	["SHIP"]       = 'SHIP',
	["VEHICLE"]    = 'GROUND_UNIT',
	["PLANE"]      = 'AIRPLANE',
	["STATIC"]     = 'STRUCTURE',
}

local function convertNames(data, namefunc)
	data.name = namefunc(data.name)

	for _, unit in ipairs(data.units or {}) do
		unit.name = namefunc(unit.name)
	end

	if data.route then
		for _, wypt in ipairs(data.route.points or {}) do
			wypt.name = namefunc(wypt.name)
		end
	end
end

local function modifyStatic(grpdata, _, dcscategory)
	if dcscategory ~= Unit.Category.STRUCTURE then
		return grpdata
	end
	local grpcpy = utils.deepcopy(grpdata.units[1])
	grpcpy.dead = grpdata.dead
	return grpcpy
end

local function processCategory(grplist, cattbl, cntryid, dcscategory, ops)
	if type(cattbl) ~= 'table' or cattbl.group == nil then
		return
	end
	for _, grp in ipairs(cattbl.group) do
		if ops.grpfilter == nil or
			ops.grpfilter(grp, cntryid, dcscategory) == true then
			if type(ops.grpmodify) == 'function' then
				grp = ops.grpmodify(grp, cntryid, dcscategory)
			end
			local grptbl = {
				["data"]      = utils.deepcopy(grp),
				["countryid"] = cntryid,
				["category"]  = dcscategory,
			}
			convertNames(grptbl.data, ops.namefunc)
			table.insert(grplist, grptbl)
		end
	end
end


local STM = {}

-- return all groups matching `grpfilter` from `tbl`
-- grpfilter(grpdata, countryid, Unit.Category)
--   returns true if the filter matches and the group entry should be kept
-- grpmodify(grpdata, countryid, Unit.Category)
--   returns a copy of the group data modified as needed
-- always returns a table, even if it is empty
function STM.processCoalition(tbl, namefunc, grpfilter, grpmodify)
	assert(type(tbl) == 'table', "value error: `tbl` must be a table")
	assert(tbl.country ~= nil and type(tbl.country) == 'table',
		"value error: `tbl` must have a member `country` that is a table")

	local grplist = {}
	if namefunc == nil then
		namefunc = env.getValueDictByKey
	end
	local ops = {
		["namefunc"] = namefunc,
		["grpfilter"] = grpfilter,
		["grpmodify"] = grpmodify,
	}

	for _, cntrytbl in ipairs(tbl.country) do
		for cat, unitcat in pairs(categorymap) do
			processCategory(grplist,
				cntrytbl[string.lower(cat)],
				cntrytbl.id,
				Unit.Category[unitcat],
				ops)
		end
	end
	return grplist
end


--[[
-- Convert STM data format
--    stm = {
--      coalition = {
--        red/blue = {
--          country = {
--            # = {
--              id = country id
--              category = {
--                group = {
--                  # = {
--                    groupdata
--    }}}}}}}}
--
-- to an internal, simplier, storage format
--
--    tpldata = {
--      [#] = {
--        category  = Unit.Category[STM_category],
--        countryid = id,
--        data      = {
--            # group definition
--            dct_deathgoal = goalspec
--    }}}

-- And here is an actualy useful thing, a real table dump: 
--]]
--[[
2022-02-10 05:41:32.144 INFO    SCRIPTING: path: C:\Users\\Saved Games\DCS\Mods\tech\DCT\theater\command\BLUE\aircraft\E2DAWACS.dct
2022-02-10 05:41:32.144 INFO    SCRIPTING: hasDeathGoals: false
2022-02-10 05:41:32.144 INFO    SCRIPTING: spawnalways: false
2022-02-10 05:41:32.144 INFO    SCRIPTING: theater: Caucasus
2022-02-10 05:41:32.144 INFO    SCRIPTING: buildings: 
2022-02-10 05:41:32.144 INFO    SCRIPTING: next_stage: false
2022-02-10 05:41:32.144 INFO    SCRIPTING: known: false
2022-02-10 05:41:32.144 INFO    SCRIPTING: CU_Type: AWACS
2022-02-10 05:41:32.144 INFO    SCRIPTING: regenerate: false
2022-02-10 05:41:32.144 INFO    SCRIPTING: super: FUNCTION: super
2022-02-10 05:41:32.144 INFO    SCRIPTING: commandUnitType: AWACS
2022-02-10 05:41:32.144 INFO    SCRIPTING: ignore: false
2022-02-10 05:41:32.144 INFO    SCRIPTING: cp_reward: 500
2022-02-10 05:41:32.144 INFO    SCRIPTING: commandUnitName: E-2C
2022-02-10 05:41:32.144 INFO    SCRIPTING: isa: FUNCTION: isa
2022-02-10 05:41:32.144 INFO    SCRIPTING: spawnable: false
2022-02-10 05:41:32.144 INFO    SCRIPTING: intel: 1
2022-02-10 05:41:32.144 INFO    SCRIPTING: codename: default codename
2022-02-10 05:41:32.144 INFO    SCRIPTING: copyData: FUNCTION: copyData
2022-02-10 05:41:32.144 INFO    SCRIPTING: uniquenames: false
2022-02-10 05:41:32.144 INFO    SCRIPTING: validate: FUNCTION: validate
2022-02-10 05:41:32.144 INFO    SCRIPTING: desc: An E2-D AWACS on Cacausus map
2022-02-10 05:41:32.144 INFO    SCRIPTING: coalition: 2
2022-02-10 05:41:32.144 INFO    SCRIPTING: objtype: 31
2022-02-10 05:41:32.144 INFO    SCRIPTING: name: AWACS1001
2022-02-10 05:41:32.144 INFO    SCRIPTING: tpldata: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:   1: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:     countryid: 2
2022-02-10 05:41:32.144 INFO    SCRIPTING:     data: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:       taskSelected: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:       modulation: 0
2022-02-10 05:41:32.144 INFO    SCRIPTING:       tasks: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:       frequency: 251
2022-02-10 05:41:32.144 INFO    SCRIPTING:       hidden: false
2022-02-10 05:41:32.144 INFO    SCRIPTING:       units: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:         1: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:           alt: 2000
2022-02-10 05:41:32.144 INFO    SCRIPTING:           type: E-2C
2022-02-10 05:41:32.144 INFO    SCRIPTING:           psi: 0
2022-02-10 05:41:32.144 INFO    SCRIPTING:           livery_id: E-2D Demo
2022-02-10 05:41:32.144 INFO    SCRIPTING:           onboard_num: 010
2022-02-10 05:41:32.144 INFO    SCRIPTING:           skill: High
2022-02-10 05:41:32.144 INFO    SCRIPTING:           y: 79435.356200528
2022-02-10 05:41:32.144 INFO    SCRIPTING:           x: -270026.38522427
2022-02-10 05:41:32.144 INFO    SCRIPTING:           name: AWACS1001 2 AIRPLANE 1-1
2022-02-10 05:41:32.144 INFO    SCRIPTING:           payload: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:             pylons: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:             fuel: 5624
2022-02-10 05:41:32.144 INFO    SCRIPTING:             flare: 60
2022-02-10 05:41:32.144 INFO    SCRIPTING:             chaff: 120
2022-02-10 05:41:32.144 INFO    SCRIPTING:             gun: 100
2022-02-10 05:41:32.144 INFO    SCRIPTING:           speed: 133.61111111111
2022-02-10 05:41:32.144 INFO    SCRIPTING:           callsign: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:             1: 1
2022-02-10 05:41:32.144 INFO    SCRIPTING:             2: 1
2022-02-10 05:41:32.144 INFO    SCRIPTING:             3: 1
2022-02-10 05:41:32.144 INFO    SCRIPTING:             name: Overlord11
2022-02-10 05:41:32.144 INFO    SCRIPTING:           heading: 1.6222224783951
2022-02-10 05:41:32.144 INFO    SCRIPTING:           alt_type: BARO
2022-02-10 05:41:32.144 INFO    SCRIPTING:       y: 79435.356200528
2022-02-10 05:41:32.144 INFO    SCRIPTING:       x: -270026.38522427
2022-02-10 05:41:32.144 INFO    SCRIPTING:       name: AWACS1001 2 AIRPLANE 1
2022-02-10 05:41:32.144 INFO    SCRIPTING:       communication: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:       route: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:         points: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:           1: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:             alt: 2000
2022-02-10 05:41:32.144 INFO    SCRIPTING:             type: Turning Point
2022-02-10 05:41:32.144 INFO    SCRIPTING:             ETA: 0
2022-02-10 05:41:32.144 INFO    SCRIPTING:             alt_type: BARO
2022-02-10 05:41:32.144 INFO    SCRIPTING:             y: 79435.356200528
2022-02-10 05:41:32.144 INFO    SCRIPTING:             x: -270026.38522427
2022-02-10 05:41:32.144 INFO    SCRIPTING:             formation_template: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:             speed_locked: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:             speed: 133.61111111111
2022-02-10 05:41:32.144 INFO    SCRIPTING:             ETA_locked: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:             task: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:               id: ComboTask
2022-02-10 05:41:32.144 INFO    SCRIPTING:               params: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:                 tasks: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:                   1: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     number: 1
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     auto: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     id: AWACS
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     enabled: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     params: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:                   2: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     number: 2
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     auto: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     id: WrappedAction
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     enabled: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:                     params: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:                       action: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:                         id: EPLRS
2022-02-10 05:41:32.144 INFO    SCRIPTING:                         params: 
2022-02-10 05:41:32.144 INFO    SCRIPTING:                           value: true
2022-02-10 05:41:32.144 INFO    SCRIPTING:                           groupId: 1
2022-02-10 05:41:32.144 INFO    SCRIPTING:             action: Turning Point
2022-02-10 05:41:32.144 INFO    SCRIPTING:       start_time: 0
2022-02-10 05:41:32.144 INFO    SCRIPTING:       task: AWACS
2022-02-10 05:41:32.144 INFO    SCRIPTING:       uncontrolled: false
2022-02-10 05:41:32.144 INFO    SCRIPTING:     category: 0
2022-02-10 05:41:32.144 INFO    SCRIPTING: __init: FUNCTION: __init
2022-02-10 05:41:32.144 INFO    SCRIPTING: namedCU: true
2022-02-10 05:41:32.144 INFO    SCRIPTING: stage: 1
--]]


-- This is the most spaghetti piece of spaghetti made to unspaghetti spaghetti
-- This is the jenga piece that will bring the whole tower down 
-- push and prod at your own risk



function STM.transform(stmdata, file)
	local template   = {}
	local lookupname =  function(name)
		if name == nil then
			return nil
		end
		local newname = name
		local namelist = stmdata.localization.DEFAULT
		if namelist[name] ~= nil then
			newname = namelist[name]
		end
		return newname
	end
	local trackUniqueCoalition = function(_, cntryid, _)
		local side = coalition.getCountryCoalition(cntryid)
		if template.coalition == nil then
			template.coalition = side
		end
		assert(template.coalition == side, string.format(
			"runtime error: invalid STM; country(%s) does not belong "..
			"to '%s' coalition, country belongs to '%s' coalition; file: %s",
			country.name[cntryid],
			tostring(utils.getkey(coalition.side, template.coalition)),
			tostring(utils.getkey(coalition.side, side)),
			file))
		return true
	end

	template.name    = lookupname(stmdata.name)
	template.theater = lookupname(stmdata.theatre)
	template.desc    = lookupname(stmdata.desc)
	template.tpldata = {}

	for _, coa_data in pairs(stmdata.coalition) do
		for _, grp in ipairs(STM.processCoalition(coa_data,
				lookupname,
				trackUniqueCoalition,
				modifyStatic)) do
			table.insert(template.tpldata, grp)
		end
	end
	return template
end

STM.categorymap = categorymap
return STM