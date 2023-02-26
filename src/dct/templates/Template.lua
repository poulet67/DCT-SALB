--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Provides functions for handling templates.
--]]

require("lfs")
local class = require("libs.class")
local utils = require("libs.utils")
local dctutils = require("libs.utils")
local enum  = require("dct.enum")
local vector= require("dct.libs.vector")
local Goal  = require("dct.Goal")
local STM   = require("dct.templates.STM")
local Logger = 	dct.Logger.getByName("Template")
local settings    = _G.dct.settings
--[[
-- represents the amount of damage that can be taken before
-- that state is no longer considered valid.
-- example:
--   goal: damage unit to 85% of original health (aka incapacitate)
--
--   unit.health = .85
--   goal = 85
--   damage_taken = (1 - unit.health) * 100 = 15
--
--   if damage_taken > goal = goal met, in this case we have
--   not met our greater than 85% damage.
--]]
local damage = {
	["UNDAMAGED"]     = 10,
	["DAMAGED"]       = 45,
	["INCAPACITATED"] = 75,
	["DESTROYED"]     = 90,
}

--[[
-- generates a death goal from an object's name by
-- using keywords.
--]]
local function goalFromName(name, objtype)
	local goal = {}
	local goalvalid = false
	name = string.upper(name)

	for k, v in pairs(Goal.priority) do
		local index = string.find(name, k)
		if index ~= nil then
			goal.priority = v
			goalvalid = true
			break
		end
	end

	for k, v in pairs(damage) do
		local index = string.find(name, k)
		if index ~= nil then
			goal.value = v
			goalvalid = true
			break
		end
	end

	if not goalvalid then
		return nil
	end
	if goal.priority == nil then
		goal.priority = Goal.priority.PRIMARY
	end
	if goal.value == nil then
		goal.value = damage.INCAPACITATED
	end
	goal.objtype  = objtype
	goal.goaltype = Goal.goaltype.DAMAGE
	return goal
end

local function makeNamesUnique(data)
	for _, grp in ipairs(data) do
		grp.data.name = grp.data.name.." #"..
			dct.Theater.singleton():getcntr()
		for _, v in ipairs(grp.data.units or {}) do
			v.name = v.name.." #"..dct.Theater.singleton():getcntr()
		end
	end
end

local function overrideUnitOptions(unit, key, tpl, basename)
	if unit.playerCanDrive ~= nil then
		unit.playerCanDrive = false
	end
	unit.unitId = nil
	unit.dct_deathgoal = goalFromName(unit.name, Goal.objtype.UNIT)
	if unit.dct_deathgoal ~= nil then
		tpl.hasDeathGoals = true
	end
	unit.name = basename.."-"..key
end

local function overrideGroupOptions(grp, idx, tpl)
	if grp.category == enum.UNIT_CAT_SCENERY then
		return
	end

	local opts = {
		visible        = true,
		uncontrollable = true,
		lateActivation = false,
	}

	for k, v in pairs(opts) do
		if grp[k] ~= nil then grp[k] = v end
	end

	local goaltype = Goal.objtype.GROUP
	if grp.category == Unit.Category.STRUCTURE then
		goaltype = Goal.objtype.STATIC
	end

	grp.data.groupId = nil
	grp.data.unitId  = nil
	grp.data.start_time = 0
	grp.data.dct_deathgoal = goalFromName(grp.data.name, goaltype)
	if grp.data.dct_deathgoal ~= nil then
		tpl.hasDeathGoals = true
	end
	--grp.data.name = tpl.regionname.."_"..tpl.name.." "..tpl.coalition.." "..
	--	utils.getkey(Unit.Category, grp.category).." "..tostring(idx)
		
	grp.data.name = tpl.name.." "..tpl.coalition.." "..
		utils.getkey(Unit.Category, grp.category).." "..tostring(idx)

	for i, unit in ipairs(grp.data.units or {}) do
		overrideUnitOptions(unit, i, tpl, grp.data.name)
	end
end

local function checktpldata(_, tpl)
	-- loop over all tpldata and process names and existence of deathgoals
	for idx, grp in ipairs(tpl.tpldata) do
		overrideGroupOptions(grp, idx, tpl)
	end
	return true
end

