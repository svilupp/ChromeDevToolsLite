# ElementHandle

```@docs
ElementHandle
```

The `ElementHandle` type represents a reference to a DOM element within a page.

## Interaction Methods

```@docs
click(::ElementHandle)
type_text(::ElementHandle, ::String)
check
uncheck
select_option(::ElementHandle, ::String)
```

## State and Property Methods

```@docs
is_visible(::ElementHandle)
get_text(::ElementHandle)
get_attribute(::ElementHandle, ::String)
evaluate_handle(::ElementHandle, ::String)
Base.show(::IO, ::ElementHandle)
Base.close(::ElementHandle)
```

### `check`
```julia
check(element::ElementHandle; options::Dict=Dict())
```

Check a checkbox or radio button.

Example from `examples/19_checkbox_comprehensive_test.jl`:
```julia
checkbox = query_selector(page, "#simple")
check(checkbox)
@assert evaluate_handle(checkbox, "el => el.checked") "Checkbox should be checked"
```

### `uncheck`
```julia
uncheck(element::ElementHandle; options::Dict=Dict())
```

Uncheck a checkbox.

Example from `examples/19_checkbox_comprehensive_test.jl`:
```julia
checked_box = query_selector(page, "#checked")
@assert evaluate_handle(checked_box, "el => el.checked") "Should start checked"
uncheck(checked_box)
@assert !evaluate_handle(checked_box, "el => el.checked") "Should be unchecked"
```

### `select_option`
```julia
select_option(element::ElementHandle, value::String; options::Dict=Dict())
```

Select an option in a dropdown.

## State and Property Methods

### `is_visible`
```julia
is_visible(element::ElementHandle) -> Bool
```

Check if the element is visible.

### `get_text`
```julia
get_text(element::ElementHandle) -> String
```

Get the element's text content.

### `get_attribute`
```julia
get_attribute(element::ElementHandle, name::String) -> Union{String, Nothing}
```

Get the value of the specified attribute.

### `evaluate_handle`
```julia
evaluate_handle(element::ElementHandle, expression::String) -> Any
```

Evaluates a JavaScript expression in the context of the element. The expression receives the element as its first argument.

Example:
```julia
# Get computed style
style = evaluate_handle(element, "el => window.getComputedStyle(el).backgroundColor")

# Check if element is checked
is_checked = evaluate_handle(element, "el => el.checked")
```

## Examples

### Basic Element Interactions
```julia
# From examples/04_element_handling.jl
elements = query_selector_all(page, ".item")
for element in elements
    # Get text content
    text = get_text(element)
    println("Element text: \$text")

    # Check visibility
    if is_visible(element)
        println("Element is visible")
    end

    # Get attributes
    class_attr = get_attribute(element, "class")
    println("Class attribute: \$class_attr")
end
```

### Form Handling
```julia
# From examples/07_checkbox_test.jl
# Handle checkboxes
checkbox = query_selector(page, "#notifications")
check(checkbox)
is_checked = evaluate_handle(checkbox, "el => el.checked")
@assert is_checked "Checkbox should be checked"

# Handle dropdowns
select = query_selector(page, "#color")
select_option(select, "blue")
value = get_attribute(select, "value")
@assert value == "blue" "Select value should be blue"
```

### Element Screenshots
```julia
# From examples/16_screenshot_comprehensive_test.jl
special_item = query_selector(page, ".item.special")
screenshot(special_item, "element.png")
```

## Error Handling

Element operations can throw:
- `ElementNotFoundError`: When the element becomes detached
- `TimeoutError`: When operations exceed their timeout limit
