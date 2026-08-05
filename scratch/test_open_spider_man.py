import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_spiderman():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        print("Clicking Spider-Man poster at (100, 620)...")
        page.mouse.click(100, 620)
        time.sleep(4.0)

        shot1 = os.path.join(SCREENSHOT_DIR, "mode4_01_detail_screen.png")
        page.screenshot(path=shot1)
        print(f"Captured Detail screen: {shot1}")

        print("Scrolling down to genre/keyword chips...")
        page.mouse.wheel(0, 450)
        time.sleep(2.0)

        shot2 = os.path.join(SCREENSHOT_DIR, "mode4_detail_keywords.png")
        page.screenshot(path=shot2)
        print(f"Captured Detail keywords: {shot2}")

        print("Tapping chip on Detail screen at (70, 520)...")
        page.mouse.click(70, 520)
        time.sleep(4.0)

        shot3 = os.path.join(SCREENSHOT_DIR, "mode4_prefilter_navigation.png")
        page.screenshot(path=shot3)
        print(f"Captured Mode 4 Pre-Filter Navigation: {shot3}")

        browser.close()

if __name__ == "__main__":
    test_spiderman()
