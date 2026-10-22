"""Render the StudEXPO illustrations: python3 docs/studexpo/scenes/render.py
Writes docs/studexpo/assets/scene_*.png (2x)."""
from pathlib import Path
from playwright.sync_api import sync_playwright

here = Path(__file__).resolve().parent
out = here.parent / "assets"
with sync_playwright() as p:
    b = p.chromium.launch()
    page = b.new_page(device_scale_factor=2, viewport={"width": 1400, "height": 1000})
    page.goto((here / "scenes.html").as_uri(), wait_until="networkidle")
    page.wait_for_timeout(300)
    for name in ("problem", "stop", "inbus"):
        page.locator("#" + name).screenshot(path=str(out / f"scene_{name}.png"), omit_background=True)
        print("wrote", out / f"scene_{name}.png")
    b.close()
