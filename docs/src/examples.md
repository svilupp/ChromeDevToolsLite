# Examples

This guide showcases practical examples of using ChromeDevToolsLite's HTTP-based Chrome DevTools Protocol implementation.

## Basic Browser Operations
```julia
# Connect to Chrome running with remote debugging enabled
browser = connect_browser("http://localhost:9222")

try
    # List all pages
    pages = get_pages(browser)
    println("Found $(length(pages)) pages")

    # Print information about each page
    for page in pages
        println("Page ID: $(page.id)")
        println("URL: $(page.url)")
        println("Title: $(page.title)")
    end
catch e
    if e isa HTTP.RequestError
        @error "Failed to connect to Chrome" exception=e
    else
        rethrow(e)
    end
end
```

## Managing Pages
```julia
# Create and manage pages
browser = connect_browser()

try
    # Create a new page
    new_page = new_page(browser)
    println("Created new page: $(new_page.id)")

    # List updated pages
    updated_pages = get_pages(browser)
    println("Total pages after creation: $(length(updated_pages))")

    # Close the new page
    close_page(browser, new_page)

    # Verify page was closed
    final_pages = get_pages(browser)
    println("Total pages after closing: $(length(final_pages))")
finally
    # Clean up any remaining pages
    for page in get_pages(browser)
        close_page(browser, page)
    end
end
```

## Error Handling
```julia
# Example of proper error handling
try
    browser = connect_browser("http://localhost:9222")

    # Try to create a new page
    page = new_page(browser)

    # Clean up
    close_page(browser, page)
catch e
    if e isa HTTP.RequestError
        @error "Failed to connect to Chrome or execute command" exception=e
    else
        @error "Unexpected error" exception=e
    end
end
```
