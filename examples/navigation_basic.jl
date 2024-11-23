using ChromeDevToolsLite

# Connect to Chrome
ws_url = get_ws_url()
client = connect_chrome(ws_url)
println("Connected to Chrome")

# Navigate to a test page
println("\nNavigating to example.com...")
goto(client, "https://example.com")

# Get page title using JavaScript
title = evaluate(client, "document.title")
println("Page title: ", title)

# Get main heading text
heading = get_text(client, "h1")
println("Main heading: ", heading)

# Get current URL
url = evaluate(client, "window.location.href")
println("Current URL: ", url)

# Clean up
close(client)
println("\nConnection closed.")
