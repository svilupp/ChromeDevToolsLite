```@meta
CurrentModule = ChromeDevToolsLite
```

# ChromeDevToolsLite

ChromeDevToolsLite.jl is a minimal Julia package for browser automation using the Chrome DevTools Protocol (CDP). It provides direct access to CDP commands with a lightweight interface.

## Features

- Direct WebSocket connection to Chrome DevTools Protocol
- Basic page navigation and JavaScript evaluation
- Element interaction (click, type)
- Screenshot capabilities
- Minimal overhead and dependencies

## Quick Start

```julia
using ChromeDevToolsLite

# Connect to Chrome running with --remote-debugging-port=9222
client = connect_browser()

try
    # Navigate to a page
    goto(client, "https://example.com")

    # Get page content
    page_content = content(client)

    # Find and interact with elements
    element = ElementHandle(client, "#submit-button")
    click(element)

    # Take a screenshot
    screenshot(client)
finally
    close(client)
end
```

See the [Getting Started with ChromeDevToolsLite.jl](@ref) guide for more examples.

```@index
```
