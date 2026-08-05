import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_filtered_search():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # 1. Nav to Search tab
        print("Navigating to Search tab (x=195, y=810)...")
        page.mouse.click(195, 810)
        time.sleep(3.0)

        # 2. Type "Batman" in search bar at (195, 175)
        print("Typing 'Batman' in search bar...")
        page.mouse.click(195, 175)
        time.sleep(0.5)
        page.keyboard.type("Batman")
        time.sleep(3.5)

        shot1 = os.path.join(SCREENSHOT_DIR, "mode2_search_mode.png")
        page.screenshot(path=shot1)
        print(f"Captured Mode 2 (Search Mode): {shot1}")

        # 3. Toggle to TV mode at (265, 135) or (265, 125)
        print("Toggling to TV mode...")
        page.mouse.click(265, 135)
        time.sleep(3.5)

        shot2 = os.path.join(SCREENSHOT_DIR, "mode3_filtered_search.png")
        page.screenshot(path=shot2)
        print(f"Captured Mode 3 (Filtered Search TV): {shot2}")

        browser.close()

if __name__ == "__main__":
    test_filtered_search()
