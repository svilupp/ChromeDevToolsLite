# Error Handling Guide

## Common Errors

### Connection Errors

1. **WebSocket Connection Errors**
```julia
try
    client = connect_browser(verbose=true)
catch e
    if e isa HTTP.WebSockets.WebSocketError
        @error "Failed to establish WebSocket connection" exception=e
    end
end
```

### Element Interaction Errors

1. **Element Visibility**
```julia
element = ElementHandle(client, "#button")
if !is_visible(element)
    @warn "Element not found or not visible"
end
```

2. **Operation Verification**
```julia
# Form interactions
element = ElementHandle(client, "#input")
type_text(element, "test")
```

### CDP Message Errors

```julia
# Use verbose flag for detailed error information
result = send_cdp_message(client, "Runtime.evaluate",
    Dict("expression" => "document.title",
         "returnByValue" => true),
    verbose=true)

if haskey(result, "error")
    @error "CDP command failed" error=result["error"]
end
```

## Best Practices

### 1. Resource Cleanup
Always use try-finally blocks to ensure proper cleanup:
```julia
client = connect_browser()
try
    # Your automation code here
finally
    close(client)
end
```

### 2. Connection Management
```julia
# Enable verbose mode during development
client = connect_browser(verbose=true)
```

### 3. Element State Verification
Always check element state before interaction:
```julia
element = ElementHandle(client, "#button", verbose=true)
if is_visible(element)
    click(element, verbose=true)
else
    @warn "Element not ready for interaction"
end
```

### 4. Debugging Options

Two ways to enable detailed logging:
```julia
# 1. Using verbose flag (recommended)
client = connect_browser(verbose=true)
element = ElementHandle(client, "#button", verbose=true)

# 2. Using Julia's logging system
using Logging
global_logger(ConsoleLogger(stderr, Logging.Debug))
```

## Common Solutions

### 1. Browser Connection
```julia
# Ensure Chrome is running with correct flags
# chromium --remote-debugging-port=9222

# Connect to browser
client = connect_browser()
```

### 2. Element Selection Issues
```julia
# Use more specific selectors
element = ElementHandle(client, "#unique-id")
# Or compound selectors
element = ElementHandle(client, "div.container > button[type='submit']")
```

### 3. Form Interaction Issues
```julia
# Clear existing input before typing
element = ElementHandle(client, "#input")
result = evaluate_handle(element, "el => el.value = ''")
type_text(element, "new text")
```

## Debugging Tips

1. Use verbose=true flag for detailed operation information
2. Check browser console for JavaScript errors
3. Verify selectors using browser developer tools
4. Use `evaluate_handle` for complex debugging scenarios
5. Monitor network requests using CDP Network domain

Remember to handle errors at the appropriate level and provide meaningful error messages to users of your automation scripts.
