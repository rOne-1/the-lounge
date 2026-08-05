import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")

def test_typing():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # Tap Search tab
        print("Tapping Search tab at (195, 800)...")
        page.mouse.click(195, 800)
        time.sleep(3.0)

        # Click center of search bar at (195, 175)
        print("Tapping search bar at (195, 175)...")
        page.mouse.click(195, 175)
        time.sleep(1.0)

        # Type "Batman" using keyboard.type with delay
        print("Typing 'Batman'...")
        page.keyboard.type("Batman", delay=100)
        time.sleep(3.0)

        shot1 = os.path.join(SCREENSHOT_DIR, "test_typing_batman.png")
        page.screenshot(path=shot1)
        print(f"Captured: {shot1}")

        # Check if text appeared or search triggered
        # Try another approach: click search bar, insert text via press
        print("Trying press per char...")
        page.mouse.click(195, 175)
        time.sleep(0.5)
        for ch in "Dune":
            page.keyboard.press(ch)
            time.sleep(0.1)
        time.sleep(3.0)

        shot2 = os.path.join(SCREENSHOT_DIR, "test_typing_dune.png")
        page.screenshot(path=shot2)
        print(f"Captured: {shot2}")

        browser.close()

if __name__ == "__main__":
    test_typing()
