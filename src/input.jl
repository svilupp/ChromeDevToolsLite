"""
    Mouse and keyboard input functionality for ChromeDevToolsLite
"""

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

    # Base parameters for mouse events
    params = Dict{String,Any}(
        "button" => button,
        "clickCount" => 1,
        "modifiers" => modifier_flags
    )

    # Add coordinates only if explicitly provided
    if !isnothing(x) && !isnothing(y)
        params["x"] = x
        params["y"] = y
        # Move to specified position first
        send_cdp(client, "Input.dispatchMouseEvent", merge(params, Dict("type" => "mouseMoved")))
    end

    # Click sequence: mousePressed -> mouseReleased
    send_cdp(client, "Input.dispatchMouseEvent", merge(params, Dict("type" => "mousePressed")))
    send_cdp(client, "Input.dispatchMouseEvent", merge(params, Dict("type" => "mouseReleased")))
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
    # Update stored mouse position
    evaluate(client, """
        window.mousePosition = { x: $(x), y: $(y) };
    """)

    # Dispatch CDP mouse move event
    send_cdp(client, "Input.dispatchMouseEvent", Dict(
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
    # Initialize mouse position if not already done
    evaluate(client, """
        if (typeof window.mousePosition === 'undefined') {
            window.mousePosition = { x: 0, y: 0 };
        }
    """)

    result = evaluate(client, "JSON.stringify(window.mousePosition)")
    parsed = JSON3.read(result)
    return (x=parsed.x, y=parsed.y)
end

"""
    get_element_position(ws_client::WSClient, element_handle::String)

Get the position of an element on the page.

# Arguments
- `ws_client::WSClient`: The WebSocket client connection
- `element_handle::String`: CSS selector for the target element

# Returns
NamedTuple with x and y coordinates of the element's center
"""
function get_element_position(ws_client::WSClient, element_handle::String)
    script = """
    (function() {
        const element = document.querySelector('$(element_handle)');
        if (!element) return null;
        const rect = element.getBoundingClientRect();
        return JSON.stringify({
            x: Math.round(rect.left + rect.width / 2),
            y: Math.round(rect.top + rect.height / 2)
        });
    })()
    """
    result = evaluate(ws_client, script)
    isnothing(result) && error("Element not found: $(element_handle)")
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

    send_cdp(client, "Input.dispatchKeyEvent", merge(params, Dict("type" => "keyDown")))
    send_cdp(client, "Input.dispatchKeyEvent", merge(params, Dict("type" => "keyUp")))
end

"""
    type_text(client::WSClient, text::String, element_handle::Union{String,Nothing}=nothing)

Type text either globally or into a specific element.

# Arguments
- `client::WSClient`: The WebSocket client to perform the action on
- `text::String`: Text to type
- `element_handle::Union{String,Nothing}=nothing`: Optional CSS selector for target element
"""
function type_text(client::WSClient, text::String, element_handle::Union{String,Nothing}=nothing)
    if !isnothing(element_handle)
        script = """
        (function() {
            const element = document.querySelector('$(element_handle)');
            if (!element) return false;
            element.value = '$(text)';
            element.dispatchEvent(new Event('input', { bubbles: true }));
            element.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
        })()
        """
        success = evaluate(client, script)
        !success && error("Element not found: $(element_handle)")
    else
        press_key(client, text)
    end
end
