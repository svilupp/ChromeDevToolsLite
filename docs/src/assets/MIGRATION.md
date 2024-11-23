# Migrating to HTTP-Only CDP Implementation

This guide helps you transition from WebSocket-based CDP implementations to ChromeDevToolsLite's HTTP-only approach.

## Key Differences

### 1. Connection Management
```julia
# Old WebSocket approach
browser = connect_websocket("ws://localhost:9222")

# ChromeDevToolsLite approach
browser = Browser("http://localhost:9222")
```

### 2. State Management
```julia
# Old WebSocket approach - NOT SUPPORTED
await page.waitForLoadState('networkidle')

# ChromeDevToolsLite approach - Explicit state checking
function verify_page_ready(browser, page, timeout=5)
    start_time = time()
    while (time() - start_time) < timeout
        result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
            "expression" => """
                ({
                    ready: document.readyState === 'complete',
                    url: window.location.href,
                    networkRequests: performance.getEntriesByType('resource').length
                })
            """,
            "returnByValue" => true
        ))
        if !haskey(result, "error") && result["result"]["value"]["ready"]
            return true
        end
        sleep(0.1)
    end
    return false
end
```

### 3. Event Handling
```julia
# Old WebSocket approach - NOT SUPPORTED
on_console_message(page) do msg
    println(msg)
end

# ChromeDevToolsLite approach - Use polling if needed
function check_console_messages()
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "console.memory",
        "returnByValue" => true
    ))
end
```

### 4. Element Handling
```julia
# Old WebSocket approach - NOT SUPPORTED
element = page.querySelector(".my-button")
element.click()

# ChromeDevToolsLite approach - Use JavaScript
execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => """
        const el = document.querySelector('.my-button');
        el && el.click();
    """,
    "returnByValue" => true
))
```

### 5. Batch Operations
```julia
# Old WebSocket approach - Multiple calls
element1.type("text1")
element2.type("text2")
element3.click()

# ChromeDevToolsLite approach - Single JavaScript execution
execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => """
        const updates = {
            '#input1': 'text1',
            '#input2': 'text2'
        };
        Object.entries(updates).forEach(([selector, value]) => {
            const el = document.querySelector(selector);
            if (el) {
                el.value = value;
                el.dispatchEvent(new Event('input'));
            }
        });
        document.querySelector('#button1')?.click();
    """,
    "returnByValue" => true
))
```

### 6. Navigation
```julia
# Old WebSocket approach - NOT SUPPORTED
await_navigation(page) do
    navigate_to(page, "https://example.com")
end

# ChromeDevToolsLite approach
result = execute_cdp_method(browser, page, "Page.navigate", Dict(
    "url" => "https://example.com"
))
sleep(1)  # Manual wait
```

## Common Patterns

### 1. Form Interaction
```julia
# Old approach
form = page.querySelector("form")
input = form.querySelector("input")
input.type("text")
form.submit()

# ChromeDevToolsLite approach
execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => """
        const form = document.querySelector('form');
        const input = form.querySelector('input');
        input.value = 'text';
        input.dispatchEvent(new Event('input'));
        form.submit();
    """,
    "returnByValue" => true
))
```

### 2. Waiting for Elements
```julia
# Old approach
wait_for_selector(page, ".dynamic-content")

# ChromeDevToolsLite approach
function wait_for_element(browser, page, selector, timeout=5)
    start_time = time()
    while (time() - start_time) < timeout
        result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
            "expression" => "!!document.querySelector('$selector')",
            "returnByValue" => true
        ))
        result["result"]["value"] && return true
        sleep(0.1)
    end
    return false
end
```

### 3. Error Handling
```julia
# Old approach
try
    await_promise(page.evaluate("async () => { ... }"))
catch e
    handle_error(e)
end

# ChromeDevToolsLite approach
result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => "(() => { ... })()",
    "returnByValue" => true
))
if haskey(result, "error")
    # Handle error
end
```

## Advanced Patterns

### 1. Complex State Verification
```julia
function verify_application_state(browser, page, timeout=5)
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            ({
                pageReady: document.readyState === 'complete',
                loginState: !!localStorage.getItem('user'),
                formState: {
                    valid: document.querySelector('form')?.checkValidity(),
                    dirty: Array.from(document.querySelectorAll('input')).some(i => i.value)
                },
                uiState: {
                    modal: !!document.querySelector('.modal[style*="display: block"]'),
                    loading: !!document.querySelector('.loading-spinner')
                }
            })
        """,
        "returnByValue" => true
    ))
    return !haskey(result, "error") ? result["result"]["value"] : nothing
end
```

### 2. Resource Management
```julia
function cleanup_resources(browser, page)
    # Clear localStorage
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "localStorage.clear()",
        "returnByValue" => true
    ))

    # Reset forms
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            document.querySelectorAll('form').forEach(f => f.reset());
            document.querySelectorAll('input').forEach(i => {
                i.value = '';
                i.dispatchEvent(new Event('input'));
            });
        """,
        "returnByValue" => true
    ))
end
```

## Unsupported Features

The following features are not available in the HTTP-only implementation:
1. Real-time events and subscriptions
2. Direct element handles
3. Automatic waiting and timeouts
4. Frame and context management
5. Network interception
6. Console monitoring
7. Dialog handling

## Best Practices

1. **Batch Operations**
   - Combine multiple operations in single JavaScript calls
   - Reduce round-trips to the browser

2. **State Management**
   - Implement explicit state checks
   - Use appropriate sleep intervals
   - Verify operation success

3. **Error Handling**
   - Always check for `error` key in responses
   - Implement timeouts for long-running operations
   - Use try/finally blocks for cleanup

4. **Performance**
   - Minimize CDP method calls
   - Use efficient selectors
   - Batch DOM operations

5. **State Verification**
   - Implement comprehensive state checks
   - Verify DOM, JavaScript, and form states
   - Use timeout-based verification
   - Handle state transitions explicitly

6. **Resource Management**
   - Clean up after operations
   - Clear form states
   - Reset application state
   - Manage browser resources

See [HTTP_LIMITATIONS.md](HTTP_LIMITATIONS.md) for detailed constraints and [HTTP_CAPABILITIES.md](HTTP_CAPABILITIES.md) for supported features.
