using ChromeDevToolsLite

# Connect to Chrome DevTools
println("Connecting to Chrome DevTools...")
browser = connect_browser("http://localhost:9222")

# Send a simple CDP command to get browser version
println("Getting browser version...")
version = send_cdp_message(browser, "Browser.getVersion", Dict())
println("Connected to: ", version.result.product)
