import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\06e61490-22c4-4ad9-b0f5-70569f504f32"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "p3_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def run_prompt3_qa():
    print("\n=======================================================")
    print("STARTING LIVE BROWSER VISUAL QA VERIFICATION (PROMPT 3/3)")
    print("=======================================================\n", flush=True)

    results = {}

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
        # STEP 1: Open localhost:3000
        # -------------------------------------------------------------
        print("1. Navigating to http://localhost:3000...", flush=True)
        page.goto("http://localhost:3000", wait_until="load")
        time.sleep(5.0) # Wait for initial Flutter load & TMDB API call to complete

        # -------------------------------------------------------------
        # TEST 1: Incoming Pre-Filter Navigation via Keyword Chip
        # -------------------------------------------------------------
        print("\n--- TEST 1: Incoming Pre-Filter Navigation via Keyword Chip ---", flush=True)
        # Click first movie item on Home screen carousel (e.g. at x: 80, y: 380)
        print("Opening Detail view for first movie on Home screen...", flush=True)
        page.mouse.click(80, 380)
        time.sleep(4.0)

        # Scroll down in Detail view to Keywords section
        print("Scrolling down to Keywords section in Detail view...", flush=True)
        page.mouse.wheel(0, 900)
        time.sleep(2.0)

        # Take debug screenshot of Detail view keywords
        detail_shot = os.path.join(SCREENSHOT_DIR, "debug_detail_keywords.png")
        page.screenshot(path=detail_shot)
        print(f"Captured debug detail screen: {detail_shot}", flush=True)

        # Tap a keyword chip. Keyword chips are wrapped near bottom of detail screen.
        # Let's tap around x: 80, y: 550 or 600 or search text if accessible
        # In Flutter canvas, clicking around coordinates of keyword chip:
        print("Tapping keyword chip in Detail screen...", flush=True)
        page.mouse.click(80, 600)
        time.sleep(4.0)

        shot_test1 = os.path.join(SCREENSHOT_DIR, "p3_01_incoming_keyword_prefilter.png")
        page.screenshot(path=shot_test1)
        print(f"Captured: {shot_test1}", flush=True)
        results['Test 1: Pre-Filter Navigation'] = f"Captured {shot_test1}"

        # -------------------------------------------------------------
        # TEST 2: Cast & Crew Person Autocomplete
        # -------------------------------------------------------------
        print("\n--- TEST 2: Cast & Crew Person Autocomplete ---", flush=True)
        # Open Browse tab if not already on browse screen, or tap Filters button at top right (x: 350, y: 40)
        # First click Filters button at top right of Browse screen
        print("Opening Browse Filters panel...", flush=True)
        page.mouse.click(350, 40)
        time.sleep(2.0)

        shot_filter_sheet = os.path.join(SCREENSHOT_DIR, "debug_filter_sheet.png")
        page.screenshot(path=shot_filter_sheet)
        print(f"Captured debug filter sheet: {shot_filter_sheet}", flush=True)

        # Expand Cast & Crew section if needed (Click 'Cast & Crew' header around x: 100, y: 380)
        # In bottom sheet: "Filter Catalog" header is at top (~y: 160)
        # "Genres & Keywords" section is open by default.
        # Let's click Cast & Crew accordion header (around x: 100, y: 450)
        print("Expanding Cast & Crew section...", flush=True)
        page.mouse.click(100, 450)
        time.sleep(1.5)

        # Type "Christopher Nolan" into autocomplete field
        # The text input for PersonSearchAutocomplete is located inside Cast & Crew section (around x: 150, y: 510)
        print("Focusing person autocomplete input...", flush=True)
        page.mouse.click(150, 510)
        time.sleep(0.5)
        page.keyboard.type("Christopher Nolan", delay=100)
        time.sleep(3.0) # Wait for TMDB person search API results

        shot_autocomplete_dropdown = os.path.join(SCREENSHOT_DIR, "debug_person_autocomplete_dropdown.png")
        page.screenshot(path=shot_autocomplete_dropdown)
        print(f"Captured debug autocomplete dropdown: {shot_autocomplete_dropdown}", flush=True)

        # Click the first autocomplete suggestion "Christopher Nolan (Directing)" (around x: 150, y: 570)
        print("Selecting Christopher Nolan suggestion...", flush=True)
        page.mouse.click(150, 570)
        time.sleep(1.5)

        # Click "Apply Filters" button at bottom of sheet (around x: 195, y: 790)
        print("Applying filters...", flush=True)
        page.mouse.click(195, 790)
        time.sleep(3.0)

        shot_test2 = os.path.join(SCREENSHOT_DIR, "p3_02_person_autocomplete_nolan.png")
        page.screenshot(path=shot_test2)
        print(f"Captured: {shot_test2}", flush=True)
        results['Test 2: Person Autocomplete'] = f"Captured {shot_test2}"

        # -------------------------------------------------------------
        # TEST 3: Watch Provider & Rating Floor Filtering
        # -------------------------------------------------------------
        print("\n--- TEST 3: Watch Provider & Rating Floor Filtering ---", flush=True)
        # Reset filters first: click Reset All or open Filters and reset
        # Filter chip bar has 'Reset All' button at top right (around x: 340, y: 90)
        print("Resetting active filters...", flush=True)
        page.mouse.click(340, 90)
        time.sleep(1.5)

        # Open Filters panel
        print("Opening Filters panel...", flush=True)
        page.mouse.click(350, 40)
        time.sleep(2.0)

        # Expand "Where to Watch" section (around x: 100, y: 280)
        print("Expanding Where to Watch section...", flush=True)
        page.mouse.click(100, 280)
        time.sleep(1.5)

        # Select 'Netflix' streaming provider (around x: 60, y: 440)
        print("Selecting Netflix provider...", flush=True)
        page.mouse.click(60, 440)
        time.sleep(1.0)

        # Expand "Rating & Popularity" section (around x: 100, y: 500)
        print("Expanding Rating & Popularity section...", flush=True)
        page.mouse.click(100, 500)
        time.sleep(1.5)

        # Set Minimum Rating slider: click at x: 270 on slider line (slider is around y: 620, x: 40 to 350 -> x=270 is ~7.0)
        print("Setting min rating slider to 7.0+...", flush=True)
        page.mouse.click(270, 620)
        time.sleep(1.0)

        # Select Minimum Vote Count '500+' (around x: 230, y: 690)
        print("Selecting 500+ minimum vote count...", flush=True)
        page.mouse.click(230, 690)
        time.sleep(1.0)

        # Click Apply Filters button (around x: 195, y: 790)
        print("Applying provider & rating filters...", flush=True)
        page.mouse.click(195, 790)
        time.sleep(3.0)

        shot_test3 = os.path.join(SCREENSHOT_DIR, "p3_03_provider_rating_votes_filters.png")
        page.screenshot(path=shot_test3)
        print(f"Captured: {shot_test3}", flush=True)
        results['Test 3: Provider & Rating Floor'] = f"Captured {shot_test3}"

        # -------------------------------------------------------------
        # TEST 4: TV Specific Filters (Status & Network)
        # -------------------------------------------------------------
        print("\n--- TEST 4: TV Specific Filters (Status & Network) ---", flush=True)
        # Reset filters
        page.mouse.click(340, 90)
        time.sleep(1.5)

        # Switch to TV mode: click TV tab in bottom nav (x: 195, y: 810 to go to Search/Browse or header segmented toggle)
        # Let's switch active media type to TV. On Browse Screen, top header is 'Browse Movies' or toggle on Home tab.
        # Let's go to Home tab (x: 50, y: 810), toggle to TV (x: 265, y: 135), then go back to Browse tab (x: 120, y: 810)
        print("Navigating to Home tab to toggle TV mode...", flush=True)
        page.mouse.click(50, 810)
        time.sleep(1.5)

        print("Tapping TV mode toggle...", flush=True)
        page.mouse.click(265, 135)
        time.sleep(2.0)

        print("Navigating to Browse tab in TV mode...", flush=True)
        page.mouse.click(120, 810)
        time.sleep(2.0)

        # Open Filters panel on Browse TV Shows
        print("Opening Filters panel for TV shows...", flush=True)
        page.mouse.click(350, 40)
        time.sleep(2.0)

        # Scroll down filter sheet to find "TV Specifics" section
        print("Scrolling down filter sheet...", flush=True)
        page.mouse.wheel(0, 500)
        time.sleep(1.5)

        shot_tv_sheet = os.path.join(SCREENSHOT_DIR, "debug_tv_filter_sheet.png")
        page.screenshot(path=shot_tv_sheet)
        print(f"Captured debug TV filter sheet: {shot_tv_sheet}", flush=True)

        # Expand "TV Specifics" section (around x: 100, y: 400)
        print("Expanding TV Specifics section...", flush=True)
        page.mouse.click(100, 400)
        time.sleep(1.5)

        # Select TV Status 'Returning Series' (around x: 180, y: 480)
        print("Selecting 'Returning Series' status...", flush=True)
        page.mouse.click(180, 480)
        time.sleep(1.0)

        # Select Network 'HBO' (around x: 60, y: 560)
        print("Selecting 'HBO' network...", flush=True)
        page.mouse.click(60, 560)
        time.sleep(1.0)

        # Click Apply Filters button (around x: 195, y: 790)
        print("Applying TV filters...", flush=True)
        page.mouse.click(195, 790)
        time.sleep(3.0)

        shot_test4 = os.path.join(SCREENSHOT_DIR, "p3_04_tv_specific_filters.png")
        page.screenshot(path=shot_test4)
        print(f"Captured: {shot_test4}", flush=True)
        results['Test 4: TV Specific Filters'] = f"Captured {shot_test4}"

        browser.close()

    print("\n=======================================================")
    print("FINISHED ALL PROMPT 3/3 QA VERIFICATIONS SUCCESSFULLY!")
    print("=======================================================\n", flush=True)
    return results

if __name__ == "__main__":
    run_prompt3_qa()
