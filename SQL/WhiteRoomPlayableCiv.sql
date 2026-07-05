-- ============================================================================
-- White Room Kid Kiyotaka - Playable Civilization Placeholder
-- ============================================================================
-- This file intentionally uses existing Civilization V art references wherever
-- possible. It is a playable shell for testing Lua/database load order before
-- custom icons, units, balance, and real trait behavior are finished.

-- --------------------------------------------------------------------------
-- Colors
-- --------------------------------------------------------------------------

INSERT OR REPLACE INTO Colors (Type, Red, Green, Blue, Alpha)
VALUES
('COLOR_WR_WHITE_ROOM_PRIMARY',   0.88, 0.88, 0.92, 1),
('COLOR_WR_WHITE_ROOM_SECONDARY', 0.08, 0.10, 0.12, 1);

INSERT OR REPLACE INTO PlayerColors (Type, PrimaryColor, SecondaryColor, TextColor)
VALUES
('PLAYERCOLOR_WR_WHITE_ROOM', 'COLOR_WR_WHITE_ROOM_PRIMARY', 'COLOR_WR_WHITE_ROOM_SECONDARY', 'COLOR_PLAYER_WHITE_TEXT');

-- --------------------------------------------------------------------------
-- Art atlases
-- --------------------------------------------------------------------------

INSERT OR REPLACE INTO IconTextureAtlases (Atlas, IconSize, Filename, IconsPerRow, IconsPerColumn)
VALUES
('WR_KIYOTAKA_LEADER_ATLAS', 256, 'WR_Kiyotaka_Leader_256.dds', 1, 1),
('WR_KIYOTAKA_LEADER_ATLAS', 128, 'WR_Kiyotaka_Leader_128.dds', 1, 1),
('WR_KIYOTAKA_LEADER_ATLAS', 80,  'WR_Kiyotaka_Leader_80.dds',  1, 1),
('WR_KIYOTAKA_LEADER_ATLAS', 64,  'WR_Kiyotaka_Leader_64.dds',  1, 1),
('WR_KIYOTAKA_LEADER_ATLAS', 48,  'WR_Kiyotaka_Leader_48.dds',  1, 1),
('WR_KIYOTAKA_LEADER_ATLAS', 45,  'WR_Kiyotaka_Leader_45.dds',  1, 1),
('WR_KIYOTAKA_LEADER_ATLAS', 32,  'WR_Kiyotaka_Leader_32.dds',  1, 1),
('WR_KIYOTAKA_LEADER_ATLAS', 24,  'WR_Kiyotaka_Leader_24.dds',  1, 1),
('WR_WHITE_ROOM_ICON_ATLAS', 256, 'WR_WhiteRoom_Icon_256.dds', 1, 1),
('WR_WHITE_ROOM_ICON_ATLAS', 128, 'WR_WhiteRoom_Icon_128.dds', 1, 1),
('WR_WHITE_ROOM_ICON_ATLAS', 80,  'WR_WhiteRoom_Icon_80.dds',  1, 1),
('WR_WHITE_ROOM_ICON_ATLAS', 64,  'WR_WhiteRoom_Icon_64.dds',  1, 1),
('WR_WHITE_ROOM_ICON_ATLAS', 48,  'WR_WhiteRoom_Icon_48.dds',  1, 1),
('WR_WHITE_ROOM_ICON_ATLAS', 45,  'WR_WhiteRoom_Icon_45.dds',  1, 1),
('WR_WHITE_ROOM_ICON_ATLAS', 32,  'WR_WhiteRoom_Icon_32.dds',  1, 1),
('WR_WHITE_ROOM_ICON_ATLAS', 24,  'WR_WhiteRoom_Icon_24.dds',  1, 1),
('WR_WHITE_ROOM_ALPHA_ATLAS', 256, 'WR_WhiteRoom_Alpha_256.dds', 1, 1),
('WR_WHITE_ROOM_ALPHA_ATLAS', 128, 'WR_WhiteRoom_Alpha_128.dds', 1, 1),
('WR_WHITE_ROOM_ALPHA_ATLAS', 80,  'WR_WhiteRoom_Alpha_80.dds',  1, 1),
('WR_WHITE_ROOM_ALPHA_ATLAS', 64,  'WR_WhiteRoom_Alpha_64.dds',  1, 1),
('WR_WHITE_ROOM_ALPHA_ATLAS', 48,  'WR_WhiteRoom_Alpha_48.dds',  1, 1),
('WR_WHITE_ROOM_ALPHA_ATLAS', 45,  'WR_WhiteRoom_Alpha_45.dds',  1, 1),
('WR_WHITE_ROOM_ALPHA_ATLAS', 32,  'WR_WhiteRoom_Alpha_32.dds',  1, 1),
('WR_WHITE_ROOM_ALPHA_ATLAS', 24,  'WR_WhiteRoom_Alpha_24.dds',  1, 1),
('WR_KIYOTAKA_UNIT_ATLAS', 256, 'WR_Kiyotaka_Unit_256.dds', 1, 1),
('WR_KIYOTAKA_UNIT_ATLAS', 128, 'WR_Kiyotaka_Unit_128.dds', 1, 1),
('WR_KIYOTAKA_UNIT_ATLAS', 80,  'WR_Kiyotaka_Unit_80.dds',  1, 1),
('WR_KIYOTAKA_UNIT_ATLAS', 64,  'WR_Kiyotaka_Unit_64.dds',  1, 1),
('WR_KIYOTAKA_UNIT_ATLAS', 48,  'WR_Kiyotaka_Unit_48.dds',  1, 1),
('WR_KIYOTAKA_UNIT_ATLAS', 45,  'WR_Kiyotaka_Unit_45.dds',  1, 1),
('WR_KIYOTAKA_UNIT_ATLAS', 32,  'WR_Kiyotaka_Unit_32.dds',  1, 1),
('WR_KIYOTAKA_UNIT_ATLAS', 24,  'WR_Kiyotaka_Unit_24.dds',  1, 1),
('WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS', 256, 'WR_FourthGenOperative_Unit_256.dds', 1, 1),
('WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS', 128, 'WR_FourthGenOperative_Unit_128.dds', 1, 1),
('WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS', 80,  'WR_FourthGenOperative_Unit_80.dds',  1, 1),
('WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS', 64,  'WR_FourthGenOperative_Unit_64.dds',  1, 1),
('WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS', 48,  'WR_FourthGenOperative_Unit_48.dds',  1, 1),
('WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS', 45,  'WR_FourthGenOperative_Unit_45.dds',  1, 1),
('WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS', 32,  'WR_FourthGenOperative_Unit_32.dds',  1, 1),
('WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS', 24,  'WR_FourthGenOperative_Unit_24.dds',  1, 1);

