--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Creates a container for managing region objects.
--]]

local utils = require("libs.utils")
local dctenum = require("dct.enum")
local vector = require("dct.libs.vector")
local Marshallable = require("dct.libs.Marshallable")
local Region = require("dct.templates.Region")
local settings = dct.settings.server
local dctutils   = require("dct.utils")
local Logger = require("dct.libs.Logger").getByName("RegionManager")
local human = require("dct.ui.human")								 
local Template   = require("dct.templates.Template")

local RegionManager = require("libs.namedclass")("RegionManager", Marshallable)

function RegionManager:__init(theater)
	self.regions = {}	
	self.mapped_regions = {} --regions that show up on the F10 map
	self.theater = theater
	region_path = settings.theaterpath..utils.sep.."tables"..utils.sep.."region"..utils.sep.."region.JSON"
	self.region_table = dctutils.read_JSON_file(region_path) or {}
	
	self:loadRegions()	
	
	theater:getAssetMgr():addObserver(self.onDCTEvent, self,
		self.__clsname..".onDCTEvent")
end

function RegionManager:getRegion(name)
	return self.regions[name]
end

function RegionManager:loadRegions()
	--DCT configs
	for filename in lfs.dir(settings.theaterpath) do
		if filename ~= "." and filename ~= ".." and
			filename ~= ".git" and filename ~= "settings" and string.match(filename, "region") ~= nil then
			local fpath = settings.theaterpath..utils.sep..filename
			local fattr = lfs.attributes(fpath)			
			if fattr.mode == "directory" then
				local r = Region(fpath)
				assert(self.regions[r.name] == nil, "duplicate regions " ..	"defined for theater: " .. settings.theaterpath)
				self.regions[r.name] = r				
			end
		end
	end
	--- WM configs
	
	for _,  WM_region in pairs(self.region_table) do
		
		Logger:debug("=> loading region:" .. WM_region.name)
		
		if self.regions[WM_region.name] then -- already defined
					
			Logger:debug("=> region defined:")
			utils.tprint(self.regions[WM_region.name])
			
			Logger:debug("=> in mergetables")
		    utils.mergetables(self.regions[WM_region.name], WM_region)
			
		else
		
			utils.tprint(WM_region)
			r = Region(nil, WM_region) --not sure why, but if I make this local everything goes to hell
			--could be an old lua thing
			Logger:debug("=> returned: "..WM_region.name)
			
			
			
			if(WM_region.type ~= "OOB") then
				
				self:checkAirbases(r)
				--
			end
			
			self.regions[r.name] = r			
			self.mapped_regions[r.name] = true
			
			
			human.updateRegionBorders(r)			
						
		end
	
	end
	
	Logger:debug("=> regions loaded!")
	--utils.tprint(r)
end

function RegionManager:checkAirbases(rgn)

	for __, side in pairs(coalition.side) do
	
		Logger:debug("ring ring")
		
		local AB_tbl = coalition.getAirbases(side) 
		
		for i = 1, #AB_tbl do
		   
			Logger:debug("ding ding")
		  
			AB_Obj = AB_tbl[i]
			ABname = AB_Obj:getName()
			ABpos = AB_Obj:getPoint()
		   
					
			Logger:debug("AB Pos is:")
			utils.tprint(ABpos)
		   
			--A refresher:
			-- In DCS the Z coordinate is the 2-D "y" coordinate as used by geometry library
			
			ABpos.y = ABpos.z
		   		   
			if rgn:isInside(ABpos) then --if this airbase is inside the region
		   
				Logger:debug("-- > inside")
				utils.tprint(rgn.bases)
				
				--rgn:add_airbase(ABname)
				rgn.bases.Airbases[ABname] = true
				
				utils.tprint(rgn.bases)
				
			else -- does not exist
			
				Logger:debug("=> BING")
			
			end			
		   
		end
		   
		
	end
	
	
end

local function cost(thisrgn, otherrgn)
	if thisrgn == nil or otherrgn == nil then
		return nil
	end
	return vector.distance(vector.Vector2D(thisrgn:getPoint()),
		vector.Vector2D(otherrgn:getPoint()))
end

function RegionManager:generate()
	for _, r in pairs(self.regions) do
		r:generate()
	end
	--self:validateEdges()
end

function RegionManager:generateStagedTemplates()
	for _, r in pairs(self.regions) do
		r:generateStagedTemplates()
	end
	--self:validateEdges()
end

function RegionManager:marshal()
	local tbl = {}
	tbl.regions = {}

	for rgnname, region in pairs(self.regions) do
		tbl.regions[rgnname] = region:marshal()
	end
	return tbl
end

function RegionManager:unmarshal(data)
	if data.regions == nil then
		return
	end
	for rgnname, region in pairs(self.regions) do
		region:unmarshal(data.regions[rgnname])
	end
end

local relevants = {
	[dctenum.event.DCT_EVENT_DEAD]      = true,
	[dctenum.event.DCT_EVENT_ADD_ASSET] = true,
}
function RegionManager:onDCTEvent(event)
	if relevants[event.id] == nil then
		return
	end

	local region = self.mapped_regions[event.initiator.rgnname]

	if region then
		region:onDCTEvent(event)
		if self.borders[region.name] ~= nil then
			human.updateBorders(region, self.borders[region.name])
		end
	end
end

return RegionManager