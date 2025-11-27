# GatherMate2ZoneTracker
Tracks visited zones with MapID for GatherMate2 Storage configuration

GatherMate2 Zone Tracker is an in-game WoW addon that automatically tracks all visited zones with
their UIMap IDs and provides them in a format ready for configuring GatherMate2 Storage TOC files.

  Purpose

  The addon solves a specific problem when creating GatherMate2 Storage addons: manually determining
   the correct UIMap IDs for X-GM2-Storage-Zones TOC entries. Instead of tediously looking up zone
  IDs from API documentation, the addon automatically tracks all visited areas during gameplay.

  Main Features
  Automatic Zone Tracking
  - Captures every zone automatically when entered
  - Saves UIMap ID, zone name, parent zone, and additional metadata
  - Automatically categorizes zones by expansion (Classic through Midnight)
  - No manual input required

  Intelligent Expansion Detection
  - Uses parent map chain walking for expansion assignment
  - Fallback to UIMap ID ranges for unambiguous classification
  - Supports all expansions from Classic (0) to Midnight (11)
  - Sorted output by expansion for better overview

  TOC Export Function
  - /gm2zones export outputs all zone IDs in TOC-compatible format
  - Automatic sorting of IDs for consistent TOC files
  - Saves time when creating new Storage addons

  Management Commands
  - /gm2zones - Shows all tracked zones with details
  - /gm2zones export - Exports zone IDs in TOC format
  - /gm2zones clear - Clears the saved data

  Usage
  1. Enable addon: Simply install in AddOns folder
  2. Visit zones: Play normally and visit all relevant areas of an expansion
  3. Export: Run /gm2zones export
  4. Copy: Paste the output zone IDs directly into your Storage TOC file

  Example Output /gm2zones export  
  <img width="609" height="140" alt="image" src="https://github.com/user-attachments/assets/58447c32-2abc-4b53-866c-0eae9ff9d5e5" />
 

  This output can be used directly as the ## X-GM2-Storage-Zones: value in GatherMate2 Storage TOC
  files.

  Technical Details
  - Event-based tracking: ZONE_CHANGED_NEW_AREA, ZONE_CHANGED, ZONE_CHANGED_INDOORS
  - SavedVariable: GM2ZoneTrackerDB (persistent storage between sessions)
  - No performance impact: Only active during zone changes
  - Compatible with Retail and Midnight Beta clients

  The addon is particularly useful for developers of GatherMate2 Storage addons and for maintaining
  existing TOC files during patch updates.

