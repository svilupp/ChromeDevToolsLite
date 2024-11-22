# http://localhost:9222/json/version
# {
#    "Browser": "Chrome/131.0.6778.86",
#    "Protocol-Version": "1.3",
#    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36",
#    "V8-Version": "13.1.201.9",
#    "WebKit-Version": "537.36 (@ee338c5c68e930761e15c97f5af9d8a082271a88)",
#    "webSocketDebuggerUrl": "ws://localhost:9222/devtools/browser/cd6af2fb-988d-4435-ac8c-4d9b9c9fbd34"
# }

using ChromeDevToolsLite
const CDP = ChromeDevToolsLite

browser = CDP.launch_browser_process(; endpoint = "http://localhost:9222")
