import subprocess
import time
import requests
import json

print("Starting Chrome...")
try:
    subprocess.run(['pkill', 'chrome'], capture_output=True)
except:
    pass
time.sleep(1)

print("Launching Chrome...")
chrome_process = subprocess.Popen(['google-chrome', '--remote-debugging-port=9222', '--headless=new', '--no-sandbox', '--disable-gpu'])
time.sleep(2)

try:
    print("\nTesting /json endpoint...")
    response = requests.get('http://localhost:9222/json')
    print(f"Status code: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")

    print("\nTesting /json/version endpoint...")
    version_response = requests.get('http://localhost:9222/json/version')
    print(f"Status code: {version_response.status_code}")
    print(f"Response: {json.dumps(version_response.json(), indent=2)}")

finally:
    print("\nCleaning up Chrome process...")
    subprocess.run(['pkill', 'chrome'], capture_output=True)
