import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_sheet():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # Go to Search tab
        page.mouse.click(195, 800)
        time.sleep(3.0)

        # Tap Filters action at (340, 108)
        print("Tapping Filters action at (340, 108)...")
        page.mouse.click(340, 108)
        time.sleep(2.5)

        shot1 = os.path.join(SCREENSHOT_DIR, "test_sheet_open.png")
        page.screenshot(path=shot1)
        print(f"Captured sheet: {shot1}")

        browser.close()

if __name__ == "__main__":
    test_sheet()
