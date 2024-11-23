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

    # Create a test page with a select element
    html = """
    <html>
        <body>
            <select id="test-select">
                <option value="1">Option 1</option>
                <option value="2">Option 2</option>
                <option value="3">Option 3</option>
            </select>
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

    println("\nTesting select option...")
    select_element = query_selector(page, "#test-select")

    # Test selecting different options
    println("Selecting option 2...")
    select_option(select_element, "2")

    # Verify selection
    selected_value = evaluate_handle(select_element, "this.value")
    println("Selected value: ", selected_value)

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
