import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def test_tv_show_item1():
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

        # Switch to TV Shows mode on Home screen (x: 260, y: 145)
        print("1. Switching to TV Shows mode on Home screen...", flush=True)
        page.mouse.click(260, 145)
        time.sleep(2.5)

        # Click the 1st TV Show card in Rail 2 (x: 75, y: 550) to open Detail screen
        print("2. Opening Detail screen for top TV show...", flush=True)
        page.mouse.click(75, 550)
        time.sleep(3.5)

        # Capture initial unwatched Detail view
        shot_item1_init = os.path.join(SCREENSHOT_DIR, "item_1_01_detail_initial_unwatched.png")
        page.screenshot(path=shot_item1_init)
        print(f"Captured: {shot_item1_init} (Initial state: whole-show Watched is inactive)", flush=True)

        # Scroll down to Seasons & Episodes section
        print("3. Scrolling down to Seasons & Episodes section...", flush=True)
        page.mouse.wheel(0, 750)
        time.sleep(2.0)

        # Mark Episode 1 watched (Click checkmark at x: 350)
        # Check episode 1 location on screen
        print("4. Marking Episode 1 watched...", flush=True)
        page.mouse.click(350, 480)
        time.sleep(1.5)

        # Scroll back up to top to verify whole-show Watched button status
        print("5. Scrolling up to verify whole-show Watched status...", flush=True)
        page.mouse.wheel(0, -750)
        time.sleep(1.5)

        shot_item1_ep1 = os.path.join(SCREENSHOT_DIR, "item_1_02_ep1_watched_show_unwatched.png")
        page.screenshot(path=shot_item1_ep1)
        print(f"Captured: {shot_item1_ep1} (Ep 1 watched, whole-show Watched button stays INACTIVE)", flush=True)

        # Scroll down to Seasons & Episodes section again
        page.mouse.wheel(0, 750)
        time.sleep(1.5)

        # Mark all remaining episodes in season watched
        print("6. Marking all remaining episodes in season watched...", flush=True)
        for ep_idx in range(1, 10):
            ep_y = 480 + (ep_idx * 56)
            if ep_y > 780:
                page.mouse.wheel(0, 160)
                time.sleep(0.5)
                ep_y -= 160
            page.mouse.click(350, ep_y)
            time.sleep(0.6)

        # Scroll back up to top of Detail view
        print("7. Scrolling back to top of Detail screen...", flush=True)
        page.mouse.wheel(0, -1200)
        time.sleep(2.0)

        shot_item1_all = os.path.join(SCREENSHOT_DIR, "item_1_03_all_episodes_watched_show_watched.png")
        page.screenshot(path=shot_item1_all)
        print(f"Captured: {shot_item1_all} (All episodes watched -> whole-show Watched button ACTIVATED)", flush=True)

        browser.close()

if __name__ == "__main__":
    test_tv_show_item1()
