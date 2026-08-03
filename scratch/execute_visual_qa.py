import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\c66a6d83-ee3b-4b5b-b46d-61244f60f061\qa_screenshots"
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

def run():
    print("Starting Perfect Playwright Visual QA Verification...")
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()
        
        # 1. Navigate to http://localhost:3000
        print("1. Navigating to http://localhost:3000...")
        page.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3)
        
        # Screenshot 1: Home screen key missing / fallback state
        print("Capturing 01_home_screen_fallback_state.png...")
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "01_home_screen_fallback_state.png"))
        
        # 2. Toggle TV on Home Screen (click TV pill at x: 270, y: 215)
        print("2. Toggling to TV Shows on Home screen...")
        page.mouse.click(270, 215)
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "02_home_tv_toggle_state.png"))
        
        # Toggle back to Movies (click Movies pill at x: 100, y: 215)
        print("Toggling back to Movies...")
        page.mouse.click(100, 215)
        time.sleep(1.0)
        
        # 3. Tab Navigation: Discover Tab (click x: 117, y: 810)
        print("3. Navigating to Discover tab...")
        page.mouse.click(117, 810)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "03_discover_tab_legend_overlay.png"))
        
        # Dismiss Legend overlay by clicking backdrop at (195, 100)
        print("Dismissing Legend overlay...")
        page.mouse.click(195, 100)
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "04_discover_deck_active.png"))
        
        # Swipe off all cards in the deck to reach empty state
        print("Swiping off cards to reach Discover empty state...")
        for i in range(12):
            page.mouse.move(195, 400)
            page.mouse.down()
            page.mouse.move(-250, 400, steps=10)
            page.mouse.up()
            time.sleep(0.3)
            
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "05_discover_empty_state.png"))
        
        # Click "Reload deck" button at (195, 555)
        print("Clicking 'Reload deck' button...")
        page.mouse.click(195, 555)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "06_discover_reloaded_deck.png"))
        
        # 4. Tab Navigation: Search Tab (click x: 195, y: 810)
        print("4. Navigating to Search tab...")
        page.mouse.click(195, 810)
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "07_search_tab_initial.png"))
        
        # Click search input field at (195, 90) and type query
        print("Clicking search bar at (195, 90) and typing query...")
        page.mouse.click(195, 90)
        time.sleep(0.5)
        page.keyboard.type("xyznonexistent123")
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "08_search_empty_state.png"))
        
        # Click "Clear search" button at (195, 470)
        print("Clicking 'Clear search' button...")
        page.mouse.click(195, 470)
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "09_search_cleared_state.png"))
        
        # 5. Tab Navigation: Your Space Tab (click x: 273, y: 810)
        print("5. Navigating to Your Space tab...")
        page.mouse.click(273, 810)
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "10_your_space_tab.png"))
        
        # 6. Tab Navigation: Calendar Tab (click x: 351, y: 810)
        print("6. Navigating to Calendar tab...")
        page.mouse.click(351, 810)
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "11_calendar_tab.png"))
        
        browser.close()
        print("Perfect Visual QA Script completed successfully!")

if __name__ == "__main__":
    run()
