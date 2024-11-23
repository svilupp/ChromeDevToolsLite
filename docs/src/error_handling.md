# Error Handling Guide

## Common Errors

### Connection Errors

1. **WebSocket Connection Errors**
```julia
try
    client = connect_browser()
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

1. **CDP Command Results**
```julia
result = send_cdp_message(client, "Runtime.evaluate",
    Dict("expression" => "document.title",
         "returnByValue" => true))

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
Use the built-in connection management:
```julia
client = connect_browser()
```

### 3. Element State Verification
Always check element state before interaction:
```julia
element = ElementHandle(client, "#button")
if is_visible(element)
    click(element)
else
    @warn "Element not ready for interaction"
end
```

### 4. Logging Levels
Use appropriate logging levels for different scenarios:
```julia
using Logging

# For development/debugging
global_logger(ConsoleLogger(stderr, Logging.Debug))

# For production
global_logger(ConsoleLogger(stderr, Logging.Info))
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

1. Enable debug logging to see detailed operation information
2. Check browser console for JavaScript errors
3. Verify selectors using browser developer tools
4. Use `evaluate_handle` for complex debugging scenarios
5. Monitor network requests using CDP Network domain

Remember to handle errors at the appropriate level and provide meaningful error messages to users of your automation scripts.
