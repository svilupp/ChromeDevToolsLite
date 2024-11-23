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

try
    # Navigate to a website
    goto(client, "https://example.com")

    # Find and interact with elements using JavaScript
    evaluate(client, """
        const button = document.querySelector('#submit-button');
        if (button) button.click();

        const searchInput = document.querySelector('#search');
        if (searchInput) searchInput.value = 'search query';
    """)

    # Take a screenshot
    screenshot(client, verbose=true)
finally
    # Clean up
    close(client)
end
```

## Key Concepts

### Browser Management
- A WebSocket connection to Chrome DevTools Protocol
- Each connection can control a Chrome browser instance
- Supports page navigation, JavaScript evaluation, and screenshots

### Page Navigation
- Use `goto` to navigate to URLs
- Use `evaluate` to run JavaScript code
- Use `content` to retrieve the page's HTML

### DOM Interaction
- Interact with elements using JavaScript via `evaluate`
- Query elements using standard CSS selectors
- Modify element properties and trigger events
- Enable verbose mode for debugging output

### Debugging
- Use verbose flag for detailed logging:
  ```julia
  client = connect_browser(verbose=true)
  result = evaluate(client, "document.querySelector('#button').click()")
  ```
- Check operation results and error messages
- Monitor browser console output

### Error Handling
The package includes error handling for:
- Connection issues
- Navigation failures
- JavaScript evaluation errors

## Best Practices

1. Always use try-finally for cleanup:
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
result = evaluate(client, """
    const element = document.querySelector('#slow-element');
    if (element) element.click();
""", verbose=true)
```

3. Handle errors gracefully:
```julia
try
    result = evaluate(client, """
        const element = document.querySelector('#maybe-exists');
        return element ? element.click() : null;
    """)
catch e
    @warn "Element interaction failed" exception=e
    rethrow(e)
end
```

4. Working with Multiple Elements:
```julia
# Find and process multiple elements
elements_data = evaluate(client, """
    const items = document.querySelectorAll('.item');
    return Array.from(items).map(item => ({
        visible: window.getComputedStyle(item).display !== 'none',
        text: item.textContent,
        testid: item.getAttribute('data-testid')
    }));
""")
for item in JSON.parse(elements_data)
    if item["visible"]
        println("Item $(item["testid"]): $(item["text"])")
    end
end
```

5. Form Interactions:
```julia
# Fill out a form
evaluate(client, """
    const nameInput = document.querySelector('#name');
    if (nameInput) nameInput.value = 'John Doe';

    const colorSelect = document.querySelector('#color');
    if (colorSelect) colorSelect.value = 'blue';

    const submitButton = document.querySelector('button[type='submit']');
    if (submitButton) submitButton.click();
""")

# Verify submission
result = evaluate(client, """
    const resultElement = document.querySelector('#result');
    return resultElement ? resultElement.textContent : '';
""")
@assert contains(result, "John Doe")
```

6. Screenshots:
```julia
# Full page screenshot
screenshot(client, verbose=true)

# Element-specific screenshot (not currently supported)
```
