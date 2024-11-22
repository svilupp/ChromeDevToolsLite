# Browser

The `Browser` type represents a browser instance that can be controlled via the Chrome DevTools Protocol.

## Constructor

```julia
launch_browser(; headless::Bool=true, options::Dict=Dict()) -> Browser
```

Launch a new browser instance with the specified options.

## Methods

### `new_context`
```julia
new_context(browser::Browser; options::Dict=Dict()) -> BrowserContext
```

Create a new browser context (similar to an incognito window).

### `contexts`
```julia
contexts(browser::Browser) -> Vector{BrowserContext}
```

Get all browser contexts associated with this browser instance.

### `close`
```julia
close(browser::Browser)
```

Close the browser and all associated contexts and pages.

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
