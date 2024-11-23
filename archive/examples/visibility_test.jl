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

    # Create a test page with visible and hidden elements
    html = """
    <html>
        <body>
            <div id="visible">Visible Element</div>
            <div id="hidden" style="display: none;">Hidden Element</div>
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

    println("\nTesting element visibility...")
    visible_element = query_selector(page, "#visible")
    hidden_element = query_selector(page, "#hidden")

    println("Visible element is_visible: ", is_visible(visible_element))
    println("Hidden element is_visible: ", is_visible(hidden_element))

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
