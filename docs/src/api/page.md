# Page Navigation and Interaction

```@docs
goto
content
evaluate
screenshot
```

## Navigation

```julia
# Navigate to a URL
goto(client, "https://example.com")

# Get page content
html = content(client)
```

## JavaScript Evaluation

```julia
# Evaluate JavaScript
title = evaluate(client, "document.title")

# Evaluate with element handle
element = ElementHandle(client, "#myButton")
result = evaluate_handle(element, "el => el.textContent")
```

## Screenshots

```julia
# Take a full page screenshot
screenshot(client)

# Take element screenshot
element = ElementHandle(client, "header")
screenshot(element)
```

## Examples

```julia
client = connect_browser()

try
    # Navigate and interact with page
    goto(client, "https://example.com")

    # Get page title
    title = evaluate(client, "document.title")

    # Find and interact with elements
    button = ElementHandle(client, "#submit-button")
    click(button)

    # Take screenshot
    screenshot(client)
finally
    close(client)
end
```

## Error Handling

Page operations can throw various exceptions. See [Error Types](@ref) in the Types section for details.

Note: All operations support a `verbose` flag for detailed logging:
```julia
goto(client, "https://example.com", verbose=true)
```
