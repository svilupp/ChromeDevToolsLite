# Troubleshooting Guide

This guide covers common issues and solutions when using ChromeDevToolsLite's HTTP-only CDP implementation.

## Common Issues

### 1. Connection Issues

#### Cannot Connect to Browser
```
ERROR: Failed to list pages: Connection refused (ECONNREFUSED)
```

**Solutions:**
1. Verify Chrome/Chromium is running with debugging enabled:
   ```bash
   chromium --remote-debugging-port=9222
   ```
2. Check if the port is accessible:
   ```bash
   curl http://localhost:9222/json/version
   ```
3. Ensure no firewall is blocking port 9222

### 2. Method Execution Failures

#### WebSocket Required Error
```
ArgumentError: Method X failed. This might be because it requires WebSocket connection.
```

**Solution:**
- This method requires WebSocket connectivity, which isn't supported
- See [HTTP_CAPABILITIES.md](HTTP_CAPABILITIES.md) for supported methods
- Consider alternative approaches using supported methods

#### Timeout Errors
```
ErrorException: Timeout executing X. The operation took too long to complete.
```

**Solutions:**
1. Check browser responsiveness
2. Increase page load wait time:
   ```julia
   sleep(2) # Increase wait time after navigation
   ```
3. Verify operation with simpler JavaScript

### 3. JavaScript Execution Issues

#### Undefined Elements
```
ERROR: CDP method error: Cannot read property 'value' of null
```

**Solutions:**
1. Add element existence check:
   ```julia
   execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
       "expression" => """
           const el = document.querySelector('.my-element');
           if (!el) return { error: 'Element not found' };
           return { value: el.value };
       """,
       "returnByValue" => true
   ))
   ```

2. Wait for element:
   ```julia
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

### 4. Navigation Issues

#### Page Load Timing
```
ERROR: Element not found (after navigation)
```

**Solutions:**
1. Use state verification utility:
   ```julia
   # After navigation, verify page state
   state = verify_page_state(browser, page)
   if state === nothing
       throw(ErrorException("Page failed to load"))
   end
   println("Page loaded: ", state["url"])
   println("Page metrics: ", state["metrics"])
   ```

2. Batch update after navigation:
   ```julia
   # Wait for page load and update form
   state = verify_page_state(browser, page)
   if state !== nothing
       updates = Dict(
           "#username" => "user123",
           "#password" => "pass456"
       )
       result = batch_update_elements(browser, page, updates)
       all(values(result)) || throw(ErrorException("Form update failed"))
   end
   ```

### 5. Memory Management

#### Browser Resource Usage
If the browser becomes unresponsive:

1. Close unused pages:
   ```julia
   for page in get_pages(browser)
       close_page(browser, page)
   end
   ```

2. Restart browser with limited resources:
   ```bash
   chromium --remote-debugging-port=9222 --disable-gpu --disable-software-rasterizer
   ```

## Best Practices

1. **Always Use Error Handling**
   ```julia
   try
       page = new_page(browser)
       # ... operations ...
   catch e
       @error "Operation failed" exception=(e, catch_backtrace())
   finally
       page !== nothing && close_page(browser, page)
   end
   ```

2. **Validate JavaScript Results**
   ```julia
   result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
       "expression" => "document.title",
       "returnByValue" => true
   ))

   if haskey(result, "error")
       @warn "JavaScript error" error=result["error"]
   elseif !haskey(result, "result") || !haskey(result["result"], "value")
       @warn "Unexpected response format" result=result
   else
       println("Title: ", result["result"]["value"])
   end
   ```

3. **State Management Best Practices**
   ```julia
   function safe_page_operation(browser, page, operation)
       # Verify initial state
       state = verify_page_state(browser, page)
       if state === nothing
           throw(ErrorException("Page not ready"))
       end

       # Perform operation with batch updates when possible
       try
           return operation(browser, page)
       finally
           # Verify final state
           final_state = verify_page_state(browser, page)
           if final_state === nothing
               @warn "Operation may have left page in invalid state"
           end
       end
   end
   ```

4. **Resource Cleanup**
   ```julia
   # Always clean up resources
   function with_page(f, browser)
       page = nothing
       try
           page = new_page(browser)
           return f(browser, page)
       finally
           page !== nothing && close_page(browser, page)
       end
   end
   ```

## Getting Help

If you encounter issues not covered here:
1. Check [HTTP_LIMITATIONS.md](HTTP_LIMITATIONS.md) for known constraints
2. Review [HTTP_CAPABILITIES.md](HTTP_CAPABILITIES.md) for supported features
3. Open an issue on GitHub with:
   - Julia version (`versioninfo()`)
   - Chrome/Chromium version
   - Minimal reproducible example
   - Error message and stack trace
