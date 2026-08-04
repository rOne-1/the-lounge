import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def test_see_all():
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

        # Click Rail 2 See All at (350, 450)
        print("Clicking Rail 2 'See all' at (350, 450)...", flush=True)
        page.mouse.click(350, 450)
        time.sleep(2.5)

        shot = os.path.join(SCREENSHOT_DIR, "test_see_all_trending.png")
        page.screenshot(path=shot)
        print(f"Captured: {shot}", flush=True)

        browser.close()

if __name__ == "__main__":
    test_see_all()
