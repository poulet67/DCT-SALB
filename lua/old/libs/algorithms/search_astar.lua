--[[
-- SPDX-License-Identifier: LGPL-3.0
--
-- Defines an A* search algorithm
--]]

local check = require("libs.check")
local PriorityQueue = require("libs.containers.pqueue")
local Queue = require("libs.containers.queue")

local function search_astar(graph, start, goal, heuristic)
	-- check inputs
	check.func(heuristic)
	local frontier = PriorityQueue()
	local from = { [start] = true, }
	local cost = { [start] = 0, }

	frontier:push(0, start)
	while not frontier:empty() do
		local current = frontier:pop()

		if current == goal then
			break
		end

		for node, edge in pairs(graph:neighbors(current) or {}) do
			local newcost = cost[current] + edge:cost()
			if cost[node] == nil or newcost < cost[node] then
				cost[node] = newcost
				local prio = newcost + heuristic(node, goal)
				frontier:push(prio, node)
				from[node] = current
			end
		end
	end

	local path = Queue()
	current = goal
	while from[current] ~= nil do
		path:pushhead(current)
		current = from[current]
	end
	return path, cost[goal]
end

return search_astar
