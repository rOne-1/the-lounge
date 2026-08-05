import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_tap_keyword():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # 1. Open Search tab and click Spider-Man
        page.mouse.click(195, 800)
        time.sleep(3.0)

        page.mouse.click(80, 380)
        time.sleep(4.0)

        # 2. Scroll down on Detail view
        page.mouse.wheel(0, 600)
        time.sleep(2.0)

        # 3. Tap #new york city keyword chip at (180, 715)
        print("Tapping '#new york city' chip at (180, 715)...")
        page.mouse.click(180, 715)
        time.sleep(4.0)

        shot = os.path.join(SCREENSHOT_DIR, "mode4_prefilter_navigation.png")
        page.screenshot(path=shot)
        print(f"Captured Mode 4 Pre-Filter Navigation: {shot}")

        browser.close()

if __name__ == "__main__":
    test_tap_keyword()
