#!/usr/bin/env python3
"""Synchronize the built Civ V manifest with the ModBuddy project."""

from __future__ import annotations

import hashlib
from pathlib import Path
import xml.etree.ElementTree as ET


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "KidKiyotakaWhiteRoom.civ5proj"
MODINFO = ROOT / "Kid Kiyotaka White Room (v 1).modinfo"
MSBUILD = {"m": "http://schemas.microsoft.com/developer/msbuild/2003"}


def normalized(path: str) -> str:
    return path.replace("/", "\\")


def local_path(path: str) -> Path:
    return ROOT.joinpath(*normalized(path).split("\\"))


def main() -> None:
    project_root = ET.parse(PROJECT).getroot()
    modinfo_tree = ET.parse(MODINFO)
    modinfo_root = modinfo_tree.getroot()

    files = modinfo_root.find("Files")
    actions = modinfo_root.find("Actions")
    entry_points = modinfo_root.find("EntryPoints")
    if files is None or actions is None or entry_points is None:
        raise RuntimeError("The modinfo is missing Files, Actions, or EntryPoints")

    files.clear()
    actions.clear()
    entry_points.clear()

    for content in project_root.findall(".//m:ItemGroup/m:Content", MSBUILD):
        path = normalized(content.attrib["Include"])
        source = local_path(path)
        if not source.is_file():
            raise FileNotFoundError(source)

        import_node = content.find("m:ImportIntoVFS", MSBUILD)
        imported = import_node is not None and (import_node.text or "").strip().lower() == "true"
        digest = hashlib.md5(source.read_bytes()).hexdigest().upper()
        node = ET.SubElement(files, "File", {"md5": digest, "import": "1" if imported else "0"})
        node.text = path

    grouped_actions: dict[str, ET.Element] = {}
    for action in project_root.findall(".//m:ModActions/m:Action", MSBUILD):
        action_set = (action.findtext("m:Set", namespaces=MSBUILD) or "").strip()
        action_type = (action.findtext("m:Type", namespaces=MSBUILD) or "").strip()
        path = normalized(action.findtext("m:FileName", namespaces=MSBUILD) or "")
        parent = grouped_actions.get(action_set)
        if parent is None:
            parent = ET.SubElement(actions, action_set)
            grouped_actions[action_set] = parent
        ET.SubElement(parent, action_type).text = path

    for content in project_root.findall(".//m:ModContent/m:Content", MSBUILD):
        entry = ET.SubElement(
            entry_points,
            "EntryPoint",
            {
                "type": (content.findtext("m:Type", namespaces=MSBUILD) or "").strip(),
                "file": normalized(content.findtext("m:FileName", namespaces=MSBUILD) or ""),
            },
        )
        ET.SubElement(entry, "Name").text = (content.findtext("m:Name", namespaces=MSBUILD) or "").strip()
        ET.SubElement(entry, "Description").text = (content.findtext("m:Description", namespaces=MSBUILD) or "").strip()

    ET.indent(modinfo_tree, space="  ")
    modinfo_tree.write(MODINFO, encoding="utf-8", xml_declaration=True)
    print(f"Synchronized {MODINFO.name} from {PROJECT.name}")


if __name__ == "__main__":
    main()
