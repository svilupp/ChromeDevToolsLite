# WebSocket Communication

This module handles low-level communication with the Chrome DevTools Protocol.

## CDP Communication

```julia
send_cdp(client::WSClient, method::String, params::Dict = Dict())
```
Sends a CDP command to the browser and returns the response.

```julia
handle_event(client::WSClient, event_handler::Function)
```
Registers a handler for CDP events.

## Error Types

The package defines several error types for specific scenarios:

- `ElementNotFoundError`: When a DOM element cannot be found
- `NavigationError`: When page navigation fails
- `EvaluationError`: When JavaScript evaluation fails
- `TimeoutError`: When an operation times out
- `ConnectionError`: When WebSocket connection fails

## Examples

```julia
# Send custom CDP command
response = send_cdp(client, "Page.navigate", Dict("url" => "https://example.com"))

# Handle network events
handle_event(client) do event
    if get(event, "method", "") == "Network.responseReceived"
        println("Response received: ", event["params"])
    end
end

# Error handling
try
    element = query_selector(client, "#non-existent")
catch e
    if e isa ElementNotFoundError
        println("Element not found: ", e.message)
    end
end
```

See the examples in `examples/5_advanced_automation.jl` for more advanced usage.
