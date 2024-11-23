using ChromeDevToolsLite
using HTTP

# Start Chrome in background and capture process ID
chrome_process = run(`chromium-browser --remote-debugging-port=9222 --headless --disable-gpu --no-sandbox`, wait=false)

# Wait for Chrome to be ready
for _ in 1:50  # 5 seconds timeout
    try
        HTTP.get("http://localhost:9222/json/version")
        break
    catch
        sleep(0.1)
    end
end

try
    # Start browser connection
    browser = connect_browser()

    # Create a new page
    page = create_page(browser)

    # Navigate to a test page
    send_cdp_message(page.browser, "Page.navigate", Dict(
        "url" => "https://example.com",
        "sessionId" => page.session_id
    ))

    println("Navigation successful!")
finally
    # Cleanup Chrome process
    try
        run(`kill $(chrome_process.pid)`)
    catch
        @warn "Failed to kill Chrome process"
    end
end
