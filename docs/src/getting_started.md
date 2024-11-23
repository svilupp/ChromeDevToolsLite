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

# Connect to browser
client = connect_browser()

# Navigate to a website
goto(client, "https://example.com")

# Find and interact with elements
element = ElementHandle(client, "#submit-button")
click(element)

# Fill out a form
input = ElementHandle(client, "#search")
type_text(input, "search query")

# Take a screenshot
screenshot(client)

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
- Find elements using CSS selectors
- Interact using methods like `click`, `type_text`
- Check element state with `is_visible`, `get_text`

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

2. Use timeouts appropriately:
```julia
# Find element when ready
element = ElementHandle(client, "#slow-element")
if !isnothing(element)
    # Interact with the element

3. Handle errors gracefully:
```julia
try
    element = ElementHandle(client, "#maybe-exists")
    if !isnothing(element)
        click(element)
    end
catch e
    @warn "Element not found or interaction failed" exception=e
    rethrow(e)
end
```

4. Working with Multiple Elements:
```julia
# Find multiple elements
items = [ElementHandle(client, ".item") for _ in 1:3]
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
name_input = ElementHandle(client, "#name")
type_text(name_input, "John Doe")

color_select = ElementHandle(client, "#color")
select_option(color_select, "blue")

submit_button = ElementHandle(client, "button[type='submit']")
click(submit_button)

# Verify submission
result = ElementHandle(client, "#result")
@assert contains(get_text(result), "John Doe")
```

6. Screenshots:
```julia
# From examples/16_screenshot_comprehensive_test.jl
# Full page screenshot
screenshot(client)

# Element-specific screenshot
header = ElementHandle(client, "header")
screenshot(header)
```
