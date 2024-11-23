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
using HTTP
using JSON3

# Connect to Chrome running with remote debugging
browser = Browser("http://localhost:9222")

try
    # Create a new page
    response = HTTP.get("$(browser.endpoint)/json/new")
    page = Page(Dict(pairs(JSON3.read(String(response.body)))))
    println("Created new page with ID: $(page.id)")

    # Navigate to a URL
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))

    # Execute JavaScript
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    if haskey(result, "result") && haskey(result["result"], "value")
        println("Page title: ", result["result"]["value"])
    end

finally
    # Clean up
    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
end
```

## Key Concepts

### Browser Management
- A `Browser` represents a connection to Chrome's debugging interface
- Each browser can have multiple `Page`s (tabs)
- Pages can be created, listed, and closed via HTTP endpoints
- All interactions are done through CDP methods using HTTP

### CDP Methods
The package provides access to Chrome DevTools Protocol methods via HTTP:
- Page.navigate: Navigate to URLs
- Runtime.evaluate: Execute JavaScript
- DOM.querySelector: Query DOM elements
- DOM.querySelectorAll: Query multiple DOM elements

### Error Handling
The package includes specific error types:
- `HTTP.RequestError`: When there are issues with the HTTP connection
- `ErrorException`: When Chrome is not running or the endpoint is incorrect
- CDP method errors: When a CDP method fails or is unsupported

## Best Practices

1. Always clean up resources:
```julia
try
    # Your code here
finally
    # Clean up pages
    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
end
```

2. Handle CDP method errors:
```julia
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => "document.title",
    "returnByValue" => true
))

if haskey(result, "result") && haskey(result["result"], "value")
    println("Success:", result["result"]["value"])
else
    println("Error:", get(result, "error", "Unknown error"))
end
```

For more detailed information about supported features and limitations, see [HTTP Capabilities](assets/HTTP_CAPABILITIES.md).
