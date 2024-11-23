using ChromeDevToolsLite
using HTTP

# Kill any existing Chrome processes
try run(`pkill chromium-browser`) catch end
sleep(1)

# Start Chrome in background
chrome_process = run(`chromium-browser --remote-debugging-port=9222 --headless --disable-gpu --no-sandbox`, wait=false)

try
    println("Connecting to browser...")
    browser = connect_browser()

    println("\nCreating new page...")
    page = create_page(browser)

    println("\nTesting basic CDP commands...")

    # Enable Page domain
    println("Enabling Page domain...")
    result = send_cdp_message(browser, "Page.enable", Dict("sessionId" => page.session_id))
    println("✓ Page domain enabled")

    # Navigate to a simple page
    println("\nNavigating to example.com...")
    result = send_cdp_message(page.browser, "Page.navigate", Dict(
        "url" => "https://example.com",
        "sessionId" => page.session_id
    ))
    println("✓ Navigation initiated")

    println("\nTest completed successfully!")

finally
    # Cleanup
    try
        if @isdefined(chrome_process) && process_running(chrome_process)
            kill(chrome_process)
            println("Chrome process killed")
        end
    catch e
        @warn "Failed to kill Chrome process: $e"
    end
end
