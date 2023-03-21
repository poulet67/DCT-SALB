--	CONFIG REGION TOOL
--	How to use:
--	- If creating a new region map for the first time, use the F10 menu to select "new region"
--	- If loading, select "import region" make sure the region.JSON file in the import folder
--	  the first region in the list will automatically be selected.
--	
--	-Use map markers to enter commands and define the vertices that encompase your region
--	 map markers without any text inside will be assumed to be vertices. Enter vertices in clockwise
--	 orientation.
--
--	-Quotation marks "" specify input to be placed between quotation marks
--	-example : NAME:"Anapa"
--	
--	Commands themselves are case insenstive
--
--	Commands:
--	FILE:"" will set the file name to export or import. "region" by default
--	NAME:"" will name the region whatever is inside the quotation marks
--	COA:"" 	Specifies region coalition options: "BLUE", "RED", "NEUTRAL" (default)
--	
--	Set Region Type:
--	REG	 Sets to regular type. Regions are regular type by default
--	NAV	 Sets to naval type. Ownership is based on number of ships inside (or something)
--	OOB  Sets the region to an out of bounds type. 
--	NC 	 Sets the region as non capturable type (needed for over water regions)
--	
--	Add region features:
--	FOB:"" 	Specifies a FOB at the marker. Name in quotations must be provided
--	FARP 	Specifies a farp at point. Must be within set distance from FOB.
--	FSB 	Specifies a fire support base at point. Must be within set distance from FOB
--	OM		Specifies an off map spawn point. This will act like an airbase as far as the inventory system works.
--	SHOP:"on" or "off" Region must have an off map spawn for this. Will create a shop for this point.
--	SP:""	Specifies a strategic point at the marker. This functions the same as towns and bases. Name in quotations must be provided
--	INV: Specifies an inventory  at the given point. This will overwrite the default.
--	will spawn assets from the base inventory that can be destroyed.
	


-- Setup package path so we can require DCT utils
do
	if not lfs or not io or not require then
		local assertmsg = "DCT requires DCS mission scripting environment"..
			" to be modified, the file needing to be changed can be found"..
			" at $DCS_ROOT\\Scripts\\MissionScripting.lua. Comment out"..
			" the removal of lfs and io and the setting of 'require' to"..
			" nil."
		assert(false, assertmsg)
	end

	-- Check that DCT mod is installed
	modpath = lfs.writedir() .. "Mods\\tech\\DCT"
	if lfs.attributes(modpath) == nil then
		local errmsg = "DCT: module not installed, mission not DCT enabled"
		if dctsettings.nomodlog then
			env.error(errmsg)
		else
			assert(false, errmsg)
		end
	else
		package.path = package.path .. ";" .. modpath .. "\\lua\\?.lua;"
		
	end
end

local JSON = require("libs.JSON")
local utils = require("libs.utils")
local dctutils = require("dct.utils")
local human = require("dct.ui.human")
local geometry = require("dct.libs.geometry")
local Logger   = require("dct.libs.Logger").getByName("Config Region")

local addmenu = missionCommands.addSubMenuForGroup
local addcmd  = missionCommands.addCommandForGroup
local coalitionMap = {
	["NEUTRAL"] = coalition.side.NEUTRAL,
	["RED"] = coalition.side.RED,
	["BLUE"] = coalition.side.BLUE,
}
		
local Marks = {}	
function Marks.new()
	
	local self = {}
	self.markerindex = 10
	self.region_def = false
	self.marks_table = {}
	self.r_table = {}
	self.curr_id = nil
	self.verts_mode = false
	self.enabled = false
	self.import = false
	self.filename = "region"

	for k, v in pairs(Marks) do
		self[k] = v
	end
	return self
	
end

