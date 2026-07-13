-- White Room Community Patch compatibility fallbacks.
-- Some Community Patch city-view builds can show raw TXT_KEY labels if these keys are
-- missing from the active localization set.

INSERT OR IGNORE INTO Language_en_US (Tag, Text)
VALUES
('TXT_KEY_CITYVIEW_HAPPINESS_TEXT', 'Happiness'),
('TXT_KEY_CITYVIEW_UNHAPPINESS_TEXT', 'Unhappiness'),
('TXT_KEY_BUILDING_WR_DUMMY_HIDDEN', 'White Room Hidden Counter');

-- Keep White Room dummy buildings out of Community Patch CityView lists. These buildings
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
