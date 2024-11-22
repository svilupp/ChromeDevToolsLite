# Getting Started with ChromeDevToolsLite.jl

## Installation

```julia
using Pkg
Pkg.add("ChromeDevToolsLite")
```

## Prerequisites

You need Chrome/Chromium running with remote debugging enabled. Start Chrome with:

```bash
chrome --remote-debugging-port=9222
```

## Basic Usage

Here's a simple example that demonstrates the core functionality:

```julia
using ChromeDevToolsLite

# Connect to Chrome running with remote debugging
browser = connect_browser("http://localhost:9222")

try
    # List all open pages
    pages = get_pages(browser)
    println("Found $(length(pages)) pages")

    # Create a new page
    page = new_page(browser)
    println("Created new page with ID: $(page.id)")
    println("Title: $(page.title)")
    println("URL: $(page.url)")

    # Clean up
    close_page(browser, page)
finally
    # Make sure to clean up any remaining pages
    for page in get_pages(browser)
        close_page(browser, page)
    end
end
```

## Key Concepts

### Browser Management
- A `Browser` represents a connection to Chrome's debugging interface
- Each browser can have multiple `Page`s (tabs)
- Pages can be created, listed, and closed via HTTP endpoints

### Error Handling
The package includes specific error types:
- `HTTP.RequestError`: When there are issues with the HTTP connection
- `ErrorException`: When Chrome is not running or the endpoint is incorrect

## Best Practices

1. Always clean up resources:
```julia
try
    # Your code here
finally
    # Clean up pages when done
    for page in get_pages(browser)
        close_page(browser, page)
    end
end
```

2. Handle connection errors gracefully:
```julia
try
    browser = connect_browser()
catch e
    @error "Failed to connect to Chrome" exception=e
    # Handle the error appropriately
end
```
