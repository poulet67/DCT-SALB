-- CONFIG REGION

-- Allows user to create a data structure that defines a region (polygon) on the F-10 map

-- 

-- Format
-- R - Region info
-- R:1
-- name:Example Name assigns region 1 the name "Example Name" (optional)
-- 
-- 
-- 																
-- V - vertices followed by which region it belongs to and which vertice this is
-- EG:
-- V:1,1
-- V:1,2
-- V:1,3
-- V:1,4
-- Vertices must be specified in clockwise order
--
--
--
-- FL: front line designated point, followed by which regions it connects EG:
-- FL:1,2
-- FL:1,3
--
-- FB: firebase, initializes a firebase in the region (WIP)
-- FARP: if there is a FARP at this FB
-- FB:1
-- FARP: true/false 
--
--
-- OM: Designates an off-map spawn (WIP)
-- name: name of spawn
-- shop: true/false <-- if this spawn will be linked to the shop
-- FARP: true
--
--
-- OOB - out of bounds region
-- OOB:5 (region 5 - must not conflict with regular regions)
-- V:5,1
-- V:5,2
-- V:5,3
-- V:5,4



--

-- Region definitions
--
-- DCS specific


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

function generate_region(Mark_Obj)

	trigger.action.outText("Exporting Region...", 30)	
	
	table.save(Marks.r_table, lfs.writedir().."\\Scripts\\config_region\\Region.lua")
	
end

enum = {}

enum.Shape = {
		
		 ["Line"] = 1,
		 ["Circle"] = 2,
		 ["Arrow"] = 3,
		 ["Text"] = 4,
		 ["Quad"] = 5,
		 ["Freeform"] = 6,
			
}	
		
enum.Coalition = {
		
		 ["All"] = -1,
		 ["Neutral"] = 0,
		 ["Red"] = 1,
		 ["Blue"] = 2,
		
		}	
		
enum.LineType = {
		
		
		 ["No Line"] = 0,
		 ["Solid"] = 1,
		 ["Dashed"] = 2,
		 ["Dotted"] = 3,
		 ["Dot Dash"] = 4,
		 ["Long Dash"] = 5,
		 ["Two Dash"] = 6,

		}
		
local Marks = {}		
function Marks.new()
	
	local self = {}
	self.markerindex = 10
	self.region_def = false
	self.marks_table = {}
	self.r_table = {["Frontlines"] = {},
					["OOB"] = {},
					}
	self.r_name = nil
	self.curr_id = nil
	self.modify = Marks.modify
	self.removeall = Marks.removeall
	
	return self
	
end

