using ChromeDevToolsLite

# Connect to Chrome and create a new page
browser = connect_browser()
page = new_page(browser)

# Navigate to a website
execute_cdp_method(browser, page, "Page.navigate", Dict("url" => "https://example.com"))

# Wait a bit for the page to load (in real usage, you might want to implement proper waiting)
sleep(1)

# Get the page title using JavaScript
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => "document.title",
    "returnByValue" => true
))

println("Page title: ", result.result.value)

# Clean up
close_page(browser, page)