-- --------------------------------------------------------------------------
-- Trait and leader
-- --------------------------------------------------------------------------

INSERT INTO Traits (Type, Description, ShortDescription)
VALUES
('TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM',
 'TXT_KEY_TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM',
 'TXT_KEY_TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM_SHORT');

INSERT INTO Leaders
    (Type, Description, Civilopedia, CivilopediaTag, ArtDefineTag,
     VictoryCompetitiveness, WonderCompetitiveness, MinorCivCompetitiveness,
     Boldness, DiploBalance, WarmongerHate, DenounceWillingness, DoFWillingness,
     Loyalty, Neediness, Forgiveness, Chattiness, Meanness, PortraitIndex, IconAtlas)
SELECT
    'LEADER_WR_KID_KIYOTAKA',
    'TXT_KEY_LEADER_WR_KID_KIYOTAKA',
    'TXT_KEY_LEADER_WR_KID_KIYOTAKA_PEDIA',
    'TXT_KEY_CIVILOPEDIA_LEADERS_WR_KID_KIYOTAKA',
    ArtDefineTag,
    VictoryCompetitiveness, WonderCompetitiveness, MinorCivCompetitiveness,
    Boldness, DiploBalance, WarmongerHate, DenounceWillingness, DoFWillingness,
    Loyalty, Neediness, Forgiveness, Chattiness, Meanness, PortraitIndex, IconAtlas
