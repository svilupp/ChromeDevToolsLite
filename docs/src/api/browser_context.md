# BrowserContext

The `BrowserContext` type represents an isolated browser context, similar to an incognito window.

## Methods

### `new_page`
```julia
new_page(context::BrowserContext; options::Dict=Dict()) -> Page
```

Create a new page within this browser context.

### `pages`
```julia
pages(context::BrowserContext) -> Vector{Page}
```

Get all pages associated with this context.

### `close`
```julia
close(context::BrowserContext)
```

Close the context and all its associated pages.

## Examples

```julia
# From examples/17_browser_context_test.jl
browser = launch_browser()

# Create multiple contexts
context1 = new_context(browser)
context2 = new_context(browser)
all_contexts = contexts(browser)

# Create pages in different contexts
page1 = new_page(context1)
page2 = new_page(context1)
context1_pages = pages(context1)

# Demonstrate context isolation
goto(page1, "https://example.com")
goto(page2, "https://google.com")

# Cleanup contexts
close(context1)
```

## Error Handling

Context operations can throw:
- `ConnectionError`: When there are issues with the CDP connection
- `TimeoutError`: When operations exceed their timeout limit

Example error handling:
```julia
try
    context = new_context(browser)
    page = new_page(context)
    goto(page, "https://example.com", Dict("timeout" => 5000))
catch e
    if e isa TimeoutError
        println("Operation timed out")
    elseif e isa ConnectionError
        println("CDP connection failed")
    else
        rethrow(e)
    end
finally
    # Always clean up resources
    close(context)
end
```
