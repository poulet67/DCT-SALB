-- put config_region in your Saved Games/Scripts folder

package.path = package.path .. ";" .. lfs.writedir() .. "Mods\\tech\\DCT\\utilities\\region info generator\\?.lua;"
require("generate_list")