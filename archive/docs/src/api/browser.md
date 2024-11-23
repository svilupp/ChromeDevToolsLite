# Browser

```@docs
Browser
BrowserProcess
launch_browser
launch_browser_process
```

## Browser Context Methods

```@docs
new_context
create_browser_context
contexts
Base.close(::Browser)
Base.show(::IO, ::Browser)
Base.show(::IO, ::BrowserProcess)
kill_browser_process
```

## Examples

```julia
# Basic browser setup with error handling
browser = launch_browser(headless=true)
try
    context = new_context(browser)
    page = new_page(context)

    # Navigate to a website
    goto(page, "https://example.com")

    # Do some work...
finally
    close(browser)
end

# Create a new context
context = new_context(browser)

# Get all contexts
all_contexts = contexts(browser)

# Close browser when done
close(browser)
```

## Error Handling

The browser operations can throw the following errors:
- `ConnectionError`: When there are issues with the CDP connection
- `TimeoutError`: When operations exceed their timeout limit
```
