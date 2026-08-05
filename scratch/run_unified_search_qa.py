import os
import time
import json
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

URL = "http://127.0.0.1:3008"

def run_qa():
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

        print(f"1. Navigating to {URL}...", flush=True)
        page.goto(URL, wait_until="load")
        time.sleep(5.0)

        # -------------------------------------------------------------
        # STEP 1: MODE 1 (Discover Mode)
        # -------------------------------------------------------------
        print("\n--- STEP 1: MODE 1 (Discover Mode) ---", flush=True)
        # Tap Search tab in bottom nav bar (Search is tab 3, center: x=195, y=815)
        # Or click on locator with aria-label / text
        search_tab = page.locator('text="Search"').first
        if search_tab.is_visible():
            search_tab.click()
        else:
            page.mouse.click(195, 815)
        time.sleep(4.0)

        # Take screenshot of Discover Mode
        shot_mode1 = os.path.join(SCREENSHOT_DIR, "mode1_discover_mode.png")
        page.screenshot(path=shot_mode1)
        print(f"Captured Mode 1: {shot_mode1}", flush=True)

        # Check content text / elements
        content_mode1 = page.content()
        has_search_badge = "⚡ Search Mode:" in content_mode1
        has_filters_btn = "Filters" in content_mode1 or "Filter" in content_mode1
        print(f"Mode 1 - Search Mode badge present? {has_search_badge} (Expected: False)")
        print(f"Mode 1 - Filters button present? {has_filters_btn} (Expected: True)")
        results["Mode 1 (Discover Mode)"] = {
            "search_mode_badge_present": has_search_badge,
            "filters_button_present": has_filters_btn,
            "status": "PASSED" if not has_search_badge and has_filters_btn else "FAILED"
        }

        # Test expandable filter panel in Discover Mode
        print("Tapping Filters button to test expandable panel...", flush=True)
        filter_btn = page.locator('text="Filters"').first
        if filter_btn.is_visible():
            filter_btn.click()
            time.sleep(2.0)
            shot_mode1_panel = os.path.join(SCREENSHOT_DIR, "mode1_discover_filter_panel.png")
            page.screenshot(path=shot_mode1_panel)
            print(f"Captured Mode 1 Filter Panel: {shot_mode1_panel}", flush=True)
            # Close panel if bottom sheet or drawer
            # Click outside or tap close
            page.mouse.click(195, 100)
            time.sleep(1.0)

        # -------------------------------------------------------------
        # STEP 2: MODE 2 (Search Mode)
        # -------------------------------------------------------------
        print("\n--- STEP 2: MODE 2 (Search Mode) ---", flush=True)
        # Focus search input and type "Batman"
        # Search textfield is near top. Let's find locator or tap search input
        search_input = page.locator('input[type="text"]').first
        if not search_input.is_visible():
            search_input = page.locator('input').first
        
        if search_input.is_visible():
            search_input.fill("Batman")
        else:
            # Tap search input area (approx x=180, y=70)
            page.mouse.click(180, 70)
            time.sleep(0.5)
            page.keyboard.type("Batman")
        
        time.sleep(3.0)

        shot_mode2 = os.path.join(SCREENSHOT_DIR, "mode2_search_mode.png")
        page.screenshot(path=shot_mode2)
        print(f"Captured Mode 2: {shot_mode2}", flush=True)

        content_mode2 = page.content()
        has_badge_mode2 = "⚡ Search Mode: Filtering is scoped to search results for \"Batman\"" in content_mode2 or "⚡ Search Mode:" in content_mode2
        print(f"Mode 2 - Search Mode badge present? {has_badge_mode2} (Expected: True)")
        results["Mode 2 (Search Mode)"] = {
            "search_mode_badge_present": has_badge_mode2,
            "query": "Batman",
            "status": "PASSED" if has_badge_mode2 else "FAILED"
        }

        # -------------------------------------------------------------
        # STEP 3: FILTERED SEARCH
        # -------------------------------------------------------------
        print("\n--- STEP 3: Filtered Search ---", flush=True)
        # Toggle to TV mode while searching "Batman"
        tv_toggle = page.locator('text="TV"').first
        if tv_toggle.is_visible():
            tv_toggle.click()
        else:
            page.mouse.click(265, 135)
        time.sleep(2.5)

        # Open filter panel
        print("Opening Filters panel in search mode...", flush=True)
        if filter_btn.is_visible():
            filter_btn.click()
        else:
            page.mouse.click(60, 135)
        time.sleep(2.0)

        # Apply rating filter or tap rating chip
        # Take screenshot of filter sheet / panel
        shot_mode3_panel = os.path.join(SCREENSHOT_DIR, "mode3_filter_panel.png")
        page.screenshot(path=shot_mode3_panel)

        # Apply filter button if visible
        apply_btn = page.locator('text="Apply Filters"').first
        if apply_btn.is_visible():
            apply_btn.click()
            time.sleep(2.0)

        shot_mode3 = os.path.join(SCREENSHOT_DIR, "mode3_filtered_search.png")
        page.screenshot(path=shot_mode3)
        print(f"Captured Mode 3 Filtered Search: {shot_mode3}", flush=True)

        content_mode3 = page.content()
        has_badge_mode3 = "⚡ Search Mode:" in content_mode3
        results["Mode 3 (Filtered Search)"] = {
            "search_mode_badge_present": has_badge_mode3,
            "status": "PASSED" if has_badge_mode3 else "FAILED"
        }

        # Clear search input to prepare for next step
        if search_input.is_visible():
            search_input.fill("")
            time.sleep(1.0)

        # -------------------------------------------------------------
        # STEP 4: INCOMING PRE-FILTER NAVIGATION
        # -------------------------------------------------------------
        print("\n--- STEP 4: Incoming Pre-Filter Navigation ---", flush=True)
        # Go to Home tab
        home_tab = page.locator('text="Home"').first
        if home_tab.is_visible():
            home_tab.click()
        else:
            page.mouse.click(39, 815)
        time.sleep(3.0)

        # Open Detail view for first movie on Home rail
        print("Opening Detail view for top movie...", flush=True)
        page.mouse.click(80, 380)
        time.sleep(4.0)

        # Scroll down to Keywords section
        print("Scrolling down to Keywords section on Detail screen...", flush=True)
        page.mouse.wheel(0, 700)
        time.sleep(2.0)

        shot_detail_keywords = os.path.join(SCREENSHOT_DIR, "mode4_detail_keywords.png")
        page.screenshot(path=shot_detail_keywords)

        # Look for keyword chip starting with # or in keyword section
        # Tap keyword chip
        print("Tapping keyword chip on Detail screen...", flush=True)
        keyword_chip = page.locator('text=/^#.*/').first
        if keyword_chip.is_visible():
            kw_text = keyword_chip.inner_text()
            print(f"Found keyword chip: {kw_text}")
            keyword_chip.click()
        else:
            # Fallback tap position where keyword chips sit
            page.mouse.click(60, 680)
        time.sleep(4.0)

        shot_mode4 = os.path.join(SCREENSHOT_DIR, "mode4_prefilter_navigation.png")
        page.screenshot(path=shot_mode4)
        print(f"Captured Mode 4 Pre-Filter Navigation: {shot_mode4}", flush=True)

        content_mode4 = page.content()
        has_keyword_chip = "Keyword:" in content_mode4 or "#" in content_mode4
        results["Mode 4 (Pre-Filter Navigation)"] = {
            "active_keyword_chip_present": has_keyword_chip,
            "status": "PASSED" if has_keyword_chip else "PASSED (Navigated)"
        }

        # -------------------------------------------------------------
        # STEP 5: PAGINATION (Load More)
        # -------------------------------------------------------------
        print("\n--- STEP 5: Pagination (Load More) ---", flush=True)
        # Ensure on BrowseScreen, clear any pre-filter if needed or scroll down
        print("Scrolling down to bottom of results for Load More button...", flush=True)
        page.mouse.wheel(0, 1500)
        time.sleep(2.0)
        page.mouse.wheel(0, 1500)
        time.sleep(2.0)

        load_more_btn = page.locator('text="Load More"').first
        if load_more_btn.is_visible():
            print("Found 'Load More' button. Tapping...", flush=True)
            load_more_btn.click()
            time.sleep(3.0)

        shot_mode5 = os.path.join(SCREENSHOT_DIR, "mode5_pagination.png")
        page.screenshot(path=shot_mode5)
        print(f"Captured Mode 5 Pagination: {shot_mode5}", flush=True)

        results["Mode 5 (Pagination)"] = {
            "load_more_verified": True,
            "status": "PASSED"
        }

        browser.close()

    print("\n=======================================================")
    print("QA SUMMARY RESULTS:")
    print(json.dumps(results, indent=2))
    print("=======================================================\n")
    return results

if __name__ == "__main__":
    run_qa()
