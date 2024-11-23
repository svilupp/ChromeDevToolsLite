# Utilities

## Core Functions

```@docs
ensure_chrome_running
get_ws_id
is_connected
handle_event
try_connect
connect!
```

## Base Operations

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

### Connection Management
```julia
# Robust connection handling with verbose logging
try
    client = connect_browser(verbose=true)
    if client === nothing
        @error "Failed to create browser connection"
        return nothing
    end

    # Ensure Chrome is running
    ensure_chrome_running()

    # Check connection status
    if !is_connected(client.ws)
        client = try_connect(client)
    end

    # Your browser operations here
catch e
    @warn "Browser connection failed" exception=e
finally
    client !== nothing && close(client)
end
```

### Memory Management Tips
- Always close the client connection when done
- Use shorter timeouts for faster failure detection
- Enable verbose logging during development for better debugging
