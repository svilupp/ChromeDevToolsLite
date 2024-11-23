using ChromeDevToolsLite
using Base64

# Connect to Chrome
ws_url = get_ws_url()
println("Connecting to Chrome at: ", ws_url)
client = connect_chrome(ws_url)

# Create a test page with some content
println("\nSetting up test page...")
evaluate(client, """
    document.body.innerHTML = `
        <div style="padding: 20px; background: #f0f0f0;">
            <h1 style="color: blue;">Screenshot Test</h1>
            <p>This is a test page for screenshot functionality.</p>
        </div>
    `;
""")

# Take screenshot
println("\nTaking screenshot...")
screenshot_data = screenshot(client)

if !isnothing(screenshot_data)
    # Save screenshot to file
    println("Saving screenshot...")
    open("test_screenshot.png", "w") do io
        write(io, base64decode(screenshot_data))
    end
    println("Screenshot saved as test_screenshot.png")
else
    println("Failed to capture screenshot")
end

close(client)
println("\nTest completed!")
