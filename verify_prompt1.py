import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\547086c9-d1c3-46b0-9ceb-a5697a0b9483"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_p1_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def run_qa():
    print("\n=======================================================")
    print("STARTING LIVE BROWSER VISUAL QA VERIFICATION (PROMPT 1/3)")
    print("=======================================================\n")
    
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()

        # Step 1: Open localhost:3000
        print("1. Navigating to http://localhost:3000...")
        page.goto("http://localhost:3000", wait_until="load")
        time.sleep(3)

        # -------------------------------------------------------------
        # CASE 1: Movie with Collection & IMDb ID ("Dune")
        # -------------------------------------------------------------
        print("\n--- CASE 1: Movie with Collection & IMDb ID ('Dune') ---")
        print("Navigating to Search tab (x: 195, y: 810)...")
        page.mouse.click(195, 810)
        time.sleep(1.5)

        # Search for "Dune"
        print("Searching for 'Dune'...")
        page.mouse.click(195, 80) # Click search field
        page.keyboard.press("Control+A")
        page.keyboard.press("Backspace")
        page.keyboard.type("Dune")
        time.sleep(2.5)

        # Click top search result (approx x: 195, y: 180)
        print("Clicking top search result for 'Dune'...")
        page.mouse.click(195, 180)
        time.sleep(3.0)

        shot1_top = os.path.join(SCREENSHOT_DIR, "p1_1_movie_dune_details_top.png")
        page.screenshot(path=shot1_top)
        print(f"Captured: {shot1_top}")

        # Scroll down to capture details
        print("Scrolling down on Dune Detail screen...")
        page.mouse.wheel(0, 450)
        time.sleep(1.5)

        shot1_bottom = os.path.join(SCREENSHOT_DIR, "p1_1_movie_dune_details_bottom.png")
        page.screenshot(path=shot1_bottom)
        print(f"Captured: {shot1_bottom}")

        # Scroll further down to see cast, director, keywords, production companies
        print("Scrolling further down...")
        page.mouse.wheel(0, 450)
        time.sleep(1.5)

        shot1_keywords = os.path.join(SCREENSHOT_DIR, "p1_1_movie_dune_keywords_production.png")
        page.screenshot(path=shot1_keywords)
        print(f"Captured: {shot1_keywords}")

        # -------------------------------------------------------------
        # CASE 4A: Tap Genre Chip on Detail Screen
        # -------------------------------------------------------------
        print("\n--- CASE 4A: Interactive Genre Chip Navigation ---")
        # Scroll back up slightly to see genre chip or click genre chip at top
        page.mouse.wheel(0, -700)
        time.sleep(1.0)
        
        # Take screenshot of genre chips before tapping
        # Click first genre chip area (approx x: 70, y: 390 depending on Dune layout)
        # Let's tap the genre chip
        print("Tapping Genre Chip on Dune detail screen...")
        page.mouse.click(60, 390)
        time.sleep(2.5)

        shot4_genre = os.path.join(SCREENSHOT_DIR, "p1_4_interactive_genre_chip_browse.png")
        page.screenshot(path=shot4_genre)
        print(f"Captured: {shot4_genre}")

        # Pop back from BrowseScreen to DetailScreen
        print("Navigating back to Detail screen...")
        page.mouse.click(30, 55)
        time.sleep(1.5)

        # -------------------------------------------------------------
        # CASE 4B: Tap Keyword Chip on Detail Screen
        # -------------------------------------------------------------
        print("\n--- CASE 4B: Interactive Keyword Chip Navigation ---")
        # Scroll down to keywords section
        page.mouse.wheel(0, 700)
        time.sleep(1.5)

        print("Tapping Keyword Chip (#keyword)...")
        # Click first keyword chip location
        page.mouse.click(70, 400)
        time.sleep(2.5)

        shot4_kw = os.path.join(SCREENSHOT_DIR, "p1_4_interactive_keyword_chip_browse.png")
        page.screenshot(path=shot4_kw)
        print(f"Captured: {shot4_kw}")

        # Pop back from BrowseScreen
        print("Navigating back from BrowseScreen...")
        page.mouse.click(30, 55)
        time.sleep(1.5)

        # Pop back from DetailScreen to SearchScreen
        print("Navigating back to Search tab...")
        page.mouse.click(30, 55)
        time.sleep(1.5)

        # -------------------------------------------------------------
        # CASE 2: TV Show with Networks & Creator ("Severance")
        # -------------------------------------------------------------
        print("\n--- CASE 2: TV Show with Networks & Creator ('Severance') ---")
        print("Searching for 'Severance'...")
        page.mouse.click(195, 80) # Click search field
        page.keyboard.press("Control+A")
        page.keyboard.press("Backspace")
        page.keyboard.type("Severance")
        time.sleep(2.5)

        print("Clicking top search result for 'Severance'...")
        page.mouse.click(195, 180)
        time.sleep(3.0)

        shot2_top = os.path.join(SCREENSHOT_DIR, "p1_2_tv_severance_details_top.png")
        page.screenshot(path=shot2_top)
        print(f"Captured: {shot2_top}")

        print("Scrolling down on Severance Detail screen...")
        page.mouse.wheel(0, 500)
        time.sleep(1.5)

        shot2_bottom = os.path.join(SCREENSHOT_DIR, "p1_2_tv_severance_details_bottom.png")
        page.screenshot(path=shot2_bottom)
        print(f"Captured: {shot2_bottom}")

        # Pop back to Search tab
        print("Navigating back to Search tab...")
        page.mouse.click(30, 55)
        time.sleep(1.5)

        # -------------------------------------------------------------
        # CASE 3: Title with Absent Fields ("Primer")
        # -------------------------------------------------------------
        print("\n--- CASE 3: Title with Absent Fields ('Primer') ---")
        print("Searching for 'Primer'...")
        page.mouse.click(195, 80)
        page.keyboard.press("Control+A")
        page.keyboard.press("Backspace")
        page.keyboard.type("Primer")
        time.sleep(2.5)

        print("Clicking top search result for 'Primer'...")
        page.mouse.click(195, 180)
        time.sleep(3.0)

        shot3 = os.path.join(SCREENSHOT_DIR, "p1_3_absent_fields_graceful.png")
        page.screenshot(path=shot3)
        print(f"Captured: {shot3}")

        browser.close()
        print("\n=======================================================")
        print("LIVE BROWSER VISUAL QA VERIFICATION COMPLETE")
        print("=======================================================\n")

if __name__ == "__main__":
    run_qa()