FROM Leaders
WHERE Type = 'LEADER_WASHINGTON';

INSERT INTO Leader_Traits (LeaderType, TraitType)
VALUES ('LEADER_WR_KID_KIYOTAKA', 'TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM');

UPDATE Leaders
SET IconAtlas = 'WR_KIYOTAKA_LEADER_ATLAS',
    PortraitIndex = 0
WHERE Type = 'LEADER_WR_KID_KIYOTAKA';

INSERT INTO Leader_MajorCivApproachBiases (LeaderType, MajorCivApproachType, Bias)
SELECT 'LEADER_WR_KID_KIYOTAKA', MajorCivApproachType, Bias
FROM Leader_MajorCivApproachBiases
WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Leader_MinorCivApproachBiases (LeaderType, MinorCivApproachType, Bias)
SELECT 'LEADER_WR_KID_KIYOTAKA', MinorCivApproachType, Bias
FROM Leader_MinorCivApproachBiases
WHERE LeaderType = 'LEADER_WASHINGTON';

INSERT INTO Leader_Flavors (LeaderType, FlavorType, Flavor)
SELECT 'LEADER_WR_KID_KIYOTAKA', FlavorType, Flavor
FROM Leader_Flavors
WHERE LeaderType = 'LEADER_WASHINGTON';

-- --------------------------------------------------------------------------
-- Civilization
-- --------------------------------------------------------------------------

INSERT INTO Civilizations
    (Type, Description, ShortDescription, Adjective, Civilopedia, CivilopediaTag,
     DefaultPlayerColor, ArtDefineTag, ArtStyleType, ArtStyleSuffix, ArtStylePrefix,
     IconAtlas, AlphaIconAtlas, PortraitIndex, MapImage, DawnOfManQuote, DawnOfManImage)
SELECT
    'CIVILIZATION_WHITE_ROOM_KID',
    'TXT_KEY_CIV_WR_WHITE_ROOM_DESC',
    'TXT_KEY_CIV_WR_WHITE_ROOM_SHORT_DESC',
    'TXT_KEY_CIV_WR_WHITE_ROOM_ADJECTIVE',
    'TXT_KEY_CIV_WR_WHITE_ROOM_PEDIA',
    'TXT_KEY_CIVILOPEDIA_CIVS_WR_WHITE_ROOM',
    'PLAYERCOLOR_WR_WHITE_ROOM',
    ArtDefineTag, ArtStyleType, ArtStyleSuffix, ArtStylePrefix,
    IconAtlas, AlphaIconAtlas, PortraitIndex,
    MapImage,
    'TXT_KEY_CIV5_DOM_WR_WHITE_ROOM_TEXT',
    DawnOfManImage
FROM Civilizations
WHERE Type = 'CIVILIZATION_AMERICA';

INSERT INTO Civilization_Leaders (CivilizationType, LeaderheadType)
VALUES ('CIVILIZATION_WHITE_ROOM_KID', 'LEADER_WR_KID_KIYOTAKA');

UPDATE Civilizations
SET IconAtlas = 'WR_WHITE_ROOM_ICON_ATLAS',
    AlphaIconAtlas = 'WR_WHITE_ROOM_ALPHA_ATLAS',
    PortraitIndex = 0,
    MapImage = 'WR_WhiteRoom_Map.dds',
    DawnOfManImage = 'WR_Kiyotaka_DOM.dds'
WHERE Type = 'CIVILIZATION_WHITE_ROOM_KID';

INSERT INTO Civilization_FreeBuildingClasses (CivilizationType, BuildingClassType)
VALUES ('CIVILIZATION_WHITE_ROOM_KID', 'BUILDINGCLASS_PALACE');

INSERT INTO Civilization_FreeTechs (CivilizationType, TechType)
VALUES ('CIVILIZATION_WHITE_ROOM_KID', 'TECH_AGRICULTURE');

