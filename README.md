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
- Julia 1.10 or higher

## Quick Start

```julia
using ChromeDevToolsLite

# Launch browser
browser = launch_browser(headless=true)

# Create new context and page
context = new_context(browser)
page = new_page(context)

# Basic page operations with error handling
try
    goto(page, "https://example.com")

    # Wait for element with timeout
    button = wait_for_selector(page, "#submit-button", timeout=5000)
    click(button)

    # Form interaction with error checking
    if input = query_selector(page, "#search")
        type_text(input, "search term")
    end

    # JavaScript evaluation
    result = evaluate(page, "document.title")
    println("Page title: $result")

    # Take screenshot
    screenshot(page, "example.png")
catch e
    if e isa TimeoutError
        println("Operation timed out")
    elseif e isa ElementNotFoundError
        println("Element not found")
    elseif e isa NavigationError
        println("Navigation failed")
    else
        rethrow(e)
    end
finally
    # Always clean up resources
    close(browser)
end

## Troubleshooting

### Common Issues and Solutions

1. **Browser Connection Issues**
```julia
# Ensure Chrome is running with debugging port
# Wrong:
chromium
# Correct:
chromium --remote-debugging-port=9222 --headless
```

2. **Timeout Errors**
```julia
# Increase timeout for slow operations
wait_for_selector(page, "#slow-element", timeout=60000)  # 60 seconds
```

3. **Element Not Found**
```julia
# Check element existence before interaction
element = query_selector(page, "#my-element")
if element !== nothing
    click(element)
else
    println("Element not found, check selector")
end
```

4. **Navigation Errors**
```julia
try
    goto(page, url)
catch e
    if e isa NavigationError
        # Retry with longer timeout
        goto(page, url, Dict("timeout" => 60000))
    end
end
```

5. **Resource Cleanup**
```julia
# Always use try-finally for proper cleanup
browser = Browser()
try
    # Your code here
finally
    close(browser)
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

- [Browser API](docs/src/api/browser.md)
- [Page API](docs/src/api/page.md)
- [ElementHandle API](docs/src/api/element_handle.md)
- [Getting Started Guide](docs/src/getting_started.md)

## Contributing

Contributions are welcome! Please read our [Contributing Guide](docs/src/contributing.md) for details.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
