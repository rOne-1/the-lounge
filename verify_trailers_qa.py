import os
import time
import json
import urllib.request
from playwright.sync_api import sync_playwright

BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\865bdab8-dec8-4e2b-9696-2bb3e664c799"
SCREENSHOT_DIR = os.path.join(BRAIN_DIR, "trailer_qa_screenshots")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

# Read token from .env
dotenv_path = r"c:\Users\myhea\Documents\GitHub\the-lounge\.env"
tmdb_token = None
if os.path.exists(dotenv_path):
    with open(dotenv_path, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith("TMDB_READ_ACCESS_TOKEN="):
                tmdb_token = line.strip().split("=", 1)[1]

print(f"Loaded TMDB token present: {bool(tmdb_token)}")

headers = {"Accept": "application/json"}
if tmdb_token and tmdb_token.startswith("eyJ"):
    headers["Authorization"] = f"Bearer {tmdb_token}"

def get_videos_for_title(query, media_type="movie"):
    """Search for title and get its videos object."""
    encoded_query = urllib.parse.quote(query)
    search_url = f"https://api.themoviedb.org/3/search/{media_type}?query={encoded_query}&include_adult=false"
    if not (tmdb_token and tmdb_token.startswith("eyJ")):
        search_url += f"&api_key={tmdb_token}"
    
    req = urllib.request.Request(search_url, headers=headers)
    with urllib.request.urlopen(req) as resp:
        search_data = json.loads(resp.read().decode('utf-8'))
        results = search_data.get('results', [])
        if not results:
            return None, None, []
        first = results[0]
        item_id = first['id']
        title = first.get('title') or first.get('name')

    # Get details with append_to_response=videos
    detail_url = f"https://api.themoviedb.org/3/{media_type}/{item_id}?append_to_response=videos"
    if not (tmdb_token and tmdb_token.startswith("eyJ")):
        detail_url += f"&api_key={tmdb_token}"
    
    req_detail = urllib.request.Request(detail_url, headers=headers)
    with urllib.request.urlopen(req_detail) as resp:
        detail_data = json.loads(resp.read().decode('utf-8'))
        videos = detail_data.get('videos', {}).get('results', [])
        return item_id, title, videos

def parse_trailer_selection(videos):
    """Replicate Flutter repository logic for selecting trailer/teaser."""
    def find_best_match(target_type):
        candidate = None
        for item in videos:
            if not isinstance(item, dict):
                continue
            v_type = item.get('type')
            site = item.get('site')
            key = item.get('key')
            official = item.get('official', False)
            if v_type == target_type and site == 'YouTube' and key:
                if candidate is None:
                    candidate = item
                elif official and not candidate.get('official', False):
                    candidate = item
        return candidate

    trailer_match = find_best_match('Trailer')
    if trailer_match:
        return 'Trailer', trailer_match.get('key'), trailer_match.get('name'), trailer_match.get('official')
    
    teaser_match = find_best_match('Teaser')
    if teaser_match:
        return 'Teaser', teaser_match.get('key'), teaser_match.get('name'), teaser_match.get('official')
    
    return None, None, None, None

def run_verification():
    titles_to_check = [
        ("Inception", "movie"),
        ("Dune: Part Two", "movie"),
        ("Severance", "tv"),
    ]

    print("\n--- TMDB API VIDEO SELECTION AUDIT ---")
    results = {}
    for query, media_type in titles_to_check:
        item_id, title, videos = get_videos_for_title(query, media_type)
        sel_type, sel_key, sel_name, sel_off = parse_trailer_selection(videos)
        results[title] = {
            "id": item_id,
            "type": media_type,
            "selected_type": sel_type,
            "key": sel_key,
            "video_title": sel_name,
            "official": sel_off,
            "total_videos": len(videos)
        }
        print(f"[{title}] (ID: {item_id}): Type={sel_type}, Key={sel_key}, Official={sel_off}, Name='{sel_name}'")

    # Teaser-only fallback title: "Avatar: Seven Havens"
    teaser_only_info = None
    print("\nChecking teaser-only title 'Avatar: Seven Havens'...")
    try:
        item_id, title, videos = get_videos_for_title("Avatar: Seven Havens", "tv")
        sel_type, sel_key, sel_name, sel_off = parse_trailer_selection(videos)
        teaser_only_info = {
            "query": "Avatar: Seven Havens",
            "title": title,
            "id": item_id,
            "type": "tv",
            "selected_type": sel_type,
            "key": sel_key,
            "video_title": sel_name,
            "official": sel_off,
            "total_videos": len(videos)
        }
        print(f"FOUND TEASER-ONLY TITLE: '{title}' (ID: {item_id}) -> Key={sel_key}, Name='{sel_name}'")
    except Exception as e:
        print(f"Error fetching teaser-only title: {e}")

    audit_data = {
        "major_titles": results,
        "teaser_only_title": teaser_only_info
    }
    with open(os.path.join(BRAIN_DIR, "trailer_api_audit.json"), "w") as f:
        json.dump(audit_data, f, indent=2)

    return audit_data

def run_playwright_visual_qa(audit_data):
    """Run Playwright UI visual QA in Flutter Web app."""
    print("\n--- PLAYWRIGHT VISUAL QA IN FLUTTER WEB APP ---")
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
        page.goto("http://localhost:3000", wait_until="load")
        time.sleep(3)

        # Click Search tab at (195, 810)
        print("Clicking Search Tab (x: 195, y: 810)...")
        page.mouse.click(195, 810)
        time.sleep(2)

        def test_title_trailer_playback(search_query, screenshot_prefix, expected_key=None):
            print(f"\n--- Testing Search Query '{search_query}' ---")
            
            # Click search text field at (195, 125)
            print("Clicking Search input at (x: 195, y: 125)...")
            page.mouse.click(195, 125)
            time.sleep(0.5)
            
            # Clear text field and type search query
            page.keyboard.press("Control+A")
            page.keyboard.press("Backspace")
            page.keyboard.type(search_query)
            time.sleep(3.5)

            # Screenshot of search results
            search_shot = os.path.join(SCREENSHOT_DIR, f"{screenshot_prefix}_search_results.png")
            page.screenshot(path=search_shot)
            print(f"Captured search results: {search_shot}")

            # Click first search result item card at (x: 195, y: 220)
            print("Clicking first search result card at (x: 195, y: 220)...")
            page.mouse.click(195, 220)
            time.sleep(4.0)

            # Screenshot of Detail View
            detail_shot = os.path.join(SCREENSHOT_DIR, f"{screenshot_prefix}_detail_view.png")
            page.screenshot(path=detail_shot)
            print(f"Captured Detail View: {detail_shot}")

            # Click Hero Play Button at (x: 195, y: 165)
            print("Clicking Hero Play Button at (x: 195, y: 165)...")
            page.mouse.click(195, 165)
            time.sleep(4.0)

            # Take TrailerPlayer screenshot
            trailer_shot = os.path.join(SCREENSHOT_DIR, f"{screenshot_prefix}_trailer_player.png")
            page.screenshot(path=trailer_shot)
            print(f"Captured Trailer Player: {trailer_shot}")

            # Check DOM for YouTube iframe src or flutter shadow DOM
            yt_srcs = page.eval_on_selector_all(
                "iframe",
                "iframes => iframes.map(i => i.src)"
            )
            print(f"Detected YouTube iFrame URLs in DOM: {yt_srcs}")
            if expected_key:
                matched = any(expected_key in src for src in yt_srcs)
                print(f"Expected YouTube Key '{expected_key}' matched in DOM iframe: {matched}")

            # Close TrailerPlayer (back arrow at top left x: 25, y: 40)
            print("Closing TrailerPlayer...")
            page.mouse.click(25, 40)
            time.sleep(2)

            # Close Detail View (back arrow at top left x: 25, y: 40)
            print("Closing DetailView...")
            page.mouse.click(25, 40)
            time.sleep(2)

        # Test Inception
        majors = audit_data.get("major_titles", {})
        test_title_trailer_playback("Inception", "1_inception", majors.get("Inception", {}).get("key"))

        # Test Dune: Part Two
        test_title_trailer_playback("Dune: Part Two", "2_dune_part_two", majors.get("Dune: Part Two", {}).get("key"))

        # Test Severance
        test_title_trailer_playback("Severance", "3_severance", majors.get("Severance", {}).get("key"))

        # Test Teaser-Only title
        teaser_info = audit_data.get("teaser_only_title")
        if teaser_info:
            teaser_query = teaser_info.get("query") or teaser_info.get("title")
            print(f"\nTesting Teaser-Only fallback title: {teaser_info}")
            test_title_trailer_playback(teaser_query, "4_teaser_only", teaser_info.get("key"))

        browser.close()

if __name__ == "__main__":
    audit_data = run_verification()
    run_playwright_visual_qa(audit_data)
