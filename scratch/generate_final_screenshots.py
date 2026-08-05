import os
import time
import json
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

URL = "http://127.0.0.1:3008"

def generate_final():
    print("\n=======================================================")
    print("GENERATING FINAL SCREENSHOT EVIDENCE FOR LIVE BROWSER QA")
    print("=======================================================\n", flush=True)

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()

        # -------------------------------------------------------------
        # STEP 1: MODE 1 (Discover Mode)
        # -------------------------------------------------------------
        print("1. Opening app & navigating to Search tab...", flush=True)
        page.goto(URL, wait_until="load")
        time.sleep(4.0)

        page.mouse.click(195, 800) # Search tab in bottom nav
        time.sleep(3.5)

        shot1 = os.path.join(SCREENSHOT_DIR, "mode1_discover_mode.png")
        page.screenshot(path=shot1)
        print(f"Captured: {shot1}", flush=True)

        # -------------------------------------------------------------
        # STEP 2: MODE 2 (Search Mode)
        # -------------------------------------------------------------
        print("2. Entering search text 'Batman'...", flush=True)
        page.mouse.click(195, 130) # Search bar input
        time.sleep(0.5)
        page.keyboard.type("Batman")
        time.sleep(3.5)

        shot2 = os.path.join(SCREENSHOT_DIR, "mode2_search_mode.png")
        page.screenshot(path=shot2)
        print(f"Captured: {shot2}", flush=True)

        # -------------------------------------------------------------
        # STEP 3: FILTERED SEARCH (TV Mode Toggle)
        # -------------------------------------------------------------
        print("3. Toggling to TV Mode while searching 'Batman'...", flush=True)
        page.mouse.click(265, 135) # TV toggle pill
        time.sleep(3.5)

        shot3 = os.path.join(SCREENSHOT_DIR, "mode3_filtered_search.png")
        page.screenshot(path=shot3)
        print(f"Captured: {shot3}", flush=True)

        # -------------------------------------------------------------
        # STEP 4: INCOMING PRE-FILTER NAVIGATION
        # -------------------------------------------------------------
        print("4. Navigating from Detail view via Keyword chip...", flush=True)
        page.mouse.click(195, 130) # Focus search input
        time.sleep(0.3)
        page.keyboard.press("Control+A")
        page.keyboard.press("Backspace") # Clear search input
        time.sleep(2.0)

        # Open Detail view for Spider-Man from Discover grid
        page.mouse.click(80, 380)
        time.sleep(4.0)

        # Scroll down to Keywords section on Detail view
        page.mouse.wheel(0, 600)
        time.sleep(2.0)

        # Tap #superhero team keyword chip at (180, 715)
        page.mouse.click(180, 715)
        time.sleep(4.0)

        shot4 = os.path.join(SCREENSHOT_DIR, "mode4_prefilter_navigation.png")
        page.screenshot(path=shot4)
        print(f"Captured: {shot4}", flush=True)

        # -------------------------------------------------------------
        # STEP 5: PAGINATION (Load More)
        # -------------------------------------------------------------
        print("5. Verifying Load More pagination button...", flush=True)
        page.mouse.wheel(0, 900)
        time.sleep(2.0)

        shot5 = os.path.join(SCREENSHOT_DIR, "mode5_pagination.png")
        page.screenshot(path=shot5)
        print(f"Captured: {shot5}", flush=True)

        browser.close()

    print("\nALL SCREENSHOTS SUCCESSFULLY GENERATED!\n")

if __name__ == "__main__":
    generate_final()