local function checkbldgdata(keydata, tpl)
	if next(tpl[keydata.name]) ~= nil and tpl.tpldata == nil then
		tpl.tpldata = {}
	end

	for _, bldg in ipairs(tpl[keydata.name]) do
		local bldgdata = {}
		bldgdata.countryid = 0
		bldgdata.category  = enum.UNIT_CAT_SCENERY
		bldgdata.data = {
			["dct_deathgoal"] = goalFromName(bldg.goal,
				Goal.objtype.SCENERY),
			["name"] = tostring(bldg.id),
		}
		local sceneryobject = { id_ = tonumber(bldgdata.data.name), }
		utils.mergetables(bldgdata.data,
			vector.Vector2D(Object.getPoint(sceneryobject)):raw())
		table.insert(tpl.tpldata, bldgdata)
		if bldgdata.data.dct_deathgoal ~= nil then
			tpl.hasDeathGoals = true
		end
	end
	return true
end

local function checkbriefing(keydata, tbl)
	if (type(tbl[keydata.name]) == "string" or tbl[keydata.name] == nil) then
		return true
	else
		return false
	end
end

local function checkheading(keydata, tbl)
	if (tbl[keydata.name] >= 0 or tbl[keydata.name] <= 360) then
		return true
	else
		return false
	end
end

local function checkobjtype(keydata, tbl)
	if type(tbl[keydata.name]) == "number" and
		utils.getkey(enum.assetType, tbl[keydata.name]) ~= nil then
		return true
	elseif type(tbl[keydata.name]) == "string" and
		enum.assetType[string.upper(tbl[keydata.name])] ~= nil then
		tbl[keydata.name] = enum.assetType[string.upper(tbl[keydata.name])]
		return true
	end
	return false
end

local function checkside(keydata, tbl)
	if type(tbl[keydata.name]) == "number" and
		utils.getkey(coalition.side, tbl[keydata.name]) ~= nil then
		return true
	elseif type(tbl[keydata.name]) == "string" and
		coalition.side[string.upper(tbl[keydata.name])] ~= nil then
		tbl[keydata.name] = coalition.side[string.upper(tbl[keydata.name])]
		return true
	end
	return false
end

local function checkregname(keydata, tbl)
	if type(tbl[keydata.name]) == "string" or tbl[keydata.name] == nil then
		return true
	end
	return false
end
local function checkstage(keydata, tbl)
	if tbl[keydata.name] >= 1 then
		return true
	end
	return false
end

local function check_cp_reward(keydata, tbl)
	if tbl[keydata.name] >= 0 then
		return true
	end
	return false
end

local function checkperiod(keydata, tbl)
	if tbl[keydata.name] == nil then
		return true
	elseif tbl[keydata.name] >= 300 then  --5 minutes TODO: make this a dct setting
		return true
	else
		return false
	end
end

local function checktakeoff(keydata, tpl)
	local allowed = {
		["inair"]   = AI.Task.WaypointType.TURNING_POINT,
		["runway"]  = AI.Task.WaypointType.TAKEOFF,
		["parking"] = AI.Task.WaypointType.TAKEOFF_PARKING,
	}

	local val = allowed[tpl[keydata.name]]
	if val then
		tpl[keydata.name] = val
		return true
	end
	return false
end

local function checkrecovery(keydata, tpl)
	local allowed = {
		["terminal"] = true,
		["land"]     = true,
		["taxi"]     = true,
	}

	if allowed[tpl[keydata.name]] then
		return true
	end
	return false
end

local function checkmsntype(keydata, tbl)
	local msnlist = {}
	for _, msntype in pairs(tbl[keydata.name]) do
		local msnstr = string.upper(msntype)
		if type(msntype) ~= "string" or
		   enum.missionType[msnstr] == nil then
			return false
		end
		msnlist[msnstr] = enum.missionType[msnstr]
	end
	tbl[keydata.name] = msnlist
	return true
end

local function check_payload_limits(keydata, tbl)
	local newlimits = {}
	for wpncat, val in pairs(tbl[keydata.name]) do
		local w = enum.weaponCategory[string.upper(wpncat)]
		if w == nil then
			return false
		end
		newlimits[w] = val
	end
	tbl[keydata.name] = newlimits
	return true
end

