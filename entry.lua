local modtitle = "DCT"
local modtbl   = {
	installed     = true,
	state         = "installed",
	dirName       = current_mod_path,
	shortName     = "DCT",
	version       = "v0.10.1",
	developerName = "github.com/jtoppins",
	info          = _("Dynamic Campaign Tools for DCS"),
}
declare_plugin(modtitle, modtbl)
plugin_done()
