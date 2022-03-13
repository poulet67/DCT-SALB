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

local defaultwaypoint = {

	["alt"] = 1000,
	["action"] = "Turning Point",
	["alt_type"] = "BARO",
	["speed"] = 138.88888888889,
	["task"] = 
	{
		["id"] = "ComboTask",
		["params"] = 
		{
			["tasks"] = 
			{
			}, -- end of ["tasks"]
		}, -- end of ["params"]
	}, -- end of ["task"]
	["type"] = "Turning Point",
	["ETA"] = 0,
	["ETA_locked"] = false,
	["y"] = 0,
	["x"] = 0,
	["formation_template"] = "",
	["speed_locked"] = true,
                                        
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
	return (s:gsub('(%b%%)', function(w) return tab[w:sub(2,-2)] or w end)) -- looks for %STRING% (string is in table tab["STRING"] in string s (not confusing at all) 
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

function utils.getHeading(velocity_vector)

	local heading = math.deg(math.atan2(velocity_vector.z, velocity_vector.x))
	
	env.info("HEADING: "..heading)
	
	if heading < 0 then
		heading = heading + 360
	end
  
	return heading
end

function utils.getAirspeed(velocity_vector)

	sum = velocity_vector.x^2 + velocity_vector.y^2 + velocity_vector.z^2
	value = math.sqrt(sum)
	
	env.info("AIRSPEED: "..value)
  
	return value
end



function utils.convertSpeed(value, from, to)

	local SpeedConversionTable = {

		["ms"] = {

		["kt"] = 1.94384,
		["kn"] = 1.94384,
		["kph"] = 3.6,
		},

		["kph"] = {

		["kt"] = 0.539957,
		["kn"] = 0.539957,
		["ms"] = 0.277778,
		},

		["kt"] = {

		["kph"] = 1.852,
		["ms"] = 0.514444,
		},		
		["kn"] = {

		["kph"] = 1.852,
		["ms"] = 0.514444,
		},

	}
	
	
	
	if SpeedConversionTable[from] and SpeedConversionTable[from][to] then		
		
		factor = SpeedConversionTable[from][to]
		return value*factor
				
	else 
	
		return nil
	
	end

end

function utils.convertDistance(value, from, to)

	local DistanceConversionTable = {

		["m"] = {
			["ft"] = 3.28084,
			["nm"] = 0.000539957,
			["km"] = 0.001,
		},

		["ft"] = {
			["m"] = 0.3048,
			["nm"] = 0.000164579,
			["km"] = 0.0003048,
		},

		["km"] = {
			["m"] = 1000,
			["ft"] = 3280.84,
			["nm"] = 0.539957,
		},

		["nm"] = {
			["km"] = 0.0003048,
			["m"] = 1000,
			["ft"] = 6076.12,
		}
	}
		
	if DistanceConversionTable[from] and DistanceConversionTable[from][to] then

		factor = DistanceConversionTable[from][to]
		
		return value*factor
		
	else 
	
		return nil
	
	end
	
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
			
	--env.info("------ inside printTabular --------------", 30)
	
	if(border and offset) then
		--env.info("------ AAAA --------------", 30)
		linestring =  border..string.rep(delimiter, total_width-2)..border
		
	else
	
		--env.info("------ CCCC --------------", 30)
		linestring = string.rep(delimiter, total_width)
		
	end
	
	--env.info(linestring, 30)
	--env.info("num outtable" .. #out_table, 30)
	
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
			--env.info("DDDDDDDDD", 30)
		else		
			--env.info("EEEEEEEEE", 30)
			offset = 0
			start_pos = 0
		end

		local col_width = math.floor((total_width/(#out_table)-1))-offset
		
		local col_ind = 1 -- starting position
		
	
		for k,v in pairs(out_table) do		
			--env.info("------ inside for -------------- Start Pos: "..start_pos, 30)
			--env.info("------ inside for -------------- Val: "..tostring(v), 30)
			--env.info("------ inside for -------------- col_width: "..col_width, 30)
			linestring = utils.stringInsert(linestring, tostring(v), start_pos)		
			--env.info("back in printTabular"..linestring, 30)
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
		
		--env.info("------ inside stringInsert --------------", 30)		
		--env.info("s".. s, 30)		
		--env.info("ins".. ins, 30)		
		--env.info("loc" .. loc, 30)
		
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
		--env.info("sBefore" .. sBefore, 30)
		--env.info("ins" .. ins, 30)
		--env.info("sAfter" .. sAfter, 30)
		--env.info("returning", 30)
		--env.info(sBefore .. ins .. sAfter, 30)
		
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

function utils.getNearestAirbaseId(fromPoint, side) --Gets the closest airbase to a set of x y z coordinates	
	
	local AB_table = coalition.getAirbases(side)
	
	local lowestValue = math.huge

	for i = 1, #AB_table do		
		ABpoint = Airbase.getPoint(AB_table[i])
		
		--trigger.action.outText("\nXcur: "..x_current.."\nYcur:"..y_current.."\nZcur: "..x_current.."\nYcur:".., 120)
	
		diffx = fromPoint.x - ABpoint.x
		diffy = fromPoint.y - ABpoint.y
		diffz = fromPoint.z - ABpoint.z
		
		--need to clear out any "helipad only" airbases, like destroyers/CC/etc	
		
		env.info(Airbase.getName(AB_table[index]))		
		
		if(Airbase:hasAttribute("Aircraft Carrier") or Airbase:hasAttribute("Airfields")) then -- aircraft carriers and airfields only
		-- N.B: This will be much more efficient if I write every airbase as a DCT object.
		
			env.info("inside")
			env.info(Airbase.getName(AB_table[index]))		
			mag = diffx^2 + diffy^2 + diffz^2 -- don't even need to do sqrt
		
			if(mag < lowestValue) then
			
				lowestValue = mag
				index = i
						
			end		
			
		end
		
	end
	
	AB_ID = Airbase.getID(AB_table[index])
	
	env.info("AIRBASE")
	env.info(index)
	env.info(AB_ID)
	env.info(Airbase.getName(AB_table[index]))
	
	return AB_ID
	
end

function utils.getNearestAirbase(fromPoint, side) --Gets the closest airbase to a set of x y z coordinates	
	
	local AB_table = coalition.getAirbases(side)
	
	local lowestValue = math.huge

	for i = 1, #AB_table do		
		AB = AB_table[i]
		ABpoint = Airbase.getPoint(AB)
		
		--trigger.action.outText("\nXcur: "..x_current.."\nYcur:"..y_current.."\nZcur: "..x_current.."\nYcur:".., 120)
	
		diffx = fromPoint.x - ABpoint.x
		diffy = fromPoint.y - ABpoint.y
		diffz = fromPoint.z - ABpoint.z
		
		--need to clear out any "helipad only" airbases, like destroyers/CC/etc	
		
		env.info(Airbase.getName(AB))	
		env.info(Airbase.getName(AB))		
		
		if(AB:hasAttribute("AircraftCarrier") or AB:hasAttribute("Airfields")) then -- aircraft carriers and airfields only
		-- N.B: This will be much more efficient if I write every airbase as a DCT object.
		
			env.info("inside")
			env.info(AB:getName())		
			mag = diffx^2 + diffy^2 + diffz^2 -- don't even need to do sqrt
		
			if(mag < lowestValue) then
			
				lowestValue = mag
				index = i
						
			end		
			
		end
		
	end
	
	AB = AB_table[index]
	
	AB_ID = AB:getID()
	
	env.info("AIRBASE")
	env.info(index)
	env.info(AB_ID)
	env.info(AB:getName())
	
	return AB
	
end

function utils.getNearestHelipadId(fromPoint, side) --Gets the closest Helipad to a set of x y z coordinates	

	
end

function utils.getAirbaseIdFromString(AB_String, side) --Gets the closest airbase to a set of x y z coordinates
	
	--[[
	local AB_table = coalition.getAirbases(side)
	
	local lowestValue = math.huge

	for i = 1, #AB_table do		
		ABpoint = Airbase.getPoint(AB_table[i])
		
		--trigger.action.outText("\nXcur: "..x_current.."\nYcur:"..y_current.."\nZcur: "..x_current.."\nYcur:".., 120)
	
		diffx = fromPoint.x - ABpoint.x
		diffy = fromPoint.y - ABpoint.y
		diffz = fromPoint.z - ABpoint.z
		
		mag = diffx^2 + diffy^2 + diffz^2 -- don't even need to do sqrt
		
		if(mag < lowestValue) then
			
			lowestValue = mag
			index = i
						
		end		

	end
	
	AB_ID = Airbase.getID(AB_table[index])
	
	env.info("AIRBASE")
	env.info(index)
	env.info(AB_ID)
	env.info(Airbase.getName(AB_table[index]))
	
	return AB_ID
	]]--
end


-- Below functions have been taken from MIST: Mission Scripting Tools
--------------------------------------------------------------------------
--[[


888b     d888 8888888 .d8888b. 88888888888 
8888b   d8888   888  d88P  Y88b    888     
88888b.d88888   888  Y88b.         888     
888Y88888P888   888   "Y888b.      888     
888 Y888P 888   888      "Y88b.    888     
888  Y8P  888   888        "888    888     
888   "   888   888  Y88b  d88P    888     
888       888 8888888 "Y8888P"     888     
                                           
--
--
-- see:
-- https://github.com/mrSkortch/MissionScriptingTools
-- thanks Grimes/MrSkortch
]]

utils.ground = {}
utils.fixedWing = {}
utils.heli = {}

function utils.ground.buildWP(point, overRideForm, overRideSpeed)

	local wp = {}
	wp.x = point.x

	if point.z then
		wp.y = point.z
	else
		wp.y = point.y
	end
	local form, speed

	if point.speed and not overRideSpeed then
		wp.speed = point.speed
	elseif type(overRideSpeed) == 'number' then
		wp.speed = overRideSpeed
	else
		wp.speed = mist.utils.kmphToMps(20)
	end

	if point.form and not overRideForm then
		form = point.form
	else
		form = overRideForm
	end

	if not form then
		wp.action = 'Cone'
	else
		form = string.lower(form)
		if form == 'off_road' or form == 'off road' then
			wp.action = 'Off Road'
		elseif form == 'on_road' or form == 'on road' then
			wp.action = 'On Road'
		elseif form == 'rank' or form == 'line_abrest' or form == 'line abrest' or form == 'lineabrest'then
			wp.action = 'Rank'
		elseif form == 'cone' then
			wp.action = 'Cone'
		elseif form == 'diamond' then
			wp.action = 'Diamond'
		elseif form == 'vee' then
			wp.action = 'Vee'
		elseif form == 'echelon_left' or form == 'echelon left' or form == 'echelonl' then
			wp.action = 'EchelonL'
		elseif form == 'echelon_right' or form == 'echelon right' or form == 'echelonr' then
			wp.action = 'EchelonR'
		else
			wp.action = 'Cone' -- if nothing matched
		end
	end

	wp.type = 'Turning Point'

	return wp

end

function utils.fixedWing.buildWP(point, side, WPtype, speed, alt, altType)

	local wp = {}
	wp.x = point.x

	if point.z then
		wp.y = point.z
	else
		wp.y = point.y
	end

	if alt and type(alt) == 'number' then
		wp.alt = alt
	else
		wp.alt = 2000
	end

	if altType then
		altType = string.lower(altType)
		if altType == 'radio' or altType == 'agl' then
			wp.alt_type = 'RADIO'
		elseif altType == 'baro' or altType == 'asl' then
			wp.alt_type = 'BARO'
		end
	else
		wp.alt_type = 'RADIO'
	end

	if point.speed then
		speed = point.speed
	end

	if point.type then
		WPtype = point.type
	end

	if not speed then
		wp.speed = mist.utils.kmphToMps(400)
	else
		wp.speed = speed
	end

	if not WPtype then
		wp.action =	'Turning Point'
	else
		WPtype = string.lower(WPtype)
		if WPtype == 'flyover' or WPtype == 'fly over' or WPtype == 'fly_over' then
			wp.action =	'Fly Over Point'
			wp.type = 'Turning Point'
		elseif WPtype == 'turningpoint' or WPtype == 'turning point' or WPtype == 'turning_point' then
			wp.action =	'Turning Point'
			wp.type = 'Turning Point'
		elseif WPtype == 'takeoff' or WPtype == 'from ramp' or WPtype == 'fromramp' then
			wp.action =	'From Runway'
			wp.type = 'TakeOff'
			nearest_AB = utils.getNearestAirbase(point, side)
			
			if(nearest_AB:hasAttribute("AircraftCarrier")) then
				
				wp.linkUnit = Airbase.getID(nearest_AB)
				wp.helipadId = Airbase.getID(nearest_AB)
				
			else
			
				wp.airdromeId = Airbase.getID(nearest_AB)
			
			end
			
			-- -- need to come up with a good DCT way to find the nearest friendly airdrome and ID	
						
		elseif WPtype == 'orbit' then
			wp.action =	'Turning Point'
			wp.type = 'Turning Point'					
			wp.task =   {
							["id"] = "ComboTask",
							["params"] = 
							{
								["tasks"] = 
								{
									[1] = 
									{
										["number"] = 1,
										["auto"] = false,
										["id"] = "Orbit",
										["enabled"] = true,
										["params"] = 
										{
											["altitude"] = alt,
											["pattern"] = "Circle",
											["speed"] = speed,
										}, -- end of ["params"]
									}, -- end of [1]
								}, -- end of ["tasks"]
							}, -- end of ["params"]
						} -- end of ["task"]
						
		else
			wp.action = 'Turning Point'
			wp.type = 'Turning Point'
		end
	end

	return wp										
										
end

function utils.heli.buildWP(point, WPtype, speed, alt, altType)

	local wp = {}
	wp.x = point.x

	if point.z then
		wp.y = point.z
	else
		wp.y = point.y
	end

	if alt and type(alt) == 'number' then
		wp.alt = alt
	else
		wp.alt = 500
	end

	if altType then
		altType = string.lower(altType)
		if altType == 'radio' or altType == 'agl' then
			wp.alt_type = 'RADIO'
		elseif altType == 'baro' or altType == 'asl' then
			wp.alt_type = 'BARO'
		end
	else
		wp.alt_type = 'RADIO'
	end

	if point.speed then
		speed = point.speed
	end

	if point.type then
		WPtype = point.type
	end

	if not speed then
		wp.speed = mist.utils.kmphToMps(200)
	else
		wp.speed = speed
	end

	if not WPtype then
		wp.action =	'Turning Point'
	else
		WPtype = string.lower(WPtype)
		if WPtype == 'flyover' or WPtype == 'fly over' or WPtype == 'fly_over' then
			wp.action =	'Fly Over Point'
		elseif WPtype == 'turningpoint' or WPtype == 'turning point' or WPtype == 'turning_point' then
			wp.action = 'Turning Point'
		else
			wp.action =	'Turning Point'
		end
	end

	wp.type = 'Turning Point'
	return wp
end

function utils.fixedWing.defaultMissionTask()

return {
 
  ["id"] = 'Mission', 
  ["params"] = { 
	["airborne"] = true,
	["route"] = { 
	  ["points"] = { 
		[1] = { 
		  ["type"] = {}, 
		  ["airdromeId"] = {},
		  ["timeReFuAr"] = {},  
		  ["helipadId"] = {}, 
		  ["linkUnit"] = {},
		  ["action"] = {}, 
		  ["x"] = {}, 
		  ["y"] = {}, 
		  ["alt"] = {}, 
		  ["alt_type"] = {}, 
		  ["speed"] = {}, 
		  ["speed_locked"] = {}, 
		  ["ETA"] = {}, 
		  ["ETA_locked"] = {}, 
		  ["name"] = {}, 
		  ["task"] = {}, 
		}
	  } 
	}, 
  } 
}
	

end


														
function utils.AddTask(Table, Task)

	table.insert(Table.params.tasks, Task)

end
														
function utils.fixedWing.DefaultTask(CommandUnitType)

	
	if(enum.commandUnitTypes[CommandUnitType] == enum.commandUnitTypes["AWACS"]) then

		return {	                                   
		
			["id"] = "ComboTask",
			["params"] = 
			{
				["tasks"] =
				{				
					[1] = 
					{
						["number"] = 1,
						["auto"] = true,
						["id"] = "AWACS",
						["enabled"] = true,
						["params"] = 
						{
						}, -- end of ["params"]
					}, -- end of [1]			
					
				}
			}
		}

	elseif(enum.commandUnitTypes[CommandUnitType] == enum.commandUnitTypes["TANKER"]) then
	
		return {
			["id"] = "ComboTask",
			["params"] = 
			{
				["tasks"] =
				{			
				 [1] = 
					{
						["number"] = 1,
						["auto"] = true,
						["id"] = "Tanker",
						["enabled"] = true,
						["params"] = 
						{
						}, -- end of ["params"]
					}, -- end of [1]
				}
			}
		}
	elseif(enum.commandUnitTypes[CommandUnitType] == enum.commandUnitTypes["CAP"]) then
	
		return {
			["id"] = "ComboTask",
			["params"] = 
			{
				["tasks"] =
				{						
					[1] = 
						{
							["number"] = 1,
							["key"] = "CAP",
							["id"] = "EngageTargets",
							["enabled"] = true,
							["auto"] = true,
							["params"] = 
							{
								["targetTypes"] = 
								{
									[1] = "Air",
								}, -- end of ["targetTypes"]
								["priority"] = 0,
							}, -- end of ["params"]
						}, -- end of [1]
				}
			}			
		}
		
	elseif(enum.commandUnitTypes[CommandUnitType] == enum.commandUnitTypes["SEAD"]) then
	
		return {
			["id"] = "ComboTask",
			["params"] = 
			{
				["tasks"] =
				{		
					[1] = 
					{
						["number"] = 1,
						["key"] = "SEAD",
						["id"] = "EngageTargets",
						["enabled"] = true,
						["auto"] = true,
						["params"] = 
						{
							["targetTypes"] = 
							{
								[1] = "Air Defence",
							}, -- end of ["targetTypes"]
							["priority"] = 0,
						}, -- end of ["params"]
					}, -- end of [1]
				}		
			}
		}
	elseif(enum.commandUnitTypes[CommandUnitType] == enum.commandUnitTypes["CAS"]) then
	
		return {
			["id"] = "ComboTask",
			["params"] = 
					{
					
					["tasks"] =
					{		
						
						[1] = 
						{
							["number"] = 1,
							["key"] = "CAS",
							["id"] = "EngageTargets",
							["enabled"] = true,
							["auto"] = true,
							["params"] = 
							{
								["targetTypes"] = 
								{
									[1] = "Helicopters",
									[2] = "Ground Units",
									[3] = "Light armed ships",
								}, -- end of ["targetTypes"]
								["priority"] = 0,
							}, -- end of ["params"]
						}, -- end of [1]
						
					}
					
				}
			}
	elseif(enum.commandUnitTypes[CommandUnitType] == enum.commandUnitTypes["ANTISHIP"]) then
	
		return {
			["id"] = "ComboTask",
			["params"] = 
			{
				["tasks"] =
				{
					
					[1] = 
					{
						["number"] = 1,
						["key"] = "AntiShip",
						["id"] = "EngageTargets",
						["enabled"] = true,
						["auto"] = true,
						["params"] = 
						{
							["targetTypes"] = 
							{
								[1] = "Ships",
							}, -- end of ["targetTypes"]
							["priority"] = 0,
						}, -- end of ["params"]
					}, -- end of [1]
				}
			}			
		}
	end
	
end


function utils.fixedWing.OrbitTask()
	return	
			{
				["number"] = {},
				["auto"] = false,
				["id"] = "Orbit",
				["enabled"] = true,
				["params"] = 
				{
					["altitude"] = {},
					["pattern"] = "Circle",
					["speed"] = {},
				}, -- end of ["params"]
			}
			


end			
										
function utils.fixedWing.RacetrackTask(altitude, speed)
	return	
			{
				["number"] = {},
				["auto"] = false,
				["id"] = "Orbit",
				["enabled"] = true,
				["params"] = 
				{
					["altitude"] = altitude,
					["pattern"] = "Race-Track",
					["speed"] = speed,
				}, -- end of ["params"]
			}
			
end				
		
			
function utils.fixedWing.EmptyTask()
	return	
		{			
			["id"] = "ComboTask",
			["params"] = 
			{
				["tasks"] =
				{
				}
			}			
		}
			
end			
										
	
return utils
