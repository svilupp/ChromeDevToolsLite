using ChromeDevToolsLite

# Connect to Chrome
println("Connecting to Chrome...")
client = connect_browser()
println("Connected to Chrome")

# Navigate to a test page
println("\nNavigating to example.com...")
goto(client, "https://example.com")

# Get page title using JavaScript
title = evaluate(client, "document.title")
println("Page title: ", title)

# Get main heading text using JavaScript
heading = evaluate(client, "document.querySelector('h1').textContent")
println("Main heading: ", heading)

# Get current URL
url = evaluate(client, "window.location.href")
println("Current URL: ", url)

# Clean up
close(client)
println("\nConnection closed.")
