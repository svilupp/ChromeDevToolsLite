using ChromeDevToolsLite

# Connect to Chrome
client = connect_browser()
println("Connected to Chrome")

# Create a test page
println("\nCreating test page...")
goto(client, "about:blank")
evaluate(client, """
    document.body.innerHTML = `
        <div id="app">
            <h1>JavaScript Evaluation Demo</h1>
            <div id="counter">0</div>
        </div>
    `;
""")

# Simple evaluation
println("\nSimple evaluation:")
title = evaluate(client, "document.title")
println("Page title: ", title)

# Evaluate with return value
println("\nEvaluating expression with return:")
counter = evaluate(client, "document.getElementById('counter').textContent")
println("Counter value: ", counter)

# Modify DOM with JavaScript
println("\nModifying DOM...")
evaluate(client, """
    document.getElementById('counter').textContent = '42';
    document.body.style.backgroundColor = '#f0f0f0';
""")

# Verify changes
println("\nVerifying changes:")
new_counter = evaluate(client, "document.getElementById('counter').textContent")
println("New counter value: ", new_counter)

# Clean up
close(client)
println("\nConnection closed.")