function Marks:modify(id, text, pos)
	
	if(self.enabled) then
		
		-- Input Parsing:
		--	CONFIG REGION TOOL

		--	Commands:
		--
		--	VERTS	Toggle on/off vertices entry mode
		-- 	Commands available in vertices entry mode:
		-- 	VERTS
		--	DEL 	Delete last vertice
		-- 	CLR     Clear all verts
		--
		--	Set Region Type:
		--	REG	 Sets to regular type. Regions are regular type by default
		--	OOB  Sets the region to an out of bounds type. 
		--	NC 	 Sets the region as non capturable type (needed for over water regions)
		--	
		--	Add region features:
		--	CLRBS 	Clears all bases of this region
		--	FARP 	Specifies a farp at point. Must be within set distance from FOB.
		--	FSB 	Specifies a fire support base at point. Must be within set distance from FOB
		--	OM		Specifies an off map spawn point. This will act like an airbase as far as the inventory system works.
		--	INV	    Specifies inventory location at the given point. This will overwrite the default.
	
		--	NAME:"" will name the region whatever is inside the quotation marks
		--	SP:""	Specifies a strategic point at the marker. This functions the same as towns and bases. Name in quotations must be provided
		--	FOB:"" 	Specifies a FOB at the marker. Name in quotations must be provided
		--	SHOP:"" Region must have an off map spawn for this. Will create a shop for this point. Name in quotations must be provided
		--	COA:"" 	Specifies region coalition options: "BLUE", "RED", "NEUTRAL" (default)
		
		
		vert = string.match(text, "^$") -- empty string
		VERTS = string.match(string.upper(text), "VERTS") -- empty string
		REG = string.match(string.upper(text), "^REG$")
		NAV = string.match(string.upper(text), "^NAV$")
		DEL = string.match(string.upper(text), "^DEL$")
		CLR = string.match(string.upper(text), "^CLR$")
		OOB = string.match(string.upper(text), "^OOB$")
		CLRBS = string.match(string.upper(text), "^CLRBS$")
		NC = string.match(string.upper(text), "^NC$")
		FARP = string.match(string.upper(text), "^FARP") 
		FSB = string.match(string.upper(text), "^FSB$")
		OM = string.match(string.upper(text), "^OM$")
		INV = string.match(string.upper(text), "^INV$")		
		
		first = string.match(text, "%a+") -- returns everything up to the :		
		second = string.match(text, "\".+\"") -- returns everything inbetween the ""
		
		if first then
			first = string.upper(first)
		end
		
		if second then 
			second = second:sub(2,second:len()-1) --removes the quotes
		end
					
		if(self.verts_mode or VERTS) then
		
			if vert and self.marks_table[#self.marks_table] ~= id then --to prevent double adding
				-- the pos vector is in x,y,z format. we need x,y (where y is actually z) format 
				pos["y"] = pos["z"]
				pos["z"] = nil
				vertice_ind = (#self.r_table[self.curr_id]["border"]["polygon"] + 1) or 1
				self.r_table[self.curr_id]["border"]["polygon"][vertice_ind] = pos
				table.insert(self.marks_table, id)
				trigger.action.outText("Current Region: #"..self.curr_id.." vertice#:"..vertice_ind.." added", 30)	
				
			elseif DEL then
				
				vertice_ind = (#self.r_table[self.curr_id]["border"]["polygon"])
				self.r_table[self.curr_id]["border"]["polygon"][vertice_ind] = nil
				
				last_id = self.marks_table[#self.marks_table]
				trigger.action.removeMark(last_id)
				
			elseif CLR then
				
				self.r_table[self.curr_id]["border"]["polygon"] = {}		
				self.r_table[self.curr_id]["border"]["triangles"] = {}				
				self:removeall()
				
			elseif(VERTS) then	
			
				self:toggle_verts_mode()
				trigger.action.removeMark(id)
				
			end
			
		else
			
			if(VERTS) then	
				self:toggle_verts_mode()
				trigger.action.removeMark(id)
				
			elseif(REG) then
				self.r_table[self.curr_id]["type"] = "regular"
							
				trigger.action.outText("Current Region: #"..self.curr_id.." type:"..self.r_table[self.curr_id]["type"], 30)			
				trigger.action.removeMark(id)

			elseif(NAV) then
				self.r_table[self.curr_id]["type"] = "naval"
							
				trigger.action.outText("Current Region: #"..self.curr_id.." type:"..self.r_table[self.curr_id]["type"], 30)			
				trigger.action.removeMark(id)
				
			elseif(OOB) then			
				self.r_table[self.curr_id]["type"] = "OOB"
							
				trigger.action.outText("Current Region: #"..self.curr_id.." type:"..self.r_table[self.curr_id]["type"], 30)			
				trigger.action.removeMark(id)	
				
			elseif(NC) then
				self.r_table[self.curr_id]["type"] = "OOB"
							
				trigger.action.outText("Current Region: #"..self.curr_id.." type:"..self.r_table[self.curr_id]["type"], 30)			
				trigger.action.removeMark(id)	
			elseif(FARP) then

				pos["y"] = pos["z"] -- map markers are X,Y,Z with Z as 2 dimensional Y axis -- all math is done as 2d
				pos["z"] = nil
								
				if(check_inside_region(self.r_table[self.curr_id], pos)) then
					local farp_name = "FARP"			
					if(string.match(string.upper(text), "NAME:")) then
						farp_name = second						
					end
					
					local farp_table = {
						["name"] = farp_name,
						["location"] = pos
						}
					table.insert(self.r_table[self.curr_id]["bases"]["FARP"], farp_table)
					trigger.action.outText("Current Region: #"..self.curr_id.." FARP ADDED!", 30)
					utils.tprint(self.r_table[self.curr_id]["bases"])
				else					
					trigger.action.outText("Current Region: #"..self.curr_id.." Not inside borders or no borders created!", 30)
				end
				self.marks_table[id] = true
				
			elseif(FSB) then					
				
				pos["y"] = pos["z"] -- map markers are X,Y,Z with Z as 2 dimensional Y axis -- all math is done as 2d
				pos["z"] = nil
								
				if(check_inside_region(self.r_table[self.curr_id], pos)) then
					local FSB_name = "FSB"			
					if(string.match(string.upper(text), "NAME:")) then
						FSB_name = second						
					end
					
					local FSB_table = {
						["name"] = FSB_name,
						["location"] = pos
						}
					table.insert(self.r_table[self.curr_id]["bases"]["FSB"], FSB_table)
					trigger.action.outText("Current Region: #"..self.curr_id.." FSB ADDED!", 30)
					utils.tprint(self.r_table[self.curr_id]["bases"])
				else					
					trigger.action.outText("Current Region: #"..self.curr_id.." Not inside borders or no borders created!", 30)
				end
				self.marks_table[id] = true
				
							
			elseif(OM) then 
				
				-- might want only 1 per region?
				
				pos["y"] = pos["z"] -- map markers are X,Y,Z with Z as 2 dimensional Y axis -- all math is done as 2d
				pos["z"] = nil
								
				if(check_inside_region(self.r_table[self.curr_id], pos)) then
					local name = "FSB"			
					if(string.match(string.upper(text), "NAME:")) then
						name = second						
					end
					
					local insert_table = {
						["name"] = name,
						["location"] = pos
						}
					table.insert(self.r_table[self.curr_id]["bases"]["OM"], insert_table)
					trigger.action.outText("Current Region: #"..self.curr_id.." OFF-MAP ADDED!", 30)
					utils.tprint(self.r_table[self.curr_id]["bases"])
				else					
					trigger.action.outText("Current Region: #"..self.curr_id.." Not inside borders or no borders created!", 30)
				end
				self.marks_table[id] = true
				
			elseif(INV) then 
			
				pos["y"] = pos["z"] -- map markers are X,Y,Z with Z as 2 dimensional Y axis -- all math is done as 2d
				pos["z"] = nil
								
				if(check_inside_region(self.r_table[self.curr_id], pos)) then
				
					local insert_table = {
						["name"] = name,
						["location"] = pos
						}
					table.insert(self.r_table[self.curr_id]["bases"]["INV"], insert_table)
					trigger.action.outText("Current Region: #"..self.curr_id.." INVENTORY REPRESENTATION ADDED!", 30)
					utils.tprint(self.r_table[self.curr_id]["bases"])
				else					
					trigger.action.outText("Current Region: #"..self.curr_id.." Not inside borders or no borders created!", 30)
				end

				self.marks_table[id] = true
				
			elseif(first == "NAME" and second) then		
				self.r_table[self.curr_id]["name"] = second
							
				trigger.action.outText("Current Region: #"..self.curr_id.." name:"..self.r_table[self.curr_id]["name"], 30)			
				trigger.action.removeMark(id)	
				
			elseif(first == "COA" and second) then	
				
				second = string.upper(second)
				
				if(coalitionMap[second]) then
					self.r_table[self.curr_id]["owner"] = coalitionMap[second]
					trigger.action.outText("Current Region: #"..self.curr_id.." name:"..self.r_table[self.curr_id]["name"].." coaltion set to: "..self.r_table[self.curr_id]["owner"], 30)
					trigger.action.removeMark(id)
				else
					trigger.action.outText("Invalid coaliton type, allowable input (not case sensitive): BLUE, RED, NEUTRAL", 30)						
				end	
				
			elseif(first == "FILE" and second) then	
				
				self.filename = second
				trigger.action.outText("Filename set to: "..self.filename, 30)			
				trigger.action.removeMark(id)
			elseif(first == "SP") then
			
				pos["y"] = pos["z"] -- map markers are X,Y,Z with Z as 2 dimensional Y axis -- all math is done as 2d
				pos["z"] = nil
								
				if(check_inside_region(self.r_table[self.curr_id], pos)) then
					local name = "Strategic Point"			
					if(string.match(string.upper(text), "NAME:")) then
						name = second						
					end
					
					local insert_table = {
						["name"] = name,
						["location"] = pos
						}
					table.insert(self.r_table[self.curr_id]["bases"]["SP"], insert_table)
					trigger.action.outText("Current Region: #"..self.curr_id.." Strategic Point ADDED!", 30)
					utils.tprint(self.r_table[self.curr_id]["bases"])
				else					
					trigger.action.outText("Current Region: #"..self.curr_id.." Not inside borders or no borders created!", 30)
				end
							
				self.marks_table[id] = true
				
			elseif(first == "FOB") then
			
				pos["y"] = pos["z"] -- map markers are X,Y,Z with Z as 2 dimensional Y axis -- all math is done as 2d
				pos["z"] = nil
								
				if(check_inside_region(self.r_table[self.curr_id], pos)) then
					local name = "Strategic Point"			
					if(string.match(string.upper(text), "NAME:")) then
						name = second						
					end
					
					local insert_table = {
						["name"] = name,
						["location"] = pos
						}
					table.insert(self.r_table[self.curr_id]["bases"]["SP"], insert_table)
					trigger.action.outText("Current Region: #"..self.curr_id.." Strategic Point ADDED!", 30)
					utils.tprint(self.r_table[self.curr_id]["bases"])
				else					
					trigger.action.outText("Current Region: #"..self.curr_id.." Not inside borders or no borders created!", 30)
				end
							
				self.marks_table[id] = true
				
			elseif(first == "SHOP" and second) then
				
				if(self.r_table[self.curr_id]["bases"]["OM"] ~= {}) then
					
					local name = "Shop"
					
					if(string.match(string.upper(text), "NAME:")) then
						name = second						
					end
										
					local shop_table = {
						["name"] = name,
						}
						
					self.r_table[self.curr_id]["shop"] = shop_table
					trigger.action.outText("Current Region: #"..self.curr_id.." SHOP ADDED!", 30)
					utils.tprint(self.r_table[self.curr_id])									
				
				else
				
					trigger.action.outText("No off-map spawns defined! Create at least one before adding a shop", 30)
				
				end
				self.marks_table[id] = true
		
			elseif(self.import) then -- importing/drawing 		
				-- (shut up)
			elseif(first) then -- command not recognized
				trigger.action.outText("Command not recognized. If adding verts, type VERTS to enable verts mode", 30)
	
			end
			
		end
	
	else
	
		trigger.action.outText("Region editing not enabled, create a new region to start", 30)
		trigger.action.removeMark(id)
	end
	
end

function Marks:removeall()
	
	for num, id in ipairs(self.marks_table) do
		trigger.action.removeMark(id)
		self.marks_table[num] = nil
	end

end

function Marks:toggle_verts_mode()
	
	self.verts_mode = not self.verts_mode
	
	if(self.verts_mode) then
		trigger.action.outText("Vertex add mode: ON you may add vertices", 30)	
	else
		vertice_ind = #self.r_table[self.curr_id]["border"]["polygon"]
		self.r_table[self.curr_id]["border"]["polygon"][vertice_ind] = nil -- due to the way this is set up, then a vertex has been added on this map marker, so clear it
		trigger.action.outText("Vertex add mode: OFF you may now place map markers and enter commands (note, the vertex created by this map marker has also been removed)", 30)	
	
	end

end


-- To do: finish these


function Marks:help()
	
	trigger.action.outText(
	"CONFIG REGION TOOL\n"..
	"How to use:\n"..
	"- If creating a new region map for the first time, use the F10 menu to select \"new region\"\n"..
	"- If loading, select \"import region\" make sure the region.JSON file in the import folder\n"..
	"the first region in the list will automatically be selected. \n"..
	"\n"..
	"-Use map markers to enter commands and define the vertices that encompase your region\n"..
	" map markers without any text inside will be assumed to be vertices. Enter vertices in clockwise\n"..
	" orientation.\n"..
	"\n"..
	"Commands:\n"..
	"NAME:\"\" will name the region with whatever is inside the quotation marks\n"..
	"\n"..
	"SET REGION TYPE:\n"..
	"REG: Sets to regular type. Regions are regular type by default\n"..
	"OOB: Sets the region to an out of bounds type. \n"..
	"NC: Sets the region as non capturable type (needed for over water regions)\n"..
	"\n"..
	"Set feature points:\n"..
	"FOB: Specified a FOB a point \n"..
	"FARP: Specifies a farp at point. Must be within set distance from FOB\n"..
	"FSB: Specifies a fire support base at point. Must be within set distance from FOB\n"..
	"OM: Specifies an off map spawn point. This will act like an airbase that can be withdrawn from\n"..
	"for the inventory system (for air spawns)\n"..
	"SHOP:\"on\" or \"off\" Region must have an off map spawn for this. Will create a shop for this point\n"..
	"SP: Specifies a strategic point at the point. This functions the same as towns and bases\n"..
	"INV: Specifies an inventory at the given point. This will overwrite the default. Inventories \n"..
	"COA:\"\" 	Specifies region coalition options: \"BLUE\", \"RED\", \"NEUTRAL\" (default)"..
	"will spawn assets from the base inventory that can be destroyed.\n" , 30)
	
end

function Marks:display_info()
			
	if (self.curr_id == nil) then -- brand new table
		trigger.action.outText("No regions currently defined, create a new one to start configuring", 30)
	else
		trigger.action.outText("Current region: "..self.curr_regions.."\n"..
							   "Name: ".."\n"..self.r_table[self.curr_id]["name"].."\n"..
							   "# of verts: "..#self.r_table[self.curr_id]["border"]["polygon"].."\n"..
							   "Type: "..self.r_table[self.curr_id]["type"].."\n"..
							   " ", 30)
	end	
		
	
end
	
function Marks:delete_region()

	if (self.curr_id == nil) then -- brand new table
		trigger.action.outText("No regions currently defined, create a new one to start configuring", 30)
		
	elseif (self.r_table[self.curr_id]) then
	
		table.remove(self.r_table, self.curr_id)
		trigger.action.outText("Region #"..self.curr_id.." deleted", 30)
		
		if(self.r_table[self.curr_id+1] == nil) then-- last entry in table
			self.curr_id = self.curr_id - 1
			if(self.r_table[self.curr_id] == nil) then -- empty table
				self.r_table = {}
				self.curr_id = nil
				self.enabled = false				
				trigger.action.outText("No more regions defined!", 30)
			else
				trigger.action.outText("Current Region: #"..self.curr_id, 30)
			end
		end
		
		
			
	end	
	
end

function Marks:select_next()
	
	if (self.curr_id == nil) then -- brand new table
		trigger.action.outText("No regions currently defined, create a new one to start configuring", 30)
		
	elseif (self.r_table[self.curr_id+1]) then
	
		self.curr_id = self.curr_id + 1		
		self.enabled = true		
		trigger.action.outText("Region #"..self.curr_id.." selected \nName: "..self.r_table[self.curr_id]["name"].. "\nYou may configure the region now with map markers", 30)
		
	else
		
		trigger.action.outText("Region #"..self.curr_id.." is the last region in the region list! You may create a new one", 30)
	
	end	
		
end

function Marks:select_prev()
	
	if (self.curr_id == nil) then -- brand new table
		trigger.action.outText("No regions currently defined, create a new one to start configuring", 30)
		
	elseif (self.r_table[self.curr_id-1]) then
	
		self.curr_id = self.curr_id - 1		
		self.enabled = true		
		trigger.action.outText("Region #"..self.curr_id.." selected \nName: "..self.r_table[self.curr_id]["name"].. "\nYou may configure the region now with map markers", 30)
		
	else
		
		trigger.action.outText("Region #"..self.curr_id.." is the first region in the region list!", 30)
	
	end	
	
end

function Marks:edit_selected()
	
	if (self.curr_id == nil) then -- brand new table
		trigger.action.outText("No regions currently defined, create a new one to start configuring", 30)
		
	elseif (self.r_table[self.curr_id]) then

		self.enabled = true		
		trigger.action.outText("Region #"..self.curr_id.." selected, you may now edit it", 30)
			
	end	
	
end

function Marks:reset_region()
	
	if (self.curr_id == nil) then -- brand new table
		trigger.action.outText("No regions currently defined, create a new one to start configuring", 30)
	else
	
		local empty_table = {["name"] = "",
						 ["border"] = {["polygon"] = {},
									   ["triangles"] = {},
									   ["center"] = {},
								     },
						 ["owner"] = coalitionMap["NEUTRAL"], -- default
						 ["type"] = {},
						 ["bases"] = {
									 
									 ["FOB"] = {},
									 ["FARP"] = {},
									 ["FSB"] = {},
									 ["OM"] = {},
									 ["SP"] = {},
									 ["INV"] = {},
									},
						}
							
		self.r_table[self.curr_id] = empty_table
		
		trigger.action.outText("Region #"..self.curr_id.." reset. You may configure the region now with map markers", 30)


	end	

	
end

function Marks:new_region()

	if (self.curr_id == nil) then -- brand new table
		self.curr_id = 1
		self.enabled = true
	else
		self.curr_id = #self.r_table + 1
		self.enabled = true
	end	
	
	local empty_table = {["name"] = "",
						 ["border"] = {["polygon"] = {},
									   ["triangles"] = {},
									   ["center"] = {},
								     },
						 ["owner"] = coalitionMap["NEUTRAL"], -- default
						 ["type"] = {},
						 ["shop"] = {},
						 ["bases"] = {
									 
									 ["FOB"] = {},
									 ["FARP"] = {},
									 ["FSB"] = {},
									 ["OM"] = {},
									 ["SP"] = {},
									 ["INV"] = {},
									},
						}
						
	self.r_table[self.curr_id] = empty_table
	
	trigger.action.outText("Region #"..self.curr_id.." created. You may configure the region now with map markers", 30)
	
end

function Marks:export_region()
	
	if(self:write_JSON_tbl(self.r_table)) then	
	
		trigger.action.outText("Region successfully written!", 30)
		
	else	
	
		trigger.action.outText("Error writing region! Are your directories set up correctly?", 30)
	
	end
	
end

function Marks:export_overwrite()
	
	if(self:overwrite_JSON_tbl(self.r_table)) then	
	
		trigger.action.outText("Import table overwritten!", 30)
		
	else	
	
		trigger.action.outText("Error writing region! Are your directories set up correctly?", 30)
	
	end
	
end

function Marks:import_region()
	
	local Json_Tbl = self:read_JSON_file()
	
	if(Json_Tbl) then
		
		self.verts_mode = false
		self.enabled = true
		self.import = true
		self.r_table = Json_Tbl
		
		for ind, region in ipairs(self.r_table) do
			self.curr_id = ind			
			trigger.action.outText(ind, 30)
			self:draw_region(ind)
		end

		self.enabled = false
		self.import = false

		trigger.action.outText("Region imported! You may create new regions or select existing ones to edit", 30)

	
	else
			
		trigger.action.outText("File: "..self.filename.." not found in import folder, or is not a valid JSON file!", 30)
	
	end
	

	-- need to read the JSON file and create the markups. going to be a bit of a job.
	
end

function Marks:debugging()
	
	utils.tprint(self.r_table)
	
end

function Marks:create_borders()

	local tri_table = {}
	
	if (self.curr_id == nil) then -- brand new table
		trigger.action.outText("No regions currently defined, create a new one to start configuring", 30)
	else
			
		utils.tprint(self.r_table[self.curr_id]["border"]["polygon"])
		self.r_table[self.curr_id]["border"]["center"] = geometry.meanCenter2D(self.r_table[self.curr_id]["border"]["polygon"])
		
		tri_table = geometry.triangulate(self.r_table[self.curr_id]["border"]["polygon"])
		utils.tprint(tri_table)

		
		if (tri_table) then -- triangulation successful
		
			--pre-calculate barycentric coords
			self.r_table[self.curr_id]["border"]["barycentric_precalcs"] = {}
			for i = 1, #tri_table do
				local b_table = geometry.barycentric_precalc(tri_table[i])
				utils.tprint(b_table)
				self.r_table[self.curr_id]["border"]["barycentric_precalcs"][i] = b_table
			end
			
			utils.tprint(tri_table)
		
			self.r_table[self.curr_id]["border"]["triangles"] = tri_table
			self:draw_region(self.curr_id)
			self.verts_mode = false	
			trigger.action.outText("Region added! You may create a new one, or export the configuration.", 30)
			self:removeall()
			
		else --triangulation unsuccessful
		
			trigger.action.outText("Region triangulation failed - invalid verts.\nYour vertices have been cleared - please try again", 30)
			self.r_table[self.curr_id]["border"]["polygon"] = {}		
			self.r_table[self.curr_id]["border"]["triangles"] = {}				
			self:removeall()
			
		end
		
	end	
	
end

function Marks:validate_region()
	
	local region = self.r_table[self.curr_id]
	local poly_table = {}
	poly_table = geometry.triangulate(self.r_table[self.curr_id]["border"]["polygon"])
	
	all_bases_in_region = true
	
	--check all bases in region
	for b_type, base in pairs(region["bases"]) do
		for ind, pos in ipairs(base) do
			--all_bases_in_region = all_bases_in_region and check_inside_region(r_table, pos)
		end
	end

	if (poly_table and all_bases_in_region) then -- triangulation successful
		return true
	else 
		return false
	end
	
end

function check_inside_region(r_table, P) -- expects P as a a proper x,y vector.
	
	env.info("inside")
	utils.tprint(P)
	inside = false	
		
	--check all bases in region
	for ind, tri in ipairs(r_table["border"]["triangles"]) do
		
		utils.tprint(tri)
		utils.tprint(r_table["border"]["barycentric_precalcs"])
		inside = inside or geometry.point_in_triangle_fast(P, tri, r_table["border"]["barycentric_precalcs"][ind])
		
	end		
	
	return inside

end

function Marks:draw_region(region_index)
	
	human.updateRegionBorders(self.r_table[self.curr_id])
	
end

function Marks:read_JSON_file()
	
	local input_path = modpath..utils.sep.."utilities"..utils.sep.."region info generator"..utils.sep.."import"..utils.sep 
	local full_path = input_path..self.filename..".JSON"	
	
	file = io.open(full_path, "r")
	
	if(file) then
		local JSONString = file:read("*all")
		file:close()
		
		if(JSONString) then
			return JSON:decode(JSONString)
		else
			return nil	
		end
		
	
	else
		
		return nil
	
	end


end

function Marks:write_JSON_tbl(tbl)

	--saves to output as well as to the theater folder (overwrite)
	local output_path = modpath..utils.sep.."utilities"..utils.sep.."region info generator"..utils.sep.."export"..utils.sep 
	local backup_path = modpath..utils.sep.."utilities"..utils.sep.."region info generator"..utils.sep.."backup"..utils.sep 
		
	output_path = output_path..self.filename..".JSON"
	backup_path = backup_path..self.filename..".JSON"
	
	file = io.open(output_path, "w+")
	
	if(file) then
		
		file:write(JSON:encode_pretty(tbl))
		file:close()		
		file = io.open(backup_path, "w+")
		file:write(JSON:encode_pretty(tbl))
		file:close()		
		return true	
	
	else
		
		return nil
	
	end


end

function Marks:overwrite_JSON_tbl(tbl)

	--saves to output as well as to the theater folder (overwrite)
	local output_path = modpath..utils.sep.."utilities"..utils.sep.."region info generator"..utils.sep.."import"..utils.sep 
	local backup_path = modpath..utils.sep.."utilities"..utils.sep.."region info generator"..utils.sep.."backup"..utils.sep 
	
	
	output_path = output_path..self.filename..".JSON"
	backup_path = backup_path..self.filename..".JSON"
	
	file = io.open(output_path, "w+")
	
	if(file) then
		
		file:write(JSON:encode_pretty(tbl))
		file:close()		
		file = io.open(backup_path, "w+")
		file:write(JSON:encode_pretty(tbl))
		file:close()		
		return true	
	
	else
		
		return nil
	
	end


end

local Mark_Obj = Marks.new()	

-- EVENT HANDLER

local handler = {}

function handler:onEvent(event)
	if event.id == world.event.S_EVENT_BIRTH then
		createMenu(event.initiator)
    elseif event.id == world.event.S_EVENT_MARK_CHANGE then
       	Mark_Obj:modify(event.idx, event.text, event.pos)
    elseif event.id == world.event.S_EVENT_MARK_ADDED then
       	Mark_Obj:modify(event.idx, event.text, event.pos)		
    end
end

-- MENUS

function createMenu(user_unit)
	local gid  = user_unit:getID()
	--local name = "Region Creator"
	
	---------------------------------------------------------------Region
	

	addcmd(gid, "Help", nil, Marks.help, Mark_Obj)	
	--addcmd(gid, "Current Region Info", nil, Marks.display_info, Mark_Obj)	
	addcmd(gid, "Delete Current Region", nil, Marks.delete_region, Mark_Obj)	
	addcmd(gid, "Select Next Region", nil, Marks.select_next, Mark_Obj)	
	addcmd(gid, "Select Previous Region", nil, Marks.select_prev, Mark_Obj)	
	addcmd(gid, "Edit Selected Region", nil, Marks.edit_selected, Mark_Obj)
	addcmd(gid, "New Region", nil, Marks.new_region, Mark_Obj)	
	addcmd(gid, "Export", nil, Marks.export_region, Mark_Obj)	
	addcmd(gid, "Export - Overwrite", nil, Marks.export_overwrite, Mark_Obj)	
	addcmd(gid, "Import", nil, Marks.import_region, Mark_Obj)
	addcmd(gid, "Create Borders", nil, Marks.create_borders, Mark_Obj)	
	
end

world.addEventHandler(handler)