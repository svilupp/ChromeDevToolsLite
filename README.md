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
  - Simple CDP-based browser control
  - Connect to existing Chrome/Chromium sessions
  - Automatic browser cleanup with try-finally blocks
  - Verbose mode for debugging

- **Page Operations**
  - Easy page navigation with `goto`
  - Screenshot capture with `screenshot`
  - Full HTML content access with `content`
  - Versatile JavaScript evaluation with `evaluate`
  - Paragraph and text extraction

- **DOM Interaction**
  - Form input field manipulation
  - Radio button and checkbox handling
  - Text area content management
  - Multiple element selection and verification

- **Input Control**
  - Mouse movement and click simulation
  - Double-click support
  - Keyboard input and key press events
  - Modifier key combinations (Control, Alt, Shift)
  - Element position detection

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

# Connect to the browser (assumes Chrome is running with remote debugging on port 9222)
client = connect_browser()

try
    # Navigate to a page
    goto(client, "https://example.com")

    # Find and interact with elements
    element = query_selector(client, "button")

    # Move mouse and click
    move_mouse(client, 100, 100)
    click(client)

    # Type text with keyboard
    input = query_selector(client, "input")
    type_text(input, "Hello World!")
    press_key(client, "Enter")

    # Take a screenshot
    screenshot(client)
finally
    close(client)
end
```

## AI Integration Example

```julia
using ChromeDevToolsLite
using Base64

function ask_llm_about_page(screenshot_path, page_info)
    # Your LLM integration code here
    # eg., OpenAI.create_chat(...) or Anthropic.messages(...)
end

client = connect_browser()
try
    # Navigate and wait for page load
    goto(client, "https://example.com")

    # Gather page information
    screenshot(client)
    page_info = Dict(
        "title" => evaluate(client, "document.title"),
        "content" => content(client),
        "url" => evaluate(client, "window.location.href")
    )

    # Ask LLM about the page
    llm_response = ask_llm_about_page("screenshot.png", page_info)
    println("LLM suggests: ", llm_response)
finally
    close(client)
end
```

## Troubleshooting

### Common Issues and Solutions

1. **Browser Connection**
```julia
# Ensure Chrome is running with debugging port
if !ensure_browser_available()
    error("Chrome not available. Start it with: chromium --remote-debugging-port=9222")
end

# Connect with verbose mode for debugging
client = connect_browser(verbose=true)
```

2. **Page Navigation and Content**
```julia
# Use try-catch for navigation issues
try
    goto(client, "https://example.com")
    page_content = content(client)
catch e
    println("Navigation failed: ", e)
end
```

3. **JavaScript Evaluation**
```julia
# Handle JavaScript evaluation safely
try
    # Find and click a button
    evaluate(client, "document.querySelector('button').click()")

    # Get input value
    value = evaluate(client, "document.querySelector('input').value")
catch e
    println("JavaScript evaluation failed: ", e)
end
```

4. **Resource Cleanup**
```julia
# Always use try-finally for proper cleanup
client = connect_browser()
try
    goto(client, "https://example.com")
    # Your automation code here
finally
    close(client)
end
```

For more detailed examples and solutions, see the [examples/](examples/) directory.

## Running Examples

The package includes six comprehensive example scripts in the `examples/` directory that demonstrate all key features:

### 1. Basic Connection (`1_basic_connection.jl`)
- Browser connection and cleanup
- Simple page navigation
- Basic operations

### 2. Page Operations (`2_page_operations.jl`)
- Navigation and content extraction
- JavaScript evaluation
- Screenshot capture
- Content manipulation

### 3. Element Interactions (`3_element_interactions.jl`)
- Finding elements on the page
- Clicking and form filling
- Element property extraction

### 4. Form Automation (`4_form_automation.jl`)
- Complex form handling with multiple input types
- Batch form field updates
- JSON-based form state verification
- Form submission and navigation tracking
- Multi-line text handling

### 5. Advanced Automation (`5_advanced_automation.jl`)
- Dynamic DOM manipulation and styling
- Complex JavaScript execution
- JSON-based content verification
- Visual result capture with screenshots

### 6. Mouse and Keyboard Control (`6_mouse_keyboard_control.jl`)
- Mouse movement and positioning
- Click and double-click operations
- Keyboard input simulation
- Modifier key combinations
- Element position detection
- Complex input sequences

To run an example:

```julia
julia --project=. examples/1_basic_connection.jl
```

## Local Development

1. Clone the repository
2. Install the package in development mode:
   ```julia
   using Pkg; Pkg.develop(path=".")
   ```
3. Start Chrome/Chromium with remote debugging:
   ```bash
   chromium --remote-debugging-port=9222
   # Or for headless testing:
   chromium --remote-debugging-port=9222 --headless
   ```
4. Run the examples to verify functionality:
   ```julia
   julia --project=. examples/1_basic_connection.jl
   ```

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
