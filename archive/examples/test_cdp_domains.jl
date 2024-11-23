using ChromeDevToolsLite
using HTTP
using JSON3

# Connect to Chrome
response = HTTP.get("http://localhost:9222/json")
targets = JSON3.read(response.body)
ws_url = first(filter(t -> t.type == "page", targets)).webSocketDebuggerUrl

println("Connecting to Chrome...")
client = connect_chrome(ws_url)

# Test navigation
println("\nNavigating to example.com...")
result = navigate(client, "https://example.com")
println("Navigation result: ", JSON3.pretty(result))
sleep(1)  # Give page time to load

# Test JavaScript evaluation
println("\nEvaluating page title...")
result = evaluate(client, "document.title")
println("Page title: ", get(result.result, :value, "Unknown"))

# Test element interaction
println("\nTesting element interaction...")
result = evaluate(client, """
    document.querySelector('h1').textContent
""")
println("H1 content: ", get(result.result, :value, "Not found"))

# Take screenshot
println("\nTaking screenshot...")
data = screenshot(client)
if !isnothing(data)
    # Save screenshot to file
    open("screenshot.png", "wb") do io
        write(io, base64decode(data))
    end
    println("Screenshot saved as screenshot.png")
end

# Clean up
close(client)
println("\nTest completed!")
