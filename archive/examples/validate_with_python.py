import chrome_remote_interface
import json
import base64
from time import sleep

def validate_functionality():
    chrome = chrome_remote_interface.Chrome()

    try:
        # 1. Test Browser Version
        print("\nTesting Browser.getVersion...")
        version = chrome.Browser.getVersion()
        print(json.dumps(version, indent=2))

        # 2. Test Navigation
        print("\nTesting Page.navigate...")
        chrome.Page.enable()
        nav_result = chrome.Page.navigate(url='https://example.com')
        print(json.dumps(nav_result, indent=2))
        sleep(1)  # Brief pause for page load

        # 3. Test JavaScript Evaluation
        print("\nTesting Runtime.evaluate...")
        js_result = chrome.Runtime.evaluate(expression='document.title')
        print(json.dumps(js_result, indent=2))

        # 4. Test Screenshot
        print("\nTesting Page.captureScreenshot...")
        screenshot = chrome.Page.captureScreenshot()
        with open('cdp_screenshot.png', 'wb') as f:
            f.write(base64.b64decode(screenshot['data']))
        print("Screenshot saved as cdp_screenshot.png")

    finally:
        chrome.close()

if __name__ == "__main__":
    print("Starting validation with Chrome DevTools Protocol...")
    validate_functionality()
