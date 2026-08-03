import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\efd9e655-15b4-432f-915d-618a5d59fccd"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def run_qa():
    print("Starting QA verification...")
    with sync_playwright() as p:
        # Launch browser
        browser = p.chromium.launch(headless=True)
        
        # Test 1: Desktop Viewport (1280x800)
        print("\n--- Testing Desktop Viewport (1280x800) ---")
        d_context = browser.new_context(viewport={'width': 1280, 'height': 800})
        d_page = d_context.new_page()
        
        d_page.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3)
        
        # Capture Desktop Home screen (Item 4: Desktop header & toggle, Item 5: clean vertical spacing)
        path_d_home = os.path.join(SCREENSHOT_DIR, "desktop_home_screen.png")
        d_page.screenshot(path=path_d_home)
        print(f"Captured: {path_d_home}")
        
        # Test 2: Mobile Viewport (390x844)
        print("\n--- Testing Mobile Viewport (390x844) ---")
        m_context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        m_page = m_context.new_page()
        
        m_page.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3)
        
        path_m_home = os.path.join(SCREENSHOT_DIR, "mobile_home_screen.png")
        m_page.screenshot(path=path_m_home)
        print(f"Captured: {path_m_home}")
        
        d_context.close()
        m_context.close()
        browser.close()

if __name__ == "__main__":
    run_qa()