INSERT INTO Civilization_FreeUnits (CivilizationType, UnitClassType, UnitAIType, Count)
VALUES
('CIVILIZATION_WHITE_ROOM_KID', 'UNITCLASS_SETTLER', 'UNITAI_SETTLE', 1),
('CIVILIZATION_WHITE_ROOM_KID', 'UNITCLASS_WARRIOR', 'UNITAI_ATTACK', 1);

INSERT INTO Civilization_Start_Region_Priority (CivilizationType, RegionType)
VALUES ('CIVILIZATION_WHITE_ROOM_KID', 'REGION_GRASS');

INSERT INTO Civilization_CityNames (CivilizationType, CityName)
VALUES
('CIVILIZATION_WHITE_ROOM_KID', 'TXT_KEY_CITY_NAME_WR_WHITE_ROOM'),
('CIVILIZATION_WHITE_ROOM_KID', 'TXT_KEY_CITY_NAME_WR_FOURTH_GENERATION'),
('CIVILIZATION_WHITE_ROOM_KID', 'TXT_KEY_CITY_NAME_WR_ADAPTATION_BLOCK'),
('CIVILIZATION_WHITE_ROOM_KID', 'TXT_KEY_CITY_NAME_WR_TRAINING_WING');

INSERT INTO Civilization_SpyNames (CivilizationType, SpyName)
VALUES
('CIVILIZATION_WHITE_ROOM_KID', 'TXT_KEY_SPY_NAME_WR_KIYOTAKA'),
('CIVILIZATION_WHITE_ROOM_KID', 'TXT_KEY_SPY_NAME_WR_INSTRUCTOR'),
('CIVILIZATION_WHITE_ROOM_KID', 'TXT_KEY_SPY_NAME_WR_OBSERVER');

-- --------------------------------------------------------------------------
-- Placeholder unique units
-- --------------------------------------------------------------------------

INSERT INTO UnitClasses (Type, Description, DefaultUnit)
VALUES
('UNITCLASS_WR_KIYOTAKA', 'TXT_KEY_UNIT_WR_KIYOTAKA', NULL),
('UNITCLASS_WR_FOURTH_GEN_OPERATIVE', 'TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE', NULL);

INSERT OR REPLACE INTO UnitPromotions
    (Type, Description, Help, CannotBeChosen, LostWithUpgrade,
     ExperiencePercent, FriendlyLandsModifier, AttackWoundedMod,
     PortraitIndex, IconAtlas, PediaType, PediaEntry, Sound)
VALUES
('PROMOTION_WR_DOUBLE_XP',
 'TXT_KEY_PROMOTION_WR_DOUBLE_XP',
 'TXT_KEY_PROMOTION_WR_DOUBLE_XP_HELP',
 1, 0, 100, 0, 0, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED',
 'TXT_KEY_PROMOTION_WR_DOUBLE_XP', 'AS2D_IF_LEVELUP'),
('PROMOTION_WR_FRIENDLY_TERRITORY',
 'TXT_KEY_PROMOTION_WR_FRIENDLY_TERRITORY',
 'TXT_KEY_PROMOTION_WR_FRIENDLY_TERRITORY_HELP',
 1, 0, 0, 15, 0, 59, 'ABILITY_ATLAS', 'PEDIA_SHARED',
 'TXT_KEY_PROMOTION_WR_FRIENDLY_TERRITORY', 'AS2D_IF_LEVELUP'),
('PROMOTION_WR_WOUNDED_TARGETS',
 'TXT_KEY_PROMOTION_WR_WOUNDED_TARGETS',
 'TXT_KEY_PROMOTION_WR_WOUNDED_TARGETS_HELP',
 1, 0, 0, 0, 33, 13, 'PROMOTION_ATLAS', 'PEDIA_MELEE',
 'TXT_KEY_PROMOTION_WR_WOUNDED_TARGETS', 'AS2D_IF_LEVELUP');

INSERT INTO Units
    (Type, Class, PrereqTech, Combat, Cost, Moves, CombatClass, Domain,
     DefaultUnitAI, Description, Civilopedia, Strategy, Help, UnitArtInfo,
     UnitFlagAtlas, UnitFlagIconOffset, PortraitIndex, IconAtlas)
