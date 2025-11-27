-- GatherMate2 Zone Tracker
-- Tracks visited zones with MapID for Storage configuration

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("ZONE_CHANGED")
frame:RegisterEvent("ZONE_CHANGED_INDOORS")

-- Expansion ID to name mapping
local expansionNames = {
	[0] = "00_Classic",
	[1] = "01_BurningCrusade",
	[2] = "02_WrathOfTheLichKing",
	[3] = "03_Cataclysm",
	[4] = "04_MistsOfPandaria",
	[5] = "05_WarlordsOfDraenor",
	[6] = "06_Legion",
	[7] = "07_BattleForAzeroth",
	[8] = "08_Shadowlands",
	[9] = "09_Dragonflight",
	[10] = "10_TheWarWithin",
	[11] = "11_Midnight",
}

-- Get expansion for a map
local function GetMapExpansion(mapID)
	if not mapID then return nil end

	-- Try to get expansion from map info
	local mapInfo = C_Map.GetMapInfo(mapID)
	if not mapInfo then return nil end

	-- Walk up the parent chain to find continent
	local currentID = mapID
	local visited = {}

	while currentID and not visited[currentID] do
		visited[currentID] = true
		local info = C_Map.GetMapInfo(currentID)
		if not info then break end

		-- Check if this is a continent or world map
		if info.mapType == Enum.UIMapType.Continent or info.mapType == Enum.UIMapType.World then
			-- Use map ID ranges to determine expansion
			if currentID >= 2393 and currentID <= 2600 then return 11 end -- Midnight
			if currentID >= 2200 and currentID <= 2392 then return 10 end -- TWW
			if currentID >= 1978 and currentID <= 2199 then return 9 end -- DF
			if currentID >= 1550 and currentID <= 1977 then return 8 end -- SL
			if currentID >= 1355 and currentID <= 1549 then return 7 end -- BfA
			if currentID >= 619 and currentID <= 1354 then return 6 end -- Legion
			if currentID >= 525 and currentID <= 618 then return 5 end -- WoD
			if currentID >= 371 and currentID <= 524 then return 4 end -- MoP
			if currentID >= 174 and currentID <= 370 then return 3 end -- Cata
			if currentID >= 94 and currentID <= 173 then return 1 end -- BC
			if currentID >= 1 and currentID <= 93 then return 0 end -- Classic
		end

		currentID = info.parentMapID
	end

	-- Fallback: use map ID ranges directly
	if mapID >= 2393 then return 11 end -- Midnight
	if mapID >= 2200 then return 10 end -- TWW
	if mapID >= 1978 then return 9 end -- DF
	if mapID >= 1550 then return 8 end -- SL
	if mapID >= 1355 then return 7 end -- BfA
	if mapID >= 619 then return 6 end -- Legion
	if mapID >= 525 then return 5 end -- WoD
	if mapID >= 371 then return 4 end -- MoP
	if mapID >= 174 then return 3 end -- Cata
	if mapID >= 94 then return 1 end -- BC
	return 0 -- Classic
end

local function TrackZone()
	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then return end

	local mapInfo = C_Map.GetMapInfo(mapID)
	if not mapInfo then return end

	local zoneName = mapInfo.name or "Unknown"
	local parentMapID = mapInfo.parentMapID
	local parentInfo = parentMapID and C_Map.GetMapInfo(parentMapID)
	local parentName = parentInfo and parentInfo.name or "None"
	local subZone = GetSubZoneText() or ""

	local expansionID = GetMapExpansion(mapID)
	local expansionName = expansionNames[expansionID] or "99_Unknown"

	-- Initialize DB
	GM2ZoneTrackerDB = GM2ZoneTrackerDB or {}
	GM2ZoneTrackerDB[expansionName] = GM2ZoneTrackerDB[expansionName] or {}

	-- Create entry
	local entry = {
		name = zoneName,
		parent = parentName,
		parentID = parentMapID,
		subZone = subZone,
		mapType = mapInfo.mapType,
	}

	-- Only add if not already tracked
	if not GM2ZoneTrackerDB[expansionName][mapID] then
		GM2ZoneTrackerDB[expansionName][mapID] = entry
		print(string.format("|cFF00FF00GM2 ZoneTracker:|r New zone! |cFFFFD200%s|r [%d] in %s", zoneName, mapID, expansionName))
	end
end

frame:SetScript("OnEvent", function(self, event)
	if event == "PLAYER_LOGIN" then
		GM2ZoneTrackerDB = GM2ZoneTrackerDB or {}
		print("|cFF00FF00GM2 ZoneTracker:|r Loaded. Type |cFFFFD200/gm2zones|r to list all tracked zones.")
		TrackZone()
	else
		TrackZone()
	end
end)

-- Slash command to show zones
SLASH_GM2ZONES1 = "/gm2zones"
SlashCmdList["GM2ZONES"] = function(msg)
	if msg == "clear" then
		GM2ZoneTrackerDB = {}
		print("|cFF00FF00GM2 ZoneTracker:|r Database cleared!")
		return
	end

	if msg == "export" then
		-- Print in TOC format for easy copy
		print("|cFF00FF00GM2 ZoneTracker:|r Export for TOC files:")
		for expansion, zones in pairs(GM2ZoneTrackerDB) do
			local ids = {}
			for mapID in pairs(zones) do
				table.insert(ids, mapID)
			end
			table.sort(ids)
			print(string.format("|cFFFFD200%s:|r %s", expansion, table.concat(ids, ", ")))
		end
		return
	end

	print("|cFF00FF00GM2 ZoneTracker:|r Tracked Zones")
	print("Use |cFFFFD200/gm2zones export|r to get TOC format")
	print("Use |cFFFFD200/gm2zones clear|r to reset")
	print("")

	-- Sort expansions
	local sortedExpansions = {}
	for expansion in pairs(GM2ZoneTrackerDB) do
		table.insert(sortedExpansions, expansion)
	end
	table.sort(sortedExpansions)

	for _, expansion in ipairs(sortedExpansions) do
		local zones = GM2ZoneTrackerDB[expansion]
		print(string.format("|cFF00FFFF=== %s ===|r", expansion))

		-- Sort by MapID
		local sortedIDs = {}
		for mapID in pairs(zones) do
			table.insert(sortedIDs, mapID)
		end
		table.sort(sortedIDs)

		for _, mapID in ipairs(sortedIDs) do
			local zone = zones[mapID]
			print(string.format("  |cFFFFD200%d|r: %s (Parent: %s [%s])",
				mapID, zone.name, zone.parent, tostring(zone.parentID)))
		end
	end
end
