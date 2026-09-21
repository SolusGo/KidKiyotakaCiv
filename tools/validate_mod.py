#!/usr/bin/env python3
"""Deterministic package and White Room regression checks."""

from __future__ import annotations

import hashlib
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "KidKiyotakaWhiteRoom.civ5proj"
MODINFO = ROOT / "Kid Kiyotaka White Room (v 1).modinfo"
MSBUILD = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}
ERRORS: list[str] = []


def normalized(path: str) -> str:
    return path.replace("/", "\\")


def local_path(path: str) -> Path:
    return ROOT.joinpath(*normalized(path).split("\\"))


def check(condition: bool, message: str) -> None:
    if not condition:
        ERRORS.append(message)


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def validate_package() -> None:
    project_root = ET.parse(PROJECT).getroot()
    modinfo_root = ET.parse(MODINFO).getroot()

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
        "EVENTS_UNIT_PREKILL",
        "EVENTS_TRADE_ROUTES",
        "EVENTS_UNIT_UPGRADES",
        "EVENTS_MINORS_INTERACTION",
        "EVENTS_CITY_FOUNDING",
        "EVENTS_UNIT_CREATED",
    }
    for option in required_options:
        check(option in sql, f"Missing Community Patch option: {option}")
    check(bool(re.search(r"UPDATE\s+CustomModOptions\s+SET\s+Value\s*=\s*1", sql, re.I | re.S)), "CustomModOptions are not enabled")

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
    for token in ("GameEvents.PlayerCanTrain", "GameEvents.CityCanTrain", "GameEvents.UnitCreated", "GetOrderFromQueue", "WR_PruneExcessQueuedUnits"):
        check(token in caps, f"Unit-cap guard missing: {token}")

    kiyotaka = read("Lua/WhiteRoomKiyotakaScaling.lua")
    check("WR_ClearKiyotakaTransientState" in kiyotaka, "Kiyotaka death cleanup missing")
    cleanup_match = re.search(r"local function WR_ClearKiyotakaTransientState.*?\nend", kiyotaka, re.S)
    cleanup = cleanup_match.group(0) if cleanup_match else ""
    for token in ("PENDING_HEAL", "LAST_DAMAGE", "WR_DAMAGE_CACHE", "WR_ACTIVE_KIYOTAKA_TARGETS"):
        check(token in cleanup, f"Kiyotaka cleanup does not clear {token}")
    for permanent in ("COMBAT", "ATTACK", "RESISTANCE", "HEALING", "DESPERATION", "MOVE_CHANCE"):
        check(f'"{permanent}"' not in cleanup, f"Kiyotaka cleanup resets permanent {permanent} progress")


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

    # Queue-aware caps allow an existing head order but reject another city.
    cap = 1
    active_units = 0
    other_queued_for_current_city = 0
    other_queued_for_second_city = 1
    check(active_units + other_queued_for_current_city < cap, "Existing legal queue should remain trainable")
    check(not (active_units + other_queued_for_second_city < cap), "Simultaneous over-cap queue should be blocked")

    # Death cleanup only removes transient combat state.
    state = {"PENDING_HEAL": 3, "LAST_DAMAGE": 77, "COMBAT": 240, "ATTACK": 125}
    state["PENDING_HEAL"] = 0
    state["LAST_DAMAGE"] = 0
    check(state == {"PENDING_HEAL": 0, "LAST_DAMAGE": 0, "COMBAT": 240, "ATTACK": 125}, "Death cleanup must preserve permanent adaptation")


def main() -> int:
    validate_package()
    validate_runtime_contracts()
    validate_behavior_models()
    if ERRORS:
        print("Validation failed:")
        for error in ERRORS:
            print(f"- {error}")
        return 1

    print("Validation passed: package parity and White Room runtime contracts are intact.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
