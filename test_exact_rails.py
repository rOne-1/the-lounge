import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32\qa_screenshots"
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def test_exact_rails():
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

        # ---------------------------------------------------------------
        # MOVIES MODE RAILS
        # ---------------------------------------------------------------
        print("\n--- Testing Movies Mode Rails ---", flush=True)

        # Rail 2: Trending This Week ("See all" at x: 350, y: 354)
        print("1. Clicking Rail 2 'See all' (Trending Movies)...", flush=True)
        page.mouse.click(350, 354)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_01_movies_trending_see_all.png"))
        print("Saved item_2_01_movies_trending_see_all.png", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 3: Top Rated
        # Scroll down so Rail 3 title row is at y: 354
        # Rail 2 total height = 24 (top spacing) + 20 (title) + 12 (spacing) + 144 (cards) = 200px
        print("2. Scrolling to Rail 3 (Top Rated Movies)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 354)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_02_movies_top_rated_see_all.png"))
        print("Saved item_2_02_movies_top_rated_see_all.png", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 4: Now Playing
        print("3. Scrolling to Rail 4 (Now Playing in Theaters)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 354)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_03_movies_now_playing_see_all.png"))
        print("Saved item_2_03_movies_now_playing_see_all.png", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 5: Upcoming
        print("4. Scrolling to Rail 5 (Upcoming Movies)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 354)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_04_movies_upcoming_see_all.png"))
        print("Saved item_2_04_movies_upcoming_see_all.png", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # ---------------------------------------------------------------
        # TV MODE RAILS
        # ---------------------------------------------------------------
        print("\n--- Testing TV Mode Rails ---", flush=True)
        # Scroll back to top
        page.mouse.wheel(0, -1000)
        time.sleep(1.0)
        # Switch toggle to TV Shows (x: 260, y: 145)
        print("Switching toggle to TV Shows...", flush=True)
        page.mouse.click(260, 145)
        time.sleep(2.0)

        # Rail 2: Trending TV Shows ("See all" at x: 350, y: 476)
        print("5. Clicking TV Rail 2 'See all' (Trending TV Shows)...", flush=True)
        page.mouse.click(350, 476)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_05_tv_trending_see_all.png"))
        print("Saved item_2_05_tv_trending_see_all.png", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 3: Top Rated TV Shows
        print("6. Scrolling to TV Rail 3 (Top Rated TV Shows)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 476)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_06_tv_top_rated_see_all.png"))
        print("Saved item_2_06_tv_top_rated_see_all.png", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 4: Airing Today
        print("7. Scrolling to TV Rail 4 (Airing Today)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 476)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_07_tv_airing_today_see_all.png"))
        print("Saved item_2_07_tv_airing_today_see_all.png", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        # Rail 5: On The Air
        print("8. Scrolling to TV Rail 5 (On The Air)...", flush=True)
        page.mouse.wheel(0, 200)
        time.sleep(1.0)
        page.mouse.click(350, 476)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_08_tv_on_the_air_see_all.png"))
        print("Saved item_2_08_tv_on_the_air_see_all.png", flush=True)
        # Go back
        page.mouse.click(30, 35)
        time.sleep(1.5)

        browser.close()

if __name__ == "__main__":
    test_exact_rails()
