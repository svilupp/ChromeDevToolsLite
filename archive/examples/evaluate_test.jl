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

    # Create a test page with an element to evaluate
    html = """
    <html>
        <body>
            <div id="test-div" class="test-class" style="color: blue;">Test Content</div>
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

    println("\nTesting element evaluation...")
    element = query_selector(page, "#test-div")

    # Test various JavaScript evaluations
    class_name = evaluate_handle(element, "this.className")
    println("Class name: ", class_name)

    style_color = evaluate_handle(element, "this.style.color")
    println("Style color: ", style_color)

    inner_text = evaluate_handle(element, "this.innerText")
    println("Inner text: ", inner_text)

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
