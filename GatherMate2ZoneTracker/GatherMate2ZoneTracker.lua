-- GatherMate2 Zone Tracker
-- Tracks visited zones with MapID for Storage configuration
-- Now with Coordinate Display!

local AddonName = "GatherMate2ZoneTracker"
local GM2ZT = LibStub("AceAddon-3.0"):NewAddon(AddonName, "AceEvent-3.0")

-- Expansion ID to name mapping
local expansionNames = {
	[1] = "01_Classic",
	[2] = "02_BurningCrusade",
	[3] = "03_WrathOfTheLichKing",
	[4] = "04_Cataclysm",
	[5] = "05_MistsOfPandaria",
	[6] = "06_WarlordsOfDraenor",
	[7] = "07_Legion",
	[8] = "08_BattleForAzeroth",
	[9] = "09_Shadowlands",
	[10] = "10_Dragonflight",
	[11] = "11_TheWarWithin",
	[12] = "12_Midnight",
}

-- Default settings
local defaults = {
	profile = {
		coordFrame = {
			enabled = true,
			point = "CENTER",
			x = 0,
			y = 0,
		},
	},
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
			if currentID >= 2393 and currentID <= 2600 then return 12 end -- Midnight
			if currentID >= 2200 and currentID <= 2392 then return 11 end -- TWW
			if currentID >= 1978 and currentID <= 2199 then return 10 end -- DF
			if currentID >= 1550 and currentID <= 1977 then return 9 end -- SL
			if currentID >= 1355 and currentID <= 1549 then return 8 end -- BfA
			if currentID >= 619 and currentID <= 1354 then return 7 end -- Legion
			if currentID >= 525 and currentID <= 618 then return 6 end -- WoD
			if currentID >= 371 and currentID <= 524 then return 5 end -- MoP
			if currentID >= 174 and currentID <= 370 then return 4 end -- Cata
			if currentID >= 113 and currentID <= 173 then return 3 end -- WotLK
			if currentID >= 94 and currentID <= 112 then return 2 end -- BC
			if currentID >= 1 and currentID <= 93 then return 1 end -- Classic
		end

		currentID = info.parentMapID
	end

	-- Fallback: use map ID ranges directly
	if mapID >= 2393 then return 12 end -- Midnight
	if mapID >= 2200 then return 11 end -- TWW
	if mapID >= 1978 then return 10 end -- DF
	if mapID >= 1550 then return 9 end -- SL
	if mapID >= 1355 then return 8 end -- BfA
	if mapID >= 619 then return 7 end -- Legion
	if mapID >= 525 then return 6 end -- WoD
	if mapID >= 371 then return 5 end -- MoP
	if mapID >= 174 then return 4 end -- Cata
	if mapID >= 113 then return 3 end -- WotLK
	if mapID >= 94 then return 2 end -- BC
	return 1 -- Classic
end

function GM2ZT:TrackZone()
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

-- ========================================
-- Coordinate Display Frame
-- ========================================

function GM2ZT:CreateCoordFrame()
	local frame = CreateFrame("Frame", "GM2ZT_CoordFrame", UIParent, "BackdropTemplate")
	frame:SetSize(120, 62) -- Increased height for ID visibility
	frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

	-- Backdrop similar to the screenshot
	frame:SetBackdrop({
		bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 }
	})
	frame:SetBackdropColor(0, 0, 0, 0.8)
	frame:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)

	-- Make it movable
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, _, x, y = self:GetPoint()
		GM2ZT.db.profile.coordFrame.point = point
		GM2ZT.db.profile.coordFrame.x = x
		GM2ZT.db.profile.coordFrame.y = y
	end)

	-- Coordinates text (like "56.4, 29.8")
	frame.coordText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	frame.coordText:SetPoint("TOP", frame, "TOP", 0, -6)
	frame.coordText:SetTextColor(1, 0.82, 0) -- Gold color
	frame.coordText:SetText("0.00, 0.00")

	-- Map name
	frame.mapText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	frame.mapText:SetPoint("TOP", frame.coordText, "BOTTOM", 0, -3)
	frame.mapText:SetTextColor(1, 1, 1)
	frame.mapText:SetText("Unknown")
	frame.mapText:SetWordWrap(false)

	-- MapID
	frame.mapIDText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	frame.mapIDText:SetPoint("TOP", frame.mapText, "BOTTOM", 0, -2)
	frame.mapIDText:SetTextColor(0.7, 0.7, 0.7)
	frame.mapIDText:SetText("ID: 0")

	self.coordFrame = frame

	-- Restore saved position
	local cfg = self.db.profile.coordFrame
	frame:ClearAllPoints()
	frame:SetPoint(cfg.point, UIParent, cfg.point, cfg.x, cfg.y)

	-- Show/hide based on settings
	if cfg.enabled then
		frame:Show()
	else
		frame:Hide()
	end