SELECT
    'UNIT_WR_KIYOTAKA',
    'UNITCLASS_WR_KIYOTAKA',
    'TECH_ROBOTICS',
    120,
    900,
    Moves,
    CombatClass,
    Domain,
    DefaultUnitAI,
    'TXT_KEY_UNIT_WR_KIYOTAKA',
    'TXT_KEY_UNIT_WR_KIYOTAKA_PEDIA',
    'TXT_KEY_UNIT_WR_KIYOTAKA_STRATEGY',
    'TXT_KEY_UNIT_WR_KIYOTAKA_HELP',
    UnitArtInfo,
    UnitFlagAtlas,
    UnitFlagIconOffset,
    PortraitIndex,
    IconAtlas
FROM Units
WHERE Type = 'UNIT_XCOM_SQUAD';

INSERT INTO Units
    (Type, Class, PrereqTech, Combat, Cost, Moves, CombatClass, Domain,
     DefaultUnitAI, Description, Civilopedia, Strategy, Help, UnitArtInfo,
     UnitFlagAtlas, UnitFlagIconOffset, PortraitIndex, IconAtlas)
SELECT
    'UNIT_WR_FOURTH_GEN_OPERATIVE',
    'UNITCLASS_WR_FOURTH_GEN_OPERATIVE',
    'TECH_PLASTIC',
    85,
    520,
    Moves,
    CombatClass,
    Domain,
    DefaultUnitAI,
    'TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE',
    'TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE_PEDIA',
    'TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE_STRATEGY',
    'TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE_HELP',
    UnitArtInfo,
    UnitFlagAtlas,
    UnitFlagIconOffset,
    PortraitIndex,
    IconAtlas
FROM Units
WHERE Type = 'UNIT_MARINE';

UPDATE Units
SET
    Combat = 130,
    Cost = 1200,
    FaithCost = -1,
    RequiresFaithPurchaseEnabled = 0,
    HurryCostModifier = -1,
    Moves = 3,
    BaseSightRange = 2,
    ExtraMaintenanceCost = 8,
    MilitarySupport = 1,
    MilitaryProduction = 1,
    Pillage = 1,
    PortraitIndex = 0,
    IconAtlas = 'WR_KIYOTAKA_UNIT_ATLAS',
    GoodyHutUpgradeUnitClass = NULL
WHERE Type = 'UNIT_WR_KIYOTAKA';

UPDATE Units
SET
    Combat = 85,
    Cost = 650,
    FaithCost = -1,
    RequiresFaithPurchaseEnabled = 0,
    HurryCostModifier = -1,
    Moves = 2,
    BaseSightRange = 2,
    ExtraMaintenanceCost = 4,
    MilitarySupport = 1,
    MilitaryProduction = 1,
    Pillage = 1,
    PortraitIndex = 0,
    IconAtlas = 'WR_FOURTH_GEN_OPERATIVE_UNIT_ATLAS',
    GoodyHutUpgradeUnitClass = NULL
WHERE Type = 'UNIT_WR_FOURTH_GEN_OPERATIVE';

INSERT INTO Civilization_UnitClassOverrides (CivilizationType, UnitClassType, UnitType)
VALUES
('CIVILIZATION_WHITE_ROOM_KID', 'UNITCLASS_WR_KIYOTAKA', 'UNIT_WR_KIYOTAKA'),
('CIVILIZATION_WHITE_ROOM_KID', 'UNITCLASS_WR_FOURTH_GEN_OPERATIVE', 'UNIT_WR_FOURTH_GEN_OPERATIVE');

INSERT INTO Unit_AITypes (UnitType, UnitAIType)
VALUES
('UNIT_WR_KIYOTAKA', 'UNITAI_ATTACK'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'UNITAI_ATTACK');

INSERT INTO Unit_Flavors (UnitType, FlavorType, Flavor)
VALUES
('UNIT_WR_KIYOTAKA', 'FLAVOR_OFFENSE', 50),
('UNIT_WR_KIYOTAKA', 'FLAVOR_DEFENSE', 35),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'FLAVOR_OFFENSE', 25),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'FLAVOR_DEFENSE', 20);

