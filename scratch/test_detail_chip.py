import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_detail_chip():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # Tap top movie poster on Home (Spider-Man at x=80, y=420)
        print("Clicking movie poster at (80, 420)...")
        page.mouse.click(80, 420)
        time.sleep(4.0)

        shot1 = os.path.join(SCREENSHOT_DIR, "mode4_01_detail_screen.png")
        page.screenshot(path=shot1)
        print(f"Captured Detail view: {shot1}")

        # Scroll down on DetailScreen
        print("Scrolling down on Detail screen...")
        page.mouse.wheel(0, 450)
        time.sleep(2.0)

        shot2 = os.path.join(SCREENSHOT_DIR, "mode4_detail_keywords.png")
        page.screenshot(path=shot2)
        print(f"Captured Detail keywords: {shot2}")

        # Tap genre or keyword chip
        print("Tapping genre/keyword chip on Detail screen...")
        page.mouse.click(70, 540)
        time.sleep(4.0)

        shot3 = os.path.join(SCREENSHOT_DIR, "mode4_prefilter_navigation.png")
        page.screenshot(path=shot3)
        print(f"Captured Mode 4 Pre-Filter Navigation: {shot3}")

        browser.close()

if __name__ == "__main__":
    test_detail_chip()
