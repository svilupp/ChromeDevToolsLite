using ChromeDevToolsLite
using JSON3
using HTTP

println("Starting Chrome...")
run(`chromium --remote-debugging-port=9222 --headless --no-sandbox`, wait=false)

# Wait for Chrome to be ready (max 10 seconds)
endpoint = "http://localhost:9222"
for _ in 1:10
    try
        response = HTTP.get("$endpoint/json/version")
        if response.status == 200
            break
        end
    catch
        sleep(1)
    end
end

try
    println("Connecting to browser...")
    browser = connect_browser("http://localhost:9222")

    println("\nCreating new page...")
    page = create_page(browser)

    println("\nNavigating to example.com...")
    goto(page, "https://example.com")
    sleep(2) # Give page time to load

    println("\nGetting page title...")
    title = evaluate(page, "document.title")
    println("Page title: ", title)

    println("\nGetting page content...")
    html = content(page)
    println("Page content length: ", length(html), " characters")

    println("\nTaking screenshot...")
    screenshot_data = screenshot(page)
    println("Screenshot data length: ", length(screenshot_data), " characters")

catch e
    println("Error occurred: ", e)
finally
    println("\nCleaning up...")
    try
        run(`pkill -f chromium`)
    catch
    end
end
