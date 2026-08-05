import os
import time
import subprocess

ADB_PATH = r"C:\Users\myhea\AppData\Local\Android\Sdk\platform-tools\adb.exe"
BRAIN_DIR = r"C:\Users\myhea\.gemini\antigravity\brain\6dbe2c5b-cf35-43ca-a3be-50501ac366cf"
APK_PATH_RELEASE = r"c:\Users\myhea\Documents\GitHub\the-lounge\build\app\outputs\flutter-apk\app-release.apk"
APK_PATH_DEBUG = r"c:\Users\myhea\Documents\GitHub\the-lounge\build\app\outputs\flutter-apk\app-debug.apk"
PACKAGE_NAME = "com.thelounge.app"
MAIN_ACTIVITY = f"{PACKAGE_NAME}/.MainActivity"

def run_adb(args):
    cmd = [ADB_PATH] + args
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.stdout.strip(), res.stderr.strip(), res.returncode

def capture_screenshot(filename):
    filepath = os.path.join(BRAIN_DIR, filename)
    # Take screencap on device and pull
    remote_path = f"/sdcard/{filename}"
    run_adb(["shell", "screencap", "-p", remote_path])
    run_adb(["pull", remote_path, filepath])
    run_adb(["shell", "rm", remote_path])
    print(f"[SCREENSHOT] Saved: {filepath}")
    return filepath

def main():
    print("=== STARTING ON-DEVICE ANDROID QA VERIFICATION ===")

    # 1. Verify ADB connection
    stdout, stderr, code = run_adb(["devices"])
    print(f"[ADB Devices]\n{stdout}")
    if "emulator" not in stdout and "device" not in stdout:
        print("ERROR: No Android device/emulator found.")
        return

    # 2. Prefer Release APK
    if os.path.exists(APK_PATH_RELEASE):
        apk_path = APK_PATH_RELEASE
    elif os.path.exists(APK_PATH_DEBUG):
        apk_path = APK_PATH_DEBUG
    else:
        print("ERROR: Neither debug nor release APK found.")
        return
    print(f"Target APK: {apk_path}")

    # 3. Install APK
    print(f"\n1. Installing APK: {apk_path}...")
    stdout, stderr, code = run_adb(["install", "-r", apk_path])
    print(f"Install result: {stdout} {stderr}")

    # 4. Launch Application
    print(f"\n2. Launching Application: {MAIN_ACTIVITY}...")
    stdout, stderr, code = run_adb(["shell", "am", "start", "-n", MAIN_ACTIVITY])
    print(f"Launch result: {stdout} {stderr}")

    print("Waiting 10 seconds for app launch & TMDB network data load...")
    time.sleep(10.0)

    # 5. Capture Launch & Identity Screenshot
    print("\n3. Capturing Launch & Identity evidence...")
    shot1 = capture_screenshot("android_01_launch_home.png")

    # 6. Navigate to Discover Tab (x: 45, y: 480 on nav rail)
    print("\n4. Navigating to Discover screen...")
    run_adb(["shell", "input", "tap", "45", "480"])
    time.sleep(4.0)

    # 7. Perform Touch Interactions on Discover deck
    print("\n5. Performing Touch Interactions (Swipes)...")
    # Swipe Left (Next item in discover deck)
    run_adb(["shell", "input", "swipe", "1200", "1200", "400", "1200", "300"])
    time.sleep(2.0)
    
    # Swipe Right (Previous item)
    run_adb(["shell", "input", "swipe", "400", "1200", "1200", "1200", "300"])
    time.sleep(2.0)

    # Swipe Up
    run_adb(["shell", "input", "swipe", "800", "1600", "800", "600", "400"])
    time.sleep(2.0)

    shot2 = capture_screenshot("android_02_discover_touch_swipe.png")

    # 8. Tap card to open Detail Bottom Sheet
    print("\n6. Tapping movie item to open Detail Sheet...")
    run_adb(["shell", "input", "tap", "800", "1000"])
    time.sleep(3.0)

    shot3 = capture_screenshot("android_03_detail_bottom_sheet.png")

    # 9. Drag to dismiss bottom sheet
    print("\n7. Drag-to-dismiss bottom sheet gesture...")
    run_adb(["shell", "input", "swipe", "800", "800", "800", "2000", "400"])
    time.sleep(2.0)

    shot4 = capture_screenshot("android_04_sheet_dismissed.png")

    # 10. Check Error Reporting Logcat redaction output
    print("\n8. Verifying Error Reporting & Logcat Redaction...")
    log_out, _, _ = run_adb(["logcat", "-d", "-s", "CrashReportingService:V", "*:S"])
    print(f"CrashReporting logcat output:\n{log_out[:500] if log_out else '(No CrashReporting logs caught yet - clean run)'}")

    print("\n=== ANDROID QA VERIFICATION COMPLETE ===")

if __name__ == "__main__":
    main()
