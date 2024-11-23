# API Reference

## Core Types

### Browser
```julia
Browser(endpoint::String)
```
Represents a connection to Chrome's debugging interface.

### Page
```julia
struct Page
    id::String
    type::String
    url::String
    title::String
    ws_debugger_url::String
    dev_tools_frontend_url::String
end
```
Represents a page/tab in Chrome.

## Core Functions

### Browser Management
```julia
Browser(endpoint::String)
new_page(browser::Browser) -> Page
close_page(browser::Browser, page::Page) -> Nothing
get_pages(browser::Browser) -> Vector{Page}
```

### State Management Utilities
```julia
# Page state verification
function verify_page_state(browser::Browser, page::Page, timeout::Number=5)
    start_time = time()
    while (time() - start_time) < timeout
        result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
            "expression" => """
                ({
                    ready: document.readyState === 'complete',
                    url: window.location.href,
                    title: document.title,
                    metrics: {
                        links: document.querySelectorAll('a').length,
                        forms: document.querySelectorAll('form').length
                    }
                })
            """,
            "returnByValue" => true
        ))
        if !haskey(result, "error") && result["result"]["value"]["ready"]
            return result["result"]["value"]
        end
        sleep(0.1)
    end
    return nothing
end

# Batch DOM operations
function batch_update_elements(browser::Browser, page::Page, updates::Dict)
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const updates = $(JSON3.write(updates));
            const results = {};
            for (const [selector, value] of Object.entries(updates)) {
                const el = document.querySelector(selector);
                if (el) {
                    el.value = value;
                    el.dispatchEvent(new Event('input'));
                    results[selector] = true;
                } else {
                    results[selector] = false;
                }
            }
            return results;
        """,
        "returnByValue" => true
    ))
end
```

### CDP Method Execution
```julia
execute_cdp_method(browser::Browser, page::Page, method::String, params::Dict=Dict())
```
Executes Chrome DevTools Protocol methods via HTTP endpoints.

#### Parameters
- `browser`: Browser instance
- `page`: Page instance
- `method`: CDP method name (e.g., "Page.navigate")
- `params`: Dictionary of parameters for the CDP method

#### Returns
Dictionary containing either:
- `result`: Success response with method-specific data
- `error`: Error information if the method failed

## Common Usage Patterns

### State Verification
```julia
# Verify page load and state
state = verify_page_state(browser, page)
if state !== nothing
    println("Page loaded: ", state["url"])
    println("Elements found: ", state["metrics"])
end

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
# Element existence check
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => """
        !!document.querySelector('.my-class')
    """,
    "returnByValue" => true
))

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

See [HTTP_LIMITATIONS.md](../../HTTP_LIMITATIONS.md) for detailed constraints and workarounds.
