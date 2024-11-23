# Browser

```@docs
connect_browser
send_cdp_message
ensure_chrome_running
get_ws_id
connect!
close
```

## Examples

```julia
# Basic browser connection
client = connect_browser()

try
    # Navigate to a website using high-level function
    goto(client, "https://example.com")

    # Get page content
    html_content = content(client)

    # Take screenshot
    screenshot(client)
finally
    close(client)
end
```

## Error Handling

The browser operations can throw:
- `WebSocketError`: When there are issues with the WebSocket connection or the browser endpoint is not available

## Configuration

The browser connection can be configured with:
- `endpoint`: The Chrome DevTools Protocol endpoint (default: "http://localhost:9222")
- `verbose`: Enable detailed logging (default: false)
