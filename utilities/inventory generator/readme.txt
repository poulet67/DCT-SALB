Inventories:

All the utilities used to generate the tables used are provided, however they may not be necessary for most users. When new ammo and airframes are added to game, users are recommended to check the github/discord for the new entries to add to inventory tables

Configuration:
	
	Part 1: Region Configuration
	
		Configure the various regions for your game state
		Any bases added to the initial state will be saved in ____ and bases.TBL
		
	Part 2: Airbase and Base list generation
		
		Copy bases.TBL from part 1 into the utilities/base list generator/bases folder (if not already placed there automatically)
		Load the .miz file for your mission into the mission editor and run the script utilities/base list generator/generate_list.lua
		This will create a list called " ".tbl

	Part 3: Inventory Generator
		
		- Navigate the folder with the map you need.
		- Configure options in option folder as you like
			
		---OPTIONS----
			
		- game
			-adds all "non-ED" game assets
			
		- display names 
			-the default "ED" names are inconsistent and often terrible they can be replaced here for good readable output
		
		- links
			- Since ED is so terrible at organizing assets, this table will allow various different weapons to be "linked"
					-examples: Swedish Aim-9s bugs where various airframes have differently named weapons, etc.
					-This will add a "link" field to this entry when inventory is generated. When checked the DCT game logic checks this field, it will use the value linked to when performing inventory operations. 
					-the table provided by default represents my best attempt to capture and consolidate all the different cases that arise. 
					-if not exist, everything will have it's own entry
						
		- store
			- add configuration for store (wip)
			
		---Configuration---
		
			---Initial---

				
			- default.json: 
				- This is the inventory table that will be given to every airbase specified as "default" in the .cfg file. 
				- if not exist, airbase/base will be empty

			- x.json 
				- Named inventory states per 'specific' option in .cfg file
				- These can be created manually using template found in template folder of top level inventories generator directory
			
		- airbases.cfg

			- Airbases settings file:
				- For every airbase specify:
					- "Initial State":
							options: "default", "empty", "specific", "value"
					(if default, any new table created will use the global default table: default.tbl if doesn't exist, will spawn with empty fields)
					(empty means the airbase will not be usable until supplied)
					(specific allows you to define the name of a file it will use to fill this inventory. If empty it will look for a file called "name.inv" where name is the name of the airbase)
					(value will allows you to specify a "values" table for each category of the inventory table)

				- Note: If for any reason airbases are not in this table they will be added with empty inventories in DCT


Execution:

	- inventory_gen.lua - Script generates initial inventory table from tables of airbases and available weapons/ammo/ground forces (so new tables can be easily created in case of additional equipment added to game).
		-run the script with lua and pass in as argument the map you want to generate for options are:
			-"caucasus"
			-"marianas"
			-"nevada"
			-"persian gulf"
			-"syria"
			-"templates"
				--> This creates blank template files with all displaynames filled in
				
	- If script executes with no errors ("Done" in stdout) inventory.JSON will be created in the map folder you specified.
			-copy that to theater/tables/inventories
		
		-example: lua inventory_gen.lua caucasus