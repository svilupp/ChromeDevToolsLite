# Browser

```@docs
connect_browser
send_cdp_message
```

## Examples

```julia
# Basic browser connection
client = connect_browser()

try
    # Navigate to a website using CDP message
    send_cdp_message(client, "Page.navigate", Dict("url" => "https://example.com"))

    # Evaluate JavaScript
    result = send_cdp_message(client, "Runtime.evaluate",
                          Dict("expression" => "document.title",
                               "returnByValue" => true))

    # Take screenshot
    screenshot = send_cdp_message(client, "Page.captureScreenshot", Dict())
finally
    close(client)  # Use close() from Base for cleanup
end
```

## Error Handling

The browser operations can throw the following errors:
- `WebSocketError`: When there are issues with the WebSocket connection
- `JSONError`: When there are issues parsing CDP messages
- `HTTP.ExceptionRequest.StatusError`: When the browser endpoint is not available

## Configuration

The browser connection can be configured with:
- `endpoint`: The Chrome DevTools Protocol endpoint (default: "http://localhost:9222")
