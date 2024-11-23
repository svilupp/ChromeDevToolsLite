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
    send_cdp_message(client, "Page.navigate", Dict("url" => "https://example.com"))

    # Evaluate JavaScript
    result = send_cdp_message(client, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    # Take a screenshot
    screenshot = send_cdp_message(client, "Page.captureScreenshot")

    # Write screenshot to file
    write("screenshot.png", base64decode(screenshot["result"]["data"]))
finally
    close(client)
end
```

See the [Getting Started with ChromeDevToolsLite.jl](@ref) guide for more examples.

```@index
```
