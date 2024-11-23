# Element Operations

```@docs
ElementHandle
click
type_text
check
uncheck
select_option
is_visible
get_text
get_attribute
evaluate_handle
```

## Examples

```julia
# Basic element interactions
element = ElementHandle(client, "#my-button")

# Click operations
success = click(element)

# Form interactions
input = ElementHandle(client, "#username")
type_text(input, "user123")

# Checkbox handling
checkbox = ElementHandle(client, "#terms")
check(checkbox)
uncheck(checkbox)

# Select dropdown
select = ElementHandle(client, "#country")
select_option(select, "US")

# Element state
if is_visible(element)
    text = get_text(element)
    class_attr = get_attribute(element, "class")
end

# JavaScript evaluation
result = evaluate_handle(element, "el => el.getBoundingClientRect()")
```

## Error Handling

All element operations include proper error handling:
- Return `false` or `nothing` on failure
- Log detailed error information at debug level
- Verify element existence and connection before operations

## Element Selection

Elements are selected using standard CSS selectors:
```julia
# ID selector
element = ElementHandle(client, "#myId")

# Class selector
element = ElementHandle(client, ".myClass")

# Complex selectors
element = ElementHandle(client, "div.container > button[type='submit']")
```

## Logging

Functions include debug and info logging. Control verbosity with Julia's logging system:
```julia
using Logging
global_logger(ConsoleLogger(stderr, Logging.Debug))
```

## Best Practices

1. Always check operation success:
```julia
if !click(element)
    @warn "Click operation failed"
end
```

2. Use proper error handling:
```julia
try
    success = type_text(element, "Hello")
    if !success
        @warn "Failed to type text"
    end
catch e
    @error "Error during text input" exception=e
end
```

3. Verify element visibility before interaction:
```julia
if is_visible(element)
    click(element)
end
```
