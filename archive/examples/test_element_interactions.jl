using ChromeDevToolsLite
using HTTP
using JSON3

# Get WebSocket URL and connect
ws_url = get_ws_url()
println("Connecting to Chrome at: ", ws_url)
client = connect_chrome(ws_url)

# Create a simple test page with various elements
println("\nSetting up test page...")
evaluate(client, """
    document.body.innerHTML = `
        <div id="test-container">
            <h1 id="test-heading">Test Heading</h1>
            <input type="text" id="test-input" />
            <button id="test-button">Click Me</button>
            <div id="test-text">Sample Text</div>
        </div>
    `;
""")

# Test element selector
println("\nTesting element selector...")
heading = query_selector(client, "#test-heading")
println("Found heading: ", !isnothing(heading))

# Test get_text
println("\nTesting get_text...")
heading_text = get_text(client, "#test-heading")
println("Heading text: ", heading_text)

# Test clicking
println("\nTesting element click...")
button_clicked = click_element(client, "#test-button")
println("Button clicked: ", button_clicked)

# Test typing
println("\nTesting text input...")
typed = type_text(client, "#test-input", "Hello, World!")
println("Text typed: ", typed)

# Verify input value
println("\nVerifying input value...")
input_text = get_text(client, "#test-input")
println("Input value: ", input_text)

# Test getting text from div
println("\nTesting div text content...")
div_text = get_text(client, "#test-text")
println("Div text: ", div_text)

close(client)
println("\nTest completed!")
