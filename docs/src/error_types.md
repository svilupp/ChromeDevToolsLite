# Error Types

ChromeDevToolsLite defines several error types for different failure scenarios:

```@docs
ElementNotFoundError
NavigationError
EvaluationError
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
```
