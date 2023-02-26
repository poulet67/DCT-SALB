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
	
		if self.regions[WM_region.name] then -- already defined
			
			Logger:debug("=> in mergetables")
			utils.mergetables(self.region_table[WM_region.name], WM_region)
			
		else
		
			local r = Region(nil, WM_region)
			Logger:debug("=> returned:"..WM_region.name)
			
			if(WM_region.type ~= "OOB") then
				
				self:checkAirbases(r)
				--
			end
			
			self.regions[r.name] = r			
			self.mapped_regions[r.name] = true
			
			human.updateRegionBorders(self.regions[r.name])			
						
		end
	
	end
	
	Logger:debug("=> regions loaded!")
	utils.tprint(r)
end

function RegionManager:checkAirbases(rgn)

	for __, side in pairs(coalition.side) do
	
		local AB_tbl = coalition.getAirbases(side) 
		
		for i = 1, #AB_tbl do
		
		   local AB_Obj = AB_tbl[i]
		   local pos = AB_Obj:getPoint()
		   
			-- TODO: check pos x, y values, could be reversed		
			
		   if rgn:isInside(pos) then --if this airbase is inside the region
		   
			Logger:debug("=> adding airbase: "..AB_Obj:getName().." to region: "..rgn.name)
			self:add_airbase(AB_Obj, rgn)
		   
		   end
		   
		end
	end
	
	
end

function RegionManager:add_airbase(AB_Obj, region)
	Logger:debug("=> Add airbase: ")
	
	local mgr = self.theater:getAssetMgr()
	
	Logger:debug("=> blah ")
	
	local AB_Tpl = {
		["objtype"] = "AIRBASE", --enum.assetType["AIRBASE"]
		["subordinates"] = {},
	}
	
   
   Logger:debug("var declared")	
   
   
   Logger:debug("=> blah ")
   AB_Tpl.name = AB_Obj:getName()
   Logger:debug("=> blah ")
   AB_Tpl.id = AB_Obj:getID()
   Logger:debug("=> blah ")
   AB_Tpl.location = AB_Obj:getPoint()
   Logger:debug("=> blah ")
   AB_Tpl.coalition = AB_Obj:getCoalition()	   
   
   Logger:debug("creating template")
   tpl = Template(AB_Tpl)
   Logger:debug("Template created")
   AB_asset = mgr:factory(tpl.objtype)(tpl, region)
   Logger:debug("Asset created")
   mgr:add(AB_asset)   
   Logger:debug("Asset added")
   AB_asset:generate(region)
   AB_asset:spawn() --kind of weird to "spawn" an airbase, but whatever
   
   Logger:debug("adding to region")
   base_tbl = {[AB_asset.name] = true}
   
   table.insert(region.bases, base_tbl)

   Logger:debug("done")
   
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