# Utilities

## Error Handling

The package provides comprehensive error handling for all operations:

### Error Types and Common Scenarios
```julia
# From examples/21_error_handling_comprehensive_test.jl

# Element not found
try
    element = query_selector(page, "#nonexistent")
    click(element)
catch e
    if e isa ElementNotFoundError
        println("Element does not exist in DOM")
    end
end

# Navigation failure
try
    goto(page, "https://nonexistent.example.com")
catch e
    if e isa NavigationError
        println("Failed to navigate to page")
    end
end

# JavaScript evaluation error
try
    evaluate(page, "nonexistentFunction()")
catch e
    if e isa EvaluationError
        println("JavaScript evaluation failed")
    end
end

# Operation timeout
try
    wait_for_selector(page, "#willNeverAppear", timeout=1000)
catch e
    if e isa TimeoutError
        println("Operation timed out")
    end
end
```

```julia
# Basic error handling
try
    element = wait_for_selector(page, "#non-existent", timeout=5000)
catch e
    if e isa TimeoutError
        println("Element not found within timeout period")
    elseif e isa ElementNotFoundError
        println("Element does not exist on the page")
    else
        rethrow(e)
    end
end

## Timeout Utilities

All operations support configurable timeouts to control operation duration:

```julia
# From examples/20_timeout_comprehensive_test.jl

# Wait for selector with explicit timeout
try
    element = wait_for_selector(page, "#delayed", timeout=3000)
catch e
    @assert e isa TimeoutError "Should throw TimeoutError"
end

# Operation timeouts via options dictionary
click(page, "#clickMe", Dict("timeout" => 1000))
type_text(page, "#typeHere", "Test Text", Dict("timeout" => 1000))

# JavaScript evaluation timeout
try
    evaluate(page, "new Promise(resolve => setTimeout(resolve, 2000))",
            Dict("timeout" => 1000))
catch e
    @assert e isa TimeoutError "Should throw TimeoutError"
end
```

### Default Timeouts
- Page navigation: 30 seconds
- Element waiting: 30 seconds
- Script evaluation: 30 seconds

You can override these defaults in individual function calls using the `options` parameter:
```julia
options = Dict("timeout" => 5000)  # 5 seconds
wait_for_selector(page, "#content", options)
click(page, "#button", options)
type_text(page, "#input", "text", options)
```

## Timeout Utilities

All operations that might take time support timeout options:

```julia
# Wait for element with custom timeout
element = wait_for_selector(page, ".dynamic-content", timeout=10000)  # 10 seconds

# Navigation with timeout
goto(page, "https://example.com", Dict("timeout" => 30000))  # 30 seconds
```

### Default Timeouts
- Page navigation: 30 seconds
- Element waiting: 30 seconds
- Script evaluation: 30 seconds

You can override these defaults in individual function calls using the `options` parameter:
```julia
options = Dict("timeout" => 5000)  # 5 seconds
wait_for_selector(page, "#content", options)
```

## Resource Management

### Best Practices
```julia
# Always use try-finally for proper cleanup
browser = Browser()
context = new_context(browser)
page = new_page(context)

try
    # Your page operations here
    goto(page, "https://example.com")
    element = wait_for_selector(page, ".content")
finally
    # Clean up in reverse order of creation
    close(page)
    close_context(context)
    close(browser)
end
```

### Memory Management Tips
- Close pages when no longer needed
- Clean up contexts after use
- Always close the browser in a `finally` block
- Use shorter timeouts for faster failure detection

### Connection Management
```julia
# Robust connection handling
try
    browser = Browser()
    if browser === nothing
        error("Failed to create browser instance")
    end

    # Your browser operations here
catch e
    if e isa ConnectionError
        println("Browser connection failed, retrying...")
        # Implement retry logic here
    end
finally
    browser !== nothing && close(browser)
end
```
