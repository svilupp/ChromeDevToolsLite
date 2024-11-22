```@meta
CurrentModule = ChromeDevToolsLite
```

# ChromeDevToolsLite

ChromeDevToolsLite.jl is a minimal Julia package for browser automation using HTTP endpoints of the Chrome DevTools Protocol (CDP). It provides a simple interface for managing Chrome/Chromium browser tabs programmatically.

## Features

- Browser connection via HTTP endpoints
- Page/tab management (create, list, close)
- Simple error handling

## Quick Start

```julia
using ChromeDevToolsLite

# Connect to Chrome running with --remote-debugging-port=9222
browser = connect_browser()

try
    # Create a new page
    page = new_page(browser)
    println("Created new page with ID: $(page.id)")

    # List all pages
    pages = get_pages(browser)
    println("Total pages: ", length(pages))

    # Clean up
    close_page(browser, page)
finally
    # Make sure to clean up any remaining pages
    for page in get_pages(browser)
        close_page(browser, page)
    end
end
```

See the [Browser](@ref) API documentation for more details.

```@index
```
