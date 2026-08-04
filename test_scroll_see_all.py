import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def test_scroll_see_all():
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

        # Scroll down 120px so Rail 2 header is at y: 385
        print("Scrolling down 120px...", flush=True)
        page.mouse.wheel(0, 120)
        time.sleep(1.0)

        # Click Trending This Week See All at (355, 385)
        print("Clicking Trending This Week 'See all' at (355, 385)...", flush=True)
        page.mouse.click(355, 385)
        time.sleep(2.5)

        shot = os.path.join(SCREENSHOT_DIR, "item_2_01_movies_trending_see_all.png")
        page.screenshot(path=shot)
        print(f"Captured: {shot}", flush=True)

        browser.close()

if __name__ == "__main__":
    test_scroll_see_all()
