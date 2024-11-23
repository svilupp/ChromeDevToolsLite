# Browser API Reference

```@docs
Browser
Page
execute_cdp_method
```

## Core Types

### Browser
Represents a connection to Chrome's debugging interface.
```julia
Browser(endpoint::String)
```

### Page
Represents a page/tab in Chrome.
```julia
struct Page
    id::String
    type::String
    url::String
    title::String
    ws_debugger_url::String
    dev_tools_frontend_url::String
end
```

## Examples

```julia
# Basic browser setup with error handling
browser = Browser("http://localhost:9222")
try
    # Create a new page
    response = HTTP.get("$(browser.endpoint)/json/new")
    page = Page(Dict(pairs(JSON3.read(String(response.body)))))

    # Navigate to a website using CDP
    execute_cdp_method(browser, page, "Page.navigate", Dict("url" => "https://example.com"))

    # Execute JavaScript using CDP
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    # Click an element using CDP
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.querySelector('.my-button').click()"
    ))

    # Type text into an input using CDP
    execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const input = document.querySelector('input[name="username"]');
            input.value = 'myusername';
            input.dispatchEvent(new Event('input'));
        """
    ))

    # Take a screenshot using CDP
    result = execute_cdp_method(browser, page, "Page.captureScreenshot")
    # result.result.data contains base64-encoded PNG

finally
    # Clean up when done
    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
end
```

## CDP Methods

The following CDP methods are supported via HTTP:

### Navigation
```julia
execute_cdp_method(browser, page, "Page.navigate", Dict("url" => "https://example.com"))
```

### JavaScript Evaluation
```julia
execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => "document.title",
    "returnByValue" => true
))
```

### DOM Querying
```julia
execute_cdp_method(browser, page, "DOM.querySelector", Dict("selector" => ".my-class"))
execute_cdp_method(browser, page, "DOM.querySelectorAll", Dict("selector" => ".my-class"))
```

## Error Handling

The browser operations can throw the following errors:
- `HTTP.RequestError`: When there are issues connecting to Chrome
- `ErrorException`: When Chrome is not running or the endpoint is incorrect
- CDP method errors: When a CDP method fails or is unsupported

For more details about supported features and limitations, see [HTTP Capabilities](../assets/HTTP_CAPABILITIES.md).
