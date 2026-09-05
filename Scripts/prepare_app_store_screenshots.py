#!/usr/bin/env python3
"""Compose source app captures into 2880x1800 Mac App Store screenshots."""

from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


CANVAS = (2880, 1800)


def font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    name = "SFNSDisplay-Bold.otf" if bold else "SFNSDisplay-Regular.otf"
    candidates = [
        Path("/System/Library/Fonts") / name,
        Path("/System/Library/Fonts/SFNS.ttf"),
        Path("/System/Library/Fonts/Helvetica.ttc"),
    ]
    for candidate in candidates:
        if candidate.exists():
            return ImageFont.truetype(str(candidate), size=size)
    return ImageFont.load_default(size=size)


def cover(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    ratio = max(size[0] / image.width, size[1] / image.height)
    resized = image.resize(
        (round(image.width * ratio), round(image.height * ratio)), Image.Resampling.LANCZOS
    )
    left = (resized.width - size[0]) // 2
    top = (resized.height - size[1]) // 2
    return resized.crop((left, top, left + size[0], top + size[1]))


def fit(image: Image.Image, size: tuple[int, int]) -> Image.Image:
    ratio = min(size[0] / image.width, size[1] / image.height)
    return image.resize(
        (round(image.width * ratio), round(image.height * ratio)), Image.Resampling.LANCZOS
    )


def base(background: Image.Image) -> Image.Image:
    canvas = cover(background.convert("RGB"), CANVAS)
    overlay = Image.new("RGBA", CANVAS, (2, 5, 18, 68))
    return Image.alpha_composite(canvas.convert("RGBA"), overlay)


def add_title(canvas: Image.Image, eyebrow: str, title: str, subtitle: str) -> None:
    draw = ImageDraw.Draw(canvas)
    draw.text((180, 105), eyebrow.upper(), font=font(42, True), fill=(47, 230, 220, 255))
    draw.text((180, 165), title, font=font(96, True), fill=(247, 249, 255, 255))
    draw.text((185, 285), subtitle, font=font(40), fill=(168, 181, 214, 255))


def paste_card(canvas: Image.Image, image: Image.Image, box: tuple[int, int, int, int]) -> None:
    x, y, width, height = box
    fitted = fit(image.convert("RGB"), (width, height))
    px = x + (width - fitted.width) // 2
    py = y + (height - fitted.height) // 2
    shadow = Image.new("RGBA", CANVAS, (0, 0, 0, 0))
    shadow_draw = ImageDraw.Draw(shadow)
    shadow_draw.rounded_rectangle(
        (px - 22, py - 18, px + fitted.width + 22, py + fitted.height + 36),
        radius=50,
        fill=(0, 0, 0, 190),
    )
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(28)))
    mask = Image.new("L", fitted.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, fitted.width, fitted.height), radius=34, fill=255)
    canvas.paste(fitted, (px, py), mask)


def crop_fraction(image: Image.Image, left: float, top: float, right: float, bottom: float) -> Image.Image:
    return image.crop(
        (round(image.width * left), round(image.height * top), round(image.width * right), round(image.height * bottom))
    )


def compose(
    background: Image.Image,
    source: Image.Image,
    eyebrow: str,
    title: str,
    subtitle: str,
    box: tuple[int, int, int, int],
    crop: tuple[float, float, float, float] | None = None,
) -> Image.Image:
    canvas = base(background)
    add_title(canvas, eyebrow, title, subtitle)
    content = crop_fraction(source, *crop) if crop else source
    paste_card(canvas, content, box)
    return canvas.convert("RGB")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--background", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("images", nargs=6, type=Path)
    args = parser.parse_args()

    args.output.mkdir(parents=True, exist_ok=True)
    background = Image.open(args.background)
    images = [Image.open(path) for path in args.images]

    specs = [
        ("REAL-TIME OVERVIEW", "Your Mac, at a glance", "CPU, memory, network and disk — always one click away.", (160, 420, 2560, 1310), None),
        ("SYSTEM HEALTH", "Know what needs attention", "A clear local health score with useful, actionable guidance.", (420, 430, 2040, 1320), None),
        ("SMART INSIGHTS", "Understand unusual activity", "Review resource pressure and traffic spikes across the last 24 hours.", (210, 510, 2460, 1130), (0.015, 0.24, 0.985, 0.94)),
        ("MEMORY", "See memory pressure clearly", "Track usage, swap and macOS memory pressure in real time.", (260, 440, 2360, 1260), None),
        ("HISTORY", "Spot trends over 24 hours", "Visualize changing resource usage without opening Activity Monitor.", (230, 520, 2420, 1080), (0.015, 0.34, 0.985, 0.76)),
        ("PRIVATE BY DESIGN", "Your metrics stay on your Mac", "No account required. Monitoring history is analyzed locally.", (170, 500, 2540, 1120), (0.015, 0.48, 0.985, 0.985)),
    ]

    for index, (eyebrow, title, subtitle, box, crop) in enumerate(specs, start=1):
        result = compose(background, images[index - 1], eyebrow, title, subtitle, box, crop)
        result.save(args.output / f"{index:02d}-silivue-app-store.png", format="PNG", optimize=True)


if __name__ == "__main__":
    main()
