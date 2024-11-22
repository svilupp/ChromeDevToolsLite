# Page

```@docs
Page
```

The `Page` type represents a single page/tab in the Chrome browser.

## Core Methods

```@docs
get_pages
new_page
close_page
```

## Examples

```julia
# Basic page management
browser = connect_browser()

try
    # List all pages
    pages = get_pages(browser)
    println("Current pages: ", length(pages))

    # Create a new page
    page = new_page(browser)
    println("Created new page with ID: $(page.id)")

    # List pages again to see the new one
    updated_pages = get_pages(browser)
    println("Updated pages count: ", length(updated_pages))

    # Clean up
    close_page(browser, page)
finally
    # Make sure to clean up any remaining pages
    for page in get_pages(browser)
        close_page(browser, page)
    end
end
```

## Error Handling

Page operations can throw:
- `HTTP.RequestError`: When there are issues with the HTTP connection
- `ErrorException`: When Chrome is not running or the endpoint is incorrect
