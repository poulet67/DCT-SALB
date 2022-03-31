
-- SPDX-License-Identifier: LGPL-3.0

local utils = {}

function utils.getkey(tbl, val)
	for k, v in pairs(tbl) do
		if v == val then
			return k
		end
	end
	return nil
end

function utils.foreach(ctx, itr, fcn, array, ...)
	for k, v in itr(array) do
		fcn(ctx, k, v, unpack({select(1, ...)}))
	end
end

function utils.shallowclone(obj)
	local obj_type = type(obj)
	local copy

	if obj_type == 'table' then
		copy = {}
		for k,v in pairs(obj) do
			copy[k] = v
		end
	else
		copy = obj
	end
	return copy
end

function utils.deepcopy(obj)
	local obj_type = type(obj)
	local copy

	if obj_type == 'table' then
		copy = {}
		for k,v in next, obj, nil do
			copy[k] = utils.deepcopy(v)
		end
	else
		copy = obj
	end
	return copy
end

function utils.mergetables(dest, source)
	assert(type(dest) == "table", "dest must be a table")
	for k, v in pairs(source or {}) do
		dest[k] = v
	end
	return dest
end

function utils.readlua(file, tblname)
	assert(file and type(file) == "string", "file path must be provided")
	local f = assert(loadfile(file))
	local config = {}
	setfenv(f, config)
	assert(pcall(f))
	local tbl = config
	if tblname ~= nil then
		tbl = config[tblname]
	end
	return tbl, file
end

function utils.loadtable(sfile)		
	local ftables,err = loadfile( sfile )
	if err then return _,err end
	local tables = ftables()
	for idx = 1,#tables do
		local tolinki = {}
		for i,v in pairs( tables[idx] ) do
			if type( v ) == "table" then
				tables[idx][i] = tables[v[1]]
			end
		if type( i ) == "table" and tables[i[1]] then
		   table.insert( tolinki,{ i,tables[i[1]] } )
		end
	 end
	 -- link indices
	 for _,v in ipairs( tolinki ) do
		tables[idx][v[2]],tables[idx][v[1]] =  tables[idx][v[1]],nil
	 end
  end
  return tables[1]
end

function utils.savetable(tbl,filename)		
  local function exportstring(s) return string.format("%q", s) end
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
			  elseif stype == "boolean" then
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

function utils.readconfigs(cfgfiles, tbl)
	for _, cfg in pairs(cfgfiles) do
		tbl[cfg.name] = cfg.default
		if lfs.attributes(cfg.file) ~= nil then
			utils.mergetables(tbl[cfg.name],
				cfg.validate(cfg,
					utils.readlua(cfg.file, cfg.cfgtblname)))
		end
	end
end

local function errorhandler(key, m, path)
	local msg = string.format("%s: %s; file: %s",
		key, m, path or "nil")
	error(msg, 2)
end

function utils.checkkeys(keys, tbl)
	for _, keydata in ipairs(keys) do
		if keydata.default == nil and tbl[keydata.name] == nil
		   and type(keydata.check) ~= "function" then
			errorhandler(keydata.name, "missing required key", tbl.path)
		elseif keydata.default ~= nil and tbl[keydata.name] == nil then
			tbl[keydata.name] = keydata.default
		else
			if keydata.type ~= nil and type(tbl[keydata.name]) ~= keydata.type then
				errorhandler(keydata.name, "invalid key value", tbl.path)
			end

			if type(keydata.check) == "function" then
				local valid, msg = keydata.check(keydata, tbl)
				if not valid then
					errorhandler(keydata.name, tostring(msg or "invalid key value"), tbl.path)
				end
			end
		end
	end
end


function utils.tprint(tbl, indent) --useful debugging tool
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("  ", indent) .. k .. ": "
    if type(v) == "table" then
      env.info(formatting)
      utils.tprint(v, indent+1)
    elseif type(v) == 'boolean' then
      env.info(formatting .. tostring(v))		
    elseif type(v) == 'function' then
	  env.info(formatting .. "FUNCTION: "..k)
    else
      env.info(formatting .. tostring(v))
    end
  end
end

--[[
-- old
function utils.checkkeys(keys, tbl) -- LUA TABLES ARE PASS BY REFERENCE BECAUSE IT IS A BEAUTIFUL LANGUAGE
	for _, keydata in ipairs(keys) do
		if keydata.default == nil and tbl[keydata.name] == nil then
			errorhandler(keydata.name, "missing required key", tbl.path)
		elseif keydata.default ~= nil and tbl[keydata.name] == nil then
			tbl[keydata.name] = keydata.default
		else
			if type(tbl[keydata.name]) ~= keydata.type then
				errorhandler(keydata.name, "invalid key value", tbl.path)
			end

			if type(keydata.check) == "function" and
				not keydata.check(keydata, tbl) then
				errorhandler(keydata.name, "invalid key value", tbl.path)
			end
		end
	end
end
--]]
-- return the directory seperator used for the given OS
utils.sep = package.config:sub(1,1)

return utils
