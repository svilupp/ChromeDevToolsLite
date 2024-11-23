using ChromeDevToolsLite
using JSON3
using Base64

# Get WebSocket URL and print it for debugging
println("Getting WebSocket URL...")
ws_url = get_ws_url()
println("WebSocket URL: ", ws_url)

println("\nConnecting to Chrome...")
try
    # Create a task to handle the WebSocket connection
    client = @sync begin
        @async connect_chrome(ws_url)
    end
    println("Connected successfully!")

    # Test navigation
    println("\nNavigating to example.com...")
    result = navigate(client, "https://example.com")
    println("Navigation result: ", JSON3.write(result))

    # Test JavaScript evaluation
    println("\nEvaluating page content...")
    title = evaluate(client, "document.title")
    println("Page title: ", title)

    heading = evaluate(client, "document.querySelector('h1').textContent")
    println("Main heading: ", heading)

    # Take screenshot
    println("\nTaking screenshot...")
    if (data = screenshot(client)) !== nothing
        open("screenshot.png", "wb") do io
            write(io, base64decode(data))
        end
        println("Screenshot saved as screenshot.png")
    end

    # Clean up
    close(client)
    println("\nTest completed!")
catch e
    println("Error during test: ", e)
    println("Stack trace:")
    for (exc, bt) in Base.catch_stack()
        showerror(stdout, exc, bt)
        println()
    end
end
