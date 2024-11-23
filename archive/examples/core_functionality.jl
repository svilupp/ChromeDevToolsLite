using ChromeDevToolsLite
using Base64
using JSON  # Add JSON package for pretty printing

println("Starting Chrome...")
try
    run(`pkill chrome`)
catch
end
sleep(1)

println("Launching Chrome...")
chrome_proc = run(`google-chrome --remote-debugging-port=9222 --headless=new --no-sandbox --disable-gpu`, wait=false)
sleep(2)

try
    # Connect to browser
    browser_ws_url = get_websocket_url()
    browser_client = WSClient(browser_ws_url)

    # Get browser version
    version_info = send_cdp_message(browser_client, "Browser.getVersion")
    println("\nBrowser Version:")
    println(JSON.json(version_info["result"], 2))

    # Connect to page
    page_ws_url = get_page_websocket_url()
    page_client = WSClient(page_ws_url)

    # Enable page events
    send_cdp_message(page_client, "Page.enable")

    # Navigate to a test page
    println("\nNavigating to example.com...")
    send_cdp_message(page_client, "Page.navigate", Dict("url" => "https://example.com"))
    sleep(1)  # Give page time to load

    # Evaluate JavaScript
    println("\nGetting page title...")
    result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))
    println("Title: ", result["result"]["result"]["value"])

    # Query and interact with elements
    println("\nGetting main heading...")
    result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
        "expression" => "document.querySelector('h1').textContent",
        "returnByValue" => true
    ))
    println("Heading: ", result["result"]["result"]["value"])

    # Take screenshot
    println("\nTaking screenshot...")
    result = send_cdp_message(page_client, "Page.captureScreenshot")

    # Save screenshot to file
    open("example_screenshot.png", "w") do io
        write(io, base64decode(result["result"]["data"]))
    end
    println("Screenshot saved as example_screenshot.png")

catch e
    println("Error occurred: ", e)
    rethrow(e)
finally
    println("\nCleaning up Chrome process...")
    try
        run(`pkill chrome`)
    catch
    end
end
