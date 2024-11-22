# Browser

```@docs
Browser
connect_browser
get_pages
new_page
close_page
execute_cdp_method
Base.show(::IO, ::Browser)
```

## Examples

```julia
# Basic browser setup with error handling
browser = connect_browser()
try
    # List all pages
    pages = get_pages(browser)

    # Create a new page
    page = new_page(browser)

    # Navigate to a website using CDP
    execute_cdp_method(browser, page, "Page.navigate", Dict("url" => "https://example.com"))

    # Execute JavaScript using CDP
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))
finally
    # Clean up when done
    close_page(browser, page)
end
```

## Error Handling

The browser operations can throw the following errors:
- `HTTP.RequestError`: When there are issues connecting to Chrome
- `ErrorException`: When Chrome is not running or the endpoint is incorrect
```
