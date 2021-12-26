--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- A class for decision making by player(s)
-- 
-- 
--]]

local enum     = require("dct.enum")
local dctutils = require("dct.utils")
local settings = _G.dct.settings
local Theater = require("dct.Theater")
local class    = require("libs.class")
local Marshallable = require("dct.libs.Marshallable")

local Decision = class(Marshallable)
function Decision:__init() -- need to pass file path to decision.cfg

	Marshallable.__init(self)
	self.decision_text = ""
	self.options = {}
	self.option_path = {} --file path to code to be run on execution
	
end

return Decision