# ChromeDevToolsLite Examples

Simple examples demonstrating core CDP functionality.

## Prerequisites

1. Chrome/Chromium with remote debugging enabled:
```bash
google-chrome --remote-debugging-port=9222 --no-first-run --no-default-browser-check --headless
```

## Core Examples

### Connection and Navigation
- `simple_connection.jl` - Basic CDP connection and version info
- `navigation_basic.jl` - Simple page navigation

### Element Interaction
- `element_basic.jl` - Basic element selection and interaction
- `form_basic.jl` - Simple form filling example

### JavaScript and Content
- `evaluate_basic.jl` - JavaScript evaluation
- `content_basic.jl` - Page content retrieval

### Screenshots
- `screenshot_basic.jl` - Basic screenshot capture

### Complete Demo
- `minimal_core_demo.jl` - Comprehensive demo of all functionality

## Running Examples

```bash
julia --project=.. example_name.jl
```

Each example is self-contained and demonstrates specific CDP functionality without complex error handling or waiting mechanisms.
