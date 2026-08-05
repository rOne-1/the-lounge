import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_touch():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        print("Touch tapping Search tab at (195, 800)...")
        page.touchscreen.tap(195, 800)
        time.sleep(3.0)

        print("Touch tapping search input at (195, 175)...")
        page.touchscreen.tap(195, 175)
        time.sleep(1.0)

        print("Typing 'Batman'...")
        page.keyboard.type("Batman")
        time.sleep(3.5)

        shot1 = os.path.join(SCREENSHOT_DIR, "test_touch_batman.png")
        page.screenshot(path=shot1)
        print(f"Captured: {shot1}")

        print("Touch tapping Filters button at (315, 108)...")
        page.touchscreen.tap(315, 108)
        time.sleep(2.5)

        shot2 = os.path.join(SCREENSHOT_DIR, "test_touch_filters.png")
        page.screenshot(path=shot2)
        print(f"Captured: {shot2}")

        browser.close()

if __name__ == "__main__":
    test_touch()
