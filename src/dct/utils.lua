--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- common utility functions
--]]

require("os")
require("math")
local check = require("libs.check")
local enum  = require("dct.enum")
local utils = {}

local enemymap = {
	[coalition.side.NEUTRAL] = false,
	[coalition.side.BLUE]    = coalition.side.RED,
	[coalition.side.RED]     = coalition.side.BLUE,
}

utils.INTELMAX = 5

function utils.getenemy(side)
	return enemymap[side]
end

function utils.isalive(grpname)
	local grp = Group.getByName(grpname)
	return (grp and grp:isExist() and grp:getSize() > 0)
end

-- I hate this so much
function utils.interp(s, tab)
	return (s:gsub('(%b%%)', function(w) return tab[w:sub(2,-2)] or w end))
end

function utils.assettype2mission(assettype)
	for k, v in pairs(enum.missionTypeMap) do
		if v[assettype] then
			return k
		end
	end
	return nil
end

local airbase_id2name_map = nil
function utils.airbaseId2Name(id)
	if id == nil then
		return nil
	end
	if airbase_id2name_map == nil then
		airbase_id2name_map = {}
		for _, ab in pairs(world.getAirbases()) do
			airbase_id2name_map[tonumber(ab:getID())] = ab:getName()
		end
	end
	return airbase_id2name_map[id]
end

function utils.time(dcsabstime)
	-- timer.getAbsTime() returns local time of day, but we still need
	-- to calculate the day
	local time = os.time({
		["year"]  = env.mission.date.Year,
		["month"] = env.mission.date.Month,
		["day"]   = env.mission.date.Day,
		["hour"]  = 0,
		["min"]   = 0,
		["sec"]   = 0,
		--["isdst"] = false,
	})
	return time + dcsabstime
end

local offsettbl = {
	["Test Theater"] =  6*3600, -- simulate US Central TZ
	["PersianGulf"]  = -4*3600,
	["Nevada"]       =  8*3600,
	["Caucasus"]     = -4*3600,
	["Normandy"]     = -1*3600,
	["Syria"]        = -3*3600, -- EEST according to sunrise times
}

function utils.zulutime(abstime)
	local correction = offsettbl[env.mission.theatre] or 0
	return (utils.time(abstime) + correction)
end

function utils.centroid(point, pcentroid, n)
	if pcentroid == nil or n == nil then
		return {["x"] = point.x, ["y"] = point.y, ["z"] = point.z,}, 1
	end

	local centroid = {}
	local n1 = n + 1
	local x = point.x or 0
	local y = point.y or 0
	local z = point.z or point.alt or 0
	pcentroid = {
		["x"] = pcentroid.x or 0,
		["y"] = pcentroid.y or 0,
		["z"] = pcentroid.z or 0,
	}
	centroid.x = (x + (n * pcentroid.x))/n1
	centroid.y = (y + (n * pcentroid.y))/n1
	centroid.z = (z + (n * pcentroid.z))/n1
	return centroid, n1
end

-- returns a value guaranteed to be between min and max, inclusive.
function utils.clamp(x, min, max)
    return math.min(math.max(x, min), max)
end

-- add a random value between +/- sigma to val and return
function utils.addstddev(val, sigma)
    return val + math.random(-sigma, sigma)
end

utils.posfmt = {
	["DD"]   = 1,
	["DDM"]  = 2,
	["DMS"]  = 3,
	["MGRS"] = 4,
}

