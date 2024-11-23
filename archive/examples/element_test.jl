using ChromeDevToolsLite
using HTTP

# Kill any existing Chrome processes (ignore errors)
try run(`pkill chromium-browser`) catch end
sleep(1)

# Start Chrome in background with proper debugging flags
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
    # Create a simple HTML file for testing
    html_content = """
    <!DOCTYPE html>
    <html>
    <body>
        <h1>Test Form</h1>
        <form>
            <input type="text" id="name" placeholder="Enter your name">
            <button type="button" id="submit">Submit</button>
        </form>
        <div id="result"></div>
    </body>
    </html>
    """
    write("test.html", html_content)

    # Start browser connection with debug output
    println("Connecting to browser...")
    browser = connect_browser()
    println("Creating new page...")
    page = create_page(browser)

    # Enable domains with explicit confirmation
    println("Enabling Page domain...")
    send_cdp_message(page.browser, "Page.enable", Dict("sessionId" => page.session_id))
    println("Enabling DOM domain...")
    send_cdp_message(page.browser, "DOM.enable", Dict("sessionId" => page.session_id))

    # Navigate with explicit load waiting
    println("\nNavigating to test page...")
    file_url = "file://$(pwd())/test.html"
    send_cdp_message(page.browser, "Page.navigate", Dict(
        "url" => file_url,
        "sessionId" => page.session_id
    ))

    # Wait for load with better messaging
    println("Waiting for page load...")
    start_time = time()
    load_complete = false
    while (time() - start_time) < 5.0 && !load_complete
        if isready(browser.messages)
            msg = take!(browser.messages)
            if get(msg, "method", "") == "Page.loadEventFired"
                load_complete = true
                println("✓ Page loaded successfully")
                break
            end
        end
        sleep(0.1)
    end

    if !load_complete
        error("Page failed to load within timeout")
    end

    # Give DOM a moment to settle
    sleep(0.5)

    println("\nTesting element interactions...")

    # Test input field with detailed output
    println("\nLocating input field...")
    input = query_selector(page, "#name")
    if input !== nothing
        println("✓ Found input element (nodeId: $(input.node_id))")
        println("Typing text...")
        type_text(input, "John Doe")
        println("✓ Text entered successfully")
    else
        error("Could not find input element #name")
    end

    # Test button with detailed output
    println("\nLocating submit button...")
    button = query_selector(page, "#submit")
    if button !== nothing
        println("✓ Found button element (nodeId: $(button.node_id))")
        println("Clicking button...")
        click(button)
        println("✓ Button clicked successfully")
    else
        error("Could not find button element #submit")
    end

    println("\nAll tests completed successfully! 🎉")

    println("\nAll tests completed successfully!")

finally
    # Cleanup
    rm("test.html", force=true)
    try
        if process_running(chrome_process)
            kill(chrome_process)
            println("Chrome process killed")
        end
    catch e
        @warn "Failed to kill Chrome process: $e"
    end
end
