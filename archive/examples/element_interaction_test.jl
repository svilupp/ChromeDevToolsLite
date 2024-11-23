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

    # Create a simple test page
    html = """
    <html>
        <body>
            <input type="text" id="test-input" />
            <button id="test-button">Click Me</button>
            <div id="test-text">Sample Text</div>
        </body>
    </html>
    """

    # Navigate and set content
    println("\nSetting up test page...")
    send_cdp_message(page.browser, "Page.enable", Dict("sessionId" => page.session_id))
    send_cdp_message(page.browser, "Page.setDocumentContent", Dict(
        "frameId" => page.frame_id,
        "html" => html,
        "sessionId" => page.session_id
    ))

    # Wait a moment for DOM to be ready
    sleep(0.5)

    println("\nTesting element interactions...")

    # Test querySelector
    println("Testing querySelector...")
    input_element = query_selector(page, "#test-input")
    button_element = query_selector(page, "#test-button")
    text_element = query_selector(page, "#test-text")

    if input_element === nothing || button_element === nothing || text_element === nothing
        error("Failed to find test elements")
    end

    # Test type_text
    println("Testing type_text...")
    type_text(input_element, "Hello, World!")

    # Test get_text
    println("Testing get_text...")
    text_content = get_text(text_element)
    println("Text content: $text_content")

    # Test get_attribute
    println("Testing get_attribute...")
    input_id = get_attribute(input_element, "id")
    println("Input ID: $input_id")

    # Test click
    println("Testing click...")
    click(button_element)

    println("\nAll element interaction tests completed!")

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
