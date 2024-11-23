# Chrome DevTools Protocol (CDP)

```@docs
extract_cdp_result
extract_element_result
```

## Usage

While ChromeDevToolsLite provides high-level functions for common operations, you can use `send_cdp_message` for direct CDP communication when needed:

```julia
# Connect to Chrome's debugging port
client = connect_browser()

try
    # Use high-level functions when possible
    goto(client, "https://example.com")

    # For advanced CDP operations, use send_cdp_message
    result = send_cdp_message(client, "DOM.getDocument", Dict())
    root_node = extract_cdp_result(result)
finally
    close(client)
end
```

## Error Handling

CDP operations may throw various errors. See [Error Types](@ref) in the Types section for details.

Note: All CDP operations support verbose logging:
```julia
send_cdp_message(client, "DOM.getDocument", Dict(), verbose=true)
```
