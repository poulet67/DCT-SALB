return{
	["Formations"] = {["Brigade"] = {--["Top"] = true,
						["CP Reward"] = 5000,
						["Batallion"] = {["Min"] = 3,
										 ["Max"] = 8,
										 ["CP Reward"] = 1000,
										 ["Company"] = {["Min"] = 3,
														["CP Reward"] = 300
														["Platoons"] = {["CP Reward"] = 100
																		["Min"] = 3,
																		["Squad"] = {["Min"] = 3,
																					  ["Infantry"] = true,
																					  ["Team"] = {["Min"] = 2,
																								  ["Infantry"] = true,
																								  }
																					 },
																					 }
																		
																	   }
													   },
										 ["Battery"] = {["Min"] = 0,
														["Section"] = {["Min"] = 3}
													   }
									
									
									
										}
						}
		

	["Restrictions"] = {["Batallion"] = {["Combined Arms"] = {} -- no restrictions
										 ["Armored"] = "Armored",
										 ["Anti-Air"] = "Anti-Air",
										 ["Artillery"] =  "Artillery",
										 ["Support"] = {"Mechanized",
													   "Motorized"}
									}
						}


								
	["Transports"] = {["Rifle"] = {"Mechanized",
							   "Motorized"
							  },
				  ["Anti-Air"] = {"Mechanized",
								  "Motorized"
								 },
				  ["Marines"] = {"Mechanized",
								 "Motorized",
								 "Amphibious"
								},
				  ["Airborne"] = {"Mechanized",
								  "Motorized"
								 },
				  ["Mortar"] = {"Mechanized",
								"Motorized"
							   },
				  ["Recon"]  = {"Mechanized",
								"Motorized"
							   },
				  ["Engineer"] = {"Mechanized",
								  "Motorized"
								 },
				  ["JTAC"]  = {"Mechanized",
							   "Motorized"
							  }
				}	
}

--[[
Settings = {["Company"] = {"Mechanized",
						   "Armored",
					       "Motorized",
					       "Amphibious",
					       "Anti-Air"},

--]]

--[[

FORMATION:CREATE
-- This will create the formation from the nearest base's inventory of manpower, ground vehicles and fuel
-- maybe could just use "" quotes once created to indicate which formation... they will all be codenamed
FORMATION:DEPLOY
FORMATION:MOVE
FORMATION:PACK -- for A/D and the like - can't move them
FORMATION:UNGROUP
FORMATION:GROUP
FORMATION:BUILD -- FSBs and such
FORMATION:DISMOUNT 
FORMATION:MOUNT 
FORMATION:COVER -- Enter bases, cities, POIs


BATTERY:ATTACK

LOGI:DEPLOY
LOGI:DELIVER
LOGI:LAND

CARGO:CREATE
CARGO:LOAD

--]]