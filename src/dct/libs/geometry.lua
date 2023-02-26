--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- 2D geometry utility functions.
--]]

-- luacheck: max comment line length 100
-- luacheck: max cyclomatic complexity 15

local class = require("libs.class")
local vec   = require("dct.libs.vector")

local geometry = {}

local Line = class()
function Line:__init(head, tail)
	if head.x > tail.x then
		head, tail = tail, head
	end
	self.head = vec.Vector2D(head)
	self.tail = vec.Vector2D(tail)
	assert(self.head ~= self.tail, "line must have non-zero length")
end

function Line:getEquation()
	local base = vec.unitvec(self.tail - self.head)
	return math.atan2(base.y, base.x), self.head.y
end

function Line:length()
	return (self.tail - self.head):magnitude()
end

function Line:intersection(other)
	local slope1, intercept1 = self:getEquation()
	local slope2, intercept2 = other:getEquation()
	if slope1 == slope2 then
		local diff = Line(other.head - self.head, other.tail - self.tail)
		if diff:length() < self:length() then
			return other.head
		else
			return nil
		end
	end

	local point = vec.Vector2D.create(
		slope1 * (intercept2 - intercept1) / (slope1 - slope2) + intercept1,
		slope1 * (intercept2 - intercept1) / (slope1 - slope2) + intercept1
	)

	if point.x >= self.head.x and point.y >= self.head.y and
	   point.x <= self.tail.x and point.y <= self.tail.y then
		return point
	end

	return nil
end

function geometry.meanCenter2D(points)
	local min = vec.Vector2D.create( math.huge,  math.huge)
	local max = vec.Vector2D.create(-math.huge, -math.huge)
	for _, point in ipairs(points) do
		min.x = math.min(min.x, point.x)
		min.y = math.min(min.y, point.y)
		max.x = math.max(max.x, point.x)
		max.y = math.max(max.y, point.y)
	end
	return (max + min) / 2
end

local function get(tbl, idx)
	if idx < 1 or idx > #tbl then
		idx = idx % #tbl
	end
	if idx == 0 then
		idx = #tbl
	end
	return tbl[idx]
end

local function intersects(a, b, polygon)
	local line = geometry.Line(a, b)
	for i = 1, #polygon do
		local curr = get(polygon, i)
		local next = get(polygon, i + 1)
		if a ~= curr and a ~= next and b ~= curr and b ~= next then
			local across = geometry.Line(curr, next)
			if line:intersection(across) ~= nil then
				return true
			end
		end
	end
	return false
end

local function signedPolyArea(polygon)
	local total = 0
	for i = 1, #polygon do
		local curr = get(polygon, i)
		local next = get(polygon, i + 1)
		total = total + (next.x - curr.x) * (next.y + curr.y)
	end
	return total / 2
end

local function polygonArea(polygon)
	return math.abs(signedPolyArea(polygon))
end

local function isClockwise(polygon)
	return signedPolyArea(polygon) > 0
end

local function isInside(vertex, triangle)
	local a = polygonArea { vertex, triangle[2], triangle[3] }
	local b = polygonArea { triangle[1], vertex, triangle[3] }
	local c = polygonArea { triangle[1], triangle[2], vertex }
	return math.abs(polygonArea(triangle) - (a + b + c)) < 0.01
end

local function anyInside(triangle, vertices)
	for _, vertex in ipairs(vertices) do
		if vertex ~= triangle[1] and vertex ~= triangle[2] and
		   vertex ~= triangle[3] and isInside(vertex, triangle) then
			return true
		end
	end
	return false
end

