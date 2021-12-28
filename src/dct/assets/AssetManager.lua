--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Provides functions to define and manage Assets.
--]]

local checklib = require("libs.check")
local utils    = require("libs.utils")
local enum     = require("dct.enum")
local dctutils = require("dct.utils")
local Command  = require("dct.Command")
local Logger   = dct.Logger.getByName("AssetManager")
local Observable = require("dct.libs.Observable")

local assetpaths = {
	"dct.assets.MobileAsset",
	"dct.assets.Airbase",
	"dct.assets.Airspace",
	"dct.assets.Player",
	"dct.assets.StaticAsset",
}

local AssetManager = require("libs.namedclass")("AssetManager", Observable)
function AssetManager:__init(theater)
	Observable.__init(self,
		require("dct.libs.Logger").getByName("AssetManager"))
	self.updaterate = 120
	-- The master list of assets, regardless of side, indexed by name.
	-- Means Asset names must be globally unique.
	self._assetset = {}

	-- The per side lists to maintain "short-cuts" to assets that
	-- belong to a given side and are alive or dead.
	-- These lists are simply asset names as keys with values of
	-- asset type. To get the actual asset object we need to lookup
	-- the name in a master asset list.
	self._sideassets = {
		[coalition.side.NEUTRAL] = {
			["assets"] = {},
		},
		[coalition.side.RED]     = {
			["assets"] = {},
		},
		[coalition.side.BLUE]    = {
			["assets"] = {},
		},
	}

	-- keeps track of static/unit/group names to asset objects,
	-- remember all spawned Asset classes will need to register the names
	-- of their DCS objects with 'something', this will be the something.
	self._object2asset = {}
	self._spawnq = {}
	self._factoryclasses = {}
	for _, path in ipairs(assetpaths) do
		local obj = require(path)
		for _, assettype in ipairs(obj.assettypes()) do
			assert(self._factoryclasses[assettype] == nil,
				"object already registered for type: "..
				utils.getkey(enum.assetType, assettype))
			self._factoryclasses[assettype] = obj
		end
	end

	theater:addObserver(self.onDCSEvent, self, "AssetManager.onDCSEvent")
	theater:queueCommand(self.updaterate,
		Command(self.__clsname..".update", self.update, self))
end

function AssetManager:factory(assettype)
	local asset = self._factoryclasses[assettype]
	assert(asset, "unsupported asset type: "..
		utils.getkey(enum.assetType, assettype))
	return asset
end

function AssetManager:remove(asset)
	if asset == nil then
		return
	end

	self._logger:debug("Removing asset: %s", asset.name)
	asset:removeObserver(self)
	self._assetset[asset.name] = nil

	-- remove asset name from per-side asset list
	self._sideassets[asset.owner].assets[asset.name] = nil

	-- remove asset object names from name list
	for _, objname in pairs(asset:getObjectNames()) do
		self._object2asset[objname] = nil
	end
end

local CapturableAsset = {
	[enum.assetType.AIRSPACE] = true,
	[enum.assetType.AIRBASE]  = true,
}
function AssetManager:add(asset)
	assert(asset ~= nil, "value error: asset object must be provided")
	assert(self._assetset[asset.name] == nil, "asset name ('"..
		asset.name.."') already exists")

	if asset:isDead() then
		self._logger:debug("AssetManager:add - not adding dead asset: %s", asset.name)

		return
	end
	self._logger:debug("AssetManager: add ", asset.name)
	self._assetset[asset.name] = asset
	asset:addObserver(self.onDCSEvent, self, "AssetManager.onDCSEvent")

	-- add asset to appropriate side lists
	if asset.type == enum.assetType.AIRSPACE then
		for _, side in pairs(coalition.side) do
			self._sideassets[side].assets[asset.name] = asset.type
		end
	else
		self._sideassets[asset.owner].assets[asset.name] = asset.type
	end

	Logger:debug("Adding object names for '%s'", asset.name)
	-- read Asset's object names and setup object to asset mapping
	-- to be used in handling DCS events and other uses
	for _, objname in pairs(asset:getObjectNames()) do
		self._logger:debug("    + %s", objname)
		self._object2asset[objname] = asset.name
	end
