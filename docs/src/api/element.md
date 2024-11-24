# Element Operations

This module provides functions for selecting and interacting with DOM elements.

## Element Selection

```julia
query_selector(client::WSClient, selector::String)
query_selector_all(client::WSClient, selector::String)
```
Select one or all elements matching the CSS selector.

## Element Information

```julia
get_element_info(element::ElementHandle)
get_text(element::ElementHandle)
get_attribute(element::ElementHandle, name::String)
is_visible(element::ElementHandle)
```

## Element Interaction

```julia
click(element::ElementHandle; options=Dict())
type_text(element::ElementHandle, text::String)
check(element::ElementHandle)
uncheck(element::ElementHandle)
select_option(element::ElementHandle, value::String)
```

## Element State

```julia
wait_for_visible(element::ElementHandle; retry_delay=0.3, timeout=10, visible=true)
evaluate_handle(element::ElementHandle, expression::String)
```

## Examples

```julia
# Select and interact with a form
form = query_selector(client, "#login-form")
username = query_selector(form, "input[name='username']")
type_text(username, "john_doe")

# Wait for and click a button
button = query_selector(client, "#submit")
wait_for_visible(button)
click(button)

# Get element text content
heading = query_selector(client, "h1")
text = get_text(heading)

# Work with multiple elements
items = query_selector_all(client, ".list-item")
for item in items
    if is_visible(item)
        println(get_text(item))
    end
end
```

See the complete examples in `examples/3_element_interactions.jl` and `examples/4_form_automation.jl`.
