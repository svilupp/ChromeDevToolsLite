"""
    Mouse and keyboard input functionality for ChromeDevToolsLite
"""

import ..ChromeDevToolsLite: WSClient, send_command
import ..ChromeDevToolsLite.evaluate
import JSON3

# Mouse Actions
"""
    click(client::WSClient; button::String="left", x::Union{Int,Nothing}=nothing, y::Union{Int,Nothing}=nothing, modifiers::Vector{String}=String[])

Perform a mouse click action at the specified coordinates or current mouse position.

# Arguments
- `client::WSClient`: The WebSocket client to perform the action on
- `button::String="left"`: Mouse button to click ("left", "right", "middle")
- `x::Union{Int,Nothing}=nothing`: Optional x-coordinate for the click
- `y::Union{Int,Nothing}=nothing`: Optional y-coordinate for the click
- `modifiers::Vector{String}=String[]`: Keyboard modifiers (e.g., ["Shift", "Control"])
"""
function click(client::WSClient; button::String="left", x::Union{Int,Nothing}=nothing, y::Union{Int,Nothing}=nothing, modifiers::Vector{String}=String[])
    # Convert modifiers to integer flags as per CDP spec
    modifier_map = Dict(
        "Alt" => 1,
        "Control" => 2,
        "Meta" => 4,
        "Shift" => 8
    )

    modifier_flags = sum((get(modifier_map, mod, 0) for mod in modifiers), init=0)

    params = Dict{String,Any}(
        "button" => button,
        "clickCount" => 1
    )

    # Get current position if x and y are not provided
    if isnothing(x) || isnothing(y)
        pos = get_mouse_position(client)
        x = pos.x
        y = pos.y
    end

    params["x"] = x
    params["y"] = y
    params["modifiers"] = modifier_flags

    send_command(client, "Input.dispatchMouseEvent", merge(params, Dict("type" => "mousePressed")))
    send_command(client, "Input.dispatchMouseEvent", merge(params, Dict("type" => "mouseReleased")))
end

"""
    dblclick(client::WSClient; x::Union{Int,Nothing}=nothing, y::Union{Int,Nothing}=nothing)

Perform a double-click action at the specified coordinates or current mouse position.
"""
function dblclick(client::WSClient; x::Union{Int,Nothing}=nothing, y::Union{Int,Nothing}=nothing)
    click(client; x=x, y=y)
    click(client; x=x, y=y)
end

"""
    move_mouse(client::WSClient, x::Int, y::Int)

Move the mouse cursor to the specified coordinates.
"""
function move_mouse(client::WSClient, x::Int, y::Int)
    send_command(client, "Input.dispatchMouseEvent", Dict(
        "type" => "mouseMoved",
        "x" => x,
        "y" => y
    ))
end

"""
    get_mouse_position(client::WSClient)

Get the current mouse cursor position.
"""
function get_mouse_position(client::WSClient)
    # Initialize mouse tracking if not already done
    evaluate(client, """
        if (typeof window.mouseX === 'undefined') {
            window.mouseX = 0;
            window.mouseY = 0;
            document.addEventListener('mousemove', (e) => {
                window.mouseX = e.clientX;
                window.mouseY = e.clientY;
            });
        }
    """)

    result = evaluate(client, "JSON.stringify({x: window.mouseX || 0, y: window.mouseY || 0})")
    parsed = JSON3.read(result)
    return (x=parsed.x, y=parsed.y)
end

# Keyboard Actions
"""
    press_key(client::WSClient, key::String; modifiers::Vector{String}=String[])

Press and release a keyboard key.

# Arguments
- `client::WSClient`: The WebSocket client to perform the action on
- `key::String`: Key to press (e.g., "a", "Enter", "ArrowUp")
- `modifiers::Vector{String}=String[]`: Keyboard modifiers (e.g., ["Shift", "Control"])
"""
function press_key(client::WSClient, key::String; modifiers::Vector{String}=String[])
    # Convert modifiers to integer flags as per CDP spec
    modifier_map = Dict(
        "Alt" => 1,
        "Control" => 2,
        "Meta" => 4,
        "Shift" => 8
    )

    modifier_flags = sum((get(modifier_map, mod, 0) for mod in modifiers), init=0)

    params = Dict{String,Any}(
        "type" => "keyDown",
        "key" => key,
        "code" => key,
        "modifiers" => modifier_flags
    )

    send_command(client, "Input.dispatchKeyEvent", merge(params, Dict("type" => "keyDown")))
    send_command(client, "Input.dispatchKeyEvent", merge(params, Dict("type" => "keyUp")))
end

"""
    type_text(client::WSClient, text::String)

Type a sequence of characters.
"""
function type_text(client::WSClient, text::String)
    for char in text
        press_key(client, string(char))
    end
end

# Export functions
export click, dblclick, move_mouse, get_mouse_position, press_key, type_text