INSERT INTO Unit_FreePromotions (UnitType, PromotionType)
VALUES
('UNIT_WR_KIYOTAKA', 'PROMOTION_MARCH'),
('UNIT_WR_KIYOTAKA', 'PROMOTION_BLITZ'),
('UNIT_WR_KIYOTAKA', 'PROMOTION_DRILL_1'),
('UNIT_WR_KIYOTAKA', 'PROMOTION_SHOCK_1'),
('UNIT_WR_KIYOTAKA', 'PROMOTION_COVER_1'),
('UNIT_WR_KIYOTAKA', 'PROMOTION_MEDIC'),
('UNIT_WR_KIYOTAKA', 'PROMOTION_SURVIVALISM_1'),
('UNIT_WR_KIYOTAKA', 'PROMOTION_IGNORE_TERRAIN_COST'),
('UNIT_WR_KIYOTAKA', 'PROMOTION_WR_DOUBLE_XP'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'PROMOTION_MARCH'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'PROMOTION_DRILL_1'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'PROMOTION_SHOCK_1'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'PROMOTION_COVER_1'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'PROMOTION_IGNORE_TERRAIN_COST'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'PROMOTION_WR_DOUBLE_XP'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'PROMOTION_WR_FRIENDLY_TERRITORY'),
('UNIT_WR_FOURTH_GEN_OPERATIVE', 'PROMOTION_WR_WOUNDED_TARGETS');

-- --------------------------------------------------------------------------
-- Text
-- --------------------------------------------------------------------------

INSERT INTO Language_en_US (Tag, Text)
VALUES
('TXT_KEY_TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM', 'The Masterpiece of the White Room'),
('TXT_KEY_TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM_SHORT', 'Masterpiece of the White Room'),
('TXT_KEY_TRAIT_WR_MASTERPIECE_OF_THE_WHITE_ROOM_HELP', 'Cannot found new cities after the starting capital, but may annex conquered cities. White Room cities and units permanently learn from repeated worked improvements, trade routes, city damage, city ranged strikes, captured cities, and Kiyotaka''s combat experience.'),

('TXT_KEY_LEADER_WR_KID_KIYOTAKA', 'Kid Kiyotaka Ayanokoji'),
('TXT_KEY_LEADER_WR_KID_KIYOTAKA_PEDIA', 'A child raised inside the Fourth Generation White Room, Kiyotaka Ayanokoji is treated less as a person than as the program''s proof of concept. His civilization cannot spread through ordinary settlement. It expands by observing failure, absorbing captured cities, and converting every repeated pattern into permanent advantage.'),
('TXT_KEY_CIVILOPEDIA_LEADERS_WR_KID_KIYOTAKA', 'Kid Kiyotaka Ayanokoji'),

('TXT_KEY_CIV_WR_WHITE_ROOM_DESC', 'The Fourth Generation White Room'),
('TXT_KEY_CIV_WR_WHITE_ROOM_SHORT_DESC', 'White Room'),
('TXT_KEY_CIV_WR_WHITE_ROOM_ADJECTIVE', 'White Room'),
('TXT_KEY_CIV_WR_WHITE_ROOM_PEDIA', 'The Fourth Generation White Room is built around controlled adaptation. It begins from a single capital and cannot train or keep settlers, but every pressure point becomes data. Worked duplicate improvements sharpen city yields. Trade routes teach economic habits. Cities harden after taking damage and refine ranged strikes after firing. When another civilization or City-State loses a city, the White Room studies the collapse and improves its own city assault and defense. Kiyotaka Ayanokoji embodies the same doctrine on the battlefield, permanently scaling from kills, damage dealt, damage taken, and survival at the edge of defeat.'),
('TXT_KEY_CIVILOPEDIA_CIVS_WR_WHITE_ROOM', 'The Fourth Generation White Room'),
('TXT_KEY_CIV5_DOM_WR_WHITE_ROOM_TEXT', 'The doors close, and the lesson begins. You lead the Fourth Generation White Room, a civilization without frontiers in the ordinary sense. Your people will not scatter across the world with settlers and hopeful banners. They will remain controlled, severe, and observant, turning every repeated task, every failed siege, every captured city, and every trade connection into another layer of refinement.[NEWLINE][NEWLINE]At the center stands Kid Kiyotaka Ayanokoji, the quiet result of an education designed to remove weakness itself. Others grow through ambition, faith, or conquest. The White Room grows by understanding why others fail.[NEWLINE][NEWLINE]Build carefully. Annex what can be used. Let the world reveal its methods, then surpass them.'),

