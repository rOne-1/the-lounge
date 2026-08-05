import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_click():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # Go to Search tab
        page.mouse.click(195, 800)
        time.sleep(3.0)

        print("Testing click down/up at (345, 108)...")
        page.mouse.move(345, 108)
        page.mouse.down()
        time.sleep(0.1)
        page.mouse.up()
        time.sleep(2.5)

        shot1 = os.path.join(SCREENSHOT_DIR, "test_filter_click_1.png")
        page.screenshot(path=shot1)
        print(f"Captured: {shot1}")

        # Also try touchscreen tap at (345, 108)
        print("Testing touchscreen tap at (345, 108)...")
        page.touchscreen.tap(345, 108)
        time.sleep(2.5)

        shot2 = os.path.join(SCREENSHOT_DIR, "test_filter_click_2.png")
        page.screenshot(path=shot2)
        print(f"Captured: {shot2}")

        browser.close()

if __name__ == "__main__":
    test_click()
