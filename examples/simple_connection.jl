using ChromeDevToolsLite

# Get WebSocket URL for Chrome DevTools
println("Getting Chrome DevTools WebSocket URL...")
ws_url = get_ws_url()
println("WebSocket URL: ", ws_url)

# Connect to Chrome
println("\nConnecting to Chrome...")
client = connect_chrome(ws_url)
println("Connected successfully!")

# Get browser version info to verify connection
println("\nGetting browser version...")
version = evaluate(client, "navigator.userAgent")
println("Browser: ", version)

# Clean up
close(client)
println("\nConnection closed.")
