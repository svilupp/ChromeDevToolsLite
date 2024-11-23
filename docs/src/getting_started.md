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
- Use `query_selector` to find elements
- `content` retrieves the page's HTML

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
# Wait for element to be available
element = query_selector(client, "#slow-element")
```

3. Handle errors gracefully:
```julia
try
    element = query_selector(client, "#maybe-exists")
    if !isnothing(element)
        click(element)
    end
catch e
    @warn "Element not found or interaction failed"
    rethrow(e)
end
```

4. Working with Multiple Elements:
```julia
# From examples/15_query_selector_all_test.jl
all_items = query_selector_all(client, ".item")
for item in items
    if is_visible(item)
        text = get_text(item)
        testid = get_attribute(item, "data-testid")
        println("Item \$testid: \$text")
    end
end
```

5. Form Interactions:
```julia
# From examples/03_page_interactions.jl
type_text(client, "#name", "John Doe")
select_option(client, "#color", "blue")
click(client, "button[type='submit']")

# Verify submission
result_text = get_text(client, "#result")
@assert contains(result_text, "John Doe")
```

6. Screenshots:
```julia
# From examples/16_screenshot_comprehensive_test.jl
# Full page screenshot
screenshot(client, "full_page.png")

# Element-specific screenshot
header = query_selector(client, "header")
screenshot(header, "header.png")
```
