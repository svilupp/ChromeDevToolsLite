# Examples

This guide showcases practical examples from our test suite demonstrating various ChromeDevToolsLite features.

## Browser Connection
```julia
# Connect to Chrome DevTools
client = connect_browser()

try
    goto(client, "https://example.com")
    content_result = content(client)
    @assert contains(content_result, "<title>Example Domain</title>")
finally
    close(client)
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
    element = ElementHandle(client, selector)
    if value isa Bool
        value ? check(element) : uncheck(element)
    elseif selector == "#country"
        select_option(element, value)
    else
        type_text(element, value)
    end
end
```

## Working with Elements
```julia
# Find and interact with elements
element = ElementHandle(client, "#submit-button")
click(element)

# Find multiple elements
elements = ElementHandles(client, ".item")
for element in elements
    if is_visible(element)
        text = get_text(element)
        testid = get_attribute(element, "data-testid")
        println("Item $testid: $text")
    end
end
```

## Dynamic Content Handling
```julia
# Check element visibility and interact
element = ElementHandle(client, "#dynamic-content")
if !isnothing(element) && is_visible(element)
    click(element)
end
```

## Taking Screenshots
```julia
# Full page screenshot
screenshot(client)

# Element-specific screenshot
special_item = ElementHandle(client, ".item.special")
screenshot(special_item)
```

## Element Interaction and Form Handling
```julia
# Checkbox interaction
checkbox = ElementHandle(client, "#notifications")
check(checkbox)
@assert evaluate_handle(checkbox, "el => el.checked") "Checkbox should be checked"

# Form submission
type_text(client, "#name", "John Doe")
select_option(client, "#color", "blue")
click(client, "button[type='submit']")

# Multiple element handling
elements = ElementHandles(client, ".item")
for element in elements
    if is_visible(element)
        text = get_text(element)
        testid = get_attribute(element, "data-testid")
        println("Item $testid: $text")
    end
end
```