function Marks:modify(id, text, pos)

	self.marks_table[id] = {["text"] = text,
							["pos"] = pos}
	
	self.curr_id = id;
		
	first = string.match(text, "%a+") -- returns everything up to the :
	second = string.match(text, "%p.+") -- returns everything after the :
	vert = string.match(text, "^V$") -- just "V"
	done = string.match(text, "^done$") -- just "done"
	OOB = string.match(text, "^OOB$") -- outofbounds
		
	if(first == "R") then-- Region info
	
		trigger.action.outText("REGION DEFINITION", 30)	
				
		R_name = second:match("%p.+"):sub(2)
		
		if(R_name ~= nil) then
			
			trigger.action.outText("REGION NAME:"..R_name.."\n", 30)	
			self.region_def = true
			self.r_name = R_name
			trigger.action.outText("You can now place vertices. \n Place them in clockwise order with \"V\" in the text field and then type \"done\" into a marker.", 30)	
			
			self.r_table[self.r_name] = {}
			self.r_table[self.r_name]["Verts"] = {}
			self.r_table[self.r_name]["r_type"] = "R"
		
		else
		
			trigger.action.outText("INVALID INPUT", 30)	
			
		end
		

	elseif(vert) then -- Vertice of a region
		
		if(self.region_def and self.r_name ~= "OOB") then
		
			table.insert(self.r_table[self.r_name]["Verts"], pos)
			trigger.action.outText("Vertex added", 30)	
		
		elseif(self.region_def and self.r_name == "OOB") then
		
			trigger.action.outText("test #rtable"..#self.r_table["OOB"], 30)
			
			table.insert(self.r_table["OOB"][#self.r_table["OOB"]]["Verts"], pos)
			trigger.action.outText("Vertex added", 30)	
		
		else
			
			trigger.action.outText("You must define a region first!", 30)	
		
		end
		
	
	elseif(done) then -- Vertice of a region
		
		if(self.region_def and r_name ~= "OOB") then

			trigger.action.outText("----------DRAWING -------------", 30)
			argtable = {}
			
			for k, v in pairs(self.r_table[self.r_name]["Verts"]) do
						
				table.insert(argtable, v)
					
			end	

			grey = {0.8,0.8,0.8,0.8}
			colorfill = {1, 0, 0, 0.5}
			linetype = enum.LineType["Solid"]
			readonly = false
			message = k
			
			table.insert(argtable, grey)
			table.insert(argtable, colorfill)
			table.insert(argtable, linetype)
			table.insert(argtable, readonly)
			table.insert(argtable, message)
			
			trigger.action.markupToAll(enum.Shape["Freeform"] , enum.Coalition["All"] , self.curr_id + 1 , unpack(argtable))
			
			self.curr_id = self.curr_id+1
			
		elseif(self.region_def and r_name == "OOB") then

			trigger.action.outText("----------DRAWING -------------", 30)
			trigger.action.outText("test #rtable"..#self.r_table["OOB"], 30)
			argtable = {}
				
			for k, v in pairs(self.r_table["OOB"][#self.r_table["OOB"]]) do
				
				table.insert(argtable, v)

			end	
			
			grey = {0.8,0.8,0.8,0.8}
			colorfill = {1, 0, 0, 0.5}
			linetype = enum.LineType["Solid"]
			readonly = false
			message = k
			
			table.insert(argtable, grey)
			table.insert(argtable, colorfill)
			table.insert(argtable, linetype)
			table.insert(argtable, readonly)
			table.insert(argtable, message)		
			
			trigger.action.markupToAll(enum.Shape["Freeform"] , enum.Coalition["All"] , self.curr_id + 1 , unpack(argtable))
			
			self.curr_id = self.curr_id+1
			
		end
						
		self.region_def = false
		self.r_name = nil
		self:removeall()
		
	elseif(first == "FL") then -- Location of a frontline
				
		trigger.action.outText("Frontline defintition", 30)	
				
		R1_id = second:match("%p%d+"):sub(2) -- sub 2 to remove colon
		R2_id = second:sub(2):match("%p%d+"):sub(2)  -- sub 2 to remove colon then to remove comma
			
		trigger.action.outText("Links:\nRegion 1: "..R1_id.."\nRegion 2: "..R2_id, 30)	
					
		table.insert(self.r_table["Frontlines"],{["r_type"] = "FL",
											["R1"] = R1_id,
											["R1"] = R2_id,
											["pos"] = pos,	
											})
						
	elseif(first == "OM") then -- Location of an off-map point
				
		
	elseif(first == "FOB") then -- Location of a FOB
	
		
	elseif(first == "OOB") then -- Vertice of an out of bounds region
	

		trigger.action.outText("OUT OF BOUNDS REGION DEFINITION", 30)	

		self.region_def = true
		self.r_name = "OOB"
		trigger.action.outText("You can now place vertices. \n Place them in clockwise order with \"V\" in the ext field and then type \"done\" into a marker.", 30)	
			
		table.insert(self.r_table["OOB"], {["Verts"] = {}} )
		
	elseif(text == "") then
	
	
	else
	
		trigger.action.outText("INVALID INPUT", 30)	
		
	end
	
	
		
end

function Marks:removeall()
	
	for k,v in pairs(self.marks_table) do
		trigger.action.removeMark(k)
		self.marks_table[k] = nil
	end

end

local Mark_Obj = Marks.new()

local handler = {}

function handler:onEvent(event)
    if event.id == world.event.S_EVENT_MARK_REMOVE then
        Mark_Obj:remove(event.idx)
    elseif event.id == world.event.S_EVENT_MARK_CHANGE then
       	Mark_Obj:modify(event.idx, event.text, event.pos)
    elseif event.id == world.event.S_EVENT_MARK_ADDED then
       	Mark_Obj:modify(event.idx, event.text, event.pos)		
    end
end



function parse_string(myString)
		
	trigger.action.outText("In Parse String...", 30)	
	
	
	return region_table

end

world.addEventHandler(handler)
missionCommands.addCommand("Export Region Config", nil, generate_region, Mark_Obj) 


local function exportstring( s )
  return string.format("%q", s)
end

--// The Save Function
function table.save(  tbl,filename )
  local charS,charE = "   ","\n"
  local file,err = io.open( filename, "wb" )
  if err then return err end

  -- initiate variables for save procedure
  local tables,lookup = { tbl },{ [tbl] = 1 }
  file:write( "return {"..charE )

  for idx,t in ipairs( tables ) do
	 file:write( "-- Table: {"..idx.."}"..charE )
	 file:write( "{"..charE )
	 local thandled = {}

	 for i,v in ipairs( t ) do
		thandled[i] = true
		local stype = type( v )
		-- only handle value
		if stype == "table" then
		   if not lookup[v] then
			  table.insert( tables, v )
			  lookup[v] = #tables
		   end
		   file:write( charS.."{"..lookup[v].."},"..charE )
		elseif stype == "string" then
		   file:write(  charS..exportstring( v )..","..charE )
		elseif stype == "number" then
		   file:write(  charS..tostring( v )..","..charE )
		end
	 end

	 for i,v in pairs( t ) do
		-- escape handled values
		if (not thandled[i]) then
		
		   local str = ""
		   local stype = type( i )
		   -- handle index
		   if stype == "table" then
			  if not lookup[i] then
				 table.insert( tables,i )
				 lookup[i] = #tables
			  end
			  str = charS.."[{"..lookup[i].."}]="
		   elseif stype == "string" then
			  str = charS.."["..exportstring( i ).."]="
		   elseif stype == "number" then
			  str = charS.."["..tostring( i ).."]="
		   end
		
		   if str ~= "" then
			  stype = type( v )
			  -- handle value
			  if stype == "table" then
				 if not lookup[v] then
					table.insert( tables,v )
					lookup[v] = #tables
				 end
				 file:write( str.."{"..lookup[v].."},"..charE )
			  elseif stype == "string" then
				 file:write( str..exportstring( v )..","..charE )
			  elseif stype == "number" then
				 file:write( str..tostring( v )..","..charE )
			  end
		   end
		end
	 end
	 file:write( "},"..charE )
  end
  file:write( "}" )
  file:close()
end
