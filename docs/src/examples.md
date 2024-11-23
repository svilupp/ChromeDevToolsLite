# Examples

This guide showcases practical examples from our test suite demonstrating various ChromeDevToolsLite features.

## Browser Connection
```julia
# Connect to Chrome DevTools with verbose logging for debugging
client = connect_browser(verbose=true)

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
# Fill out a complex form with verbose logging
form_data = Dict(
    "#name" => "John Doe",
    "#email" => "john@example.com",
    "#country" => "US",
    "#terms" => true
)

for (selector, value) in form_data
    element = ElementHandle(client, selector, verbose=true)
    if value isa Bool
        value ? check(element, verbose=true) : uncheck(element, verbose=true)
    elseif selector == "#country"
        select_option(element, value, verbose=true)
    else
        type_text(element, value, verbose=true)
    end
end
```

## Working with Elements
```julia
# Find and interact with elements
element = ElementHandle(client, "#submit-button", verbose=true)
click(element, verbose=true)

# Find and interact with multiple elements
items = [ElementHandle(client, item, verbose=true) for item in ["#item1", "#item2", "#item3"]]
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
# Check element visibility and interact with verbose logging
element = ElementHandle(client, "#dynamic-content", verbose=true)
if !isnothing(element) && is_visible(element)
    click(element, verbose=true)
end
```

## Taking Screenshots
```julia
# Full page screenshot
screenshot(client, verbose=true)

# Element-specific screenshot
special_item = ElementHandle(client, ".item.special", verbose=true)
screenshot(special_item, verbose=true)
```

## Element Interaction and Form Handling
```julia
# Enable verbose mode for detailed operation logging
checkbox = ElementHandle(client, "#notifications", verbose=true)
check(checkbox, verbose=true)
@assert evaluate_handle(checkbox, "el => el.checked", verbose=true) "Checkbox should be checked"

# Form submission
input = ElementHandle(client, "#name", verbose=true)
type_text(input, "John Doe", verbose=true)

select = ElementHandle(client, "#color", verbose=true)
select_option(select, "blue", verbose=true)

submit = ElementHandle(client, "button[type='submit']", verbose=true)
click(submit, verbose=true)

# Multiple element handling
items = [ElementHandle(client, item, verbose=true) for item in ["#item1", "#item2", "#item3"]]
for element in items
    if is_visible(element)
        text = get_text(element)
        testid = get_attribute(element, "data-testid")
        println("Item $testid: $text")
    end
end
```