function utils.LLtostring(lat, long, precision, fmt)
	-- reduce the accuracy of the position to the precision specified
	lat  = tonumber(string.format("%0"..(3+precision).."."..precision.."f",
		lat))
	long = tonumber(string.format("%0"..(3+precision).."."..precision.."f",
		long))

	local northing = "N"
	local easting  = "E"
	local degsym   = '°'

	if fmt == utils.posfmt.DDM then
		if precision > 1 then
			precision = precision - 1
		else
			precision = 0
		end
	elseif fmt == utils.posfmt.DMS then
		if precision > 2 then
			precision = precision - 2
		else
			precision = 0
		end
	end

	local width  = 3 + precision
	local fmtstr = "%0"..width

	if precision == 0 then
		fmtstr = fmtstr.."d"
	else
		fmtstr = fmtstr.."."..precision.."f"
	end

	if lat < 0 then
		northing = "S"
	end

	if long < 0 then
		easting = "W"
	end

	lat  = math.abs(lat)
	long = math.abs(long)

	if fmt == utils.posfmt.DD then
		return string.format(fmtstr..degsym, lat)..northing..
			" "..
			string.format(fmtstr..degsym, long)..easting
	end

	local latdeg   = math.floor(lat)
	local latmind  = (lat - latdeg)*60
	local longdeg  = math.floor(long)
	local longmind = (long - longdeg)*60

	if fmt == utils.posfmt.DDM then
		return string.format("%02d"..degsym..fmtstr.."'", latdeg, latmind)..
			northing..
			" "..
			string.format("%03d"..degsym..fmtstr.."'", longdeg, longmind)..
			easting
	end

	local latmin   = math.floor(latmind)
	local latsecd  = (latmind - latmin)*60
	local longmin  = math.floor(longmind)
	local longsecd = (longmind - longmin)*60

	return string.format("%02d"..degsym.."%02d'"..fmtstr.."\"",
			latdeg, latmin, latsecd)..
		northing..
		" "..
		string.format("%03d"..degsym.."%02d'"..fmtstr.."\"",
			longdeg, longmin, longsecd)..
		easting
end

function utils.MGRStostring(mgrs, precision)
	local str = mgrs.UTMZone .. " " .. mgrs.MGRSDigraph

	if precision == 0 then
		return str
	end

	local divisor = 10^(5-precision)
	local fmtstr  = "%0"..precision.."d"
	return str .. string.format(fmtstr, (mgrs.Easting/divisor)) ..
		string.format(fmtstr, (mgrs.Northing/divisor))
end

function utils.degrade_position(position, precision)
	local lat, long = coord.LOtoLL(position)
	lat  = tonumber(string.format("%0"..(3+precision).."."..precision.."f",
		lat))
	long = tonumber(string.format("%0"..(3+precision).."."..precision.."f",
		long))
	return coord.LLtoLO(lat, long, 0)
end

function utils.fmtposition(position, precision, fmt)
	precision = math.floor(precision)
	assert(precision >= 0 and precision <= 5,
		"value error: precision range [0,5]")
	local lat, long = coord.LOtoLL(position)

	if fmt == utils.posfmt.MGRS then
		return utils.MGRStostring(coord.LLtoMGRS(lat, long),
			precision)
	end

	return utils.LLtostring(lat, long, precision, fmt)
end

function utils.trimTypeName(typename)
	return string.match(typename, "[^.]-$")
end

utils.buildevent = {}
function utils.buildevent.dead(obj)
	check.table(obj)
	local event = {}
	event.id = enum.event.DCT_EVENT_DEAD
	event.initiator = obj
	return event
end

function utils.buildevent.hit(asset, weapon)
	check.table(asset)
	check.table(weapon)
	local event = {}
	event.id = enum.event.DCT_EVENT_HIT
	event.initiator = asset
	event.weapon = weapon
	return event
end

