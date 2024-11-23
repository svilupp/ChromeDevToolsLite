using ChromeDevToolsLite
using JSON3

# Connect to Chrome DevTools
println("Connecting to Chrome DevTools...")
client = connect_browser("http://localhost:9222")
println("Connected successfully!")

# Test connection by evaluating JavaScript
println("\nTesting connection...")
response = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}("expression" => "navigator.userAgent"))
println("Browser: ", response["result"]["result"]["value"])

# Clean up
println("\nClosing connection...")
close(client)
println("Connection closed.")
