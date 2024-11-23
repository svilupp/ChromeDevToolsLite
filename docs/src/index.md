```@meta
CurrentModule = ChromeDevToolsLite
```

# ChromeDevToolsLite

ChromeDevToolsLite.jl is a minimal Julia package for browser automation using HTTP endpoints of the Chrome DevTools Protocol (CDP). It provides a lightweight interface for executing CDP methods over HTTP, focusing on core browser automation tasks without WebSocket dependencies.

## Features

- Browser connection via HTTP endpoints
- Page/tab management (create, list, close)
- CDP method execution over HTTP
- JavaScript evaluation and DOM manipulation
- Simple error handling

## Quick Start

```julia
using ChromeDevToolsLite
using HTTP
using JSON3

# Connect to Chrome running with --remote-debugging-port=9222
browser = Browser("http://localhost:9222")

try
    # Create a new page
    response = HTTP.get("$(browser.endpoint)/json/new")
    page = Page(Dict(pairs(JSON3.read(String(response.body)))))

    # Navigate to a website
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))

    # Execute JavaScript
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    println("Page title:", get(result, "result", Dict())["value"])
finally
    # Clean up
    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
end
```

See the [Browser](@ref) API documentation and [HTTP Capabilities](assets/HTTP_CAPABILITIES.md) for supported features and limitations.

```@index
```
