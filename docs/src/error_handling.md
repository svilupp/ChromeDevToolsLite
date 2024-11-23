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

2. **Browser Not Available**
```julia
if !verify_browser_available("http://localhost:9222")
    @error "Chrome not available. Start it with: chromium --remote-debugging-port=9222"
end
```

### Element Interaction Errors

1. **Element Not Found**
```julia
element = ElementHandle(client, "#non-existent")
if !is_visible(element)
    @warn "Element not found or not visible"
end
```

2. **Operation Failures**
```julia
# Click operations
if !click(element)
    @warn "Click operation failed"
end

# Form interactions
if !type_text(element, "test")
    @warn "Failed to input text"
end
```

### CDP Message Errors

1. **Invalid CDP Commands**
```julia
result = send_cdp_message(client, "Runtime.evaluate",
    Dict("expression" => "document.title",
         "returnByValue" => true))

if haskey(result, "error")
    @error "CDP command failed" error=result["error"]
end
```

2. **JavaScript Evaluation Errors**
```julia
result = evaluate_handle(element, "el => el.someUndefinedMethod()")
if result === nothing
    @warn "JavaScript evaluation failed"
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
    close_browser(client)
end
```

### 2. Connection Retry Logic
Use the built-in retry mechanism for robust connections:
```julia
client = connect_browser(; max_retries=3)
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

### 1. Browser Launch Issues
```julia
# Ensure Chrome is running with correct flags
# chromium --remote-debugging-port=9222

# Verify browser availability
if !ensure_chrome_running(max_attempts=5, delay=1.0)
    error("Failed to connect to Chrome")
end
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
