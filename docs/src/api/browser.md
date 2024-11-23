# Browser

```@docs
connect_browser
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

Browser operations can throw various exceptions. See [Error Types](@ref) in the Types section for details.

## Usage Notes
- Ensure Chrome is running in debug mode before connecting
- Always close the connection when done
- Use verbose mode for debugging connection issues

## Configuration

The browser connection can be configured with:
- `endpoint`: The Chrome DevTools Protocol endpoint (default: "http://localhost:9222")
- `verbose`: Enable detailed logging (default: false)
