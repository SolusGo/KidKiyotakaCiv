"""Execute the real Civ V UI Lua against strict XML-backed mock controls."""
from pathlib import Path
import xml.etree.ElementTree as ET
from lupa.lua51 import LuaRuntime

ROOT = Path(__file__).resolve().parents[1]


def make_ui(kind="status", active_player=0):
    lua = LuaRuntime(unpack_returned_tuples=True)
    lua.execute((ROOT / "tools/tests/white_room_mock.lua").read_text(encoding="utf-8-sig"))
    filename = "WhiteRoomStatusPanel" if kind == "status" else "WhiteRoomUnitUnlock"
    tree = ET.parse(ROOT / "UI" / (filename + ".xml"))
    controls = {}
    for node in tree.iter():
        if "ID" in node.attrib:
            controls[node.attrib["ID"]] = dict(node.attrib)
    lua.globals().UI_SEED = lua.table_from(controls, recursive=True)
    lua.globals().ACTIVE_PLAYER = active_player
    lua.execute((ROOT / "tools/tests/white_room_ui_mock.lua").read_text(encoding="utf-8-sig"))
    if kind == "status":
        lua.execute("TECHS[21] = true; TECHS[22] = true")
    lua.execute((ROOT / "Lua/WhiteRoomTelemetry.lua").read_text(encoding="utf-8-sig"))
    lua.execute("""
        for index = 1, 9 do
            local category = index % 2 == 0 and "OPERATIVE" or "SUBJECT"
            WR_RecordTelemetry(0, category, index % 2 == 0 and "OPERATIVE-02 // ENGAGEMENT RECORDED" or "COMBAT PATTERN ACQUIRED // SUBJECT 004",
                index % 2 == 0 and "24 damage dealt / 8 taken. Career record updated. Full observation retained."
                or "Combat +0.13% / Attack +0.13% / Flow +0.07%. Every failure becomes data.")
        end
        UI_SAVE_READS = 0
        UI_SAVE_WRITES = 0
    """)
    lua.execute((ROOT / "UI" / (filename + ".lua")).read_text(encoding="utf-8-sig"))
    return lua, tree


def control_snapshot(lua):
    result = {}
    for key, value in lua.globals().Controls.items():
        result[key] = {name: value[name] for name in ("text", "hidden", "width", "height", "x", "y", "texture", "disabled", "tooltip") if value[name] is not None}
    return result