local function check_marshalpoint(keydata, tbl) -- permits nil values
	local loc = tbl[keydata.name]
	
	if tbl[keydata.name] == nil then
		return true
	end
	
	if(type(tbl[keydata.name]) == "table") then
		
		for _, val in pairs({"x", "y"}) do
			if loc[val] == nil or type(loc[val]) ~= "number" then
				return false
			end
		end
		
		local vec2 = vector.Vector2D(tbl[keydata.name])                                 --thanks to eagle dynamics and their complete inability to do anything consistently 
		tbl[keydata.name] =	vector.Vector3D(vec2, land.getHeight(vec2:raw())):raw()     --  land.getHeight is specifed as X, Y (where Y is actually Z, according to their broken coordinate system)
																					-- have fun
		return true	
	
	else
		
		
		
	end
	

end

local function getkeys(objtype)
	local notpldata = {
		[enum.assetType.AIRSPACE]       = true,
		[enum.assetType.AIRBASE]        = true,
		[enum.assetType.WAYPOINT]        = true,
		[enum.assetType.WEAPON]        = true,
	}
	local defaultintel = 1
	if objtype == enum.assetType.AIRBASE then
		defaultintel = 5
	end

	local keys = {  --NOTE: Nil values are allowed IF the key has: 1) no type defined, 2) a check function that (should check for type since that is no longer being done, and) will allow for nil values
		{
			["name"]  = "name",
			["type"]  = "string",
		}, {
			["name"]  = "regionname",
			["check"] = checkregname
		}, {
			["name"]  = "coalition",
			["type"]  = "number",
			["check"] = checkside,
		}, {
			["name"]    = "uniquenames",
			["type"]    = "boolean",
			["default"] = false,
		}, {
			["name"]    = "ignore",
			["type"]    = "boolean",
			["default"] = false,
		}, {
			["name"]    = "regenerate",
			["type"]    = "boolean",
			["default"] = false,
		},{
			["name"]    = "intel",
			["type"]    = "number",
			["default"] = defaultintel,
		}, {
			["name"]    = "spawnalways",
			["type"]    = "boolean",
			["default"] = false,
		}, {
			["name"]    = "spawnable", -- can spawn from f10 menu
			["type"]    = "boolean",
			["default"] = false,
		}, {
			["name"]    = "cp_reward",
			["type"]    = "number",
			["default"] = 500,
			["check"] = check_cp_reward,
		}, {
			["name"]    = "desc",
			["type"]    = "string",
			["default"] = "false",
		},{
			["name"]    = "codename",
			["type"]    = "string",
			["default"] = "default codename",
		},{
			["name"]    = "stage",
			["type"]    = "number",
			["default"] = 1,
			["check"] = checkstage,
		},{
			["name"]    = "known",
			["type"]    = "boolean",
			["default"] = false,
		},{
			["name"]    = "next_stage",
			["type"]    = "boolean",
			["default"] = false,
		},{
			["name"]    = "period", -- how often a mission for this asset will be created and re-created
			["check"] = checkperiod,
		},{
			["name"]    = "marshal_point", -- where players should marshal to strike at the same time once
			["check"] = check_marshalpoint,
		},
	}

	if notpldata[objtype] == nil then
		table.insert(keys, {
			["name"]    = "buildings",
			["type"]    = "table",
			["default"] = {},
			["check"] = checkbldgdata,})
		table.insert(keys, {
			["name"]  = "tpldata",
			["type"]  = "table",
			["check"] = checktpldata,})
	end

	if objtype == enum.assetType.AIRSPACE then
		table.insert(keys, {
			["name"]  = "location",
			["type"]  = "table",})
		table.insert(keys, {
			["name"]  = "volume",
			["type"]  = "table", })
	end
	
	if objtype == enum.assetType.WAYPOINT then
		table.insert(keys, {
			["name"]  = "location",
			["type"]  = "table",})
	end
	
	if objtype == enum.assetType.WEAPON then
		table.insert(keys, {
			["name"]  = "location",
			["type"]  = "table",})
	end

	if objtype == enum.assetType.AIRBASE then
		table.insert(keys, {
			["name"]  = "subordinates",
			["type"]  = "table", })
		table.insert(keys, {
			["name"]    = "takeofftype",
			["type"]    = "string",
			["default"] = "inair",
			["check"]   = checktakeoff,})
		table.insert(keys, {
			["name"]    = "recoverytype",
			["type"]    = "string",
			["default"] = "terminal",
			["check"]   = checkrecovery,})
	end

	return keys
