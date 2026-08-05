import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

URL = "http://127.0.0.1:3008"

def test_steps():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()

        print(f"Navigating to {URL}...", flush=True)
        page.goto(URL, wait_until="load")
        time.sleep(4.0)

        # -------------------------------------------------------------
        # STEP 1: MODE 1 (Discover Mode)
        # -------------------------------------------------------------
        print("\n=== STEP 1: MODE 1 (Discover Mode) ===")
        print("Navigating to Search / Browse tab (click x=195, y=810)...")
        page.mouse.click(195, 810)
        time.sleep(3.5)

        shot_mode1 = os.path.join(SCREENSHOT_DIR, "mode1_discover_mode.png")
        page.screenshot(path=shot_mode1)
        print(f"Captured: {shot_mode1}")

        # Test Filter panel in Discover Mode (Filter button is around x=60, y=125 or x=330, y=70)
        # Let's check where Filter button is
        print("Opening Filter sheet/panel...")
        # In BrowseScreen top bar or filter bar: Filter button icon is at x=45, y=125 or near search bar
        page.mouse.click(45, 125)
        time.sleep(2.0)

        shot_mode1_panel = os.path.join(SCREENSHOT_DIR, "mode1_discover_filter_panel.png")
        page.screenshot(path=shot_mode1_panel)
        print(f"Captured: {shot_mode1_panel}")

        # Close filter sheet by tapping backdrop (x=195, y=150)
        page.mouse.click(195, 150)
        time.sleep(1.5)

        # -------------------------------------------------------------
        # STEP 2: MODE 2 (Search Mode)
        # -------------------------------------------------------------
        print("\n=== STEP 2: MODE 2 (Search Mode) ===")
        print("Clicking search bar (x=180, y=70) and typing 'Batman'...")
        page.mouse.click(180, 70)
        time.sleep(0.5)
        page.keyboard.press("Control+A")
        page.keyboard.press("Backspace")
        page.keyboard.type("Batman")
        time.sleep(3.5)

        shot_mode2 = os.path.join(SCREENSHOT_DIR, "mode2_search_mode.png")
        page.screenshot(path=shot_mode2)
        print(f"Captured: {shot_mode2}")

        # -------------------------------------------------------------
        # STEP 3: FILTERED SEARCH
        # -------------------------------------------------------------
        print("\n=== STEP 3: Filtered Search ===")
        print("Toggling to TV mode...")
        # Toggle button: Movies/TV pill segment at x=265, y=125
        page.mouse.click(265, 125)
        time.sleep(2.5)

        print("Opening Filter Sheet...")
        page.mouse.click(45, 125)
        time.sleep(2.0)

        shot_mode3_panel = os.path.join(SCREENSHOT_DIR, "mode3_filter_panel.png")
        page.screenshot(path=shot_mode3_panel)
        print(f"Captured: {shot_mode3_panel}")

        # Close filter sheet
        page.mouse.click(195, 150)
        time.sleep(1.5)

        shot_mode3 = os.path.join(SCREENSHOT_DIR, "mode3_filtered_search.png")
        page.screenshot(path=shot_mode3)
        print(f"Captured: {shot_mode3}")

        # -------------------------------------------------------------
        # STEP 4: INCOMING PRE-FILTER NAVIGATION
        # -------------------------------------------------------------
        print("\n=== STEP 4: Incoming Pre-Filter Navigation ===")
        # Go to Home tab (x=40, y=810)
        page.mouse.click(40, 810)
        time.sleep(3.0)

        print("Opening top movie from Home rail...")
        page.mouse.click(80, 380)
        time.sleep(4.0)

        print("Scrolling down to Keywords section...")
        page.mouse.wheel(0, 600)
        time.sleep(2.0)

        shot_detail_keywords = os.path.join(SCREENSHOT_DIR, "mode4_detail_keywords.png")
        page.screenshot(path=shot_detail_keywords)
        print(f"Captured: {shot_detail_keywords}")

        print("Tapping keyword chip...")
        # Click on keyword chip location (around x=70, y=680 or y=620)
        page.mouse.click(70, 680)
        time.sleep(4.0)

        shot_mode4 = os.path.join(SCREENSHOT_DIR, "mode4_prefilter_navigation.png")
        page.screenshot(path=shot_mode4)
        print(f"Captured: {shot_mode4}")

        # -------------------------------------------------------------
        # STEP 5: PAGINATION
        # -------------------------------------------------------------
        print("\n=== STEP 5: Pagination (Load More) ===")
        print("Scrolling down to bottom...")
        page.mouse.wheel(0, 1200)
        time.sleep(1.5)
        page.mouse.wheel(0, 1200)
        time.sleep(1.5)

        # Tap Load More (around x=195, y=750)
        print("Tapping Load More button...")
        page.mouse.click(195, 750)
        time.sleep(3.0)

        shot_mode5 = os.path.join(SCREENSHOT_DIR, "mode5_pagination.png")
        page.screenshot(path=shot_mode5)
        print(f"Captured: {shot_mode5}")

        browser.close()

if __name__ == "__main__":
    test_steps()
