using ChromeDevToolsLite

# Kill any existing Chrome processes
try run(`pkill chromium`) catch end
sleep(1)

# Start Chrome in background
chrome_process = run(`chromium --remote-debugging-port=9222 --headless --disable-gpu --no-sandbox`, wait=false)

try
    println("Connecting to browser...")
    browser = connect_browser()
    page = create_page(browser)

    # Create a test page with a checkbox
    html = """
    <html>
        <body>
            <input type="checkbox" id="test-checkbox">
            <label for="test-checkbox">Test Checkbox</label>
        </body>
    </html>
    """

    println("\nSetting up test page...")
    send_cdp_message(page.browser, "Page.enable", Dict("sessionId" => page.session_id))
    send_cdp_message(page.browser, "Page.setDocumentContent", Dict(
        "frameId" => page.frame_id,
        "html" => html,
        "sessionId" => page.session_id
    ))

    sleep(0.5)

    println("\nTesting checkbox interactions...")
    checkbox = query_selector(page, "#test-checkbox")

    # Test checking
    println("Checking checkbox...")
    check(checkbox)
    is_checked = evaluate_handle(checkbox, "this.checked")
    println("Checkbox checked: ", is_checked)

    # Test unchecking
    println("\nUnchecking checkbox...")
    uncheck(checkbox)
    is_checked = evaluate_handle(checkbox, "this.checked")
    println("Checkbox checked: ", is_checked)

finally
    # Cleanup
    try
        if @isdefined(chrome_process) && process_running(chrome_process)
            kill(chrome_process)
            println("\nChrome process killed")
        end
    catch e
        @warn "Failed to kill Chrome process: $e"
    end
end
