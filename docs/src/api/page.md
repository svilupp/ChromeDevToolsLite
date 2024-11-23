# Page Navigation and Interaction

This section describes the core CDP messages used for page navigation and interaction.

## Navigation

To navigate to a URL:
```julia
send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))
```

## JavaScript Evaluation

To evaluate JavaScript:
```julia
result = send_cdp_message(client, "Runtime.evaluate", Dict{String, Any}(
    "expression" => "document.title",
    "returnByValue" => true
))
```

## Element Interaction

To click an element:
```julia
# First find the element
element = send_cdp_message(client, "DOM.querySelector", Dict{String, Any}(
    "nodeId" => 1,  # document node
    "selector" => "#submit-button"
))

# Then click it
send_cdp_message(client, "DOM.click", Dict{String, Any}("nodeId" => element["result"]["nodeId"]))
```

## Screenshots

To take a screenshot:
```julia
screenshot = send_cdp_message(client, "Page.captureScreenshot", Dict{String, Any}())
# Screenshot data is in screenshot["result"]["data"] as base64
```

## Examples

```julia
# Basic page navigation and interaction
client = connect_browser()

try
    # Navigate to page
    send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))

    # Wait for page load
    sleep(2)  # Simple wait for demo purposes

    # Evaluate JavaScript
    title = send_cdp_message(client, "Runtime.evaluate", Dict{String, Any}(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    # Take screenshot
    screenshot = send_cdp_message(client, "Page.captureScreenshot", Dict{String, Any}())
finally
    close_browser(client)
end
```

## Error Handling

Operations can throw:
- `WebSocketError`: When there are issues with the WebSocket connection
- `JSONError`: When there are issues parsing CDP messages
