# ChromeDevToolsLite [![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svilupp.github.io/ChromeDevToolsLite.jl/stable/) [![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svilupp.github.io/ChromeDevToolsLite.jl/dev/) [![Build Status](https://github.com/svilupp/ChromeDevToolsLite.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/svilupp/ChromeDevToolsLite.jl/actions/workflows/CI.yml?query=branch%3Amain) [![Coverage](https://codecov.io/gh/svilupp/ChromeDevToolsLite.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svilupp/ChromeDevToolsLite.jl)

A lightweight Julia implementation for Chrome DevTools Protocol (CDP) focused exclusively on HTTP endpoints. This package provides essential browser automation capabilities without WebSocket dependencies, making it ideal for environments where WebSocket connections are restricted or not needed.

## Features

- ✅ **HTTP-Only CDP Implementation**
  - Page lifecycle management (create, navigate, close)
  - JavaScript execution and evaluation
  - DOM manipulation via JavaScript
  - Form interaction through JavaScript injection
  - Robust error handling and state verification
  - Batch operations support

- ⚠️ **Limitations** (see [HTTP_LIMITATIONS.md](HTTP_LIMITATIONS.md))
  - No real-time events or updates
  - No direct element handles
  - No WebSocket-dependent features

## Installation

```julia
using Pkg
Pkg.add("ChromeDevToolsLite")
```

## Prerequisites

- Chrome/Chromium browser with remote debugging enabled:
  ```bash
  chromium --remote-debugging-port=9222
  # or for Chrome
  google-chrome --remote-debugging-port=9222
  ```
- Julia 1.10 or higher

## Quick Start

```julia
using ChromeDevToolsLite

# Connect to Chrome
browser = Browser("http://localhost:9222")
page = nothing

try
    # Create new page
    page = new_page(browser)

    # Navigate and verify state
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))

    # Use state management utility
    state = verify_page_state(browser, page)
    if state !== nothing && state["ready"]
        println("Navigation successful")
        println("• Title: ", state["title"])
        println("• URL: ", state["url"])
        println("• Metrics: ", state["metrics"])
    end

    # Batch element updates
    updates = Dict(
        "#search" => "query term",
        "#filter" => "category",
        "#sort" => "date"
    )

    result = batch_update_elements(browser, page, updates)
    for (selector, success) in result
        println("Update $selector: ", success ? "✓" : "✗")
    end

    # Execute JavaScript with error handling
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            ({
                title: document.title,
                heading: document.querySelector('h1')?.textContent,
                metrics: {
                    links: document.querySelectorAll('a').length,
                    images: document.querySelectorAll('img').length
                }
            })
        """,
        "returnByValue" => true
    ))

    if haskey(result, "error")
        println("Error: ", result["error"])
    else
        data = result["result"]["value"]
        println("Page Analysis:")
        println("• Title: ", data["title"])
        println("• Heading: ", data["heading"])
        println("• Links: ", data["metrics"]["links"])
        println("• Images: ", data["metrics"]["images"])
    end
finally
    page !== nothing && close_page(browser, page)
end
```

## Examples

See the `examples/` directory for detailed examples:
- `01_basic_usage.jl`: Basic browser control and navigation
- `02_javascript_evaluation.jl`: Advanced JavaScript execution
- `03_form_interaction.jl`: Form interactions via JavaScript
- `04_error_handling.jl`: Error handling patterns and best practices
- `05_state_management.jl`: State verification and batch operations

## Documentation

- [HTTP Capabilities](HTTP_CAPABILITIES.md): Comprehensive guide to supported CDP methods and features
- [HTTP Limitations](HTTP_LIMITATIONS.md): Implementation constraints and workarounds
- [Troubleshooting Guide](TROUBLESHOOTING.md): Common issues and solutions
- [Migration Guide](MIGRATION.md): Guide for transitioning from WebSocket-based implementations
- [API Reference](docs/src/api/reference.md): Detailed API documentation

## Best Practices

1. **Error Handling**
   - Always check for `error` key in CDP responses
   - Implement proper cleanup in finally blocks
   - Use timeouts for all operations
   - Verify operation success explicitly
   - Handle connection errors gracefully

2. **State Management**
   - Use `verify_page_state` for reliable page state verification
   - Implement `batch_update_elements` for efficient DOM updates
   - Validate operation success through state checks
   - Cache state information when appropriate
   - Implement proper cleanup

3. **Performance Optimization**
   - Use batch operations for multiple DOM updates
   - Minimize CDP method calls through state caching
   - Implement efficient JavaScript selectors
   - Group related operations together
   - Use reasonable timeouts

4. **Limitations Awareness**
   - No real-time events
   - No WebSocket features
   - Manual state tracking required
   - See [HTTP_LIMITATIONS.md](HTTP_LIMITATIONS.md)

## Contributing

Contributions welcome! Please read our [Contributing Guide](docs/src/contributing.md).

## License

MIT License - see the LICENSE file for details.
