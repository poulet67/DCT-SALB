-- RUN a mission periodically

--require("os")
--local class    = require("libs.class")
--local utils    = require("libs.utils")
--local enum     = require("dct.enum")
--local dctutils = require("dct.utils")
--local Command  = require("dct.Command")
--local theater = require("dct.Theater")
--local Commander = require("dct.ai.Commander")

--[[

local Logger = dct.Logger.getByName("periodicMission")
local Mission = require("dct.ai.Mission")
local AssetBase = require("dct.assets.AssetBase")
local Template = require("dct.templates.Template")

local function  startperiodicMission(cmdr, side, missiontype)

	Logger:debug("------ kukiric it's starting  --------------")

	local airspacetpl = Template({
		["objtype"]    = "airspace",
		["name"]       = "Dummy",
		["regionname"] = "dummy",
		["regionprio"] = 1000,
		["desc"]       = "airspace",
		["coalition"]  = coalition.side.BLUE,
		["location"]   =  { x = 18160, y = 9000, z = -11584 } ,
		["intel"] = 5,
		["spawnable"] = false,
		["latespawn"] = false,
		["public"] = false,
		["period"] = 0,
		["volume"]     = {
			["point"]  =  { x = 0, y = 0, z = 0 } ,
			["radius"] = 55560,  -- 30NM
		},
	})
	
	local dummytgttable = AssetBase(airspacetpl)
	--self:addTemplate(airspacetpl)
	dummytgttable._location = { x = 18160, y = 9000, z = -11584 }
	
	Logger:debug("------ kukiric it worked --------------")
	--env.info("RUNNING PERIODIC")
	
	--local dummytgttable = {
	--	name = "Dummy",
	--	briefing = "Dummy Briefing",
	--	cost = 10,
	--	getStatus = function(self)
	--		return 0 -- 0% complete
	--	end,
	--	getLocation = function(self)
	--		return { x = 0, y = 0, z = 0 } -- you'd probably want to get the unit you want to escort and use unit:getPoint() on it instead
	--	end,
	--	
	--	setTargeted = function(side, val)
	--	assert(type(val) == "boolean",
	--	"value error: argument must be of type bool")
	--self._targeted[side] = val
	--end
	--}
	
	dummyplantable = {}
	
	
	env.info("RUNNING PERIODIC")
	Logger:debug("------ RUNNING PERIODIC --------------")
	local packagecomms = "267.325 MHz" 
	local custombriefing = "Target AO is the marshall point, TOT = Mission Start, Target: Soviet Carrier Group at Novorossiysk"
	local mission = Mission(cmdr, missiontype, dummytgttable, dummyplantable, true, custombriefing, 1800, packagecomms, true)
	cmdr:addMission(mission)
	
	return mission:getID()
	

end 

local function  endperiodicMission(cmdr, side, id)

	Logger:debug("------ kukiric it's closing  --------------")
	
	local MyMission = cmdr:getMission(id)
	
	Logger:debug(id)	
	--Logger:debug(cmdr)
	--Logger:debug(getMission(id))
	--Logger:debug(cmdr)
	
	MyMission:forceEnd() -- bit of a hacky way to do things, but it works
	
	
	Logger:debug("------ kukiric it worked --------------")
	
end 

local functable = {
  startperiodicMission = startperiodicMission,
  endperiodicMission = endperiodicMission
}

return functable

--]]