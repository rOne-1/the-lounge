import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_appbar():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        print("Navigating to Search tab (x=195, y=800)...")
        page.mouse.click(195, 800)
        time.sleep(3.0)

        # 1. Test Filters button at (340, 70)
        print("Clicking Filters button at (340, 70)...")
        page.mouse.click(340, 70)
        time.sleep(2.5)

        shot_filter = os.path.join(SCREENSHOT_DIR, "test_appbar_filters.png")
        page.screenshot(path=shot_filter)
        print(f"Captured Filters sheet: {shot_filter}")

        # Close sheet if open (click backdrop at x=195, y=100)
        page.mouse.click(195, 100)
        time.sleep(1.5)

        # 2. Test Search field at (195, 130)
        print("Clicking search bar at (195, 130)...")
        page.mouse.click(195, 130)
        time.sleep(0.5)

        print("Typing 'Batman'...")
        page.keyboard.type("Batman")
        time.sleep(3.5)

        shot_batman = os.path.join(SCREENSHOT_DIR, "test_appbar_batman.png")
        page.screenshot(path=shot_batman)
        print(f"Captured Search 'Batman': {shot_batman}")

        browser.close()

if __name__ == "__main__":
    test_appbar()
