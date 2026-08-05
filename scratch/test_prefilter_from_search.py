import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_prefilter_search():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # 1. Go to Search tab (x=195, y=800)
        print("Going to Search tab...")
        page.mouse.click(195, 800)
        time.sleep(3.0)

        # 2. Click Spider-Man card in Discover grid at (80, 380)
        print("Clicking Spider-Man card in grid (80, 380)...")
        page.mouse.click(80, 380)
        time.sleep(4.0)

        shot1 = os.path.join(SCREENSHOT_DIR, "mode4_01_detail_screen.png")
        page.screenshot(path=shot1)
        print(f"Captured Detail view: {shot1}")

        # 3. Scroll down on Detail view to see Keywords / Genres section
        print("Scrolling down on Detail view...")
        page.mouse.wheel(0, 500)
        time.sleep(2.0)

        shot2 = os.path.join(SCREENSHOT_DIR, "mode4_detail_keywords.png")
        page.screenshot(path=shot2)
        print(f"Captured Detail keywords: {shot2}")

        # 4. Tap keyword / genre chip at (80, 520) or (60, 480)
        print("Tapping keyword chip...")
        page.mouse.click(80, 520)
        time.sleep(4.0)

        shot3 = os.path.join(SCREENSHOT_DIR, "mode4_prefilter_navigation.png")
        page.screenshot(path=shot3)
        print(f"Captured Mode 4 Pre-Filter Navigation: {shot3}")

        browser.close()

if __name__ == "__main__":
    test_prefilter_search()
