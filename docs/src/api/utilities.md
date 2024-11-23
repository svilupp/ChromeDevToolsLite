# Utilities

## Base Operations

The package implements several Base operations for its core types:

```@docs
Base.close(::WSClient)
Base.show(::IO, ::WSClient)
```

## Resource Management

### Best Practices
```julia
# Always use try-finally for proper cleanup
client = connect_browser()

try
    # Your page operations here
    goto(client, "https://example.com")
    element = ElementHandle(client, ".content")
finally
    # Clean up
    close(client)
end
```

### Memory Management Tips
- Always close the client connection when done
- Use shorter timeouts for faster failure detection

### Connection Management
```julia
# Robust connection handling
try
    client = connect_browser()
    if client === nothing
        @error "Failed to create browser connection"
        return nothing
    end

    # Your browser operations here
catch e
    @warn "Browser connection failed" exception=e
    # Implement retry logic here
finally
    client !== nothing && close(client)
end
```
