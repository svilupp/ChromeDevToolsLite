# Getting Started with ChromeDevToolsLite.jl

## Installation

```julia
using Pkg
Pkg.add("ChromeDevToolsLite")
```

## Basic Usage

Here's a simple example that demonstrates the core functionality:

```julia
using ChromeDevToolsLite

# Connect to browser (enable verbose mode for debugging)
client = connect_browser(verbose=true)

# Navigate to a website
goto(client, "https://example.com")

# Find and interact with elements
element = ElementHandle(client, "#submit-button", verbose=true)
click(element, verbose=true)

# Fill out a form
input = ElementHandle(client, "#search", verbose=true)
type_text(input, "search query", verbose=true)

# Take a screenshot
screenshot(client, verbose=true)

# Clean up
close(client)
```

## Key Concepts

### Browser Management
- A WebSocket connection to Chrome DevTools Protocol
- Each connection can control a Chrome browser instance
- Supports page navigation, element interaction, and JavaScript evaluation

### Page Navigation
- Use `goto` to navigate to URLs
- Use `ElementHandle` to find elements
- Use `content` to retrieve the page's HTML

### Element Interaction
- Find elements using CSS selectors with `ElementHandle`
- Interact using methods like `click`, `type_text`
- Check element state with `is_visible`, `get_text`
- Enable verbose mode for debugging: `ElementHandle(client, selector, verbose=true)`

### Debugging
- Use verbose flag for detailed logging:
  ```julia
  client = connect_browser(verbose=true)
  element = ElementHandle(client, "#button", verbose=true)
  click(element, verbose=true)
  ```
- Check operation results and error messages
- Monitor browser console output

### Error Handling
The package includes error handling for:
- Connection issues
- Navigation failures
- Element interaction failures

## Best Practices

1. Always close resources:
```julia
try
    # Your code here
finally
    close(client)
end
```

2. Use verbose mode during development:
```julia
# Enable verbose mode for detailed logging
client = connect_browser(verbose=true)
element = ElementHandle(client, "#slow-element", verbose=true)
if !isnothing(element)
    click(element, verbose=true)
end
```

3. Handle errors gracefully:
```julia
try
    element = ElementHandle(client, "#maybe-exists", verbose=true)
    if !isnothing(element)
        click(element, verbose=true)
    end
catch e
    @warn "Element not found or interaction failed" exception=e
    rethrow(e)
end
```

4. Working with Multiple Elements:
```julia
# Find multiple elements
items = [ElementHandle(client, ".item", verbose=true) for _ in 1:3]
for item in items
    if is_visible(item)
        text = get_text(item)
        testid = get_attribute(item, "data-testid")
        println("Item $testid: $text")
    end
end
```

5. Form Interactions:
```julia
# Fill out a form
name_input = ElementHandle(client, "#name", verbose=true)
type_text(name_input, "John Doe", verbose=true)

color_select = ElementHandle(client, "#color", verbose=true)
select_option(color_select, "blue", verbose=true)

submit_button = ElementHandle(client, "button[type='submit']", verbose=true)
click(submit_button, verbose=true)

# Verify submission
result = ElementHandle(client, "#result", verbose=true)
@assert contains(get_text(result), "John Doe")
```

6. Screenshots:
```julia
# From examples/16_screenshot_comprehensive_test.jl
# Full page screenshot
screenshot(client, verbose=true)

# Element-specific screenshot
header = ElementHandle(client, "header", verbose=true)
screenshot(header, verbose=true)
```
