```@meta
CurrentModule = ChromeDevToolsLite
```

# ChromeDevToolsLite

ChromeDevToolsLite.jl is a minimal Julia package for browser automation using the Chrome DevTools Protocol (CDP). It provides direct access to CDP commands with a lightweight interface.

## Features

- Direct WebSocket connection to Chrome DevTools Protocol
- Page navigation and JavaScript evaluation
- DOM element selection and manipulation
- Mouse and keyboard control
- Form automation capabilities
- Screenshot and page content extraction
- Multi-page handling
- Minimal overhead and dependencies

## Quick Start

```julia
using ChromeDevToolsLite

# Connect to Chrome running with --remote-debugging-port=9222
client = connect_browser()

try
    # Navigate to a page
    goto(client, "https://example.com")

    # Find and interact with elements
    element = query_selector(client, "#login-form")

    # Type text into form
    input = query_selector(element, "input[type='text']")
    type_text(input, "username")

    # Click submit using mouse control
    submit = query_selector(element, "button[type='submit']")
    click(submit)

    # Take a screenshot
    screenshot(client)
finally
    close(client)
end
```

## Examples

Check out our example scripts in the `examples/` directory:

1. Basic Connection (`examples/1_basic_connection.jl`)
2. Page Operations (`examples/2_page_operations.jl`)
3. Element Interactions (`examples/3_element_interactions.jl`)
4. Form Automation (`examples/4_form_automation.jl`)
5. Advanced Automation (`examples/5_advanced_automation.jl`)
6. Mouse and Keyboard Control (`examples/6_mouse_keyboard_control.jl`)

See the [API Reference](@ref) for detailed documentation of all available functions.
```