-- reference:
-- https://www.gamedev.net/articles/programming/graphics/polygon-triangulation-r3334/
function geometry.triangulate(polygon)
	local clockwise = isClockwise(polygon)
	local triangulated = {}
	local vertices = {}
	for i = 1, #polygon do
		if clockwise then
			table.insert(vertices, 1, vec.Vector2D(polygon[i]))
		else
			table.insert(vertices, vec.Vector2D(polygon[i]))
		end
	end

	while true do
		local continue = false
		for i = 1, #vertices do
			local prev = get(vertices, i - 1)
			local curr = get(vertices, i)
			local next = get(vertices, i + 1)
			local triangle = { prev, curr, next }
			-- make sure we're creating a triangle on the inner side of the polygon
			local crossProduct = vec.cross(prev - curr, next - curr)
			if crossProduct > 0 and
			   not anyInside(triangle, vertices) and
			   not intersects(prev, next, vertices) and
			   not intersects(prev, curr, vertices) and
			   not intersects(curr, next, vertices) then
				table.insert(triangulated, triangle)
				table.remove(vertices, i)
				continue = true
				break
			end
		end
		if not continue then
			break
		end
	end
		
	-- error checking, removed asserts since I want this to be able to fail in my config_regions script
		
	if(#vertices ~= 2) then
		return nil
	end

	
	for i = 1, #triangulated do
		if #triangulated[i] ~= 3 then
			return nil
		end
	end		
	
	--[[
	assert(#vertices == 2,
		string.format( "not all vertices were triangulated: %d left", #vertices))
		

	for i = 1, #triangulated do
		assert(#triangulated[i] == 3,
			string.format("polygon idx %d is not a triangle", i))
	end
	--]]
	return triangulated
end

-- reference:
-- https://www.gamedev.net/articles/programming/graphics/polygon-triangulation-r3334/
function geometry.triangulate(polygon)
	local clockwise = isClockwise(polygon)
	local triangulated = {}
	local vertices = {}
	for i = 1, #polygon do
		if clockwise then
			table.insert(vertices, 1, vec.Vector2D(polygon[i]))
		else
			table.insert(vertices, vec.Vector2D(polygon[i]))
		end
	end

	while true do
		local continue = false
		for i = 1, #vertices do
			local prev = get(vertices, i - 1)
			local curr = get(vertices, i)
			local next = get(vertices, i + 1)
			local triangle = { prev, curr, next }
			-- make sure we're creating a triangle on the inner side of the polygon
			local crossProduct = vec.cross(prev - curr, next - curr)
			if crossProduct > 0 and
			   not anyInside(triangle, vertices) and
			   not intersects(prev, next, vertices) and
			   not intersects(prev, curr, vertices) and
			   not intersects(curr, next, vertices) then
				table.insert(triangulated, triangle)
				table.remove(vertices, i)
				continue = true
				break
			end
		end
		if not continue then
			break
		end
	end
		
	-- error checking, removed asserts since I want this to be able to fail in my config_regions script
		
	if(#vertices ~= 2) then
		return nil
	end

	
	for i = 1, #triangulated do
		if #triangulated[i] ~= 3 then
			return nil
		end
	end		
	
	--[[
	assert(#vertices == 2,
		string.format( "not all vertices were triangulated: %d left", #vertices))
		

	for i = 1, #triangulated do
		assert(#triangulated[i] == 3,
			string.format("polygon idx %d is not a triangle", i))
	end
	--]]
	return triangulated
end

function geometry.barycentric_precalc(triangle)
--precalculates barycentric values for point in triangle test
-- Compute barycentric coordinates (u, v, w) for
-- point p with respect to triangle (a, b, c)

	local b_table = {}	
		
	local v0 = (triangle[2]-triangle[1])
	local v1 = (triangle[3]-triangle[1])

		
	local d00 = vec.dot(v0, v0)
	local d01 = vec.dot(v0, v1)
	local d11  = vec.dot(v1, v1)

	local denom = d00*d11 - d01*d01

		
	b_table["v0"] = v0
	b_table["v1"] = v1

		
	b_table["d00"] = d00
	b_table["d01"] = d01
	b_table["d11"]  = d11

	b_table["denom"] = denom
	
	return b_table
	
end

function geometry.point_in_triangle_fast(point, triangle, info) 
-- now optimized - no Vec casting or calls required.
--P : a point in table form ["x"] = x, ["y"] = y
--info : a table with all barycentric precalculations for triangle


	local v0 = info["v0"]
	local v1 = info["v1"]	
	
	local v2 = {}
	v2["x"] = point["x"]-triangle[1]["x"]
	v2["y"] = point["y"]-triangle[1]["y"]
	
	local d00 =  info["d00"]
	local d01 =  info["d01"]
	local d11 =  info["d11"]
	local d20 =  v2["x"]*v0["x"] + v2["y"]*v0["y"] -- dot product
	local d21 =  v2["x"]*v1["x"] + v2["y"]*v1["y"]

	local denom =  info["denom"]

	v = (d11*d20-d01*d21)/denom
	w = (d00*d21-d01*d20)/denom
	u = 1 - v - w;
	
	--env.info("v: "..v.." w: "..w.." u: "..u) for debugging
	
	return (v >= 0) and (w >= 0) and ((v + w) <= 1);
	
end

--[[
old (but working) methods
function geometry.point_in_triangle_fast(point, triangle, tolerance) --assumes that triangle has precalculated barycentric values

	local P = vec.Vector2D(point)
	local T1 = {["x"] = triangle["1"]["x"], ["y"] = triangle["1"]["y"]}

	local v0 = vec.Vector2D(triangle["barycentric"]["v0"])
	local v1 = vec.Vector2D(triangle["barycentric"]["v1"])
	local v2 = P-T1;
	
	local d00 =  triangle["barycentric"]["d00"]
	local d01 =  triangle["barycentric"]["d01"]
	local d11 =  triangle["barycentric"]["d11"]
	local d20 =  vec.dot(v2, v0)
	local d21 =  vec.dot(v2, v1)

	local denom =  triangle["barycentric"]["denom"]
	
	local lower_lim = 0-tolerance;
	local upper_lim = 1+tolerance;	

	v = (d11*d20-d01*d21)/denom;
	w = (d00*d21-d01*d20)/denom;
	u = 1 - v - w;
	
	env.info("v: "..v.." w: "..w.." u: "..u)
	
	return (v >= lower_lim) and (w >= lower_lim) and ((v + w) <= upper_lim);	
	
end


function [u, v, w] = convert_to_barycentric(P, triangle)
	
	
	v0 = (triangle(2,:)-triangle(1,:));
	v1 = (triangle(3,:)-triangle(1,:));
	v2 = P-triangle(1,:);
	
	d00 = dot(v0, v0);
	d01 = dot(v0, v1);
	d11 = dot(v1, v1);
	d20 = dot(v2, v0);
	d21 = dot(v2, v1);
	denom = d00*d11 - d01*d01;
	v = (d11*d20-d01*d21)/denom;
	w = (d00*d21-d01*d20)/denom;
	u = 1 - v - w;
	
end
]]--

geometry.Line = Line

return geometry