end

function AssetManager:getAsset(name)
	return self._assetset[name]
end


function AssetManager:iterate()
	if next(self._assetset) == nil then
		return function() end, nil, nil
	end
	return next, self._assetset, nil
end

-- dcsObjName must be one of; group, static, or airbase names
function AssetManager:getAssetByDCSObject(dcsObjName)
	local assetname = self._object2asset[dcsObjName]
	if assetname == nil then
		return nil
	end
	return self._assetset[assetname]
end
--[[
-- filterAssets - return all asset names matching `filter`
-- filter(asset)
--   returns true if the filter matches and the asset name should be kept
-- Return: a table with asset names as keys. Will always returns a table,
--   even if it is empty
--]]
function AssetManager:filterAssets(filter)
	checklib.func(filter)

	local list = {}
	for name, asset in pairs(self._assetset) do
		if filter(asset) then
			list[name] = asset
		end
	end
	return list
end


--[[
-- getTargets - returns the names of the assets conforming to the asset
--   type filter list, the caller must use AssetManager:get() to obtain
--   the actual asset object.
-- assettypelist - a list of asset types wanted to be included
-- requestingside - the coalition requesting the target list, thus
--     we need to return their enemy asset list
-- Return: return a table that lists the asset names that fit the
--    filter list requested
--]]


function AssetManager:getTargets(requestingside, assettypelist)
	local enemy = dctutils.getenemy(requestingside)
	local tgtlist = {}
	local filterlist

	-- some sides may not have enemies, return an empty target list
	-- in this case
	if enemy == false then
		return {}
	end

	if type(assettypelist) == "table" then
		filterlist = assettypelist
	elseif type(assettypelist) == "number" then
		filterlist = {}
		filterlist[assettypelist] = true
	else
		assert(false, "value error: assettypelist must be a number or table")
	end

	for tgtname, tgttype in pairs(self._sideassets[enemy].assets) do
		if filterlist[tgttype] ~= nil and
		   not self._assetset[tgtname].ignore then
			tgtlist[tgtname] = tgttype
		end
	end
	return tgtlist
end


function AssetManager:getKnownTables(requestingside)
	local enemy = dctutils.getenemy(requestingside)
	local knownlist = {}

	--Logger:debug("getKnownTables -- ")
	
	-- some sides may not have enemies, return an empty target list
	-- in this case
	if enemy == false then
		return {}
	end
	
	--Logger:debug("getKnownTables start-- ")
	
	--if(self._sideassets[enemy].assets ~= nil) then --no enemy assets
	
	for name, _ in pairs(self._sideassets[enemy].assets) do
	 
		--for lol, kek in pairs(self:getAsset(name)) do    -- Good way to see all keys of an asset
		
		--	Logger:debug("getKnownTargets -- "..lol)
			
			--if(lol == "known") then
			
			--	Logger:debug("KNOWN FOUND -- ".. tostring(kek))
			--	Logger:debug("KNOWN FOUND -- ".. name)
				
				
			--end
		
		--end
		asset = self:getAsset(name)
		if (asset.known) then
			knownlist[name] = true
			Logger:debug("getKnownTables -- known found: "..name)
			asset.known = nil -- to prevent recurrent accesses
		end
	end
	

--		Logger:debug("getKnownTargets -- nil")
		
--	
	
	--Logger:debug("getKnownTargets -- done ")
	
	return knownlist
end

function AssetManager:update()
	local deletionq = {}
	for _, asset in pairs(self._assetset) do
		if type(asset.update) == "function" then
			asset:update()
		end
		if asset:isDead() and not asset:isSpawned() then
			deletionq[asset.name] = true
		end
	end
	for name, _ in pairs(deletionq) do
		self:remove(self:getAsset(name))
	end
	return self.updaterate
end

local function handleDead(self, event)
	self._object2asset[tostring(event.initiator:getName())] = nil
end

