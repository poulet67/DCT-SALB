Inventories:

All the utilities used to generate the tables used are provided, however they may not be necessary for most users. When new ammo and airframes are added to game, users are recommended to check the github/discord for the new entries to add to inventory tables

Configuration:

	- Navigate the folder with the map you need.
	
	- game.tbl 
		-adds all "non-ED" game assets
	
	- link.tbl
		- Since ED is so terrible at organizing assets, this table will allow various different weapons to be "linked"
				-examples: Swedish Mavericks vs. AGM-65(or whatever) counterpart, various different 'tail types' of bombs on mosquito, bugs where various airframes have differently named weapons.
				-This will add a "link" field to this entry when inventory is generated. When checked the DCT game logic checks this field, it will use the value linked to when performing inventory operations. 
				-the table provided by default represents my best attempt to capture and consolidate all the different cases that arise. 
				-if not exist, everything will have it's own entry
	
	- set up configuration to your desire/needs the following files are provided
	
		- airbases.cfg

			- Airbases settings file:
				- For every airbase specify:
					- "Initial State":
							options: "default", "empty", "specific", "value"
					(if default, any new table created will use the global default table: default.tbl if doesn't exist, will spawn with empty fields)
					(empty means the airbase will not be usable until supplied)
					(specific means it will look for a file called "name.inv" that it will use for its inventory table)
					(value will allows you to specify a "values" table for each category of the inventory table)

				- Note: Airbases not in this table will be added with empty inventories
					
					
				
		- bases.cfg
			- add any configuration for bases defined in Region definition here (starting template provided)
			
			- Bases settings file:
				- If you have specified any bases on start in the region definition you can set the inventory state here
					- "Initial State":
							options: "default", "empty", "specific", "value: #"
					(if default, any new table created will use the global default table: default.tbl)
					(empty means the airbase will not be usable until supplied)
					(specific means it will look for a file called "name.inv" that it will use for its inventory table)
					(value will add all assets defined in tables with quantities of # (useful for training maps or offmaps - set to a sufficiently high value so users can sandbox wih it or have a sufficiently ))
		
		- store.cfg
			- add configuration for store (wip)
			
		- default.tbl: 
			- This is the inventory table that will be given to every airbase specified as "default" in the .cfg file. 
			- if not exist, airbase/base will be empty

	- For more fine control you will have to modify the fields in the table generated in the next step by hand. Hope to GUI-fy this in
	the future so it is less arduous.


Execution:

	- inventory_gen.lua - Script generates initial inventory table from tables of airbases and available weapons/ammo/ground forces (so new tables can be easily created in case of additional equipment added to game).
		-run the script with lua and pass in as argument the map you want to generate for options are:
			-"caucasus"
			-"marianas"
			-"nevada"
			-"persian gulf"
			-"syria"
		
	- If script executes with no errors ("Done" in stdout) inventory.JSON will be created in the map folder you specified.
			-copy that to theater/tables/inventories
		
		-example: lua inventory_gen.lua caucasus