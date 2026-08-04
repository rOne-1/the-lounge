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
        time.sleep(5.0)

        # -------------------------------------------------------------
        # TEST 1: Incoming Pre-Filter Navigation via Keyword Chip
        # -------------------------------------------------------------
        print("\n--- TEST 1: Incoming Pre-Filter Navigation via Keyword Chip ---", flush=True)
        print("Opening Detail view for first movie on Home screen...", flush=True)
        page.mouse.click(80, 380)
        time.sleep(4.0)

        print("Scrolling down to Keywords section in Detail view...", flush=True)
        page.mouse.wheel(0, 900)
        time.sleep(2.0)

        shot_test1 = os.path.join(SCREENSHOT_DIR, "p3_01_incoming_keyword_prefilter.png")
        # Tap keyword chip
        page.mouse.click(80, 600)
        time.sleep(4.0)
        page.screenshot(path=shot_test1)
        print(f"Captured: {shot_test1}", flush=True)
        results['Test 1'] = shot_test1

        # -------------------------------------------------------------
        # TEST 2: Cast & Crew Person Autocomplete
        # -------------------------------------------------------------
        print("\n--- TEST 2: Cast & Crew Person Autocomplete ---", flush=True)
        print("Opening Browse Filters panel...", flush=True)
        page.mouse.click(350, 40)
        time.sleep(2.0)

        print("Expanding Cast & Crew section...", flush=True)
        page.mouse.click(100, 450)
        time.sleep(1.5)

        print("Focusing person autocomplete input...", flush=True)
        page.mouse.click(150, 510)
        time.sleep(0.5)
        page.keyboard.type("Christopher Nolan", delay=100)
        time.sleep(3.0)

        print("Selecting Christopher Nolan suggestion...", flush=True)
        page.mouse.click(150, 570)
        time.sleep(1.5)

        print("Applying filters...", flush=True)
        page.mouse.click(195, 790)
        time.sleep(3.0)

        shot_test2 = os.path.join(SCREENSHOT_DIR, "p3_02_person_autocomplete_nolan.png")
        page.screenshot(path=shot_test2)
        print(f"Captured: {shot_test2}", flush=True)
        results['Test 2'] = shot_test2

        # -------------------------------------------------------------
        # TEST 3: Watch Provider & Rating Floor Filtering
        # -------------------------------------------------------------
        print("\n--- TEST 3: Watch Provider & Rating Floor Filtering ---", flush=True)
        print("Resetting active filters...", flush=True)
        page.mouse.click(340, 90)
        time.sleep(1.5)

        print("Opening Filters panel...", flush=True)
        page.mouse.click(350, 40)
        time.sleep(2.0)

        print("Expanding Where to Watch section...", flush=True)
        page.mouse.click(100, 280)
        time.sleep(1.5)

        print("Selecting Netflix provider...", flush=True)
        page.mouse.click(60, 440)
        time.sleep(1.0)

        print("Expanding Rating & Popularity section...", flush=True)
        page.mouse.click(100, 500)
        time.sleep(1.5)

        print("Setting min rating slider to 7.0+...", flush=True)
        page.mouse.click(270, 620)
        time.sleep(1.0)

        print("Selecting 500+ minimum vote count...", flush=True)
        page.mouse.click(230, 690)
        time.sleep(1.0)

        print("Applying provider & rating filters...", flush=True)
        page.mouse.click(195, 790)
        time.sleep(3.0)

        shot_test3 = os.path.join(SCREENSHOT_DIR, "p3_03_provider_rating_votes_filters.png")
        page.screenshot(path=shot_test3)
        print(f"Captured: {shot_test3}", flush=True)
        results['Test 3'] = shot_test3

        # -------------------------------------------------------------
        # TEST 4: TV Specific Filters (Status & Network)
        # -------------------------------------------------------------
        print("\n--- TEST 4: TV Specific Filters (Status & Network) ---", flush=True)
        page.mouse.click(340, 90)
        time.sleep(1.5)

        print("Navigating to Home tab...", flush=True)
        page.mouse.click(50, 810)
        time.sleep(1.5)

        print("Tapping TV mode toggle...", flush=True)
        page.mouse.click(265, 135)
        time.sleep(2.0)

        print("Navigating to Browse tab...", flush=True)
        page.mouse.click(120, 810)
        time.sleep(2.0)

        print("Opening Filters panel for TV shows...", flush=True)
        page.mouse.click(350, 40)
        time.sleep(2.0)

        print("Scrolling down filter sheet...", flush=True)
        page.mouse.wheel(0, 500)
        time.sleep(1.5)

        print("Expanding TV Specifics section...", flush=True)
        page.mouse.click(100, 400)
        time.sleep(1.5)

        print("Selecting 'Returning Series' status...", flush=True)
        page.mouse.click(180, 480)
        time.sleep(1.0)

        print("Selecting 'HBO' network...", flush=True)
        page.mouse.click(60, 560)
        time.sleep(1.0)

        print("Applying TV filters...", flush=True)
        page.mouse.click(195, 790)
        time.sleep(3.0)

        shot_test4 = os.path.join(SCREENSHOT_DIR, "p3_04_tv_specific_filters.png")
        page.screenshot(path=shot_test4)
        print(f"Captured: {shot_test4}", flush=True)
        results['Test 4'] = shot_test4

        browser.close()

    print("\nFINISHED QA VERIFICATIONS!")
    return results

if __name__ == "__main__":
    run_prompt3_qa()