end

function GM2ZT:UpdateCoordinates()
	if not self.coordFrame then return end

	local mapID = C_Map.GetBestMapForUnit("player")
	if not mapID then
		self.coordFrame.coordText:SetText("--.--, --.--")
		self.coordFrame.mapText:SetText("No Map")
		self.coordFrame.mapIDText:SetText("ID: --")
		self:ResizeCoordFrame()
		return
	end

	local position = C_Map.GetPlayerMapPosition(mapID, "player")
	if position then
		local x, y = position:GetXY()
		x = x * 100
		y = y * 100
		self.coordFrame.coordText:SetText(string.format("%.2f, %.2f", x, y))
	else
		self.coordFrame.coordText:SetText("--.--, --.--")
	end

	local mapInfo = C_Map.GetMapInfo(mapID)
	if mapInfo then
		self.coordFrame.mapText:SetText(mapInfo.name or "Unknown")
	else
		self.coordFrame.mapText:SetText("Unknown")
	end

	self.coordFrame.mapIDText:SetText(string.format("ID: %d", mapID))

	-- Dynamically resize frame based on content
	self:ResizeCoordFrame()
end

function GM2ZT:ResizeCoordFrame()
	if not self.coordFrame then return end

	local frame = self.coordFrame
	local padding = 16 -- Left + Right padding

	-- Get text widths
	local coordWidth = frame.coordText:GetStringWidth()
	local mapWidth = frame.mapText:GetStringWidth()
	local idWidth = frame.mapIDText:GetStringWidth()

	-- Find the maximum width
	local maxWidth = math.max(coordWidth, mapWidth, idWidth)

	-- Set minimum width and add padding
	local newWidth = math.max(100, maxWidth + padding)

	-- Update frame size (keep height at 62)
	frame:SetSize(newWidth, 62)
end

-- ========================================
-- Export Frame
-- ========================================

function GM2ZT:CreateExportFrame()
	if self.exportFrame then
		return self.exportFrame
	end

	local frame = CreateFrame("Frame", "GM2ZT_ExportFrame", UIParent, "BackdropTemplate")
	frame:SetSize(700, 600)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetFrameLevel(100)

	frame:SetBackdrop({
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 }
	})
	frame:SetBackdropColor(0, 0, 0, 1)

	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()

	-- Title
	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	title:SetPoint("TOP", 0, -16)
	title:SetText("GM2 Zone Tracker - Export for TOC")

	-- ScrollFrame for the text
	local scrollFrame = CreateFrame("ScrollFrame", "GM2ZT_ExportScrollFrame", frame, "UIPanelScrollFrameTemplate")
	scrollFrame:SetPoint("TOPLEFT", 16, -45)
	scrollFrame:SetPoint("BOTTOMRIGHT", -32, 55)

	-- EditBox for the content
	local editBox = CreateFrame("EditBox", "GM2ZT_ExportEditBox", scrollFrame)
	editBox:SetMultiLine(true)
	editBox:SetAutoFocus(false)
	editBox:SetMaxLetters(0)
	editBox:SetFontObject(ChatFontNormal)
	editBox:SetWidth(650)

	-- Enable text selection
	editBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)

	scrollFrame:SetScrollChild(editBox)

	-- Select All button
	local selectAllBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	selectAllBtn:SetSize(120, 25)
	selectAllBtn:SetPoint("BOTTOMLEFT", 16, 16)
	selectAllBtn:SetText("Select All")
	selectAllBtn:SetScript("OnClick", function()
		editBox:SetFocus()
		editBox:HighlightText()
	end)

	-- Close button
	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
	closeBtn:SetSize(80, 25)
	closeBtn:SetPoint("BOTTOMRIGHT", -16, 16)
	closeBtn:SetText("Close")
	closeBtn:SetScript("OnClick", function()
		editBox:ClearFocus()
		frame:Hide()
	end)

	frame.editBox = editBox
	frame.scrollFrame = scrollFrame
	self.exportFrame = frame

	return frame
