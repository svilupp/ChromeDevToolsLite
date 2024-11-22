```@meta
CurrentModule = ChromeDevToolsLite
```

# ChromeDevToolsLite

ChromeDevToolsLite.jl is a lightweight Julia package for browser automation using the Chrome DevTools Protocol (CDP). It provides a simple, intuitive interface for controlling Chrome/Chromium browsers programmatically.

## Features

- Browser automation and control via Chrome DevTools Protocol
- Page navigation and interaction with timeouts and error handling
- Comprehensive element selection and manipulation
- Form handling (input, checkboxes, dropdowns)
- Screenshot capabilities (full page and elements)
- Robust error handling with specific error types

## Quick Start

```julia
using ChromeDevToolsLite

# Launch browser and navigate
browser = launch_browser()
context = new_context(browser)
page = new_page(context)

try
    # Navigate and wait for content
    goto(page, "https://example.com")
    element = wait_for_selector(page, "#content")

    # Interact with forms
    type_text(page, "#search", "query")
    click(page, "#submit")

    # Handle multiple elements
    items = query_selector_all(page, ".item")
    for item in items
        println(get_text(item))
    end

    # Take screenshots
    screenshot(page, "page.png")
finally
    close(browser)
end
```

See the [Getting Started](@ref) guide for more examples.

```@index
```

```@autodocs
Modules = [ChromeDevToolsLite]
```
