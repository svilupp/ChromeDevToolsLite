# API Reference

## Types

```@autodocs
Modules = [ChromeDevToolsLite]
Order   = [:type]
```

## Functions

```@autodocs
Modules = [ChromeDevToolsLite]
Order   = [:function]
```

## Common Usage Patterns

### State Verification
```julia
# Verify page load and state
state = verify_page_state(browser, page)
if state !== nothing
    println("Page loaded: ", state["url"])
    println("Elements found: ", state["metrics"])
end
```

```julia
# Batch form updates
updates = Dict(
    "#username" => "user123",
    "#password" => "pass456",
    "#email" => "test@example.com"
)
result = batch_update_elements(browser, page, updates)
```

```julia
# Batch form updates
updates = Dict(
    "#username" => "user123",
    "#password" => "pass456",
    "#email" => "test@example.com"
)
result = batch_update_elements(browser, page, updates)
```

### Navigation
```julia
# Basic navigation
result = execute_cdp_method(browser, page, "Page.navigate", Dict(
    "url" => "https://example.com"
))

# Wait for load (manual since no WebSocket events)
sleep(1)

# Verify navigation
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => "document.readyState",
    "returnByValue" => true
))
```

### DOM Operations
```julia
# Form interaction
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => """
        const input = document.querySelector('input[name="username"]');
        if (input) {
            input.value = 'test_user';
            input.dispatchEvent(new Event('input'));
            return true;
        }
        return false;
    """,
    "returnByValue" => true
))

# Multiple operations in single call
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => """
        (function() {
            const form = document.querySelector('form');
            if (!form) return { success: false, error: 'Form not found' };

            const username = form.querySelector('input[name="username"]');
            const password = form.querySelector('input[name="password']");

            if (!username || !password) {
                return { success: false, error: 'Fields not found' };
            }

            username.value = 'test_user';
            password.value = 'password123';

            form.submit();
            return { success: true };
        })()
    """,
    "returnByValue" => true
))
```

## Error Handling

The API can throw the following errors:
- `HTTP.RequestError`: Connection issues with Chrome
- `ErrorException`: Chrome not running or incorrect endpoint
- CDP method errors: When a CDP method fails or is unsupported

Example error handling:
```julia
try
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    if haskey(result, "result")
        println("Success:", result["result"]["value"])
    else
        println("Error:", get(result, "error", "Unknown error"))
    end
catch e
    if e isa HTTP.RequestError
        println("Connection error:", e)
    else
        println("Unexpected error:", e)
    end
end
```

## HTTP-Specific Considerations

### Limitations
- No WebSocket support means no real-time events
- All operations are synchronous HTTP requests
- Manual waiting required for navigation/loading
- DOM operations must be done via JavaScript
- No direct element handles or references

### Best Practices
1. **State Management**
   - Use `verify_page_state` for reliable state checking
   - Implement timeouts for all operations
   - Batch related operations together
   - Cache state information when possible

2. **Performance Optimization**
   - Use `batch_update_elements` for multiple updates
   - Combine related JavaScript operations
   - Minimize CDP method calls
   - Cache selector results in JavaScript

3. **Error Recovery**
   - Implement retry mechanisms for transient failures
   - Validate state after operations
   - Clean up resources after errors
   - Use appropriate timeouts

4. **Resource Management**
   - Close pages when done
   - Clear form states after use
   - Reset application state between tests
   - Manage browser memory usage

See [HTTP Limitations](../guides/http_limitations.md) for detailed constraints and workarounds.
