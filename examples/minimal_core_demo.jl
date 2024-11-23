using ChromeDevToolsLite
using Base64

# Connect to Chrome
ws_url = get_ws_url()
println("Connecting to Chrome at: ", ws_url)
client = connect_chrome(ws_url)

# Navigate to a test page
println("\nNavigating to test page...")
goto(client, "about:blank")

# Create test content
println("\nCreating test content...")
evaluate(client, """
    document.body.innerHTML = `
        <div id="container" style="padding: 20px; font-family: Arial;">
            <h1 id="title">ChromeDevToolsLite Demo</h1>
            <input type="text" id="test-input" placeholder="Type here...">
            <button id="test-button">Click me</button>
            <div id="output">Initial text</div>
        </div>
    `;
""")

# Test element selection and text content
println("\nTesting element content...")
title_text = get_text(client, "#title")
println("Title text: ", title_text)

# Test input interaction
println("\nTesting input interaction...")
type_result = type_text(client, "#test-input", "Hello from Julia!")
println("Text typed: ", type_result)

# Test button click
println("\nTesting button click...")
click_result = click_element(client, "#test-button")
println("Button clicked: ", click_result)

# Get page content
println("\nGetting page content...")
html = content(client)
println("Page content length: ", length(html))

# Take screenshot
println("\nTaking screenshot...")
screenshot_data = screenshot(client)
if !isnothing(screenshot_data)
    open("minimal_demo.png", "w") do io
        write(io, base64decode(screenshot_data))
    end
    println("Screenshot saved as minimal_demo.png")
end

close(client)
println("\nDemo completed!")
