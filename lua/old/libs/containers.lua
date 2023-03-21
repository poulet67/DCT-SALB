-- SPDX-License-Identifier: LGPL-3.0

local queue      = require("libs.containers.queue")
local pqueue     = require("libs.containers.pqueue")
local ringbuffer = require("libs.containers.ringbuffer")

local containers = {
	Queue         = queue,
	PriorityQueue = pqueue,
	RingBuffer    = ringbuffer,
}

return containers
