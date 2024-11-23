# Browser

```@docs
connect_browser
send_cdp_message
close_browser
verify_browser_available
ensure_chrome_running
get_ws_id
```

## Examples

```julia
# Basic browser connection with retry handling
client = connect_browser(; max_retries=3)

try
    # Verify browser is responding
    if !verify_browser_available("http://localhost:9222")
        error("Browser not available")
    end

    # Navigate to a website using CDP message
    send_cdp_message(client, "Page.navigate", Dict("url" => "https://example.com"))

    # Evaluate JavaScript
    result = send_cdp_message(client, "Runtime.evaluate",
                          Dict("expression" => "document.title",
                               "returnByValue" => true))

    # Take screenshot
    screenshot = send_cdp_message(client, "Page.captureScreenshot", Dict())
finally
    close_browser(client)
end
```

## Error Handling

The browser operations can throw the following errors:
- `WebSocketError`: When there are issues with the WebSocket connection
- `JSONError`: When there are issues parsing CDP messages
- `HTTP.ExceptionRequest.StatusError`: When the browser endpoint is not available
- `TimeoutError`: When connection attempts exceed max_retries

## Configuration

The browser connection can be configured with:
- `endpoint`: The Chrome DevTools Protocol endpoint (default: "http://localhost:9222")
- `max_retries`: Number of connection retry attempts (default: 3)
- `max_attempts`: Number of attempts to verify browser availability (default: 5)
- `delay`: Delay between retry attempts in seconds (default: 1.0)
