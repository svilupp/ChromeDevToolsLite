using ChromeDevToolsLite

println("Connecting to Chrome...")
browser = connect_browser("http://localhost:9222")

# Get the target info for a new page
target_info = send_cdp_message(browser, "Target.createTarget", Dict("url" => "about:blank"))
page = Page(browser, get(target_info, "targetId", ""))

println("Navigating to example.com...")
goto(page, "https://example.com")

# Find and interact with elements
h1 = query_selector(page, "h1")
if h1 !== nothing
    # Get text content
    println("Header text: ", get_text(h1))

    # Get attributes
    println("Class attribute: ", get_attribute(h1, "class"))
end

# Take a screenshot
screenshot_data = screenshot(page)
println("Screenshot data length: ", length(screenshot_data))

# Get page content
html_content = content(page)
println("Page content length: ", length(html_content))
