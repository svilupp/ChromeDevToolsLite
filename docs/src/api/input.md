# Input Operations

This module provides comprehensive mouse and keyboard control functionality.

## Mouse Operations

```julia
click(client::WSClient; button::String = "left", x::Union{Int, Nothing} = nothing, y::Union{Int, Nothing} = nothing, modifiers::Vector{String} = String[])
```
Simulates a mouse click at the specified coordinates or current mouse position.

```julia
dblclick(client::WSClient; x::Union{Int, Nothing} = nothing, y::Union{Int, Nothing} = nothing)
```
Performs a double-click action at the specified coordinates or current mouse position.

```julia
move_mouse(client::WSClient, x::Int, y::Int)
```
Moves the mouse cursor to the specified coordinates.

```julia
get_mouse_position(client::WSClient)
```
Returns the current mouse cursor position.

```julia
get_element_position(ws_client::WSClient, element_handle::String)
```
Retrieves the position of a specific DOM element.

## Keyboard Operations

```julia
press_key(client::WSClient, key::String; modifiers::Vector{String} = String[])
```
Simulates pressing a keyboard key with optional modifier keys (e.g., "Control", "Alt", "Shift").

```julia
type_text(client::WSClient, text::String; modifiers::Vector{String} = String[])
```
Types the specified text with optional modifier keys.

## Examples

```julia
# Move mouse and click
move_mouse(client, 100, 100)
click(client)

# Type text with modifiers
type_text(client, "Hello World!")
press_key(client, "Enter", modifiers=["Control"])

# Double click at specific coordinates
dblclick(client, x=200, y=200)
```

See the complete example in `examples/6_mouse_keyboard_control.jl`.
