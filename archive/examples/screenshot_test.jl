using ChromeDevToolsLite
using Base64

println("Starting Chrome...")
try
    run(`pkill chrome`)
catch
end
sleep(0.5)

println("Launching Chrome...")
chrome_proc = run(`google-chrome --remote-debugging-port=9222 --headless=new --no-sandbox --disable-gpu`, wait=false)

# Wait for Chrome to be ready
println("Waiting for Chrome to be ready...")
for _ in 1:10
    if check_endpoint()
        println("Chrome is ready!")
        break
    end
    sleep(0.2)
end

try
    # Connect to page
    page_ws_url = get_page_websocket_url()
    page_client = WSClient(page_ws_url)

    # Enable necessary domains
    send_cdp_message(page_client, "Page.enable")
    send_cdp_message(page_client, "Runtime.enable")

    # Get main frame ID
    result = send_cdp_message(page_client, "Page.getFrameTree")
    frame_id = result["result"]["frameTree"]["frame"]["id"]

    # Create a test page with specific elements to screenshot
    html = """
    <!DOCTYPE html>
    <html>
    <body style="background-color: white;">
        <div id="test-div" style="margin: 20px; padding: 20px; border: 2px solid black; background-color: lightblue; width: 300px;">
            <h2>Element Screenshot Test</h2>
            <p>This is a test element for screenshots.</p>
            <button style="background-color: green; color: white; padding: 10px;">Test Button</button>
        </div>
    </body>
    </html>
    """

    # Set content
    println("\nSetting up test page...")
    send_cdp_message(page_client, "Page.setDocumentContent", Dict(
        "frameId" => frame_id,
        "html" => html
    ))

    # Wait for page load
    println("Waiting for page load...")
    for _ in 1:10
        result = send_cdp_message(page_client, "Runtime.evaluate", Dict(
            "expression" => "document.readyState",
            "returnByValue" => true
        ))
        if result["result"]["result"]["value"] == "complete"
            println("Page loaded!")
            break
        end
        sleep(0.2)
    end

    # Take full page screenshot
    println("\nTaking screenshot...")
    result = send_cdp_message(page_client, "Page.captureScreenshot")

    # Save screenshot
    open("page_screenshot.png", "w") do io
        write(io, base64decode(result["result"]["data"]))
    end
    println("Screenshot saved as page_screenshot.png")

catch e
    println("Error occurred: ", e)
    rethrow(e)
finally
    println("\nCleaning up...")
    try
        rm("page_screenshot.png", force=true)
        run(`pkill chrome`)
    catch
    end
end
