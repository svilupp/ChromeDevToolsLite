# Chrome DevTools Protocol (CDP)

This section describes the core functionality for interacting with Chrome DevTools Protocol.

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

## Examples

```julia
# Connect to Chrome's debugging port
client = connect_browser()

# Send CDP messages
response = send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))

# Evaluate JavaScript
result = send_cdp_message(client, "Runtime.evaluate",
                       Dict("expression" => "document.title",
                            "returnByValue" => true))

# Take screenshot
screenshot = send_cdp_message(client, "Page.captureScreenshot", Dict())

# Close connection when done
close(client)  # Use Base.close
```

## Error Handling

The following errors may be thrown:
- `WebSocketError`: Connection or message transmission issues
