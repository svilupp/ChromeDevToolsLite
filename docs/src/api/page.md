# Page

The `Page` type represents a single page in a browser context.

## Navigation Methods

### `goto`
```julia
goto(page::Page, url::String; options::Dict=Dict())
```

Navigate to the specified URL.

### `content`
```julia
content(page::Page) -> String
```

Get the page's HTML content.

## Element Selection

### `query_selector`
```julia
query_selector(page::Page, selector::String) -> Union{ElementHandle, Nothing}
```

Find first element matching the CSS selector.

### `query_selector_all`
```julia
query_selector_all(page::Page, selector::String) -> Vector{ElementHandle}
```

Find all elements matching the CSS selector.

### `wait_for_selector`
```julia
wait_for_selector(page::Page, selector::String; timeout::Int=30000) -> ElementHandle
```

Wait for an element matching the selector to appear.

## Interaction Methods

### `click`
```julia
click(page::Page, selector::String; options::Dict=Dict())
```

Click the element matching the selector.

### `type_text`
```julia
type_text(page::Page, selector::String, text::String; options=Dict())
```

Type text into the element matching the selector.

## Screenshots

### `screenshot`
```julia
screenshot(page::Page; options::Dict=Dict()) -> String
```

Take a screenshot of the page. Supports full page, element-specific, and clipped region screenshots.

## Examples
```julia
# Full page screenshot
screenshot(page, "full_page.png")

# Element-specific screenshot
box = query_selector(page, "#box1")
screenshot(box, "element.png")

# Screenshot with clip region
container = query_selector(page, ".container")
box = get_bounding_box(container)
screenshot(page, "clipped.png", Dict("clip" => box))
```

```julia
# Basic page navigation and interaction
browser = launch_browser()
context = new_context(browser)
page = new_page(context)

try
    # Navigation with wait
    goto(page, "https://example.com")
    wait_for_selector(page, "h1")

    # Multiple element selection
    items = query_selector_all(page, ".item")
    for item in items
        text = get_text(item)
        println("Found item: $text")
    end

    # Form interaction
    type_text(page, "#search", "query")
    click(page, "#submit")

    # Take screenshot
    screenshot(page, "page.png")

    # Element-specific screenshot
    header = query_selector(page, "header")
    screenshot(header, "header.png")
finally
    close(page)
end
```

### Common Patterns

#### Form Submission
```julia
# From examples/03_page_interactions.jl
goto(page, "file://form.html")
type_text(page, "#name", "John Doe")
select_option(page, "#color", "blue")
click(page, "button[type='submit']")
```

#### Waiting for Elements
```julia
# Wait for specific element with timeout
element = wait_for_selector(page, "#dynamic-content", timeout=5000)

# Check element visibility
if is_visible(element)
    println("Element is visible")
end
```

## Error Handling

Page operations can throw:
- `NavigationError`: When page navigation fails
- `ElementNotFoundError`: When an element cannot be found
- `TimeoutError`: When operations exceed their timeout limit
- `EvaluationError`: When JavaScript evaluation fails
