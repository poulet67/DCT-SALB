--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Basic Graph container
--]]

local class = require("libs.namedclass")

local errno = {
	ENONE     = 0,  -- no error
	ENODEEXTS = 1,  -- node already exists in node table
	ENODE     = 2,  -- node does not exist in node table
}

local Edge = class("graph-edge")
function Edge:__init(cost)
	self._cost = cost or 1
end

function Edge:cost()
	return self._cost
end

local Node = class("graph-node")
function Node:__init()
end

-- the storage model for adjancy means we can only have 1 edge per
-- node pair. This should be ok as we can just have the edge class
-- have flags for things like domain
local Graph = class("graph")
function Graph:__init()
	self.nodes = {}
end

function Graph:exists(x)
	return self.nodes[x] ~= nil
end

function Graph:neighbors(x)
	return self.nodes[x]
end

function Graph:adjacent(x, y)
	local x_adj = self:neighbors(x)
	return x_adj ~= nil and x_adj[y] ~= nil
end

function Graph:add_node(x)
	if self.nodes[x] ~= nil then
		return errno.ENODEEXTS
	end
	local neighbors = {}
	-- make keys weak for neighbors table
	setmetatable(neighbors, { __mode = "k", })
	self.nodes[x] = neighbors
	return errno.ENONE
end

function Graph:remove_node(x)
	if self.nodes[x] == nil then
		return errno.ENONE
	end
	for n in pairs(self:neighbors(x)) do
		local n_adj = self.nodes[n]
		n_adj[x] = nil
	end
	self.nodes[x] = nil
	return errno.ENONE
end

-- will overwrite any edge previously associated with a x-y pair
function Graph:add_edge(x, y, edge)
	local x_adj = self:neighbors(x)
	if x_adj == nil then
		return errno.ENODE
	end
	x_adj[y] = edge
	return errno.ENONE
end

function Graph:remove_edge(x, y)
	local x_adj = self:neighbors(x)
	if x_adj == nil then
		return errno.ENONE
	end
	x_adj[y] = nil
	return errno.ENONE
end

local graph = {}
graph.errno = errno
graph.Edge = Edge
graph.Node = Node
graph.Graph = Graph
return graph
