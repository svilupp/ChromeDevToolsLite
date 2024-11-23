# API Reference

## Browser Operations
### `connect_browser(; verbose=false)`
Connects to a Chrome browser instance running with remote debugging enabled.

Example:
```julia
client = connect_browser(verbose=true)
```

### `close(client)`
Closes the connection to the browser.

Example:
```julia
close(client)
```

## Page Operations
### `goto(client, url)`
Navigates to the specified URL.

Example:
```julia
goto(client, "https://example.com")
```

### `content(client)`
Gets the HTML content of the current page.

Example:
```julia
html_content = content(client)
```

### `evaluate(client, script)`
Executes JavaScript code on the current page.

Example:
```julia
title = evaluate(client, "document.title")
```

### `screenshot(client; verbose=false)`
Takes a screenshot of the current page.

Example:
```julia
screenshot(client, verbose=true)
```

## Element Operations
### Element Selection and Interaction
Use `evaluate()` with JavaScript DOM operations for element interactions:

Example:
```julia
# Click a button
evaluate(client, "document.querySelector('button').click()")

# Fill a form field
evaluate(client, "document.querySelector('input[name=\"username\"]').value = 'John'")

# Get element text
text = evaluate(client, "document.querySelector('.content').textContent")
```

## Best Practices
1. Always use a `try`-`finally` block to ensure browser connections are properly closed:
```julia
client = connect_browser()
try
    # Your automation code here
finally
    close(client)
end
```

2. Use verbose mode for debugging:
```julia
client = connect_browser(verbose=true)
```

3. Handle JavaScript evaluation results appropriately:
```julia
# For complex data, use JSON serialization
data = evaluate(client, """
    JSON.stringify({
        title: document.title,
        url: window.location.href
    })
""")
parsed_data = JSON.parse(data)
```

## Examples
See the `examples/` directory for complete working examples:

1. `1_basic_connection.jl` - Basic browser connection and cleanup
2. `2_page_operations.jl` - Navigation, content extraction, and screenshots
3. `3_element_interactions.jl` - Finding and interacting with page elements
4. `4_form_automation.jl` - Complex form handling and submission
5. `5_advanced_automation.jl` - Advanced DOM manipulation and page modifications
