import time
from playwright.sync_api import sync_playwright

def test_input():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport={'width': 390, 'height': 844}, is_mobile=True, has_touch=True)
        page.goto("http://127.0.0.1:3008", wait_until="load")
        time.sleep(4.0)

        # Tap Search tab
        page.mouse.click(195, 800)
        time.sleep(3.0)

        inputs = page.locator('input').all()
        print(f"Found {len(inputs)} input elements.")
        for i, inp in enumerate(inputs):
            print(f"Input {i}: outerHTML={inp.evaluate('el => el.outerHTML')}")

        # Try clicking search bar at (195, 175) first to focus input
        page.mouse.click(195, 175)
        time.sleep(1.0)

        inputs2 = page.locator('input').all()
        print(f"After click, found {len(inputs2)} input elements.")
        for i, inp in enumerate(inputs2):
            print(f"Input {i}: outerHTML={inp.evaluate('el => el.outerHTML')}")
            try:
                inp.fill("Batman")
                print("Filled successfully!")
            except Exception as e:
                print(f"Fill error: {e}")

        time.sleep(3.0)
        page.screenshot(path=r"C:\Users\myhea\.gemini\antigravity\brain\0301b456-a5e6-4a7e-a71a-11c9b700e0e1\screenshots\test_input_fill.png")
        browser.close()

if __name__ == "__main__":
    test_input()
