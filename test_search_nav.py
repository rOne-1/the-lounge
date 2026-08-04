import os
import time
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\547086c9-d1c3-46b0-9ceb-a5697a0b9483"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "qa_p1_screenshots")

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    context = browser.new_context(
        viewport={'width': 390, 'height': 844},
        device_scale_factor=2,
        is_mobile=True,
        has_touch=True,
    )
    page = context.new_page()
    page.goto("http://localhost:3000", wait_until="load")
    time.sleep(3)

    # Screenshot initial
    page.screenshot(path=os.path.join(SCREENSHOT_DIR, "test_init.png"))

    # Try clicking search icon at top right (350, 105)
    print("Clicking top right search icon at (350, 105)...")
    page.mouse.click(350, 105)
    time.sleep(1.5)
    page.screenshot(path=os.path.join(SCREENSHOT_DIR, "test_after_top_search.png"))

    # Try clicking bottom nav search tab at (195, 810)
    print("Clicking bottom nav search icon at (195, 810)...")
    page.mouse.click(195, 810)
    time.sleep(1.5)
    page.screenshot(path=os.path.join(SCREENSHOT_DIR, "test_after_bottom_search.png"))

    browser.close()
