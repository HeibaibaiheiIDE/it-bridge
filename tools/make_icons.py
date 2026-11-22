"""Generate IT Bridge Windows ICO and Android launcher PNGs from assets/Android_IT.png.

Usage: python tools/make_icons.py
Requires Pillow (pip install pillow).
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "assets" / "Android_IT.png"
WIN_ICON = ROOT / "apps" / "itbridge_desktop" / "windows" / "runner" / "resources" / "app_icon.ico"
ANDROID_RES = ROOT / "apps" / "itbridge_mobile" / "android" / "app" / "src" / "main" / "res"

DENSITIES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def square_crop(image: Image.Image) -> Image.Image:
    width, height = image.size
    side = min(width, height)
    left = (width - side) // 2
    top = (height - side) // 2
    return image.crop((left, top, left + side, top + side)).convert("RGBA")


def main() -> None:
    if not SOURCE.exists():
        raise SystemExit(f"Source icon not found: {SOURCE}")
    base = square_crop(Image.open(SOURCE).convert("RGBA"))
    WIN_ICON.parent.mkdir(parents=True, exist_ok=True)
    base.save(WIN_ICON, format="ICO", sizes=[(16, 16), (32, 32), (48, 48), (64, 64), (128, 128), (256, 256)])
    for folder, size in DENSITIES.items():
        target_dir = ANDROID_RES / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        base.resize((size, size), Image.Resampling.LANCZOS).save(target_dir / "ic_launcher.png")
        base.resize((size, size), Image.Resampling.LANCZOS).save(target_dir / "ic_launcher_round.png")
    print(f"Generated {WIN_ICON}")
    print(f"Generated launcher icons in {ANDROID_RES}")


if __name__ == "__main__":
    main()
