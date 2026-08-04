import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def find_click():
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

        for x in [130, 140, 150, 160, 170, 180, 190]:
            print(f"Testing click at ({x}, 215)...", flush=True)
            page.mouse.click(x, 215)
            time.sleep(1.0)
            shot = os.path.join(SCREENSHOT_DIR, f"toggle_click_{x}.png")
            page.screenshot(path=shot)

        browser.close()

if __name__ == "__main__":
    find_click()
