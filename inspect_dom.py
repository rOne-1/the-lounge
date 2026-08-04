import os
import time
from playwright.sync_api import sync_playwright

def inspect_elements():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context(
            viewport={'width': 390, 'height': 844},
            device_scale_factor=2,
            is_mobile=True,
            has_touch=True,
        )
        page = context.new_page()
        page.goto("http://localhost:3000", wait_until="networkidle")
        time.sleep(3)
        
        # Check text elements
        see_alls = page.locator('text="See all"').all()
        print(f"Found {len(see_alls)} 'See all' elements.")
        for i, el in enumerate(see_alls):
            try:
                box = el.bounding_box()
                print(f"  See all #{i}: box={box}")
            except Exception as e:
                print(f"  See all #{i}: err={e}")
                
        browser.close()

if __name__ == "__main__":
    inspect_elements()
