import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\b253e635-21ee-4cce-bcfa-daf0cc517f32\qa_screenshots"
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def run_qa():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()
        
        print("1. Navigating to http://localhost:3000...")
        page.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3)
        
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "00_home_initial.png"))
        print("Saved 00_home_initial.png")
        
        browser.close()

if __name__ == "__main__":
    run_qa()
