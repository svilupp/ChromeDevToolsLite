using ChromeDevToolsLite
using Base64

# Connect to Chrome
println("Connecting to Chrome...")
client = connect_browser()
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
evaluate(client, """
    document.querySelector('#name').value = 'Julia User';
    document.querySelector('#name').dispatchEvent(new Event('input'));
""")
println("Text entered")

# Click the button
println("\nClicking button...")
evaluate(client, """
    document.querySelector('#greet').click();
""")

# Verify the interaction worked
println("\nVerifying interaction...")
input_value = evaluate(client, "document.querySelector('#name').value")
println("Input value: ", input_value)

# Clean up
close(client)
println("\nConnection closed.")
