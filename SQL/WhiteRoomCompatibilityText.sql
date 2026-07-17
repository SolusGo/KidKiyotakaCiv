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

UPDATE Building_BuildingClassHappiness
SET BuildingType = 'BUILDING_AURONTRAIT'
WHERE BuildingType = 'AURONTRAIT'
  AND EXISTS (
      SELECT 1
      FROM Buildings
      WHERE Type = 'BUILDING_AURONTRAIT'
  );

UPDATE Building_BuildingClassLocalHappiness
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

DELETE FROM Building_BuildingClassHappiness
WHERE BuildingType IS NULL
   OR NOT EXISTS (
       SELECT 1
       FROM Buildings
       WHERE Buildings.Type = Building_BuildingClassHappiness.BuildingType
   );

DELETE FROM Building_BuildingClassLocalHappiness
WHERE BuildingType IS NULL
   OR NOT EXISTS (
       SELECT 1
       FROM Buildings
       WHERE Buildings.Type = Building_BuildingClassLocalHappiness.BuildingType
   );

-- CP's unit and technology tooltips assume every free-promotion reference
-- resolves to a real promotion. Invalid links cannot grant any gameplay effect,
-- but they can abort the research-panel refresh and leave stale technology UI.
DELETE FROM Unit_FreePromotions
WHERE PromotionType IS NULL
   OR NOT EXISTS (
       SELECT 1
       FROM UnitPromotions
       WHERE UnitPromotions.Type = Unit_FreePromotions.PromotionType
   );

-- CP's unique-unit tooltip indexes UnitClasses.DefaultUnit before checking the
-- result. Several custom civilizations, including White Room, use a NULL
-- default to make a unit class civilization-exclusive. Give those classes a
-- valid tooltip default, then explicitly disable the class for every civ that
-- did not already own an override so availability remains unchanged.
CREATE TEMP TABLE WR_CP_NullDefaultUnitClasses (
    UnitClassType TEXT PRIMARY KEY,
    DefaultUnitType TEXT NOT NULL
);

INSERT INTO WR_CP_NullDefaultUnitClasses (UnitClassType, DefaultUnitType)
SELECT UnitClasses.Type, MIN(Civilization_UnitClassOverrides.UnitType)
FROM UnitClasses
JOIN Civilization_UnitClassOverrides
  ON Civilization_UnitClassOverrides.UnitClassType = UnitClasses.Type
JOIN Units
  ON Units.Type = Civilization_UnitClassOverrides.UnitType
WHERE UnitClasses.DefaultUnit IS NULL
   OR UnitClasses.DefaultUnit = ''
GROUP BY UnitClasses.Type;

UPDATE UnitClasses
SET DefaultUnit = (
    SELECT WR_CP_NullDefaultUnitClasses.DefaultUnitType
    FROM WR_CP_NullDefaultUnitClasses
    WHERE WR_CP_NullDefaultUnitClasses.UnitClassType = UnitClasses.Type
)
WHERE Type IN (
    SELECT UnitClassType
    FROM WR_CP_NullDefaultUnitClasses
);

INSERT INTO Civilization_UnitClassOverrides
    (CivilizationType, UnitClassType, UnitType)
SELECT Civilizations.Type, WR_CP_NullDefaultUnitClasses.UnitClassType, NULL
FROM Civilizations
CROSS JOIN WR_CP_NullDefaultUnitClasses
WHERE NOT EXISTS (
    SELECT 1
    FROM Civilization_UnitClassOverrides
    WHERE Civilization_UnitClassOverrides.CivilizationType = Civilizations.Type
      AND Civilization_UnitClassOverrides.UnitClassType = WR_CP_NullDefaultUnitClasses.UnitClassType
);

DROP TABLE WR_CP_NullDefaultUnitClasses;

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
