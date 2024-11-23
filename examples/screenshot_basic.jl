using ChromeDevToolsLite
using Base64

# Connect to Chrome
client = connect_chrome(get_ws_url())
println("Connected to Chrome")

# Create a test page with some content
println("\nCreating test page...")
goto(client, "about:blank")
evaluate(client, """
    document.body.innerHTML = `
        <div style="padding: 40px; background: linear-gradient(45deg, #f06, #9f6);">
            <h1 style="color: white;">Screenshot Test</h1>
            <p style="color: white;">This page demonstrates screenshot functionality.</p>
            <div style="width: 100px; height: 100px; background: white; margin: 20px;"></div>
        </div>
    `;
""")

# Take a screenshot
println("\nTaking screenshot...")
screenshot_data = screenshot(client)

# Save the screenshot
if !isnothing(screenshot_data)
    filename = "test_screenshot.png"
    open(filename, "w") do io
        write(io, base64decode(screenshot_data))
    end
    println("Screenshot saved as: ", filename)
else
    println("Failed to capture screenshot")
end

# Clean up
close(client)
println("\nConnection closed.")
