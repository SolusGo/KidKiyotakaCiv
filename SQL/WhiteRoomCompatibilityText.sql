-- White Room compatibility text fallbacks.
-- Some CP/EUI city-view builds can show raw TXT_KEY labels if these keys are
-- missing from the active localization set. Keep these as non-overriding
-- fallbacks so the UI remains readable without replacing another mod's text.

INSERT OR IGNORE INTO Language_en_US (Tag, Text)
VALUES
('TXT_KEY_CITYVIEW_HAPPINESS_TEXT', 'Happiness'),
('TXT_KEY_CITYVIEW_UNHAPPINESS_TEXT', 'Unhappiness'),
('TXT_KEY_BUILDING_WR_DUMMY_HIDDEN', 'White Room Hidden Counter'),
('TXT_KEY_WR_CP_TOOLTIP_FALLBACK', 'Hidden Counter');

-- CP/EUI tooltip builders assume every grouped game object has a Description.
-- Some enabled civ mods leave hidden counter buildings/classes blank, which can
-- abort the research panel update while CP is building tech/building tooltips.
UPDATE Resources
SET Description = 'TXT_KEY_WR_CP_TOOLTIP_FALLBACK'
WHERE Description IS NULL OR Description = '';

UPDATE Features
SET Description = 'TXT_KEY_WR_CP_TOOLTIP_FALLBACK'
WHERE Description IS NULL OR Description = '';

UPDATE Terrains
SET Description = 'TXT_KEY_WR_CP_TOOLTIP_FALLBACK'
WHERE Description IS NULL OR Description = '';

UPDATE Plots
SET Description = 'TXT_KEY_WR_CP_TOOLTIP_FALLBACK'
WHERE Description IS NULL OR Description = '';

UPDATE Specialists
SET Description = 'TXT_KEY_WR_CP_TOOLTIP_FALLBACK'
WHERE Description IS NULL OR Description = '';

UPDATE Improvements
SET Description = 'TXT_KEY_WR_CP_TOOLTIP_FALLBACK'
WHERE Description IS NULL OR Description = '';

UPDATE BuildingClasses
SET Description = 'TXT_KEY_WR_CP_TOOLTIP_FALLBACK'
WHERE Description IS NULL OR Description = '';

UPDATE Buildings
SET Description = 'TXT_KEY_WR_CP_TOOLTIP_FALLBACK'
WHERE Description IS NULL OR Description = '';

-- Arendelle's United Republic of Nations writes AURONTRAIT instead of its
-- actual dummy building type. CP's research tooltip resolves BuildingType
-- values as building IDs, so the malformed rows abort the entire tech panel.
-- Repair the known typo first so that mod keeps its intended yield effects.
UPDATE Building_BuildingClassYieldChanges
SET BuildingType = 'BUILDING_AURONTRAIT'
WHERE BuildingType = 'AURONTRAIT'
  AND EXISTS (
      SELECT 1
      FROM Buildings
      WHERE Type = 'BUILDING_AURONTRAIT'
  );

-- CP assumes every BuildingType in this base-game table resolves to a real
-- building. Discard only orphaned references left by enabled content mods.
DELETE FROM Building_BuildingClassYieldChanges
WHERE BuildingType IS NULL
   OR NOT EXISTS (
       SELECT 1
       FROM Buildings
       WHERE Buildings.Type = Building_BuildingClassYieldChanges.BuildingType
   );

-- Keep White Room dummy buildings out of CP/EUI CityView lists. These buildings
-- are mechanical counters only and should not appear as city buildings,
-- specialist containers, great-work buildings, or production entries.
UPDATE BuildingClasses
SET Description = 'TXT_KEY_BUILDING_WR_DUMMY_HIDDEN'
WHERE Type GLOB 'BUILDINGCLASS_WR_*';

UPDATE Buildings
SET Description = 'TXT_KEY_BUILDING_WR_DUMMY_HIDDEN',
    Civilopedia = 'TXT_KEY_BUILDING_WR_DUMMY_HIDDEN',
    Strategy = 'TXT_KEY_BUILDING_WR_DUMMY_HIDDEN',
    Help = 'TXT_KEY_BUILDING_WR_DUMMY_HIDDEN',
    IconAtlas = 'WR_WHITE_ROOM_ICON_ATLAS',
    PortraitIndex = 0,
    GreatWorkCount = -1,
    NeverCapture = 1,
    NukeImmune = 1,
    HurryCostModifier = -1,
    ConquestProb = 0,
    ShowInPedia = 0,
    IsDummy = 1
WHERE Type GLOB 'BUILDING_WR_*';
