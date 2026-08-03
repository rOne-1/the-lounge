import os
import urllib.request
import json

def verify_live_api():
    env_path = os.path.join(os.path.dirname(__file__), '..', '.env')
    if not os.path.exists(env_path):
        print("ERROR: .env file not found")
        return False
    
    token = None
    with open(env_path, 'r', encoding='utf-8') as f:
        for line in f:
            if line.startswith('TMDB_READ_ACCESS_TOKEN='):
                token = line.strip().split('=', 1)[1]
                break
    
    if not token:
        print("ERROR: TMDB_READ_ACCESS_TOKEN not found in .env")
        return False

    # Test configuration endpoint
    req = urllib.request.Request(
        'https://api.themoviedb.org/3/configuration',
        headers={
            'Accept': 'application/json',
            'Authorization': f'Bearer {token}'
        }
    )
    
    try:
        with urllib.request.urlopen(req) as resp:
            status = resp.getcode()
            data = json.loads(resp.read().decode('utf-8'))
            if status == 200 and 'images' in data:
                print("Configuration endpoint SUCCESS (Status 200, images base_url present)")
            else:
                print(f"Configuration endpoint unexpected response: status {status}")
                return False
    except Exception as e:
        print(f"Configuration endpoint call failed: {e}")
        return False

    # Test trending movies endpoint
    req_trending = urllib.request.Request(
        'https://api.themoviedb.org/3/trending/movie/week',
        headers={
            'Accept': 'application/json',
            'Authorization': f'Bearer {token}'
        }
    )

    try:
        with urllib.request.urlopen(req_trending) as resp:
            status = resp.getcode()
            data = json.loads(resp.read().decode('utf-8'))
            results_count = len(data.get('results', []))
            if status == 200 and results_count > 0:
                print(f"Trending movies endpoint SUCCESS (Status 200, received {results_count} items)")
                return True
            else:
                print(f"Trending movies unexpected response: status {status}, results count {results_count}")
                return False
    except Exception as e:
        print(f"Trending movies endpoint call failed: {e}")
        return False

if __name__ == '__main__':
    success = verify_live_api()
    if success:
        print("LIVE API VERIFICATION SUCCESSFUL")
    else:
        print("LIVE API VERIFICATION FAILED")
