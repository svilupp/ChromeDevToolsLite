# Browser Operations

This module handles browser connection, context management, and basic browser operations.

## Connection Management

```julia
connect_browser(; options...)
```
Establishes connection to Chrome/Chromium browser. Options include:
- `verbose`: Enable detailed logging
- `port`: Chrome debugging port (default: 9222)
- `host`: Chrome debugging host (default: "localhost")

```julia
connect!(client::WSClient)
close(client::WSClient)
is_connected(client::WSClient)
try_connect(host::String, port::Int)
```

## Browser Context

```julia
new_context(client::WSClient; viewport::Dict = Dict(), user_agent::String = "")
```
Creates a new browser context with optional viewport settings and user agent.

```julia
ensure_browser_available(; options...)
```
Ensures Chrome/Chromium is running and available for connection.

## Examples

```julia
# Basic connection
client = connect_browser(verbose=true)

# Custom context with viewport
client = connect_browser()
context = new_context(client,
    viewport=Dict("width" => 1920, "height" => 1080),
    user_agent="Custom User Agent"
)

# Connection with error handling
try
    client = connect_browser()
    # Your automation code here
finally
    close(client)
end
```

See the complete example in `examples/1_basic_connection.jl`.
