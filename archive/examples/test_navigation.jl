using ChromeDevToolsLite

# Connect to Chrome
ws_url = get_ws_url()
println("Connecting to Chrome at: ", ws_url)
client = connect_chrome(ws_url)

# Test goto navigation
println("\nTesting goto navigation...")
success = goto(client, "https://example.com")
println("Navigation successful: ", success)

# Test getting page content
println("\nGetting page content...")
html_content = content(client)
if !isnothing(html_content)
    println("Content length: ", length(html_content))
    println("Content preview: ", html_content[1:min(100, length(html_content))], "...")
else
    println("Failed to get page content")
end

close(client)
println("\nTest completed!")
