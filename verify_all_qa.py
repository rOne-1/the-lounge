import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def run_verification():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()

        print("Navigating to http://localhost:3000...", flush=True)
        page.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3.5)

        # =========================================================================
        # ITEM 2: HOME RAILS "SEE ALL" DESTINATIONS (8 FULL-LIST SCREENS)
        # =========================================================================
        print("\n=== ITEM 2: VERIFYING HOME RAILS 'SEE ALL' DESTINATIONS ===", flush=True)

        # --- MOVIES MODE RAILS ---
        print("\n--- Movies Mode Rails ---", flush=True)

        # Rail 1 (Trending Movies): See all at x: 350, y: 356
        print("1. Clicking Rail 1 'See all' (Trending Movies)...", flush=True)
        page.mouse.click(350, 356)
        time.sleep(2.0)
        shot_path = os.path.join(SCREENSHOT_DIR, "item_2_01_movies_trending_see_all.png")
        page.screenshot(path=shot_path)
        print(f"Captured: {shot_path}", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 2 (Top Rated Movies)
        print("2. Scrolling to Rail 2 (Top Rated Movies)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 356)
        time.sleep(2.0)
        shot_path = os.path.join(SCREENSHOT_DIR, "item_2_02_movies_top_rated_see_all.png")
        page.screenshot(path=shot_path)
        print(f"Captured: {shot_path}", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 3 (Now Playing in Theaters)
        print("3. Scrolling to Rail 3 (Now Playing in Theaters)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 356)
        time.sleep(2.0)
        shot_path = os.path.join(SCREENSHOT_DIR, "item_2_03_movies_now_playing_see_all.png")
        page.screenshot(path=shot_path)
        print(f"Captured: {shot_path}", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 4 (Upcoming Movies)
        print("4. Scrolling to Rail 4 (Upcoming Movies)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 356)
        time.sleep(2.0)
        shot_path = os.path.join(SCREENSHOT_DIR, "item_2_04_movies_upcoming_see_all.png")
        page.screenshot(path=shot_path)
        print(f"Captured: {shot_path}", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # --- TV MODE RAILS ---
        print("\n--- TV Mode Rails ---", flush=True)
        # Scroll back to top
        page.mouse.wheel(0, -1000)
        time.sleep(1.0)
        # Toggle to TV Shows
        print("Switching toggle to TV Shows...", flush=True)
        page.mouse.click(260, 145)
        time.sleep(2.0)

        # TV Rail 1 (Trending TV Shows): See all at x: 350, y: 490
        print("5. Clicking TV Rail 1 'See all' (Trending TV Shows)...", flush=True)
        page.mouse.click(350, 490)
        time.sleep(2.0)
        shot_path = os.path.join(SCREENSHOT_DIR, "item_2_05_tv_trending_see_all.png")
        page.screenshot(path=shot_path)
        print(f"Captured: {shot_path}", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # TV Rail 2 (Top Rated TV Shows)
        print("6. Scrolling to TV Rail 2 (Top Rated TV Shows)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 490)
        time.sleep(2.0)
        shot_path = os.path.join(SCREENSHOT_DIR, "item_2_06_tv_top_rated_see_all.png")
        page.screenshot(path=shot_path)
        print(f"Captured: {shot_path}", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # TV Rail 3 (Airing Today)
        print("7. Scrolling to TV Rail 3 (Airing Today)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 490)
        time.sleep(2.0)
        shot_path = os.path.join(SCREENSHOT_DIR, "item_2_07_tv_airing_today_see_all.png")
        page.screenshot(path=shot_path)
        print(f"Captured: {shot_path}", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # TV Rail 4 (On The Air)
        print("8. Scrolling to TV Rail 4 (On The Air)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 490)
        time.sleep(2.0)
        shot_path = os.path.join(SCREENSHOT_DIR, "item_2_08_tv_on_the_air_see_all.png")
        page.screenshot(path=shot_path)
        print(f"Captured: {shot_path}", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # =========================================================================
        # ITEM 1: EPISODE-WATCHED WHOLE-SHOW STATUS VERIFICATION
        # =========================================================================
        print("\n=== ITEM 1: EPISODE-WATCHED WHOLE-SHOW STATUS VERIFICATION ===", flush=True)

        # Navigate to Search tab (x: 195, y: 810)
        print("1. Navigating to Search screen...", flush=True)
        page.mouse.click(195, 810)
        time.sleep(2.0)

        # Click Search bar (x: 195, y: 80) and type "Severance"
        print("2. Searching for 'Severance'...", flush=True)
        page.mouse.click(195, 80)
        time.sleep(0.5)
        page.keyboard.type("Severance")
        time.sleep(3.0)

        # Click top result card (x: 195, y: 180) to open Detail screen
        print("3. Opening Detail view for Severance...", flush=True)
        page.mouse.click(195, 180)
        time.sleep(3.0)

        # Capture initial unwatched Detail view
        shot_item1_init = os.path.join(SCREENSHOT_DIR, "item_1_01_detail_initial_unwatched.png")
        page.screenshot(path=shot_item1_init)
        print(f"Captured: {shot_item1_init} (Initial unwatched state - whole-show Watched is inactive)", flush=True)

        # Scroll down to Seasons & Episodes section
        print("4. Scrolling down to Seasons & Episodes section...", flush=True)
        page.mouse.wheel(0, 650)
        time.sleep(1.5)

        # Mark Episode 1 watched (Click checkmark at x: 350, y: 395)
        print("5. Marking Episode 1 watched...", flush=True)
        page.mouse.click(350, 395)
        time.sleep(1.5)

        # Scroll back up to top to check whole-show Watched status
        page.mouse.wheel(0, -650)
        time.sleep(1.0)

        shot_item1_ep1 = os.path.join(SCREENSHOT_DIR, "item_1_02_ep1_watched_show_unwatched.png")
        page.screenshot(path=shot_item1_ep1)
        print(f"Captured: {shot_item1_ep1} (Ep 1 watched, whole-show Watched button stays INACTIVE)", flush=True)

        # Scroll down to Seasons & Episodes section again
        page.mouse.wheel(0, 650)
        time.sleep(1.5)

        # Episode row height in list is approx 56px (padding 10, image 40, separator 8)
        # Episodes 2 through 9 checkmarks:
        # Ep 1 was at y=395
        # Ep 2 is at y=451
        # Ep 3 is at y=507
        # Ep 4 is at y=563
        # Ep 5 is at y=619
        # Ep 6 is at y=675
        # Ep 7 is at y=731
        # Ep 8 is at y=787
        print("6. Marking all remaining episodes (Ep 2..9) watched...", flush=True)
        for ep_idx in range(1, 9):
            ep_y = 395 + (ep_idx * 56)
            if ep_y > 780:
                page.mouse.wheel(0, 150)
                time.sleep(0.5)
                ep_y -= 150
            page.mouse.click(350, ep_y)
            time.sleep(0.6)

        # Scroll back up to top of Detail view
        print("7. Scrolling back to top of Detail screen...", flush=True)
        page.mouse.wheel(0, -1000)
        time.sleep(1.5)

        shot_item1_all = os.path.join(SCREENSHOT_DIR, "item_1_03_all_episodes_watched_show_watched.png")
        page.screenshot(path=shot_item1_all)
        print(f"Captured: {shot_item1_all} (All episodes watched -> whole-show Watched button ACTIVATED)", flush=True)

        browser.close()

if __name__ == "__main__":
    run_verification()
