import os
import time
from playwright.sync_api import sync_playwright

ARTIFACT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\8e61ecfd-d3a9-4060-9bb1-f1fccf8ee673"
SCREENSHOT_DIR = os.path.join(ARTIFACT_DIR, "glow_qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def run():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()
        
        print("Navigating to http://localhost:3000...")
        page.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3) # Wait for initial render and Flutter web app initialization
        
        print("Toggling to TV Shows tab to show Next Episode card & Discover CTA...")
        # Header toggle TV segment click at (x: 140, y: 215)
        page.mouse.click(140, 215)
        time.sleep(1.0)
        
        print("Capturing frame progression evidence for Ambient Glow cycle (15s total):")
        # t = 0s
        t0_path = os.path.join(SCREENSHOT_DIR, "glow_t0_0s.png")
        page.screenshot(path=t0_path)
        print(f"Captured t=0s -> {t0_path}")
        
        # Wait 7.5s -> t = 7.5s
        time.sleep(7.5)
        t75_path = os.path.join(SCREENSHOT_DIR, "glow_t7_5s.png")
        page.screenshot(path=t75_path)
        print(f"Captured t=7.5s -> {t75_path}")
        
        # Wait 7.5s -> t = 15s
        time.sleep(7.5)
        t15_path = os.path.join(SCREENSHOT_DIR, "glow_t15_0s.png")
        page.screenshot(path=t15_path)
        print(f"Captured t=15s -> {t15_path}")
        
        # Also capture Home screen Movies tab at t=0s and t=7.5s if desired
        print("Toggling back to Movies tab to capture Discover CTA card glow progression...")
        page.mouse.click(70, 215)
        time.sleep(1.0)
        movies_t0 = os.path.join(SCREENSHOT_DIR, "glow_movies_t0.png")
        page.screenshot(path=movies_t0)
        time.sleep(7.5)
        movies_t75 = os.path.join(SCREENSHOT_DIR, "glow_movies_t7_5s.png")
        page.screenshot(path=movies_t75)

        browser.close()
        print("Glow QA script finished successfully!")

if __name__ == "__main__":
    run()
