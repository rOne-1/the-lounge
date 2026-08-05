import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_prefilter():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # 1. Open movie detail from Home rail (Spider-Man at x=80, y=420)
        print("Opening Spider-Man detail from Home...")
        page.mouse.click(80, 420)
        time.sleep(4.0)

        shot1 = os.path.join(SCREENSHOT_DIR, "mode4_01_detail_top.png")
        page.screenshot(path=shot1)

        # Scroll down on detail page to see genres and keywords
        print("Scrolling down on detail page...")
        page.mouse.wheel(0, 500)
        time.sleep(2.0)

        shot2 = os.path.join(SCREENSHOT_DIR, "mode4_02_detail_keywords.png")
        page.screenshot(path=shot2)
        print(f"Captured detail keywords: {shot2}")

        # Tap genre or keyword chip at (80, 520) or (60, 470)
        print("Tapping chip at (80, 520)...")
        page.mouse.click(80, 520)
        time.sleep(4.0)

        shot3 = os.path.join(SCREENSHOT_DIR, "mode4_prefilter_navigation.png")
        page.screenshot(path=shot3)
        print(f"Captured Mode 4 Pre-Filter Navigation: {shot3}")

        browser.close()

if __name__ == "__main__":
    test_prefilter()
