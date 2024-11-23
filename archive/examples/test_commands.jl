using ChromeDevToolsLite
using HTTP
using JSON3

# Get WebSocket URL and connect
ws_url = get_ws_url()
println("Connecting to Chrome at: ", ws_url)
client = connect_chrome(ws_url)

# Test navigation
println("\nTesting navigation...")
result = navigate(client, "https://example.com")
println("Navigation result: ", JSON3.write(result))
sleep(1) # Allow page to load

# Test JavaScript evaluation with full response logging
println("\nTesting JavaScript evaluation...")
result = send_cdp_message(client, Dict(
    "method" => "Runtime.evaluate",
    "params" => Dict(
        "expression" => "document.title",
        "returnByValue" => true,
        "awaitPromise" => true
    )
))
println("Raw evaluation result: ", JSON3.write(result))
title = evaluate(client, "document.title")
println("Processed title: ", title)

# Test screenshot
println("\nTesting screenshot...")
screenshot_data = screenshot(client)
println("Screenshot captured: ", !isnothing(screenshot_data))

close(client)
println("\nTest completed!")