end

function GM2ZT:ShowExportData()
	print("|cFF00FF00GM2 ZoneTracker:|r Export function called...")

	local frame = self:CreateExportFrame()
	if not frame then
		print("|cFFFF0000GM2 ZoneTracker:|r Failed to create export frame!")
		return
	end

	-- Check if database has data
	if not GM2ZoneTrackerDB or not next(GM2ZoneTrackerDB) then
		print("|cFFFF0000GM2 ZoneTracker:|r No zones tracked yet!")
		frame.editBox:SetText("No zones tracked yet!\n\nVisit some zones first, then use /gm2zones export again.")
		frame.editBox:SetHeight(200)
		frame.editBox:SetCursorPosition(0)
		frame:Show()
		return
	end

	print("|cFF00FF00GM2 ZoneTracker:|r Building export data...")

	local output = {}

	-- Sort expansions
	local sortedExpansions = {}
	for expansion in pairs(GM2ZoneTrackerDB) do
		table.insert(sortedExpansions, expansion)
	end
	table.sort(sortedExpansions)

	print(string.format("|cFF00FF00GM2 ZoneTracker:|r Found %d expansions", #sortedExpansions))

	-- Header
	table.insert(output, "==============================================")
	table.insert(output, "GM2 ZONE TRACKER EXPORT FOR TOC FILE")
	table.insert(output, "==============================================")
	table.insert(output, "")
	table.insert(output, "Copy the X-GM2-Storage-Zones lines below into your TOC file.")
	table.insert(output, "")

	-- Generate TOC format
	for _, expansion in ipairs(sortedExpansions) do
		local zones = GM2ZoneTrackerDB[expansion]

		-- Collect and sort IDs
		local sortedIDs = {}
		for mapID in pairs(zones) do
			table.insert(sortedIDs, mapID)
		end
		table.sort(sortedIDs)

		-- X-GM2-Storage-Zones line
		local idsString = table.concat(sortedIDs, ", ")
		table.insert(output, string.format("## X-GM2-Storage-Zones-%s: %s", expansion, idsString))
	end

	table.insert(output, "")
	table.insert(output, "==============================================")
	table.insert(output, "ZONE DETAILS (FOR NOTES)")
	table.insert(output, "==============================================")
	table.insert(output, "")

	-- Zone details for notes
	for _, expansion in ipairs(sortedExpansions) do
		local zones = GM2ZoneTrackerDB[expansion]
		table.insert(output, "")
		table.insert(output, string.format("=== %s ===", expansion))

		-- Sort by MapID
		local sortedIDs = {}
		for mapID in pairs(zones) do
			table.insert(sortedIDs, mapID)
		end
		table.sort(sortedIDs)

		for _, mapID in ipairs(sortedIDs) do
			local zone = zones[mapID]
			table.insert(output, string.format("  %d: %s (Parent: %s [%s])",
				mapID, zone.name or "Unknown", zone.parent or "None", tostring(zone.parentID or "nil")))
		end
	end

	table.insert(output, "")
	table.insert(output, "==============================================")

	local fullText = table.concat(output, "\n")
	local editBox = frame.editBox

	-- Calculate height based on number of lines
	local numLines = #output
	local lineHeight = 14
	local textHeight = math.max(500, numLines * lineHeight)

	print(string.format("|cFF00FF00GM2 ZoneTracker:|r Setting text: %d lines, %d characters, height: %d", numLines, #fullText, textHeight))

	-- Set the text
	editBox:SetText(fullText)
	editBox:SetHeight(textHeight)
	editBox:SetCursorPosition(0)

	print("|cFF00FF00GM2 ZoneTracker:|r Text set successfully. Showing frame...")

	frame:Show()

	print("|cFF00FF00GM2 ZoneTracker:|r Export window opened! Use 'Select All' button or click in the box and press CTRL+A, then CTRL+C to copy.")
end

-- ========================================
-- Options Panel
-- ========================================

function GM2ZT:SetupOptions()
	local options = {
		type = "group",
		name = "GatherMate2 Zone Tracker",
		args = {
			header = {
				type = "header",
				name = "Coordinate Display Settings",
				order = 1,
			},
			enable = {
				type = "toggle",
				name = "Enable Coordinate Display",
				desc = "Show/hide the coordinate display frame",
				get = function() return self.db.profile.coordFrame.enabled end,
				set = function(_, value)
					self.db.profile.coordFrame.enabled = value
					if value then
						self.coordFrame:Show()
					else
						self.coordFrame:Hide()
					end
				end,
				order = 2,
			},
			reset = {
				type = "execute",
				name = "Reset Position",
				desc = "Reset coordinate frame to center of screen",
				func = function()
					self.coordFrame:ClearAllPoints()
					self.coordFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
					self.db.profile.coordFrame.point = "CENTER"
					self.db.profile.coordFrame.x = 0
					self.db.profile.coordFrame.y = 0
				end,
				order = 3,
			},
		},
	}

	LibStub("AceConfig-3.0"):RegisterOptionsTable("GM2ZoneTracker", options)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GM2ZoneTracker", "GM2 Zone Tracker")
end

-- ========================================
-- Addon Initialization
-- ========================================

function GM2ZT:OnInitialize()
	-- Setup database
	self.db = LibStub("AceDB-3.0"):New("GM2ZoneTrackerDB", defaults, true)

	-- Setup options
	self:SetupOptions()
end

function GM2ZT:OnEnable()
	-- Register events
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "TrackZone")
	self:RegisterEvent("ZONE_CHANGED", "TrackZone")
	self:RegisterEvent("ZONE_CHANGED_INDOORS", "TrackZone")

	-- Create coordinate frame
	self:CreateCoordFrame()

	-- Start update timer (0.1 second updates)
	self.updateTimer = C_Timer.NewTicker(0.1, function()
		self:UpdateCoordinates()
	end)

	-- Track initial zone
	self:TrackZone()

	print("|cFF00FF00GM2 ZoneTracker:|r Loaded. Type |cFFFFD200/gm2zones|r to list zones.")
end

-- ========================================
-- Slash Commands
-- ========================================

SLASH_GM2ZONES1 = "/gm2zones"
SlashCmdList["GM2ZONES"] = function(msg)
	if msg == "clear" then
		GM2ZoneTrackerDB = {}
		print("|cFF00FF00GM2 ZoneTracker:|r Database cleared!")
		return
	end

	if msg == "export" then
		local success, err = pcall(function()
			GM2ZT:ShowExportData()
		end)
		if not success then
			print("|cFFFF0000GM2 ZoneTracker Error:|r " .. tostring(err))
		end
		return
	end

	if msg == "config" or msg == "options" then
		InterfaceOptionsFrame_OpenToCategory("GM2 Zone Tracker")
		InterfaceOptionsFrame_OpenToCategory("GM2 Zone Tracker")
		return
	end

	print("|cFF00FF00GM2 ZoneTracker:|r Tracked Zones")
	print("Use |cFFFFD200/gm2zones export|r to get TOC format")
	print("Use |cFFFFD200/gm2zones clear|r to reset")
	print("Use |cFFFFD200/gm2zones config|r to open settings")
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
