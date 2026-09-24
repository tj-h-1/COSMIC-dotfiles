#!/usr/bin/env python3

import json
import re
import subprocess
import sys
from pathlib import Path

if len(sys.argv) != 4:
    print("Usage: convert-cosmic.py WALLPAPER BASE OUTPUT")
    sys.exit(1)

wallpaper = Path(sys.argv[1])
base_file = Path(sys.argv[2])
output_file = Path(sys.argv[3])

# Ask Matugen for the same colour scheme it uses for other templates.
result = subprocess.run(
    [
        "matugen",
        "image",
        str(wallpaper),
        "-m", "dark",
        "--source-color-index", "0",
        "--dry-run",
        "-j", "strip",
    ],
    capture_output=True,
    text=True,
    check=True,
)

data = json.loads(result.stdout)

def get(name):
    return data["colors"][name]["dark"]["color"]

def rgba(hex_color):
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16) / 255
    g = int(hex_color[2:4], 16) / 255
    b = int(hex_color[4:6], 16) / 255

    return (
        "(\n"
        f"            red: {r:.8f},\n"
        f"            green: {g:.8f},\n"
        f"            blue: {b:.8f},\n"
        "            alpha: 1.0,\n"
        "        )"
    )

def rgb(hex_color):
    hex_color = hex_color.lstrip("#")
    r = int(hex_color[0:2], 16) / 255
    g = int(hex_color[2:4], 16) / 255
    b = int(hex_color[4:6], 16) / 255

    return (
        "(\n"
        f"        red: {r:.8f},\n"
        f"        green: {g:.8f},\n"
        f"        blue: {b:.8f},\n"
        "    )"
    )

text = base_file.read_text()

# Palette entries in Fedora's RON are RGBA.
palette = {
    "bright_red": "error",
    "bright_green": "tertiary",
    "bright_orange": "secondary",

    "gray_1": "surface",
    "gray_2": "surface_container",

    "neutral_0": "scrim",
    "neutral_1": "surface",
    "neutral_2": "surface_container_low",
    "neutral_3": "surface_container",
    "neutral_4": "surface_container_high",
    "neutral_5": "surface_container_highest",
    "neutral_6": "outline_variant",
    "neutral_7": "outline",
    "neutral_8": "on_surface_variant",
    "neutral_9": "on_surface",
    "neutral_10": "on_surface",

    "accent_blue": "primary",
    "accent_indigo": "secondary",
    "accent_purple": "tertiary",
    "accent_pink": "primary_fixed",
    "accent_red": "error",
    "accent_orange": "secondary_fixed",
    "accent_yellow": "tertiary_fixed",
    "accent_green": "tertiary",
    "accent_warm_grey": "on_surface_variant",

    "ext_warm_grey": "outline",
    "ext_orange": "secondary",
    "ext_yellow": "tertiary",
    "ext_blue": "primary",
    "ext_purple": "tertiary",
    "ext_pink": "primary_fixed_dim",
    "ext_indigo": "secondary_fixed_dim",
}

for field, color_name in palette.items():
    pattern = rf"({field}:\s*)\([^)]*?\)"
    text = re.sub(
        pattern,
        lambda m: m.group(1) + rgba(get(color_name)),
        text,
        count=1,
        flags=re.DOTALL,
    )

# bg_color is RGBA.
text = re.sub(
    r"bg_color:\s*Some\(\(.*?\)\)",
    "bg_color: Some(" + rgba(get("surface")) + ")",
    text,
    count=1,
    flags=re.DOTALL,
)

# These Fedora fields are RGB rather than RGBA.
rgb_fields = {
    "neutral_tint": "surface_container_highest",
    "text_tint": "on_surface",
    "accent": "primary",
    "success": "tertiary",
    "warning": "secondary",
    "destructive": "error",
}

for field, color_name in rgb_fields.items():
    pattern = rf"{field}:\s*Some\(\(.*?\)\)"
    replacement = f"{field}: Some({rgb(get(color_name))})"

    text = re.sub(
        pattern,
        replacement,
        text,
        count=1,
        flags=re.DOTALL,
    )

# Restore your compact/pixel-style COSMIC geometry.
text = re.sub(
    r"spacing:\s*\(.*?\n    \),",
    """spacing: (
        space_none: 0,
        space_xxxs: 4,
        space_xxs: 4,
        space_xs: 8,
        space_s: 8,
        space_m: 16,
        space_l: 24,
        space_xl: 32,
        space_xxl: 48,
        space_xxxl: 64,
    ),""",
    text,
    count=1,
    flags=re.DOTALL,
)

text = re.sub(
    r"corner_radii:\s*\(.*?\n    \),",
    """corner_radii: (
        radius_0: (0.0, 0.0, 0.0, 0.0),
        radius_xs: (2.0, 2.0, 2.0, 2.0),
        radius_s: (2.0, 2.0, 2.0, 2.0),
        radius_m: (2.0, 2.0, 2.0, 2.0),
        radius_l: (2.0, 2.0, 2.0, 2.0),
        radius_xl: (2.0, 2.0, 2.0, 2.0),
    ),""",
    text,
    count=1,
    flags=re.DOTALL,
)

text = re.sub(r"gaps:\s*\([^)]*\)", "gaps: (0, 6)", text)
text = re.sub(r"active_hint:\s*\d+", "active_hint: 2", text)

# Give imported themes an identifiable name.
text = text.replace('name: "cosmic-dark"', 'name: "matugen-dark"', 1)

output_file.write_text(text)

print(f"COSMIC theme generated: {output_file}")
