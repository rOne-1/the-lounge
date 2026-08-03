import os
import time
from playwright.sync_api import sync_playwright

SCREENSHOT_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\de0a587a-5ed8-458a-983d-69401a1268f7\qa_screenshots"
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
        
        print("1. Navigating to http://localhost:3000...")
        page.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3)
        
        # 1. Home Screen initial Movies state (Item 7 Movies state & Item 6/8 Ambiance)
        print("2. Capturing Home screen Movies state...")
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_7_home_movies_state.png"))
        
        # Click TV segment on Home screen header toggle (x: 140, y: 215)
        print("3. Toggling to TV Shows on Home screen...")
        page.mouse.click(140, 215)
        time.sleep(1.5)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_7_home_tv_shows_next_episode_expanded.png"))
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_6_8_ambient_glow_and_noise_texture.png"))
        print("Captured TV Shows state & Ambient Glow / Noise Texture.")
        
        # 2. Switch to Discover tab (x: 117, y: 810)
        print("4. Navigating to Discover tab...")
        page.mouse.click(117, 810)
        time.sleep(2.5)
        
        # Item 3 & 5 screenshots
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_3_legend_cta_above_navbar.png"))
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_5_compact_layout_single_toggle.png"))
        print("Captured Legend CTA above Navbar & Compact Single Toggle screenshots.")

        # Dismiss legend by clicking backdrop at (195, 100)
        print("5. Dismissing Legend overlay...")
        page.mouse.click(195, 100)
        time.sleep(1.5)
        
        # Item 1 screenshot (Discover deck active)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_1_swipe_cards_deck.png"))
        print("Captured Discover deck screenshot.")
        
        # Item 4: Drag card right -> highlight Maybe button
        print("6. Testing swipe right action button highlight...")
        page.mouse.move(195, 450)
        page.mouse.down()
        page.mouse.move(290, 450, steps=15)
        time.sleep(0.4)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_4_swipe_right_button_highlight.png"))
        page.mouse.up()
        time.sleep(1.0)

        # Drag card left -> highlight Skip button
        print("7. Testing swipe left action button highlight...")
        page.mouse.move(195, 450)
        page.mouse.down()
        page.mouse.move(100, 450, steps=15)
        time.sleep(0.4)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_4_swipe_left_button_highlight.png"))
        page.mouse.up()
        time.sleep(1.0)
        
        # Item 2: Tap card to open Detail view
        print("8. Opening Detail view...")
        page.mouse.click(195, 450)
        time.sleep(2.0)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_detail_screen_view.png"))
        
        # Click "Watched" button (x: 314, y: 530) to test Item 2 state change
        print("Clicking Watched button in Detail view...")
        page.mouse.click(314, 530)
        time.sleep(1.2)
        page.screenshot(path=os.path.join(SCREENSHOT_DIR, "item_2_detail_watched_toggled.png"))
        
        browser.close()
        print("QA Script completed successfully!")

if __name__ == "__main__":
    run()
