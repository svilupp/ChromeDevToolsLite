using ChromeDevToolsLite

# Connect to Chrome (make sure Chrome is running with --remote-debugging-port=9222)
browser = connect_browser()

# List current pages
println("Current pages:")
for page in get_pages(browser)
    println(" - Page '$(page.title)' at $(page.url)")
end

# Create a new page
page = new_page(browser)
println("\nCreated new page with ID: $(page.id)")

# List pages again to see our new page
println("\nUpdated pages:")
for page in get_pages(browser)
    println(" - Page '$(page.title)' at $(page.url)")
end

# Close the page
close_page(browser, page)
println("\nClosed page $(page.id)")
