# DOM Manipulation

This section describes how to interact with DOM elements using CDP messages.

## Finding Elements

To find an element by selector:
```julia
element = send_cdp_message(client, "DOM.querySelector", Dict{String, Any}(
    "nodeId" => 1,  # document node
    "selector" => "#my-element"
))
```

## Element Interaction

### Clicking Elements
```julia
# Click an element
send_cdp_message(client, "DOM.click", Dict{String, Any}("nodeId" => element_id))
```

### Input Interaction
```julia
# Type text into an input
send_cdp_message(client, "DOM.focus", Dict{String, Any}("nodeId" => input_id))
send_cdp_message(client, "Input.insertText", Dict{String, Any}("text" => "Hello World"))
```

### Getting Element Properties
```julia
# Get element text content
text_content = send_cdp_message(client, "DOM.getOuterHTML", Dict{String, Any}("nodeId" => element_id))

# Get element attributes
attrs = send_cdp_message(client, "DOM.getAttributes", Dict{String, Any}("nodeId" => element_id))
```

## Examples

```julia
client = connect_browser()

try
    # Navigate to page
    send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => "https://example.com"))
    sleep(2)  # Wait for load

    # Find an element
    element = send_cdp_message(client, "DOM.querySelector", Dict{String, Any}(
        "nodeId" => 1,
        "selector" => "h1"
    ))

    # Get its text content
    content = send_cdp_message(client, "DOM.getOuterHTML", Dict{String, Any}(
        "nodeId" => element["result"]["nodeId"]
    ))

    println("Found heading: ", content["result"]["outerHTML"])
finally
    close_browser(client)
end
```

## Error Handling

DOM operations can throw:
- `WebSocketError`: When there are issues with the WebSocket connection
- `JSONError`: When there are issues parsing CDP messages
