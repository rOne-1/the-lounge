import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def test_tv_debug():
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
        time.sleep(4.0)

        # Move mouse over TV toggle and click
        print("Moving to (150, 215) and clicking...", flush=True)
        page.mouse.move(150, 215)
        time.sleep(0.3)
        page.mouse.down()
        time.sleep(0.1)
        page.mouse.up()
        time.sleep(2.5)

        shot1 = os.path.join(SCREENSHOT_DIR, "debug_tv_150.png")
        page.screenshot(path=shot1)
        print(f"Captured: {shot1}", flush=True)

        browser.close()

if __name__ == "__main__":
    test_tv_debug()
