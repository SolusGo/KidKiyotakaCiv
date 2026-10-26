#!/usr/bin/env python3
"""Render XML + real Lua fixture state for layout QA, not a Civ V screenshot."""
from pathlib import Path
import re
from PIL import Image, ImageDraw, ImageFont
from ui_fixture import make_ui, control_snapshot

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "ui"
SCALE = 2


def pair(value, default=(0, 0)):
    return tuple(float(n) for n in value.split(",")) if value else default


def clean(value):
    value = str(value).replace("[NEWLINE]", "\n")
    value = re.sub(r"\[ICON_[^]]+\]", "", value)
    return re.sub(r"\[(?:COLOR_[^]]+|ENDCOLOR)\]", "", value).strip()


def color(value, default=(234, 234, 225, 255)):
    return tuple(int(n) for n in value.split(",")) if value else default


def font(size):
    for name in ("segoeui.ttf", "arial.ttf"):
        path = Path("C:/Windows/Fonts") / name
        if path.is_file():
            return ImageFont.truetype(str(path), round(size * SCALE))
    return ImageFont.load_default()


def render(tree, state, root_id, target):
    canvas = Image.new("RGBA", (984 * SCALE, 714 * SCALE), (7, 11, 16, 255))
    root = next(node for node in tree.iter() if node.attrib.get("ID") == root_id)

    def draw_node(node, parent, force=False):
        if node.tag == "ShowOnMouseOver":
            return
        attrs = node.attrib
        dynamic = state.get(attrs.get("ID"), {})
        if not force and dynamic.get("hidden", attrs.get("Hidden") == "1"):
            return
        px, py, pw, ph = parent
        width, height = pair(attrs.get("Size"), (pw, ph))
        width, height = dynamic.get("width", width), dynamic.get("height", height)
        ox, oy = pair(attrs.get("Offset"))
        ox, oy = dynamic.get("x", ox), dynamic.get("y", oy)
        anchor = attrs.get("Anchor", "L,T").split(",")
        x = px + (pw - width) / 2 + ox if anchor[0] == "C" else px + pw - width - ox if anchor[0] == "R" else px + ox
        y = py + (ph - height) / 2 + oy if anchor[1] == "C" else py + ph - height - oy if anchor[1] == "B" else py + oy
        if force:
            x, y = 32, 28
        bounds = tuple(round(n * SCALE) for n in (x, y, x + width, y + height))
        if node.tag == "Box":
            layer = Image.new("RGBA", canvas.size)
            ImageDraw.Draw(layer).rectangle(bounds, fill=color(attrs.get("Color")))
            canvas.alpha_composite(layer)
        elif node.tag == "Image":
            texture = dynamic.get("texture", attrs.get("Texture"))
            if texture and (ROOT / texture).is_file():
                with Image.open(ROOT / texture) as source:
                    art = source.convert("RGBA").resize((max(1, bounds[2] - bounds[0]), max(1, bounds[3] - bounds[1])), Image.Resampling.LANCZOS)
                alpha = color(attrs.get("Color"))[3]
                if alpha < 255:
                    art.putalpha(art.getchannel("A").point(lambda n: n * alpha // 255))
                canvas.alpha_composite(art, bounds[:2])
        elif node.tag == "Label":
            text = clean(dynamic.get("text", attrs.get("String", "")))
            match = re.search(r"(\d+)$", attrs.get("Font", "TwCenMT16"))
            size = int(match.group(1)) if match else 16
            face = font(size * 0.88)
            limit = float(attrs.get("WrapWidth", attrs.get("TruncateWidth", str(width)))) * SCALE
            draw = ImageDraw.Draw(canvas)
            lines = []
            for paragraph in text.split("\n"):
                if "WrapWidth" in attrs:
                    line = ""
                    for word in paragraph.split():
                        next_line = (line + " " + word).strip()
                        if line and draw.textlength(next_line, font=face) > limit:
                            lines.append(line)
                            line = word
                        else:
                            line = next_line
                    lines.append(line)
                else:
                    while paragraph and draw.textlength(paragraph, font=face) > limit:
                        paragraph = paragraph[:-2].rstrip() + "…" if not paragraph.endswith("…") else paragraph[:-2].rstrip() + "…"
                    lines.append(paragraph)
            layer = Image.new("RGBA", canvas.size)
            text_draw = ImageDraw.Draw(layer)
            text_draw.multiline_text((round(x * SCALE), round(y * SCALE)), "\n".join(lines), font=face,
                                     fill=color(attrs.get("Color")), spacing=round(3 * SCALE))
            # Scroll content is clipped to its parent's viewport.
            clip = tuple(round(n * SCALE) for n in (px, py, px + pw, py + ph))
            canvas.alpha_composite(layer.crop(clip), (clip[0], clip[1]))
        for child in node:
            draw_node(child, (x, y, width, height))

    draw_node(root, (0, 0, 984, 714), True)
    ImageDraw.Draw(canvas).text((32 * SCALE, 685 * SCALE), "LAYOUT PREVIEW / REAL LUA FIXTURE DATA / NOT AN IN-GAME CAPTURE", font=font(10), fill=(112, 128, 139, 255))
    canvas.convert("RGB").save(target)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    lua, tree = make_ui()
    lua.execute("Controls.WhiteRoomStatusButton:Click()")
    for page, button in (("facility", "Empire"), ("kiyotaka", "Kiyotaka"), ("operatives", "Units"), ("telemetry", "Telemetry")):
        lua.execute(f"Controls.{button}TabButton:Click()")
        render(tree, control_snapshot(lua), "StatusPanel", OUTPUT / (page + ".png"))
    unlock, tree = make_ui("unlock")
    unlock.execute("TECHS[21] = true; GameEvents.TeamTechResearched(0, 21)")
    render(tree, control_snapshot(unlock), "UnlockPanel", OUTPUT / "unlock-kiyotaka.png")
    unlock.execute("Controls.AcknowledgeButton:Click(); TECHS[22] = true; GameEvents.TeamTechResearched(0, 22)")
    render(tree, control_snapshot(unlock), "UnlockPanel", OUTPUT / "unlock-operatives.png")
    print("Layout previews:", OUTPUT)


if __name__ == "__main__":
    main()
