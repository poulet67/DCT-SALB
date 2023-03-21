-- SPDX-License-Identifier: LGPL-3.0

local class = require("libs.class")
local json  = require("libs.json")
local utils = require("libs.utils")
local containers = require("libs.containers")

local _G   = _G
local libs = {
	_VERSION     = "1",
	_DESCRIPTION = "libs: general functions that most common languages have",
	_COPYRIGHT   = "Copyright (c) 2019 Jonathan Toppins",
	class        = class,
	json         = json,
	utils        = utils,
	containers   = containers,
}

_G.libs = libs
return libs