('TXT_KEY_CITY_NAME_WR_WHITE_ROOM', 'White Room'),
('TXT_KEY_CITY_NAME_WR_FOURTH_GENERATION', 'Fourth Generation'),
('TXT_KEY_CITY_NAME_WR_ADAPTATION_BLOCK', 'Adaptation Block'),
('TXT_KEY_CITY_NAME_WR_TRAINING_WING', 'Training Wing'),
('TXT_KEY_SPY_NAME_WR_KIYOTAKA', 'Kiyotaka'),
('TXT_KEY_SPY_NAME_WR_INSTRUCTOR', 'Instructor'),
('TXT_KEY_SPY_NAME_WR_OBSERVER', 'Observer'),

('TXT_KEY_UNIT_WR_KIYOTAKA', 'Kiyotaka Ayanokoji'),
('TXT_KEY_UNIT_WR_KIYOTAKA_HELP', 'Unique White Room super-unit unlocked at Robotics. Limited to one active copy. Cannot be purchased. Starts with March, Blitz, Drill I, Shock I, Cover I, Medic I, Survivalism I, Ignore Terrain Cost, and White Room Training. Perfect Adaptation permanently improves him from kills, damage dealt, damage taken, and low-HP survival.'),
('TXT_KEY_UNIT_WR_KIYOTAKA_STRATEGY', 'Kiyotaka is an extremely expensive late-game unit whose value comes from survival. Keep him active but alive: kills improve his combat strength and class-specific matchups, damage dealt improves his attack profile, damage taken improves his resistance, and surviving near death grants a larger adaptation burst.'),
('TXT_KEY_UNIT_WR_KIYOTAKA_PEDIA', 'Kiyotaka is the White Room masterpiece translated into a battlefield unit: singular, controlled, and terrifyingly adaptive. He is not meant to be mass-produced. He is meant to observe combat directly and become harder to answer each time an enemy fails to finish him.'),
('TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE', '4th Generation Operative'),
('TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE_HELP', 'Elite White Room infantry unit. Limited to three active copies. Cannot be purchased. Starts with Drill I, Shock I, March, Cover I, Ignore Terrain Cost, White Room double experience, a friendly-territory bonus, and a bonus against wounded units.'),
('TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE_STRATEGY', '4th Generation Operatives are expensive elite infantry unlocked at Plastics. Their cap is low, so use them as a small strike team: hold key terrain, punish wounded enemies, and exploit their double experience to build highly specialized veterans.'),
('TXT_KEY_UNIT_WR_FOURTH_GEN_OPERATIVE_PEDIA', '4th Generation Operatives represent the White Room''s training program expressed as military doctrine. They are few in number, costly to field, and unsuited to careless attrition. In the right hands they become a compact force of disciplined problem-solvers.'),
('TXT_KEY_PROMOTION_WR_DOUBLE_XP', 'White Room Training'),
('TXT_KEY_PROMOTION_WR_DOUBLE_XP_HELP', '+100% experience from combat.'),
('TXT_KEY_PROMOTION_WR_FRIENDLY_TERRITORY', 'Controlled Environment'),
('TXT_KEY_PROMOTION_WR_FRIENDLY_TERRITORY_HELP', '+15% combat strength in friendly territory.'),
('TXT_KEY_PROMOTION_WR_WOUNDED_TARGETS', 'Exploit Weakness'),
('TXT_KEY_PROMOTION_WR_WOUNDED_TARGETS_HELP', '+33% combat strength when attacking wounded units.');
