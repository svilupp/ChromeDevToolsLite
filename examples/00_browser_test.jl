using ChromeDevToolsLite

# Start browser and create a new page
browser = Browser()
context = new_context(browser)
page = create_page(context)

# Navigate to a simple webpage
goto(page, "https://example.com")

# Print the title to verify it worked
println("Page title: ", get_title(page))

# Cleanup
close(page)
close(browser)