function utils.printTabular(out_table, total_width, delimiter, border, offset) 
	--Outputs a string that is formated all pretty and tabular that can be outputed to the DCS console
	--Eg. 100-----------200---------String---------D <--- each string will be started at the same character position, so when printed consecutively it will be tabular
	--out table is a table with the strings to be printed as keys 
	--out table = { "string","number", "blah","bleep bloop" }
	--width is the max width
	--col space is the column spacing
	--offset allows one to specify where exactly the "first" column starts and will squeeze the columns in to accomodate
	--so one can have borders:
	--   ==INFO       INFO       INFO==
	--   ==
	
	-- N.B: I haven't really tested different values of offset
	-- This thing is held together by glue, and can break very easily
	
	if(delimiter == nil)then 
		delimiter = " "
	end
	
	if(offset == nil and border == nil) then
		offset = 0
	elseif(offset == nil and border) then
		offset = 2;
	end
	
	assert((type(out_table) == "table" or type(out_table) == "string") and total_width ~= nil, "invalid type - out table input, or total width not specified")
			
	env.info("------ inside printTabular --------------", 30)
	
	if(border and offset) then
		env.info("------ AAAA --------------", 30)
		linestring =  border..string.rep(delimiter, total_width-2)..border
		
	else
	
		env.info("------ CCCC --------------", 30)
		linestring = string.rep(delimiter, total_width)
		
	end
	
	env.info(linestring, 30)
	env.info("num outtable" .. #out_table, 30)
	
	if(type(out_table) == "string") then
		
		local col_width = math.floor((total_width/2))
		local start_pos = col_width-(math.floor(string.len(out_table)/2))   ----- if only 1 item, center it
		
		if(offset) then
			local start_pos = start_pos+offset
		end
		
		return utils.stringInsert(linestring, out_table, start_pos)		
		
		
	elseif(type(out_table) == "table") then		
		
		if(offset) then		
			start_pos = offset			
			env.info("DDDDDDDDD", 30)
		else		
			env.info("EEEEEEEEE", 30)
			offset = 0
			start_pos = 0
		end

		local col_width = math.floor((total_width/(#out_table)-1))-offset
		
		local col_ind = 1 -- starting position
		
	
		for k,v in pairs(out_table) do		
			env.info("------ inside for -------------- Start Pos: "..start_pos, 30)
			env.info("------ inside for -------------- Val: "..tostring(v), 30)
			env.info("------ inside for -------------- col_width: "..col_width, 30)
			linestring = utils.stringInsert(linestring, tostring(v), start_pos)		
			env.info("back in printTabular"..linestring, 30)
			col_ind = col_ind + 1
			start_pos = start_pos+col_width
		
		end
	
		return linestring
	end
			
	
	
end


-- inserts and overwrites string "ins" into string s at location loc without changing length.
-- thanks Grimes/MrSkortch
function utils.stringInsert(s, ins, loc) -- WHY DO YOU HAVE TO MESS WITH THE FORMATTING? DAMN YOU. DAMN YOU ALL TO HELL!
        --net.log('insert')
        --net.log(s)
        --net.log(ins)
		
		env.info("------ inside stringInsert --------------", 30)		
		env.info("s".. s, 30)		
		env.info("ins".. ins, 30)		
		env.info("loc" .. loc, 30)
		
        local sBefore
        if loc > 1 then
            sBefore = s:sub(1, loc-1)
        else
            sBefore = ''
        end
        local sAfter
        if (loc + ins:len() + 1) <= s:len() then
            sAfter = s:sub(loc + ins:len() + 1)
            
        else
            sAfter = ''
        end
        --net.log(table.concat({sBefore, ins, sAfter}))
		env.info("sBefore" .. sBefore, 30)
		env.info("ins" .. ins, 30)
		env.info("sAfter" .. sAfter, 30)
		env.info("returning", 30)
		env.info(sBefore .. ins .. sAfter, 30)
		
        return (sBefore .. ins .. sAfter)
end

function utils.buildevent.operational(base, state)
	check.table(base)
	check.bool(state)
	local event = {}
	event.id = enum.event.DCT_EVENT_OPERATIONAL
	event.initiator = base
	event.state = state
	return event
end

function utils.buildevent.impact(wpn)
	check.table(wpn)
	local event = {}
	event.id = enum.event.DCT_EVENT_IMPACT
	event.initiator = wpn
	event.point = wpn:getImpactPoint()
	return event
end

return utils
