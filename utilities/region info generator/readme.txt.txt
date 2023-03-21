-- CONFIG REGION

-- Allows user to create a data structure that defines a region (polygon) on the F-10 map

-- 

-- Format
-- R - Region info
-- R:1
-- name:Example Name assigns region 1 the name "Example Name" (optional)
-- 
-- 
-- 																
-- V - vertices followed by which region it belongs to and which vertice this is
-- EG:
-- V:1,1
-- V:1,2
-- V:1,3
-- V:1,4
-- Vertices must be specified in clockwise order
--
--
--
-- FL: front line designated point, followed by which regions it connects EG:
-- FL:1,2
-- FL:1,3
--
-- FB: firebase, initializes a firebase in the region (WIP)
-- FARP: if there is a FARP at this FB
-- FB:1
-- FARP: true/false 
--
--
-- OM: Designates an off-map spawn (WIP)
-- name: name of spawn
-- shop: true/false <-- if this spawn will be linked to the shop
-- FARP: true
--
--
-- OOB - out of bounds region
-- OOB:5 (region 5 - must not conflict with regular regions)
-- V:5,1
-- V:5,2
-- V:5,3
-- V:5,4



--

-- Region definitions
--
-- DCS specific