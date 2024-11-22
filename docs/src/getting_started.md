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

# Launch a browser
browser = launch_browser()

# Create a new context and page
context = new_context(browser)
page = new_page(context)

# Navigate to a website
goto(page, "https://example.com")

# Find and interact with elements
button = wait_for_selector(page, "#submit-button")
click(button)

# Fill out a form
input = query_selector(page, "#search")
type_text(input, "search query")

# Take a screenshot
screenshot(page)

# Clean up
close(browser)
```

## Key Concepts

### Browser Management
- A `Browser` instance represents a Chromium browser process
- Each browser can have multiple `BrowserContext`s (like incognito windows)
- Each context can have multiple `Page`s

### Page Navigation
- Use `goto` to navigate to URLs
- `wait_for_selector` ensures elements are available
- `content` retrieves the page's HTML

### Element Interaction
- Find elements using CSS selectors
- Interact using methods like `click`, `type_text`
- Check element state with `is_visible`, `get_text`

### Error Handling
The package includes specific error types:
- `TimeoutError`: Operation exceeded time limit
- `ElementNotFoundError`: Element not found
- `NavigationError`: Navigation failed
- `ConnectionError`: CDP connection issues

## Best Practices

1. Always close resources:
```julia
try
    # Your code here
finally
    close(browser)
end
```

2. Use timeouts appropriately:
```julia
# Wait up to 5 seconds for element
element = wait_for_selector(page, "#slow-element", timeout=5000)
```

3. Handle errors gracefully:
```julia
try
    element = query_selector(page, "#maybe-exists")
    if !isnothing(element)
        click(element)
    end
catch e
    if e isa ElementNotFoundError
        @warn "Element not found"
    else
        rethrow(e)
    end
end
```

4. Working with Multiple Elements:
```julia
# From examples/15_query_selector_all_test.jl
all_items = query_selector_all(page, ".item")
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
# From examples/03_page_interactions.jl
type_text(page, "#name", "John Doe")
select_option(page, "#color", "blue")
click(page, "button[type='submit']")

# Verify submission
result_text = get_text(page, "#result")
@assert contains(result_text, "John Doe")
```

6. Screenshots:
```julia
# From examples/16_screenshot_comprehensive_test.jl
# Full page screenshot
screenshot(page, "full_page.png")

# Element-specific screenshot
header = query_selector(page, "header")
screenshot(header, "header.png")
```
