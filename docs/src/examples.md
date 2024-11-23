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

# Find and interact with multiple elements
items = [ElementHandle(client, item) for item in ["#item1", "#item2", "#item3"]]
for element in items
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
input = ElementHandle(client, "#name")
type_text(input, "John Doe")

select = ElementHandle(client, "#color")
select_option(select, "blue")

submit = ElementHandle(client, "button[type='submit']")
click(submit)

# Multiple element handling
items = [ElementHandle(client, item) for item in ["#item1", "#item2", "#item3"]]
for element in items
    if is_visible(element)
        text = get_text(element)
        testid = get_attribute(element, "data-testid")
        println("Item $testid: $text")
    end
end