end

--[[
--  Template class
--    base class that reads in a template file and organizes
--    the data for spawning.
--
--    properties
--    ----------
--      * objtype   - represents an abstract type of asset
--      * name      - name of the template
--      * region    - the region name the template belongs to
--      * coalition - which coalition the template belongs to
--                    templates can only belong to one side and
--                    one side only
--      * desc      - description of the template, used to generate
--		              mission breifings from
--
--    Storage
--    -------
--    tpldata = {
--      # = {
--          category = Unit.Category
--          countryid = id,
--          data      = {
--            # group def members
--            dct_deathgoal = goalspec
--    }}}
--
--    DCT File
--    --------
--      Required Keys:
--        * objtype - the kind of "game object" the template represents
--
--      Optional Keys:
--        * uniquenames - when a Template's data is copied the group and
--              unit names a guaranteed to be unique if true
--
--]]

local Template = class()
function Template:__init(data)
	Logger:debug("TEMPLATE INIT")	
	assert(data and type(data) == "table", "value error: data required")
	self.hasDeathGoals = false
	Logger:debug("BEFORE MERGETABLES")	
	utils.mergetables(self, utils.deepcopy(data))
	Logger:debug("AFTER MERGETABLES")	
	self:validate()
	self.checklocation = nil
	self.fromFile = nil
	
	Logger:debug("DONE")	
end

function Template:validate()

	utils.checkkeys({ [1] = {
		["name"]  = "objtype",
		["type"]  = "string",
		["check"] = checkobjtype,
	},}, self)

	utils.checkkeys(getkeys(self.objtype), self)
	
end

-- PUBLIC INTERFACE
function Template:copyData()
	local copy = utils.deepcopy(self.tpldata)
	if self.uniquenames == true then
		makeNamesUnique(copy)
	end
	return copy
end

function Template.fromFile(dctfile, stmfile, command_unit)  --region, dctfile, stmfile)
	--assert(region ~= nil, "region is required")
	assert(dctfile ~= nil, "dctfile is required")

	Logger:debug("TEMPLATE -- IN TEMPLATES: %s")
	
	local template = utils.readlua(dctfile)
	
	Logger:debug("TEMPLATE -- LUA READ")	
	Logger:debug(tostring(command_unit))	
	
	if template.metadata then
		template = template.metadata
	end

	if template.regionname then
		template.regionname	= region.name
	end
	
	if template.regionprio then
		template.regionprio = region.priority
	end
	
	
	template.path = dctfile
	
	if(template.desc) then		
		Logger:debug("TEMPLATE -- desc found: %s", template.desc)
	
	end
	
	if template.desc == "false" then
	
		template.desc = nil
		
	end
	-- this should be last
	
	if stmfile ~= nil then
		Logger:debug("TEMPLATE -- STM TRANSFORM")
		template_from_file = STM.transform(utils.readlua(stmfile, "staticTemplate"))
		utils.tprint(template_from_file)
		template = utils.mergetables(template_from_file, template)
		Logger:debug("template dump")
		utils.tprint(template)
		
	end
	
		
	if(command_unit) then
		--should probably add a restriction to regular template names (i.e can not contain TANKER or AWACS)
		template.commandUnitType = template.CU_Type
		if(template.display_name == nil) then
			template.display_name = template.tpldata[1].data["units"][1]["type"] -- A default name for display purposes
		end		

		template.name = template.commandUnitType..dct.Theater.singleton():getcntr() -- just for uniqueness, we will rename during dispatch anyhow
		template.objtype = "DISPATCHABLE" -- must be done so the right type gets applied during validate
		
	
		Logger:debug("TEMPLATE -- name found: %s", template.name)
		Logger:debug("TEMPLATE -- commandUnitType found: %s", template.commandUnitType)
		
	end	
	
	Logger:debug("RETURN")	
	return Template(template)
	
end


--[[
function Template.notfromFile(region, desc)

	local template = utils.readlua(dctfile)
	if template.metadata then
		template = template.metadata
	end
	template.regionname = region.name;
	template.regionprio = region.priority;
	template.path = nil;
	template.desc = desc;
	end

	return Template(template)
end
]]--
return Template
