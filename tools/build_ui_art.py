#!/usr/bin/env python3
"""Prepare generated source paintings as Civ V DDS textures (no runtime work)."""
from pathlib import Path
import argparse
import shutil
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "Art" / "UI"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("facility", "subject", "operatives"):
        parser.add_argument("--" + name, type=Path)
    args = parser.parse_args()
    sources = ART / "Source"
    sources.mkdir(parents=True, exist_ok=True)
    for name in ("facility", "subject", "operatives"):
        source = getattr(args, name)
        target = sources / (name + ".png")
        if source and source.resolve() != target.resolve():
            shutil.copyfile(source, target)
        if not target.is_file():
            raise FileNotFoundError(target)
    specs = {
        "WR_UI_Facility": ("facility", (1024, 256), (0.5, 0.5)),
        "WR_UI_FacilityPanel": ("facility", (512, 768), (0.5, 0.5)),
        "WR_UI_Subject": ("subject", (512, 1024), (0.5, 0.0)),
        "WR_UI_SubjectPanel": ("subject", (512, 768), (0.5, 0.0)),
        "WR_UI_Operatives": ("operatives", (512, 1024), (0.5, 0.0)),
        "WR_UI_OperativesPanel": ("operatives", (512, 768), (0.5, 0.0)),
    }
    for name, (source, size, centering) in specs.items():
        with Image.open(sources / (source + ".png")) as original:
            texture = ImageOps.fit(original.convert("RGBA"), size, Image.Resampling.LANCZOS, centering=centering)
            texture.save(ART / (name + ".dds"), pixel_format="DXT5")
        print(name, size)


if __name__ == "__main__":
    main()
