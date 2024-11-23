# ChromeDevToolsLite 
[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svilupp.github.io/ChromeDevToolsLite.jl/stable/) 
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svilupp.github.io/ChromeDevToolsLite.jl/dev/)
[![Build Status](https://github.com/svilupp/ChromeDevToolsLite.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/svilupp/ChromeDevToolsLite.jl/actions/workflows/CI.yml?query=branch%3Amain) 
[![Coverage](https://codecov.io/gh/svilupp/ChromeDevToolsLite.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/svilupp/ChromeDevToolsLite.jl) 
[![Aqua](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

A lightweight Julia package for browser automation using the Chrome DevTools Protocol (CDP). Inspired by Python's Playwright but providing just the essential functionality to get you started with browser automation in Julia.

> [!WARNING]
> This package is experimental and was developed with the help of Cognition's Devin. While it's great for supervised browser automation, never leave AI agents unsupervised when controlling your browser!

## Why ChromeDevToolsLite?

- **Lightweight & Simple**: Focused on essential browser automation features
- **Existing Browser Sessions**: Connect to already open Chrome windows (keep your login sessions!)
- **AI-Friendly**: Perfect for supervised browser automation with LLMs
- **Modern Protocol**: Uses Chrome DevTools Protocol (CDP) for reliable communication

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

## Installation

Package is not registered yet.

```julia
using Pkg
Pkg.add(url="https://github.com/svilupp/ChromeDevToolsLite.jl")
```

## Prerequisites

- Chrome/Chromium browser started with remote debugging enabled
- Julia 1.10 or higher

See [Chrome Setup Guide](#chrome-setup-guide) at the end of this README for detailed instructions for your operating system.

## Quick Start

```julia
using ChromeDevToolsLite

# 1. Start Chrome with remote debugging enabled (see Chrome Setup Guide below). Assumed to be started on port 9222.
# 2. Connect to the browser
client = connect_browser("http://localhost:9222") # your chrome debugging connection

# 3. Basic automation example
try
    # Navigate to a page
    send_cdp_message(client, "Page.navigate", Dict("url" => "https://example.com"))
    
    # Take a screenshot
    screenshot = send_cdp_message(client, "Page.captureScreenshot")
    write("screenshot.png", base64decode(screenshot["result"]["data"]))
    
    # Find and click a button
    button = ElementHandle(client, "#submit-button")
    click(button)
finally
    close_browser(client)
end
```

## AI Integration Example

```julia
using ChromeDevToolsLite
using Base64

function ask_llm_about_page(screenshot_path)
    # Your LLM integration code here
    # eg., OpenAI.create_chat(...) or Anthropic.messages(...)
end

client = connect_browser()
try
    # Navigate to page
    send_cdp_message(client, "Page.navigate", Dict("url" => "https://example.com"))
    
    # Capture screenshot
    screenshot = send_cdp_message(client, "Page.captureScreenshot")
    write("screenshot.png", base64decode(screenshot["result"]["data"]))
    
    # Ask LLM about the page
    llm_response = ask_llm_about_page("screenshot.png")
    
    # Let LLM suggest next actions (with proper supervision!)
    println("LLM suggests: ", llm_response)
finally
    close_browser(client)
end
```

## Troubleshooting

### Common Issues and Solutions

1. **Browser Connection Issues**
```julia
# Ensure Chrome is running with debugging port
# First, check if Chrome is available
if !ensure_browser_available("http://localhost:9222")
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

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Chrome Setup Guide

### Windows
1. Find your Chrome/Chromium installation path (typically `C:\Program Files\Google\Chrome\Application\chrome.exe`)
2. Open Command Prompt (cmd) and run:
```batch
"C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222
```
Or for headless mode:
```batch
"C:\Program Files\Google\Chrome\Application\chrome.exe" --remote-debugging-port=9222 --headless
```

### macOS
1. Open Terminal and run:
```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222
```
Or for headless mode:
```bash
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome --remote-debugging-port=9222 --headless
```

### Linux
1. Open Terminal and run:
```bash
google-chrome --remote-debugging-port=9222
# Or for Chromium
chromium --remote-debugging-port=9222
```
Or for headless mode:
```bash
google-chrome --remote-debugging-port=9222 --headless
# Or for Chromium
chromium --remote-debugging-port=9222 --headless
```

### Verifying Setup
To verify Chrome is running in debug mode:
1. Open your browser and navigate to: `http://localhost:9222`
2. You should see a JSON page listing available debugging targets
3. In Julia, you can verify with:
```julia
using ChromeDevToolsLite
ensure_browser_available("http://localhost:9222")
```

### Common Setup Issues
- **Port Already in Use**: If port 9222 is taken, try a different port (e.g., 9223)
- **Permission Denied**: Run the command with elevated privileges (admin/sudo). Add permissions to the terminal / VSCode in your Mac's Security & Privacy settings.
- **Chrome Not Found**: Ensure the path to Chrome executable is correct
- **Chrome Already Running**: If you have Chrome already running, you cannot start a new instance with debugging enabled. You need to first close Chrome and then start it with the debugging port enabled.
- **Firewall Issues**: Check if your firewall is blocking the connection


## Alternative Packages

- [WebDriver.jl](https://github.com/Nosferican/WebDriver.jl): A mature package using the Selenium WebDriver protocol. While it requires opening new browser windows (losing existing sessions), it's battle-tested and might be more suitable for production use cases.