local function handleAssetDeath(_ --[[self]], event)
	local asset = event.initiator
	
	--poulet: will change this to record losses in a loss table (for stats card at ending and theater update)
	
	--dct.Theater.singleton():getTickets():loss(asset.owner, asset.cost, false)
	
end

local handlers = {
	[world.event.S_EVENT_DEAD] = handleDead,
	[enum.event.DCT_EVENT_DEAD] = handleAssetDeath,
}

function AssetManager:doOneObject(obj, event)
	if event.id > world.event.S_EVENT_MAX then
		return
	end

	local name = tostring(obj:getName())
	if obj.className_ ~= "Airbase" and
	   obj:getCategory() == Object.Category.UNIT then
	   name = obj:getGroup():getName()
	end

	local asset = self:getAssetByDCSObject(name)
						 
	if asset == nil then
		Logger:debug("onDCSEvent - asset doesn't exist, name: %s", name)
		self._object2asset[name] = nil
		return
	end
	asset:onDCTEvent(event)
end

function AssetManager:onDCSEvent(event)
	local relevents = {
		[world.event.S_EVENT_BIRTH]           = true,
		[world.event.S_EVENT_ENGINE_STARTUP]  = true,
		[world.event.S_EVENT_ENGINE_SHUTDOWN] = true,
		[world.event.S_EVENT_TAKEOFF]         = true,
		[world.event.S_EVENT_LAND]            = true,
		[world.event.S_EVENT_CRASH]           = true,
		[world.event.S_EVENT_KILL]            = true,
		[world.event.S_EVENT_PILOT_DEAD]      = true,
		[world.event.S_EVENT_EJECTION]        = true,
		[world.event.S_EVENT_HIT]             = true,
		[world.event.S_EVENT_DEAD]            = true,
		[world.event.S_EVENT_BASE_CAPTURED]   = true,														  
		[enum.event.DCT_EVENT_DEAD]           = true,
		--[world.event.S_EVENT_UNIT_LOST]     = true,
	}
	local objmap = {
		[world.event.S_EVENT_HIT]  = "target", -- type: Object
		[world.event.S_EVENT_KILL] = "target", -- type: Unit
		[world.event.S_EVENT_LAND] = "place", -- type: Object
		[world.event.S_EVENT_TAKEOFF] = "place", -- type: Object
		[world.event.S_EVENT_BASE_CAPTURED] = "place", -- type: Airbase	   
	}

	if not relevents[event.id] then
		self._logger:debug("onDCSEvent - not relevant event: %s", tostring(event.id))
		
		return
	end

	local objs = { event.initiator }
	if objmap[event.id] ~= nil then
		if event[objmap[event.id]] ~= nil then
			table.insert(objs, event[objmap[event.id]])
		end
	end

	for _, obj in ipairs(objs) do
		self:doOneObject(obj, event)
	end
	local handler = handlers[event.id]
	if handler ~= nil then
		handler(self, event)
	end
end

function AssetManager:marshal()
	local tbl = {
		["assets"] = {},
	}

	for name, asset in pairs(self._assetset) do
		if type(asset.marshal) == "function" and not asset:isDead() then
			tbl.assets[name] = asset:marshal()
		end
	end
	return tbl
end

function AssetManager:unmarshal(data)
	for _, assettbl in pairs(data.assets) do
		local assettype = assettbl.type
		local asset = self:factory(assettype)()
		asset:unmarshal(assettbl)
		self:add(asset)
		if asset:isSpawned() then
			self._spawnq[asset.name] = true
		end
	end

	for assetname, _ in pairs(spawnq) do
		self:getAsset(assetname):spawn(true)
	end
end

function AssetManager:postinit()
	for assetname, _ in pairs(self._spawnq) do
		self:getAsset(assetname):spawn(true)
	end
	self._spawnq = {}
end
	

function AssetManager:get_dist(point)
--returns the distance from the asset's current coordinate to the point passed in as an argument


end

function AssetManager:in_region(region)
--returns whether or not the asset is inside the region defined by the verticies
	
	isInside = false;
	
	return isInside;
	

end

return AssetManager