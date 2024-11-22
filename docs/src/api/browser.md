# Browser

```@docs
Browser
connect_browser
get_pages
new_page
close_page
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

    # Do some work...
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
