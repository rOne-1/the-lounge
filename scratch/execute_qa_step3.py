import os
import time
import json
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\0cb91cf6-8765-4847-8fe8-2bbfd2ac299e"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "qa_step3_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

findings = {
    "network_errors": [],
    "console_logs": [],
    "api_calls": [],
    "test_results": {}
}

def log_finding(category, text):
    print(f"[{category.upper()}] {text}")

def run_qa():
    print("=== Starting Live Verification & QA Analysis against Real TMDB API ===")
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)

        # -------------------------------------------------------------
        # PHASE 1: MOBILE VIEWPORT (390x844)
        # -------------------------------------------------------------
        print("\n--- Phase 1: Mobile Viewport (390x844) ---")
        context_mobile = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page_mobile = context_mobile.new_page()

        # Listen to console & network
        page_mobile.on("console", lambda msg: findings["console_logs"].append(f"Mobile Console [{msg.type}]: {msg.text}"))
        page_mobile.on("requestfailed", lambda req: findings["network_errors"].append(f"Mobile Request Failed: {req.url} - {req.failure}"))
        page_mobile.on("response", lambda res: findings["api_calls"].append(f"Mobile API: {res.status} {res.url}") if "api.themoviedb.org" in res.url else None)

        print("1. Navigating to http://localhost:3000 (Mobile)...")
        page_mobile.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3.5) # Allow Flutter Web initialization & API fetch

        # Screenshot: Home Screen Movies state
        mobile_home_movies = os.path.join(SCREENSHOT_DIR, "01_mobile_home_movies.png")
        page_mobile.screenshot(path=mobile_home_movies)
        print(f"Saved: {mobile_home_movies}")

        # Ambiance switch: Toggle to Reading Room (top right light icon at x: 350, y: 35)
        print("2. Toggling Ambiance (Screening Room -> Reading Room)...")
        page_mobile.mouse.click(350, 35)
        time.sleep(1.2)
        mobile_reading_room = os.path.join(SCREENSHOT_DIR, "02_mobile_ambiance_reading_room.png")
        page_mobile.screenshot(path=mobile_reading_room)
        print(f"Saved: {mobile_reading_room}")

        # Switch ambiance back to Screening Room
        page_mobile.mouse.click(350, 35)
        time.sleep(1.2)

        # Toggle Movies <-> TV Shows on Home Header (x: 140, y: 215)
        print("3. Toggling to TV Shows tab on Home...")
        page_mobile.mouse.click(140, 215)
        time.sleep(2.0)
        mobile_home_tv = os.path.join(SCREENSHOT_DIR, "03_mobile_home_tv_shows.png")
        page_mobile.screenshot(path=mobile_home_tv)
        print(f"Saved: {mobile_home_tv}")

        # Switch back to Movies tab (x: 70, y: 215)
        page_mobile.mouse.click(70, 215)
        time.sleep(1.0)

        # -------------------------------------------------------------
        # DISCOVER TAB & SWIPE DECK
        # -------------------------------------------------------------
        print("4. Navigating to Discover tab (x: 117, y: 810)...")
        page_mobile.mouse.click(117, 810)
        time.sleep(2.5)

        # Dismiss legend overlay if present (x: 195, y: 100)
        page_mobile.mouse.click(195, 100)
        time.sleep(1.0)
        mobile_discover_deck = os.path.join(SCREENSHOT_DIR, "04_mobile_discover_deck.png")
        page_mobile.screenshot(path=mobile_discover_deck)
        print(f"Saved: {mobile_discover_deck}")

        # Test Swipe Right (Save / Maybe)
        print("Testing Swipe Right (Save)...")
        page_mobile.mouse.move(195, 450)
        page_mobile.mouse.down()
        page_mobile.mouse.move(300, 450, steps=15)
        time.sleep(0.4)
        mobile_swipe_right = os.path.join(SCREENSHOT_DIR, "05_mobile_swipe_right_save.png")
        page_mobile.screenshot(path=mobile_swipe_right)
        page_mobile.mouse.up()
        time.sleep(1.2)

        # Test Swipe Left (Skip)
        print("Testing Swipe Left (Skip)...")
        page_mobile.mouse.move(195, 450)
        page_mobile.mouse.down()
        page_mobile.mouse.move(90, 450, steps=15)
        time.sleep(0.4)
        mobile_swipe_left = os.path.join(SCREENSHOT_DIR, "06_mobile_swipe_left_skip.png")
        page_mobile.screenshot(path=mobile_swipe_left)
        page_mobile.mouse.up()
        time.sleep(1.2)

        # Click top card to open Detail View
        print("5. Opening Detail View from Card Deck...")
        page_mobile.mouse.click(195, 450)
        time.sleep(2.5)
        mobile_detail = os.path.join(SCREENSHOT_DIR, "07_mobile_movie_detail.png")
        page_mobile.screenshot(path=mobile_detail)
        print(f"Saved: {mobile_detail}")

        # Click "Watched" button on Detail screen (x: 314, y: 530)
        print("Marking title as Watched in Detail screen...")
        page_mobile.mouse.click(314, 530)
        time.sleep(1.0)
        mobile_detail_watched = os.path.join(SCREENSHOT_DIR, "08_mobile_movie_detail_watched.png")
        page_mobile.screenshot(path=mobile_detail_watched)

        # Go back to main shell (back button at x: 30, y: 35)
        page_mobile.mouse.click(30, 35)
        time.sleep(1.2)

        # -------------------------------------------------------------
        # SEARCH TAB
        # -------------------------------------------------------------
        print("6. Navigating to Search tab (x: 195, y: 810)...")
        page_mobile.mouse.click(195, 810)
        time.sleep(1.5)

        # Search Title: "Inception"
        print("Searching Title 'Inception'...")
        page_mobile.mouse.click(150, 45) # Click search field
        time.sleep(0.5)
        page_mobile.keyboard.type("Inception", delay=50)
        time.sleep(2.5) # Wait for TMDB search API
        mobile_search_inception = os.path.join(SCREENSHOT_DIR, "09_mobile_search_inception.png")
        page_mobile.screenshot(path=mobile_search_inception)
        print(f"Saved: {mobile_search_inception}")

        # Clear search
        page_mobile.mouse.click(360, 45)
        time.sleep(1.0)

        # Search Person: "Christopher Nolan"
        print("Searching Person 'Christopher Nolan'...")
        page_mobile.mouse.click(150, 45)
        time.sleep(0.5)
        page_mobile.keyboard.type("Christopher Nolan", delay=50)
        time.sleep(2.5)
        mobile_search_nolan = os.path.join(SCREENSHOT_DIR, "10_mobile_search_person_nolan.png")
        page_mobile.screenshot(path=mobile_search_nolan)
        print(f"Saved: {mobile_search_nolan}")

        # Clear search
        page_mobile.mouse.click(360, 45)
        time.sleep(1.0)

        # Search Person: "Pedro Pascal"
        print("Searching Person 'Pedro Pascal'...")
        page_mobile.mouse.click(150, 45)
        time.sleep(0.5)
        page_mobile.keyboard.type("Pedro Pascal", delay=50)
        time.sleep(2.5)
        mobile_search_pascal = os.path.join(SCREENSHOT_DIR, "11_mobile_search_person_pascal.png")
        page_mobile.screenshot(path=mobile_search_pascal)

        # Clear search
        page_mobile.mouse.click(360, 45)
        time.sleep(1.0)

        # Test Failure condition: No results query "xyz123abc999"
        print("Searching No Results Query 'xyz123abc999'...")
        page_mobile.mouse.click(150, 45)
        time.sleep(0.5)
        page_mobile.keyboard.type("xyz123abc999", delay=50)
        time.sleep(2.5)
        mobile_search_no_results = os.path.join(SCREENSHOT_DIR, "12_mobile_search_no_results.png")
        page_mobile.screenshot(path=mobile_search_no_results)
        print(f"Saved: {mobile_search_no_results}")

        # Clear search
        page_mobile.mouse.click(360, 45)
        time.sleep(1.0)

        # -------------------------------------------------------------
        # YOUR SPACE TAB & CALENDAR TAB
        # -------------------------------------------------------------
        print("7. Navigating to Your Space tab (x: 273, y: 810)...")
        page_mobile.mouse.click(273, 810)
        time.sleep(1.5)
        mobile_your_space = os.path.join(SCREENSHOT_DIR, "13_mobile_your_space.png")
        page_mobile.screenshot(path=mobile_your_space)
        print(f"Saved: {mobile_your_space}")

        # Switch to "Watched" tab in Your Space (x: 325, y: 25)
        page_mobile.mouse.click(325, 25)
        time.sleep(1.0)
        mobile_your_space_watched = os.path.join(SCREENSHOT_DIR, "14_mobile_your_space_watched.png")
        page_mobile.screenshot(path=mobile_your_space_watched)

        print("8. Navigating to Calendar tab (x: 350, y: 810)...")
        page_mobile.mouse.click(350, 810)
        time.sleep(2.0)
        mobile_calendar = os.path.join(SCREENSHOT_DIR, "15_mobile_calendar.png")
        page_mobile.screenshot(path=mobile_calendar)
        print(f"Saved: {mobile_calendar}")

        context_mobile.close()

        # -------------------------------------------------------------
        # PHASE 2: DESKTOP VIEWPORT (1280x800)
        # -------------------------------------------------------------
        print("\n--- Phase 2: Expanded Desktop Viewport (1280x800) ---")
        context_desktop = browser.new_context(
            viewport={'width': 1280, 'height': 800},
            device_scale_factor=1,
        )
        page_desktop = context_desktop.new_page()

        page_desktop.on("console", lambda msg: findings["console_logs"].append(f"Desktop Console [{msg.type}]: {msg.text}"))
        page_desktop.on("requestfailed", lambda req: findings["network_errors"].append(f"Desktop Request Failed: {req.url} - {req.failure}"))
        page_desktop.on("response", lambda res: findings["api_calls"].append(f"Desktop API: {res.status} {res.url}") if "api.themoviedb.org" in res.url else None)

        print("1. Navigating to http://localhost:3000 (Desktop)...")
        page_desktop.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3.5)

        # Screenshot Desktop Home Movies
        desktop_home = os.path.join(SCREENSHOT_DIR, "16_desktop_home_movies.png")
        page_desktop.screenshot(path=desktop_home)
        print(f"Saved: {desktop_home}")

        # Desktop Navigation Rail: Nav items are at x=40, y=140 (Home), y=190 (Discover), y=240 (Search), y=290 (Your Space), y=340 (Calendar)
        # Ambiance toggle at x=40, y=35

        # Test Ambiance toggle desktop
        page_desktop.mouse.click(40, 35)
        time.sleep(1.0)
        desktop_reading_room = os.path.join(SCREENSHOT_DIR, "17_desktop_ambiance_reading_room.png")
        page_desktop.screenshot(path=desktop_reading_room)
        page_desktop.mouse.click(40, 35) # Switch back
        time.sleep(1.0)

        # Open Detail screen directly via URL / or clicking card
        # Test TV Show Detail View (e.g. Severance / Breaking Bad)
        print("2. Opening TV Show Detail View on Desktop...")
        # Search for Severance on Search tab (Rail icon at y=240)
        page_desktop.mouse.click(40, 240)
        time.sleep(1.5)
        page_desktop.mouse.click(250, 45) # Search box
        time.sleep(0.5)
        page_desktop.keyboard.type("Severance", delay=50)
        time.sleep(2.5)

        desktop_search_severance = os.path.join(SCREENSHOT_DIR, "18_desktop_search_severance.png")
        page_desktop.screenshot(path=desktop_search_severance)

        # Click first result in search (x: 300, y: 120)
        page_desktop.mouse.click(300, 120)
        time.sleep(2.5)
        desktop_tv_detail = os.path.join(SCREENSHOT_DIR, "19_desktop_tv_detail_severance.png")
        page_desktop.screenshot(path=desktop_tv_detail)
        print(f"Saved: {desktop_tv_detail}")

        # Test Watch Provider Country Selector in Detail View
        # Click Country Dropdown (at approx x: 1100, y: 550 or where "Where to Watch" dropdown is)
        # Let's capture Country selector screenshot
        desktop_watch_providers = os.path.join(SCREENSHOT_DIR, "20_desktop_watch_providers_us.png")
        page_desktop.screenshot(path=desktop_watch_providers)

        # Back button on Detail AppBar (x: 100, y: 35)
        page_desktop.mouse.click(100, 35)
        time.sleep(1.2)

        # Test Failure condition: non-existent ID (e.g. search or direct navigation if supported)
        print("3. Testing non-existent ID search/error handling...")
        # Search for "99999999"
        page_desktop.mouse.click(250, 45)
        page_desktop.keyboard.press("Control+A")
        page_desktop.keyboard.press("Backspace")
        page_desktop.keyboard.type("99999999", delay=50)
        time.sleep(2.5)
        desktop_search_invalid = os.path.join(SCREENSHOT_DIR, "21_desktop_search_invalid_id.png")
        page_desktop.screenshot(path=desktop_search_invalid)

        context_desktop.close()
        browser.close()

    print("\n=== QA Script completed successfully! ===")
    
    # Save findings JSON
    findings_path = os.path.join(ARTIFACT_DIR, "qa_step3_findings.json")
    with open(findings_path, "w") as f:
        json.dump(findings, f, indent=2)
    print(f"Saved QA findings to: {findings_path}")

if __name__ == "__main__":
    run_qa()
