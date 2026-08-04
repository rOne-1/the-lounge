import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def test_tv_toggle():
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

        # Click TV segment on SegmentedMediaTypeToggle (x: 124, y: 106)
        print("1. Clicking TV toggle segment (x: 124, y: 106)...", flush=True)
        page.mouse.click(124, 106)
        time.sleep(2.5)

        shot_home_tv = os.path.join(SCREENSHOT_DIR, "00_home_tv_mode.png")
        page.screenshot(path=shot_home_tv)
        print(f"Captured: {shot_home_tv}", flush=True)

        browser.close()

if __name__ == "__main__":
    test_tv_toggle()
