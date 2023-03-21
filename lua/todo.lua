--------------------------- DCT TO DO:

-- Additional Mission Fields:
	--Package Name 
	--Squad leader <--- first person to join mission, and whenever they leave it passes to the next in a queue
		-- Can change package name of a mission	

-- COMMANDER OVERHAUL!!! :D
	-- Commander loads templates at mission start (x)
			-- needs more testing
	-- 
	-- Expand map sniffer commands
		
		--> Add check for commander (make it UCID based)
			--> Change push time, Marshal Point
			--> Change/Add ToT
		
		
-- Finish stages!

-- Restrict which airframes can join which missions based on ATO table

-- Extend Region class to include coordinates of polygon (X)
		--> Need to test, add geometry library and extend more
					--> get point in polygon function working (crucial)
		--> Add towns.lua
				--> Create an asset class for Towns, or maybe POI (points of interest/importance), or StategicPoints? 
						--> Initialize an inventory (or "mini inventory")


-- Graft Inventories on.
		--> New class, each base has an inventory
		--> New folder in theater for tables
		-->


-- RECON system!
		
-- See if you can get asset manager to spawn at a different point than the template
			--> comming soon with FOBs!
			
-- New settings require list:
	--> RECON_ACTIVATION_TIMER (or something)
	--> COMMAND_UNITS_TAKEOFF_FROM_RAMP
	
-- STYLE Annoyances list:
	--enum vs dct.enum
	--2 diff util.lua files really necessary?
	--requires at the header or oneliners?
	--scratchpad can be refactored out now


-- Add a "command pending" blocker to the map marker parser so malicious individuals can't grind the server to a halt




-- Asset Manager: extend to allow for deployed and reserved (stowed?) assets

-- Major additions and changes to template system 
		-- Keep a list of all the new properties added
				--oof
				--some have been made obsolete but:
						--periodic
						--stage
						--cp_reward
						--known
				--to delete (clear out of codebase):
					--custombriefing (I just didn't understand desc)
					--
						
-- Get export back up and running!
	
---------------------------------DONE!:

-- Rip out the tickets system (x)
		--Probably broke DCT in the process, need to re-install DCT and get a mission set up and running (x)
-- Mission Board ui menu display
	---> may want to add some more fields as mission system is extended
	
	--> Package comms (x)
-- Rip apart the mission system to make it more visible (x)

-- Add new settings files (x)

-- Modify mission briefing behavior for Transport and non-target missions (x)
		---> it's so goddamned beautiful!
		
-- Get scratchpad to auto set when mission join (x) 
--						--> It works, more thought may be required  (maybe tear it apart, map sniffer will be required anyhow)

-- Graft in map sniffer (x)
		--> Start with scratch pad and config region open

-- Fix location method (X)

-- More changes to mission.lua 
		-- Finish Periodic missions and get rid of auto-deletion code (x)
		
-- Extend Theater class to allow for staged spawns (x)
			--> Initialization working, need to add stage transitions
		
-- Get stages working (x) 
	--> Still need to get stage transitions working, but template and initialization wise is working.
				
-- Vote system (x)

-- Add in anti-ship missile auto intercept mission (X)

--
-- Test vote system online when commander is working (X)
					-- Half tested, full test forthcoming
					
-- Player commander (x)
		-- Still needs testing and in development