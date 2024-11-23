using ChromeDevToolsLite
const CDP = ChromeDevToolsLite
# Start browser and create a new page
# browser = Browser(; endpoint = "http://localhost:9222")
browser = Browser(; endpoint = "http://localhost:9222")
context = new_context(browser)
page = create_page(context)

# Navigate to a simple webpage
goto(page, "https://example.com")

# Print the title to verify it worked
println("Page title: ", get_title(page))

# Cleanup
close(page)
close(browser)
