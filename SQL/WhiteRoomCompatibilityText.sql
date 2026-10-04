-- White Room-owned CP/EUI compatibility only.
-- Never rewrite unrelated mod objects or delete temporarily orphaned links.
INSERT OR IGNORE INTO Language_en_US (Tag, Text)
VALUES
('TXT_KEY_BUILDING_WR_DUMMY_HIDDEN', 'White Room Hidden Counter'),
('TXT_KEY_WR_CP_TOOLTIP_FALLBACK', 'Hidden Counter');

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
WHERE (UnitClasses.DefaultUnit IS NULL
   OR UnitClasses.DefaultUnit = '')
  AND UnitClasses.Type IN (
      'UNITCLASS_WR_KIYOTAKA',
      'UNITCLASS_WR_FOURTH_GEN_OPERATIVE'
  )
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
