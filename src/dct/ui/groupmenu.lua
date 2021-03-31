--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Handles applying a F10 menu UI to player groups
--]]

--[[
-- Assumptions:
-- It is assumed each player group consists of a single player
-- aircraft due to issues with the game.
--
-- Notes:
--   Once a menu is added to a group it does not need to be added
--   again, which is why we need to track which group ids have had
--   a menu added. The reason why this cannot be done up front on
--   mission start is because the the group does not exist until at
--   least one player occupies a slot. We must add the menu upon
--   object creation.
--]]

local utils   = require("libs.utils")
local enum    = require("dct.enum")

local menu = {}
menu.ItemTypes = {
	["MENU"] = 1,
	["CMD"]  = 2,
}

menu.IDs = {
	["SCRATCHPAD"] = 1,  --"Scratch Pad"
	["INTEL"]      = 2,  --"Intel & Maps"
	["GROUNDCREW"] = 3,  --"Ground Crew"
	["MISSION"]    = 4,  --"Mission"
}

menu.TitleMap = {
	[menu.IDs.SCRATCHPAD] = "Scratch Pad",
	[menu.IDs.INTEL]      = "Intel & Maps",
	[menu.IDs.GROUNDCREW] = "Ground Crew",
	[menu.IDs.MISSION]    = "Mission",
}

menu.ItemLists = {
	[menu.IDs.SCRATCHPAD] = {
		{
			type  = menu.ItemTypes.CMD,
			title = "Display",
			path  = menu.IDs.SCRATCHPAD,
			data  = {
				type = enum.uiRequestType.SCRATCHPADGET,
			},
		}, {
			type  = menu.ItemTypes.CMD,
			title = "Set",
			path  = menu.IDs.SCRATCHPAD,
			data  = {
				type = enum.uiRequestType.SCRATCHPADSET,
			},
		},
	},
	[menu.IDs.INTEL] = {
		{
			type  = menu.ItemTypes.CMD,
			title = "Theater Status",
			path  = menu.IDs.INTEL,
			data  = {
				type = enum.uiRequestType.THEATERSTATUS,
			},
		}, {
			type  = menu.ItemTypes.CMD,
			title = "Strategic",
			path  = menu.IDs.INTEL,
			data  = {
				type = enum.uiRequestType.MAPSTRATEGIC,
			},
		}, {
			type  = menu.ItemTypes.CMD,
			title = "Air Defense",
			path  = menu.IDs.INTEL,
			data  = {
				type = enum.uiRequestType.MAPAIRDEFENSE,
			},
		}, {
			type  = menu.ItemTypes.CMD,
			title = "Target",
			path  = menu.IDs.INTEL,
			data  = {
				type = enum.uiRequestType.MAPTARGET,
			},
		}, {
			type  = menu.ItemTypes.CMD,
			title = "Clear All Marks",
			path  = menu.IDs.INTEL,
			data  = {
				type = enum.uiRequestType.MAPCLEAR,
			},
		},
	},
	[menu.IDs.GROUNDCREW] = {
		{
			type  = menu.ItemTypes.CMD,
			title = "Check Payload",
			path  = menu.IDs.INTEL,
			data  = {
				["type"] = enum.uiRequestType.CHECKPAYLOAD,
			},
		},
	},
}

menu.addmenu    = missionCommands.addSubMenuForGroup
menu.addcmd     = missionCommands.addCommandForGroup
menu.removeitem = missionCommands.removeItemForGroup

--[[
-- Accepts a table describing the menu item;
--   tbl.type  - the type of menu item, command vs. menu
--   tbl.title - title of the item
--   tbl.path  - the player menuid for well known menus the player
--               uses, the actual path will be looked up before
--               use. Can be nil.
--   tbl.callback - optional
--   tbl.ctx   - optional
--   tbl.data  - a table containing additional information for the
--               command
--   tbl.data.type  - type of player request
--   tbl.data.value - additional value needed by the request type,
--               can be nil
--]]
function menu.buildcmd(asset, cmdtbl)
	local data = utils.deepcopy(cmdtbl.data)
	data.name = asset.name
	local path = asset:getMenuPath(cmdtbl.path)
	local cb = cmdtbl.callback or asset.request
	local ctx = cmdtbl.ctx or asset

	return menu.addcmd(asset.groupId, cmdtbl.title, path, cb, ctx, data)
end

function menu.buildmenu(asset, cmdtbl)
	return menu.addmenu(asset.groupId, cmdtbl.title,
		asset:getMenuPath(cmdtbl.path))
end

function menu.createMenu(asset)
	if asset.uimenus ~= nil then
		asset._logger:debug("createMenu - group("..asset.name..
			") already had menu added")
		return
	end

	asset._logger:debug("createMenu - adding menu for group: "..
		tostring(asset.name))

	asset.uimenus = {}
	for id, _ in ipairs(menu.TitleMap) do
		asset:resetMenu(id)
		for _, item in ipairs(menu.ItemLists[id] or {}) do
			asset:addMenuItem(item)
		end
	end
	asset:setDefaultMissionItems()
end

return menu
