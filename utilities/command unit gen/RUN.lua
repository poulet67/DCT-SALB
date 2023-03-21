do
	if not lfs or not io or not require then
		local assertmsg = "DCT requires DCS mission scripting environment"..
			" to be modified, the file needing to be changed can be found"..
			" at $DCS_ROOT\\Scripts\\MissionScripting.lua. Comment out"..
			" the removal of lfs and io and the setting of 'require' to"..
			" nil."
		assert(false, assertmsg)
	end

	-- 'dctsettings' can be defined in the mission to set nomodlog
	dctsettings = dctsettings or {}

	-- Check that DCT mod is installed
	local modpath = lfs.writedir() .. "Mods\\tech\\DCT"
	if lfs.attributes(modpath) == nil then
		local errmsg = "DCT: module not installed, mission not DCT enabled"
		if dctsettings.nomodlog then
			env.error(errmsg)
		else
			assert(false, errmsg)
		end
	else
		package.path = package.path .. ";" .. modpath .. "\\lua\\?.lua;"
		package.path = package.path .. ";" .. modpath .. "\\utilities\\command unit gen\\?.lua;"
		--require("dct")
		--dct.init()
	end
end

require("dct")
require("gen_command_units")