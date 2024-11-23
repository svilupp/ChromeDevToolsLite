using ChromeDevToolsLite
using Base64

# Connect to Chrome
client = connect_chrome(get_ws_url())
println("Connected to Chrome")

# Create a test page with interactive elements
println("\nCreating test page...")
goto(client, "about:blank")
evaluate(client, """
    document.body.innerHTML = `
        <div style="padding: 20px;">
            <input type="text" id="name" placeholder="Enter your name">
            <button id="greet">Greet</button>
            <div id="output"></div>
        </div>
    `;
""")

# Type into input field
println("\nTyping into input field...")
type_text(client, "#name", "Julia User")
println("Text entered")

# Click the button
println("\nClicking button...")
click_element(client, "#greet")

# Verify the interaction worked
println("\nVerifying interaction...")
input_value = evaluate(client, "document.querySelector('#name').value")
println("Input value: ", input_value)

# Clean up
close(client)
println("\nConnection closed.")
