# Error Types

ChromeDevToolsLite defines several error types for different failure scenarios:

```@docs
ElementNotFoundError
NavigationError
EvaluationError
TimeoutError
ConnectionError
```

## Error Handling Examples

```julia
# Handle element not found
try
    element = ElementHandle(client, "#non-existent")
catch e
    if e isa ElementNotFoundError
        @warn "Element not found" selector="#non-existent"
    end
end

# Handle navigation errors
try
    goto(client, "invalid-url")
catch e
    if e isa NavigationError
        @error "Navigation failed" url="invalid-url" reason=e.msg
    end
end

# Handle evaluation errors
try
    result = evaluate(client, "invalid javascript")
catch e
    if e isa EvaluationError
        @error "JavaScript evaluation failed" reason=e.msg
    end
end

# Handle timeouts
try
    element = ElementHandle(client, "#slow-loading", timeout=1.0)
catch e
    if e isa TimeoutError
        @warn "Operation timed out" operation="element selection"
    end
end

# Handle connection errors
try
    client = connect_browser()
catch e
    if e isa ConnectionError
        @error "Failed to connect to browser" reason=e.msg
    end
end
```
