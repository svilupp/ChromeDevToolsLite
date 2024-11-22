# Page

```@docs
Page
```

The `Page` type represents a single page in a browser context.

## Navigation Methods

```@docs
goto
content
url
get_title
wait_for_load
```

## Element Selection and Waiting

```@docs
query_selector
query_selector_all
wait_for_selector
count_elements(::Page, ::String)
count_elements(::AbstractPage, ::String)
```

## Interaction Methods

```@docs
click(::Page, ::String)
type_text(::Page, ::String, ::String)
press_key
submit_form
select_option(::Page, ::String, ::String)
set_file_input_files
```

## State and Property Methods

```@docs
is_visible(::Page, ::String)
is_visible(::AbstractPage, ::String)
get_text(::Page, ::String)
get_text(::AbstractPage, ::String)
get_value
is_checked
evaluate(::Page, ::String)
screenshot(::Page)
screenshot(::Page, ::String)
Base.show(::IO, ::Page)
Base.close(::Page)
```

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
```

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
        println("Found item: \$text")
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
