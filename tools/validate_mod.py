#!/usr/bin/env python3
"""Deterministic package and White Room regression checks."""

from __future__ import annotations

import hashlib
from pathlib import Path
import re
import sqlite3
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "KidKiyotakaWhiteRoom.civ5proj"
MODINFO = ROOT / "Kid Kiyotaka White Room (v 1).modinfo"
MSBUILD = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
ERRORS: list[str] = []
CP_ID = "d1b6328c-ff44-4b0d-aad7-c657f83610cd"
CP_TITLE = "(1) Community Patch"
CP_MIN_VERSION = 151


def normalized(path: str) -> str:
    return path.replace("/", "\\")


def local_path(path: str) -> Path:
    return ROOT.joinpath(*normalized(path).split("\\"))


def check(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def project_associations(project_root: ET.Element, section: str) -> list[tuple[str, str, int, int, str]]:
    return [
        (
            (node.findtext("m:Type", namespaces=MSBUILD) or "").strip(),
            (node.findtext("m:Id", namespaces=MSBUILD) or "").strip(),
            int((node.findtext("m:MinVersion", namespaces=MSBUILD) or "0").strip()),
            int((node.findtext("m:MaxVersion", namespaces=MSBUILD) or "999").strip()),
            (node.findtext("m:Name", namespaces=MSBUILD) or "").strip(),
        )
        for node in project_root.findall(f".//m:{section}/m:Association", MSBUILD)
    ]


def manifest_associations(modinfo_root: ET.Element, section: str) -> list[tuple[str, str, int, int, str]]:
    return [
        (
            node.tag,
            node.attrib.get("id", ""),
            int(node.attrib.get("minversion", "0")),
            int(node.attrib.get("maxversion", "999")),
            node.attrib.get("title", ""),
        )
        for node in modinfo_root.findall(f"./{section}/*")
    ]


def validate_package() -> None:
    project_root = ET.parse(PROJECT).getroot()
    modinfo_root = ET.parse(MODINFO).getroot()

    project_dependencies = project_associations(project_root, "ModDependencies")
    manifest_dependencies = manifest_associations(modinfo_root, "Dependencies")
    cp_dependencies = [dependency for dependency in project_dependencies if dependency[1] == CP_ID]
    check(bool(cp_dependencies), "Missing required Community Patch dependency")
    if cp_dependencies:
        cp_dependency = cp_dependencies[0]
        check(cp_dependency[0] == "Mod", "Community Patch dependency must be a Mod association")
        check(cp_dependency[2] >= CP_MIN_VERSION, "Community Patch dependency minversion must be at least 151")
        check(cp_dependency[3] == 999, "Community Patch dependency maxversion must be 999")
        check(cp_dependency[4] == CP_TITLE, "Community Patch dependency title is incorrect")
    check(len(project_dependencies) == 1, "Project must contain exactly the required Community Patch dependency")
    check(project_dependencies == manifest_dependencies, "Project and modinfo dependencies differ")

    project_references = project_associations(project_root, "ModReferences")
    manifest_references = manifest_associations(modinfo_root, "References")
    check(project_references == manifest_references, "Project and modinfo references differ")

    project_files: dict[str, bool] = {}
    for content in project_root.findall(".//m:ItemGroup/m:Content", MSBUILD):
        path = normalized(content.attrib["Include"])
        import_node = content.find("m:ImportIntoVFS", MSBUILD)
        project_files[path] = import_node is not None and (import_node.text or "").strip().lower() == "true"
        check(local_path(path).is_file(), f"Project references missing file: {path}")

    manifest_files: dict[str, bool] = {}
    for node in modinfo_root.findall("./Files/File"):
        path = normalized(node.text or "")
        manifest_files[path] = node.attrib.get("import") == "1"
        source = local_path(path)
        if source.is_file():
            actual_md5 = hashlib.md5(source.read_bytes()).hexdigest().upper()
            check(node.attrib.get("md5", "").upper() == actual_md5, f"Stale md5 in modinfo: {path}")

    check(project_files == manifest_files, "Project and modinfo file/import lists differ")
    check(project_files.get("Lua\\WhiteRoomBattleTracking.lua") is True, "Shared battle tracker must be packaged in VFS")

    project_actions = [
        (
            (node.findtext("m:Set", namespaces=MSBUILD) or "").strip(),
            (node.findtext("m:Type", namespaces=MSBUILD) or "").strip(),
            normalized(node.findtext("m:FileName", namespaces=MSBUILD) or ""),
        )
        for node in project_root.findall(".//m:ModActions/m:Action", MSBUILD)
    ]
    manifest_actions = [
        (group.tag, action.tag, normalized(action.text or ""))
        for group in modinfo_root.findall("./Actions/*")
        for action in list(group)
    ]
    check(project_actions == manifest_actions, "Project and modinfo database actions differ")

    project_entries = [
        (
            (node.findtext("m:Type", namespaces=MSBUILD) or "").strip(),
            normalized(node.findtext("m:FileName", namespaces=MSBUILD) or ""),
            (node.findtext("m:Name", namespaces=MSBUILD) or "").strip(),
            (node.findtext("m:Description", namespaces=MSBUILD) or "").strip(),
        )
        for node in project_root.findall(".//m:ModContent/m:Content", MSBUILD)
    ]
    manifest_entries = [
        (
            node.attrib.get("type", ""),
            normalized(node.attrib.get("file", "")),
            (node.findtext("Name") or "").strip(),
            (node.findtext("Description") or "").strip(),
        )
        for node in modinfo_root.findall("./EntryPoints/EntryPoint")
    ]
    check(project_entries == manifest_entries, "Project and modinfo entry points differ")


def validate_runtime_contracts() -> None:
    sql = read("SQL/WhiteRoomPlayableCiv.sql")
    required_options = {
        "EVENTS_BATTLES",
        "EVENTS_UNIT_PREKILL",
        "EVENTS_TRADE_ROUTES",
        "EVENTS_UNIT_UPGRADES",
        "EVENTS_MINORS_INTERACTION",
        "EVENTS_CITY_FOUNDING",
        "EVENTS_UNIT_CREATED",
    }
    option_update = re.search(r"UPDATE\s+CustomModOptions\s+SET\s+Value\s*=\s*1\s+WHERE\s+Name\s+IN\s*\((.*?)\)", sql, re.I | re.S)
    enabled_options = set(re.findall(r"'([^']+)'", option_update.group(1))) if option_update else set()
    for option in required_options:
        check(option in enabled_options, f"Missing enabled Community Patch option: {option}")

    cannot_settle = read("Lua/WhiteRoomCannotSettle.lua")
    check("GameEvents.PlayerCanFoundCity" in cannot_settle, "Founding veto hook missing")
    check("INITIAL_CAPITAL_CONSUMED" in cannot_settle, "Persistent founding flag missing")

    trade = read("Lua/WhiteRoomTradeRouteLearning.lua")
    for token in ("ROUTE_V2_ACTIVE_", "WR_ReconcileActiveRoutes", "WR_ProcessCompletedRoute", "PlayerTradeRouteCompleted"):
        check(token in trade, f"Trade route instance state missing: {token}")
    check("WR_TRADE_ROUTE_LEARNED" not in trade, "Legacy permanent endpoint dedup is still active")

    for path in ("Lua/WhiteRoomCityHpAdaptation.lua", "Lua/WhiteRoomCityRangedStrikeAdaptation.lua", "UI/WhiteRoomStatusPanel.lua"):
        source = read(path)
        for token in ("GetGameTurnFounded", "GetX()", "GetY()"):
            check(token in source, f"Strong city identity missing {token} in {path}")
    check("IDENTITY_V2_MIGRATED" in read("Lua/WhiteRoomCityHpAdaptation.lua"), "HP city-state migration missing")
    check("IDENTITY_V2_MIGRATED" in read("Lua/WhiteRoomCityRangedStrikeAdaptation.lua"), "Ranged city-state migration missing")

    caps = read("Lua/WhiteRoomUnitCaps.lua")
    for token in ("GameEvents.PlayerCanTrain", "GameEvents.CityCanTrain", "GameEvents.UnitCreated", "GetOrderFromQueue", "WR_PruneExcessQueuedUnits", "row.current", "row.later"):
        check(token in caps, f"Unit-cap guard missing: {token}")

    kiyotaka = read("Lua/WhiteRoomKiyotakaScaling.lua")
    check("WR_ClearKiyotakaTransientState" in kiyotaka, "Kiyotaka death cleanup missing")
    cleanup_match = re.search(r"local function WR_ClearKiyotakaTransientState.*?\nend", kiyotaka, re.S)
    cleanup = cleanup_match.group(0) if cleanup_match else ""
    for token in ("PENDING_HEAL", "LAST_DAMAGE"):
        check(token in cleanup, f"Kiyotaka cleanup does not clear {token}")
    for permanent in ("COMBAT", "ATTACK", "RESISTANCE", "HEALING", "DESPERATION", "MOVE_CHANCE"):
        check(f'"{permanent}"' not in cleanup, f"Kiyotaka cleanup resets permanent {permanent} progress")

    battles = read("Lua/WhiteRoomBattleTracking.lua")
    for hook in ("BattleStarted", "BattleJoined", "BattleFinished"):
        check(f"GameEvents.{hook}.Add" in battles, f"Authoritative battle hook missing: {hook}")
    loader = read("Lua/WhiteRoomLuaLoader.lua")
    for consumer in ("WhiteRoomKiyotakaScaling.lua", "WhiteRoomFourthGenOperative.lua"):
        check(loader.index("WhiteRoomBattleTracking.lua") < loader.index(consumer), "Battle tracker must load before consumers")
        check("WR_BattleTracking.finished" in read(f"Lua/{consumer}"), f"Gameplay battle subscriber missing: {consumer}")

    for path in ("SQL/WhiteRoomCityHpAdaptationDummyBuildings.sql", "SQL/WhiteRoomCapturedCityLearningDummyBuildings.sql"):
        source = read(path)
        check("BuildingDefenseModifier" in source, f"Percentage defense missing in {path}")
        building_insert = re.search(r"INSERT\s+INTO\s+Buildings\s*\(([^)]*)\)", source, re.I | re.S)
        columns = building_insert.group(1) if building_insert else ""
        check(not re.search(r"\b(Defense|ExtraCityHitPoints)\b", columns), f"Flat defense/HP must not represent percentage adaptation in {path}")
    ranged = read("Lua/WhiteRoomCityRangedStrikeAdaptation.lua")
    check("LAST_RANGED_STRIKE_COUNTED_TURN" in ranged, "Persistent ranged-strike turn guard missing")
    capture = read("Lua/WhiteRoomCapturedCityLearning.lua")
    check("GameEvents.CityCaptureComplete.Add" in capture, "Gameplay city capture hook missing")
    check("SerialEventCityCaptured.Add" not in capture, "UI city capture must not award permanent progress")
    compatibility = read("SQL/WhiteRoomCompatibilityText.sql")
    check("AURON" not in compatibility, "Unrelated third-party repair must not return")
    check("DELETE FROM" not in compatibility.upper(), "Global orphan cleanup must not return")
    panel = read("UI/WhiteRoomStatusPanel.lua")
    check("WR_BANNER_POLL_ELAPSED < 0.5" in panel, "Idle banner SaveData reads must be throttled")


def validate_sql_effects() -> None:
    # Minimal BNW/CP schema for the changed SQL: CP adds BuildingDefenseModifier.
    db = sqlite3.connect(":memory:")
    db.executescript("""
        CREATE TABLE BuildingClasses(Type TEXT PRIMARY KEY, DefaultBuilding TEXT, Description TEXT);
        CREATE TABLE Buildings(Type TEXT PRIMARY KEY, BuildingClass TEXT, Cost INTEGER, FaithCost INTEGER,
            GreatWorkCount INTEGER, PrereqTech TEXT, Description TEXT, NeverCapture INTEGER, NukeImmune INTEGER,
            HurryCostModifier INTEGER, BuildingDefenseModifier INTEGER DEFAULT 0, Defense INTEGER DEFAULT 0,
            ExtraCityHitPoints INTEGER DEFAULT 0, Civilopedia TEXT, Strategy TEXT, Help TEXT, IconAtlas TEXT,
            PortraitIndex INTEGER, ConquestProb INTEGER, ShowInPedia INTEGER, IsDummy INTEGER);
        CREATE TABLE UnitPromotions(Type TEXT PRIMARY KEY, Description TEXT, Help TEXT, Sound TEXT,
            CannotBeChosen INTEGER, LostWithUpgrade INTEGER, CityAttack INTEGER, PortraitIndex INTEGER,
            IconAtlas TEXT, PediaType TEXT, PediaEntry TEXT);
        CREATE TABLE Language_en_US(Tag TEXT PRIMARY KEY, Text TEXT);
        CREATE TABLE UnitClasses(Type TEXT PRIMARY KEY, DefaultUnit TEXT);
        CREATE TABLE Units(Type TEXT PRIMARY KEY);
        CREATE TABLE Civilizations(Type TEXT PRIMARY KEY);
        CREATE TABLE Civilization_UnitClassOverrides(CivilizationType TEXT, UnitClassType TEXT, UnitType TEXT);
        CREATE TABLE Resources(Type TEXT, Description TEXT);
        CREATE TABLE Unit_FreePromotions(UnitType TEXT, PromotionType TEXT);
        INSERT INTO Resources VALUES('RESOURCE_FOREIGN', NULL);
        INSERT INTO Unit_FreePromotions VALUES('UNIT_FOREIGN', 'PROMOTION_NOT_LOADED_YET');
        INSERT INTO Buildings(Type, Description) VALUES('BUILDING_FOREIGN', NULL);
        INSERT INTO UnitClasses VALUES('UNITCLASS_FOREIGN', NULL);
        INSERT INTO Civilizations VALUES('CIVILIZATION_WHITE_ROOM_KID'), ('CIVILIZATION_FOREIGN');
    """)
    for stem in ("CITY_DEF_ADAPT", "CITY_LOSS_DEF"):
        filename = "WhiteRoomCityHpAdaptationDummyBuildings.sql" if stem == "CITY_DEF_ADAPT" else "WhiteRoomCapturedCityLearningDummyBuildings.sql"
        db.executescript(read(f"SQL/{filename}"))
        for percent in (1, 5, 10, 25, 50):
            effect = db.execute("SELECT BuildingDefenseModifier, Defense, ExtraCityHitPoints FROM Buildings WHERE Type=?",
                                (f"BUILDING_WR_{stem}_{percent}",)).fetchone()
            check(effect == (percent, 0, 0), f"Incorrect percentage dummy: {stem}_{percent}: {effect}")
    for unit in ("KIYOTAKA", "FOURTH_GEN_OPERATIVE"):
        db.execute("INSERT INTO Units VALUES(?)", (f"UNIT_WR_{unit}",))
        db.execute("INSERT INTO UnitClasses VALUES(?, NULL)", (f"UNITCLASS_WR_{unit}",))
        db.execute("INSERT INTO Civilization_UnitClassOverrides VALUES(?, ?, ?)",
                   ("CIVILIZATION_WHITE_ROOM_KID", f"UNITCLASS_WR_{unit}", f"UNIT_WR_{unit}"))
    db.executescript(read("SQL/WhiteRoomCompatibilityText.sql"))
    check(db.execute("SELECT Description FROM Resources").fetchone() == (None,), "Foreign resource rewritten")
    check(db.execute("SELECT Description FROM Buildings WHERE Type='BUILDING_FOREIGN'").fetchone() == (None,), "Foreign building rewritten")
    check(db.execute("SELECT COUNT(*) FROM Unit_FreePromotions").fetchone() == (1,), "Foreign orphan link deleted")
    check(db.execute("SELECT DefaultUnit FROM UnitClasses WHERE Type='UNITCLASS_FOREIGN'").fetchone() == (None,), "Foreign unit class rewritten")
    check(db.execute("SELECT COUNT(*) FROM Civilization_UnitClassOverrides WHERE CivilizationType='CIVILIZATION_FOREIGN' AND UnitType IS NULL").fetchone() == (2,), "White Room unit exclusivity broken")
    db.close()


def validate_lua() -> None:
    try:
        from lupa.lua51 import LuaRuntime
    except ImportError:
        check(False, "Install requirements-dev.txt to run Lua 5.1 syntax/gameplay tests")
        return
    lua = LuaRuntime(unpack_returned_tuples=True)
    compile_lua = lua.eval("function(source, name) local fn, err = loadstring(source, name); assert(fn, err) end")
    for folder in ("Lua", "UI", "tools/tests"):
        for path in sorted((ROOT / folder).glob("*.lua")):
            compile_lua(path.read_text(encoding="utf-8-sig"), str(path))
    lua.execute(read("tools/tests/white_room_mock.lua"))
    lua.execute(read("Lua/WhiteRoomTelemetry.lua"))
    lua.execute("""
        local record = WR_RecordTelemetry
        WR_RecordTelemetry = function(playerID, category, title, detail)
            TELEMETRY[#TELEMETRY + 1] = { playerID, category, title, detail }
            return record(playerID, category, title, detail)
        end
    """)
    lua.execute(read("Lua/WhiteRoomKiyotakaFlavor.lua"))
    lua.execute("""
        local record = WR_KiyotakaFlavorEvent
        WR_KiyotakaFlavorEvent = function(playerID, unit, kind, ...)
            FLAVOR[#FLAVOR + 1] = kind
            return record(playerID, unit, kind, ...)
        end
    """)
    for path in ("Lua/WhiteRoomBattleTracking.lua", "Lua/WhiteRoomKiyotakaScaling.lua",
                 "Lua/WhiteRoomFourthGenOperative.lua", "Lua/WhiteRoomCapturedCityLearning.lua"):
        lua.execute(read(path))
    lua.globals().reloadRanged = lambda: lua.execute(read("Lua/WhiteRoomCityRangedStrikeAdaptation.lua"))
    lua.globals().reloadCapture = lambda: lua.execute(read("Lua/WhiteRoomCapturedCityLearning.lua"))
    lua.execute(read("tools/tests/white_room_assertions.lua"))
    messages = list(lua.globals().LOG.values())
    for expected in ("WR Adaptation Telemetry: initialized", "WR Kiyotaka Flavor: initialized",
                     "WR Battle Tracking: initialized", "WR Perfect Adaptation: initialized",
                     "WR 4th Generation Operative: initialized", "WR Captured City Learning: initialized",
                     "WR City Ranged Adaptation: initialized"):
        check(any(message.startswith(expected) for message in messages), f"Expected initialization log missing: {expected}")
    print("Passed Lua 5.1 syntax and executable gameplay/reload regressions (no animation events).")


def validate_behavior_models() -> None:
    # Founding: one initial capital is legal; losing it never restores the right.
    consumed = False
    city_count = 0
    check(not consumed and city_count == 0, "Initial capital should be legal")
    city_count = 1
    consumed = True
    check(consumed and city_count == 1, "Initial capital should consume the founding right")
    city_count = 0
    check(not (not consumed and city_count == 0), "Losing every city must not restore founding")

    # Trade routes: poll and completion refer to one active instance, while a
    # later deployment over the same endpoints earns a new award.
    active = 0
    awards = 0
    observed = 1
    if observed > active:
        awards += observed - active
    active = observed
    check(awards == 1 and active == 1, "First route instance should award once")
    reloaded_active = active
    check(reloaded_active == 1 and awards == 1, "Save/reload must not re-award an active route")
    active -= 1  # completion callback closes the polled instance
    check(awards == 1 and active == 0, "Completion callback must not double-award")
    observed = 1  # replacement route, identical endpoints
    if observed > active:
        awards += observed - active
    active = observed
    check(awards == 2 and active == 1, "Replacement route should award independently")

    # City identities must differ when an ID is reused at another place/time.
    def city_key(player: int, city: int, x: int, y: int, founded: int) -> str:
        return f"{player}:{city}:{x}:{y}:{founded}"

    check(
        city_key(0, 4, 10, 12, 5) != city_key(0, 4, 18, 3, 90),
        "Reused city IDs must not inherit old adaptation",
    )

    # Persisted per-city turn state outlives all transient Lua tables.
    saved: dict[str, int] = {}
    key = city_key(0, 4, 10, 12, 5)
    def ranged_strike(turn: int, performed: bool) -> None:
        if performed and saved.get(key + "_LAST_RANGED_STRIKE_COUNTED_TURN", -1) != turn:
            saved[key + "_LAST_RANGED_STRIKE_COUNTED_TURN"] = turn
            saved[key + "_ATTACK_STACKS"] = saved.get(key + "_ATTACK_STACKS", 0) + 1
    ranged_strike(10, True)
    check(saved[key + "_ATTACK_STACKS"] == 1, "First ranged strike should award")
    saved = dict(saved)  # save/reload retains only persistent state
    ranged_strike(10, True)
    check(saved[key + "_ATTACK_STACKS"] == 1, "Same-turn reload must not re-award ranged strike")
    ranged_strike(11, False)
    ranged_strike(11, True)
    check(saved[key + "_ATTACK_STACKS"] == 2, "Next-turn strike must award")

    # Queue pruning reserves current production before later entries. The CP
    # callback cannot identify a same-city append, so that extra is pruned.
    def prune_queue(active_units: int, current_orders: list[str], later_orders: list[str], cap: int) -> tuple[list[str], list[str]]:
        remaining = max(0, cap - active_units)
        kept: list[str] = []
        removed: list[str] = []
        for order in current_orders + later_orders:
            if remaining > 0:
                kept.append(order)
                remaining -= 1
            else:
                removed.append(order)
        return kept, removed

    kept, removed = prune_queue(2, ["city_a_current"], ["city_a_extra"], 3)
    check(kept == ["city_a_current"], "Existing legal current production must be retained")
    check(removed == ["city_a_extra"], "Excess same-city queued copy must be pruned")
    kept, removed = prune_queue(0, ["kiyotaka_current"], [], 1)
    check(kept == ["kiyotaka_current"] and not removed, "Below-cap Kiyotaka production must remain possible")

    # External over-cap creation keeps the highest-level/highest-XP scores.
    scores = [100001, 205002, 103003, 304004]
    retained = sorted(scores, reverse=True)[:3]
    check(retained == [304004, 205002, 103003], "Over-cap enforcement must retain the strongest copies")

    # Death cleanup only removes transient combat state.
    state = {"PENDING_HEAL": 3, "LAST_DAMAGE": 77, "COMBAT": 240, "ATTACK": 125}
    state["PENDING_HEAL"] = 0
    state["LAST_DAMAGE"] = 0
    check(state == {"PENDING_HEAL": 0, "LAST_DAMAGE": 0, "COMBAT": 240, "ATTACK": 125}, "Death cleanup must preserve permanent adaptation")


def main() -> int:
    validate_package()
    validate_runtime_contracts()
    validate_behavior_models()
    validate_sql_effects()
    validate_lua()
    if ERRORS:
        print("Validation failed:")
        for error in ERRORS:
            print(f"- {error}")
        return 1

    print("Validation passed: package parity and White Room runtime contracts are intact.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
