# ChromeDevToolsLite [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svilupp.github.io/ChromeDevToolsLite.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svilupp.github.io/ChromeDevToolsLite.jl/dev/) [![Build Status](https://github.com/svilupp/ChromeDevToolsLite.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/svilupp/ChromeDevToolsLite.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/svilupp/ChromeDevToolsLite.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svilupp/ChromeDevToolsLite.jl) [![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

A lightweight Julia package for browser automation using the Chrome DevTools Protocol (CDP).

## Features

- **Browser Automation**
  - CDP-based browser control
  - Isolated browser contexts
  - Multiple page management
  - Configurable timeouts

- **Page Operations**
  - Navigation and URL handling
  - Screenshot capture
  - HTML content access
  - JavaScript evaluation

- **DOM Interaction**
  - Element selection and querying
  - Form handling (input, checkboxes, radio buttons)
  - Click and type operations
  - Element visibility checking

- **Error Handling**
  - Timeout management
  - Navigation error recovery
  - Element not found handling
  - Evaluation error handling

- **Resource Management**
  - Automatic cleanup
  - Context isolation
  - Memory optimization

## Installation

```julia
using Pkg
Pkg.add("ChromeDevToolsLite")
```

## Prerequisites

- Chrome/Chromium browser
  - On Linux: Will be automatically installed during tests
  - On other systems: Must be installed manually and started in debug mode
- Julia 1.10 or higher

## Quick Start

```julia
using ChromeDevToolsLite

# Connect to browser with retry handling
client = connect_browser(; max_retries=3)

try
    # Basic CDP message for navigation
    send_cdp_message(client, "Page.navigate", Dict("url" => "https://example.com"))

    # Create element handles for interaction
    button = ElementHandle(client, "#submit-button")
    if is_visible(button)
        click(button)
    end

    # Form interaction
    input = ElementHandle(client, "#search")
    type_text(input, "search term")

    # JavaScript evaluation
    result = send_cdp_message(client, "Runtime.evaluate",
                           Dict("expression" => "document.title",
                                "returnByValue" => true))
    println("Page title: ", result["result"]["value"])

    # Take screenshot
    screenshot_result = send_cdp_message(client, "Page.captureScreenshot")
    # Save base64 screenshot data
    write("screenshot.png", base64decode(screenshot_result["result"]["data"]))
catch e
    if e isa HTTP.WebSockets.WebSocketError
        println("WebSocket connection error")
    elseif e isa HTTP.ExceptionRequest.StatusError
        println("Browser connection failed")
    else
        rethrow(e)
    end
finally
    # Clean up resources
    close_browser(client)
end
```

## Troubleshooting

### Common Issues and Solutions

1. **Browser Connection Issues**
```julia
# Ensure Chrome is running with debugging port
# First, check if Chrome is available
if !verify_browser_available("http://localhost:9222")
    error("Chrome not available. Start it with: chromium --remote-debugging-port=9222")
end

# Connect with retry mechanism
client = connect_browser(; max_retries=3)
```

2. **Connection Retries**
```julia
# Use ensure_chrome_running for automatic retry
if !ensure_chrome_running(max_attempts=5, delay=1.0)
    error("Failed to connect to Chrome after multiple attempts")
end
```

3. **Element Interaction**
```julia
# Check element visibility before interaction
element = ElementHandle(client, "#my-element")
if is_visible(element)
    click(element)
else
    @warn "Element not visible or not found"
end
```

4. **JavaScript Evaluation**
```julia
# Evaluate JavaScript with proper error handling
result = send_cdp_message(client, "Runtime.evaluate",
    Dict("expression" => "document.title",
         "returnByValue" => true))
if haskey(result, "result")
    println("Result: ", result["result"]["value"])
end
```

5. **Resource Cleanup**
```julia
# Always use try-finally for proper cleanup
client = connect_browser()
try
    # Your code here
finally
    close_browser(client)
end
```

For more detailed examples and solutions, see the [examples/](examples/) directory.

## Running Examples

The package includes comprehensive example scripts in the `examples/` directory:

### Basic Operations
- `00_browser_test.jl`: Browser setup and management
- `01_page_navigation_test.jl`: Page navigation
- `02_local_navigation_test.jl`: Local file handling

### DOM Interaction
- `03_text_content_test.jl`: Text content extraction
- `04_form_interaction_test.jl`: Form handling
- `13_page_selectors_test.jl`: Element selectors
- `14_evaluate_handle_test.jl`: JavaScript evaluation

### Advanced Features
- `18_screenshot_comprehensive_test.jl`: Screenshot capabilities
- `19_checkbox_comprehensive_test.jl`: Checkbox interactions
- `20_timeout_comprehensive_test.jl`: Timeout handling
- `21_error_handling_comprehensive_test.jl`: Error management

To run an example:

```julia
julia --project=. examples/01_page_navigation_test.jl
```

## Local Development

1. Clone the repository
2. Start Chrome/Chromium with remote debugging:
   ```bash
   chromium --remote-debugging-port=9222 --headless
   ```
3. Run the examples to verify functionality

## Documentation

For detailed API documentation, see the `docs/` directory:

- [Browser API](docs/src/api/browser.md): Browser connection and CDP message handling
- [Element API](docs/src/api/element.md): DOM element interactions and form handling
- [Getting Started Guide](docs/src/getting_started.md): Quick start and basic usage examples
- [Error Handling Guide](docs/src/error_handling.md): Common errors and troubleshooting

## Contributing

Contributions are welcome! Please read our [Contributing Guide](docs/src/contributing.md) for details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
