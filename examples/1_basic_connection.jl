"""
    Basic Browser Connection Example

This example demonstrates how to:
1. Connect to a Chrome browser
2. Navigate to a page
3. Properly clean up resources
"""

using ChromeDevToolsLite

# Connect to Chrome browser
println("Connecting to browser...")
client = connect_browser(verbose = true)

try
    # Navigate to a test page
    println("Navigating to example.com...")
    goto(client, "https://example.com")

    # Get page title using JavaScript evaluation
    title = evaluate(client, "document.title")
    println("Page title: $title")

    println("Example completed successfully!")
finally
    # Always close the connection
    println("Closing browser connection...")
    close(client)
end
