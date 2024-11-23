# Chrome DevTools Protocol (CDP)

This section describes the core functionality for interacting with Chrome DevTools Protocol.

## Core Functions

```@docs
connect_browser
send_cdp_message
close_browser
```

## WebSocket Connection

The library uses WebSockets from HTTP.jl to establish connections to Chrome's debugging port (default: 9222).

```julia
# Connect to Chrome's debugging port
client = connect_browser()

# Send CDP messages
response = send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))

# Close connection when done
close_browser(client)
```

## Message Format

CDP messages are sent as JSON with the following structure:
```julia
# Request format
Dict{String, Any}(
    "id" => message_id,
    "method" => method_name,
    "params" => parameters
)

# Response format
Dict{String, Any}(
    "id" => message_id,
    "result" => result_data
)
```

## Error Handling

The following errors may be thrown:
- `WebSocketError`: Connection or message transmission issues
- `JSONError`: Message parsing issues
