# Examples

This guide showcases practical examples from our test suite demonstrating various ChromeDevToolsLite features.

## Browser and Page Management
```julia
# From examples/00_browser_test.jl
browser = launch_browser()
context = new_context(browser)
page = new_page(context)

try
    goto(page, "https://example.com")
    title = get_title(page)
    @assert title == "Example Domain"
finally
    close(browser)
end
```

## Form Filling
```julia
# Fill out a complex form
form_data = Dict(
    "#name" => "John Doe",
    "#email" => "john@example.com",
    "#country" => "US",
    "#terms" => true
)

for (selector, value) in form_data
    element = query_selector(page, selector)
    if value isa Bool
        value ? check(element) : uncheck(element)
    elseif selector == "#country"
        select_option(element, value)
    else
        type_text(element, value)
    end
end
```

## Working with Multiple Pages
```julia
# Open multiple pages
page1 = new_page(context)
page2 = new_page(context)

# Navigate each page
goto(page1, "https://example.com/page1")
goto(page2, "https://example.com/page2")

# Get all pages
all_pages = pages(context)
```

## Error Handling Examples
```julia
try
    # Wait for dynamic content with timeout
    element = wait_for_selector(page, "#dynamic-content", timeout=5000)

    # Interact if element exists
    if !isnothing(element) && is_visible(element)
        click(element)
    end
catch e
    if e isa TimeoutError
        @warn "Element did not appear in time"
    elseif e isa ElementNotFoundError
        @warn "Element not found"
    else
        rethrow(e)
    end
end
```

## Taking Screenshots
```julia
# From examples/16_screenshot_comprehensive_test.jl
# Full page screenshot
screenshot(page, "full_page.png")

# Element-specific screenshot
special_item = query_selector(page, ".item.special")
screenshot(special_item, "element.png")

# Screenshot with custom clip region
container = query_selector(page, ".container")
box = get_bounding_box(container)
screenshot(page, "clipped.png", Dict("clip" => box))

## Element Interaction and Form Handling
```julia
# From examples/07_checkbox_test.jl
# Checkbox interaction
checkbox = query_selector(page, "#notifications")
check(checkbox)
@assert evaluate_handle(checkbox, "el => el.checked") "Checkbox should be checked"

# From examples/03_page_interactions.jl
# Form submission
type_text(page, "#name", "John Doe")
select_option(page, "#color", "blue")
click(page, "button[type='submit']")

# From examples/15_query_selector_all_test.jl
# Multiple element handling
elements = query_selector_all(page, ".item")
for element in elements
    if is_visible(element)
        text = get_text(element)
        testid = get_attribute(element, "data-testid")
        println("Item \$testid: \$text")
    end
end
