"""
    Mouse and keyboard input functionality for ChromeDevToolsLite
"""

# Mouse Actions
"""
    click(client::WSClient; button::String = "left", x::Union{Int, Nothing} = nothing,
        y::Union{Int, Nothing} = nothing, modifiers::Vector{String} = String[], verbose::Bool = false)

Perform a mouse click action at the specified coordinates or current mouse position.

# Arguments
- `client::WSClient`: The WebSocket client to perform the action on
- `button::String="left"`: Mouse button to click ("left", "right", "middle")
- `x::Union{Int,Nothing}=nothing`: Optional x-coordinate for the click
- `y::Union{Int,Nothing}=nothing`: Optional y-coordinate for the click
- `modifiers::Vector{String}=String[]`: Keyboard modifiers (e.g., ["Shift", "Control"])
"""
function click(client::WSClient; button::String = "left", x::Union{Int, Nothing} = nothing,
        y::Union{Int, Nothing} = nothing, modifiers::Vector{String} = String[], verbose::Bool = false)
    # Convert modifiers to integer flags as per CDP spec
    modifier_map = Dict(
        "Alt" => 1,
        "Control" => 2,
        "Meta" => 4,
        "Shift" => 8
    )

    modifier_flags = sum((get(modifier_map, mod, 0) for mod in modifiers), init = 0)

    # If coordinates aren't provided, get current mouse position
    if isnothing(x) || isnothing(y)
        pos = get_mouse_position(client)
        x = pos.x
        y = pos.y
    else
        ## User provided x and y, let's make sure we're there
        move_mouse(client, x, y)
    end

    # Base parameters for mouse events
    params = Dict{String, Any}(
        "button" => button,
        "clickCount" => 1,
        "modifiers" => modifier_flags,
        "x" => x,
        "y" => y  # Now x and y are always defined
    )

    # Click sequence: mousePressed -> mouseReleased
    result = send_cdp(
        client, "Input.dispatchMouseEvent", merge(params, Dict("type" => "mousePressed")))
    result = send_cdp(
        client, "Input.dispatchMouseEvent", merge(params, Dict("type" => "mouseReleased")))
    if haskey(result, "error")
        verbose && @info "Click operation failed"
        return false
    end
    verbose && @info "Click operation completed"
    return true
end

"""
    dblclick(client::WSClient; x::Union{Int, Nothing} = nothing,
        y::Union{Int, Nothing} = nothing, verbose::Bool = false)

Perform a double-click action at the specified coordinates or current mouse position.
"""
function dblclick(client::WSClient; x::Union{Int, Nothing} = nothing,
        y::Union{Int, Nothing} = nothing, verbose::Bool = false)
    click(client; x = x, y = y, verbose = verbose)
    click(client; x = x, y = y, verbose = verbose)
end

"""
    move_mouse(client::WSClient, x::Int, y::Int)

Move the mouse cursor to the specified coordinates.
"""
function move_mouse(client::WSClient, x::Int, y::Int, verbose::Bool = false)
    # Update stored mouse position
    evaluate(client, """
        window.mousePosition = { x: $(x), y: $(y) };
    """)

    # Dispatch CDP mouse move event
    result = send_cdp(client, "Input.dispatchMouseEvent",
        Dict(
            "type" => "mouseMoved",
            "x" => x,
            "y" => y
        ))
    if haskey(result, "error")
        verbose && @info "Mouse move operation failed"
        return false
    end
    verbose && @info "Mouse moved to $(x), $(y)"
    return true
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
    return (x = parsed.x, y = parsed.y)
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
    return (x = parsed.x, y = parsed.y)
end

# Keyboard Actions
KEY_MAPPINGS = Dict(
    # Letters
    "a" => Dict("code" => "KeyA", "key" => "a", "keyCode" => 65),
    "b" => Dict("code" => "KeyB", "key" => "b", "keyCode" => 66),
    "c" => Dict("code" => "KeyC", "key" => "c", "keyCode" => 67),
    "d" => Dict("code" => "KeyD", "key" => "d", "keyCode" => 68),
    "e" => Dict("code" => "KeyE", "key" => "e", "keyCode" => 69),
    "f" => Dict("code" => "KeyF", "key" => "f", "keyCode" => 70),
    "g" => Dict("code" => "KeyG", "key" => "g", "keyCode" => 71),
    "h" => Dict("code" => "KeyH", "key" => "h", "keyCode" => 72),
    "i" => Dict("code" => "KeyI", "key" => "i", "keyCode" => 73),
    "j" => Dict("code" => "KeyJ", "key" => "j", "keyCode" => 74),
    "k" => Dict("code" => "KeyK", "key" => "k", "keyCode" => 75),
    "l" => Dict("code" => "KeyL", "key" => "l", "keyCode" => 76),
    "m" => Dict("code" => "KeyM", "key" => "m", "keyCode" => 77),
    "n" => Dict("code" => "KeyN", "key" => "n", "keyCode" => 78),
    "o" => Dict("code" => "KeyO", "key" => "o", "keyCode" => 79),
    "p" => Dict("code" => "KeyP", "key" => "p", "keyCode" => 80),
    "q" => Dict("code" => "KeyQ", "key" => "q", "keyCode" => 81),
    "r" => Dict("code" => "KeyR", "key" => "r", "keyCode" => 82),
    "s" => Dict("code" => "KeyS", "key" => "s", "keyCode" => 83),
    "t" => Dict("code" => "KeyT", "key" => "t", "keyCode" => 84),
    "u" => Dict("code" => "KeyU", "key" => "u", "keyCode" => 85),
    "v" => Dict("code" => "KeyV", "key" => "v", "keyCode" => 86),
    "w" => Dict("code" => "KeyW", "key" => "w", "keyCode" => 87),
    "x" => Dict("code" => "KeyX", "key" => "x", "keyCode" => 88),
    "y" => Dict("code" => "KeyY", "key" => "y", "keyCode" => 89),
    "z" => Dict("code" => "KeyZ", "key" => "z", "keyCode" => 90),

    # Numbers
    "0" => Dict("code" => "Digit0", "key" => "0", "keyCode" => 48),
    "1" => Dict("code" => "Digit1", "key" => "1", "keyCode" => 49),
    "2" => Dict("code" => "Digit2", "key" => "2", "keyCode" => 50),
    "3" => Dict("code" => "Digit3", "key" => "3", "keyCode" => 51),
    "4" => Dict("code" => "Digit4", "key" => "4", "keyCode" => 52),
    "5" => Dict("code" => "Digit5", "key" => "5", "keyCode" => 53),
    "6" => Dict("code" => "Digit6", "key" => "6", "keyCode" => 54),
    "7" => Dict("code" => "Digit7", "key" => "7", "keyCode" => 55),
    "8" => Dict("code" => "Digit8", "key" => "8", "keyCode" => 56),
    "9" => Dict("code" => "Digit9", "key" => "9", "keyCode" => 57),

    # Special characters
    " " => Dict("code" => "Space", "key" => " ", "keyCode" => 32),
    "." => Dict("code" => "Period", "key" => ".", "keyCode" => 190),
    "," => Dict("code" => "Comma", "key" => ",", "keyCode" => 188),
    "-" => Dict("code" => "Minus", "key" => "-", "keyCode" => 189),
    "=" => Dict("code" => "Equal", "key" => "=", "keyCode" => 187),
    ";" => Dict("code" => "Semicolon", "key" => ";", "keyCode" => 186),
    "'" => Dict("code" => "Quote", "key" => "'", "keyCode" => 222),
    "/" => Dict("code" => "Slash", "key" => "/", "keyCode" => 191),
    "\\" => Dict("code" => "Backslash", "key" => "\\", "keyCode" => 220),
    "[" => Dict("code" => "BracketLeft", "key" => "[", "keyCode" => 219),
    "]" => Dict("code" => "BracketRight", "key" => "]", "keyCode" => 221),
    "`" => Dict("code" => "Backquote", "key" => "`", "keyCode" => 192),

    # Control keys
    "Enter" => Dict("code" => "Enter", "key" => "Enter", "keyCode" => 13),
    "Tab" => Dict("code" => "Tab", "key" => "Tab", "keyCode" => 9),
    "Backspace" => Dict("code" => "Backspace", "key" => "Backspace", "keyCode" => 8),
    "Delete" => Dict("code" => "Delete", "key" => "Delete", "keyCode" => 46),
    "Escape" => Dict("code" => "Escape", "key" => "Escape", "keyCode" => 27),

    # Arrow keys
    "ArrowUp" => Dict("code" => "ArrowUp", "key" => "ArrowUp", "keyCode" => 38),
    "ArrowDown" => Dict("code" => "ArrowDown", "key" => "ArrowDown", "keyCode" => 40),
    "ArrowLeft" => Dict("code" => "ArrowLeft", "key" => "ArrowLeft", "keyCode" => 37),
    "ArrowRight" => Dict("code" => "ArrowRight", "key" => "ArrowRight", "keyCode" => 39),

    # Function keys
    "F1" => Dict("code" => "F1", "key" => "F1", "keyCode" => 112),
    "F2" => Dict("code" => "F2", "key" => "F2", "keyCode" => 113),
    "F3" => Dict("code" => "F3", "key" => "F3", "keyCode" => 114),
    "F4" => Dict("code" => "F4", "key" => "F4", "keyCode" => 115),
    "F5" => Dict("code" => "F5", "key" => "F5", "keyCode" => 116),
    "F6" => Dict("code" => "F6", "key" => "F6", "keyCode" => 117),
    "F7" => Dict("code" => "F7", "key" => "F7", "keyCode" => 118),
    "F8" => Dict("code" => "F8", "key" => "F8", "keyCode" => 119),
    "F9" => Dict("code" => "F9", "key" => "F9", "keyCode" => 120),
    "F10" => Dict("code" => "F10", "key" => "F10", "keyCode" => 121),
    "F11" => Dict("code" => "F11", "key" => "F11", "keyCode" => 122),
    "F12" => Dict("code" => "F12", "key" => "F12", "keyCode" => 123)
)

"Translates the `key` into codes and keycodes where possible"
function get_key_info(key)
    global KEY_MAPPINGS

    # Default to the first character's uppercase ASCII value if not found
    default = Dict(
        "key" => key,
        "code" => length(key) == 1 ? "Key$(uppercase(key))" : key,
        "keyCode" => length(key) == 1 ? Int(uppercase(key)[1]) : 0
    )

    return get(KEY_MAPPINGS, lowercase(key), default)
end
"""
    press_key(client::WSClient, key::String; modifiers::Vector{String} = String[],
        verbose::Bool = false)

Press and release a keyboard key.

# Arguments
- `client::WSClient`: The WebSocket client to perform the action on
- `key::String`: Key to press (e.g., "a", "Enter", "ArrowUp")
- `modifiers::Vector{String}=String[]`: Keyboard modifiers (e.g., ["Shift", "Control"])
- `verbose::Bool=false`: Whether to print verbose output
"""
function press_key(client::WSClient, key::String; modifiers::Vector{String} = String[],
        verbose::Bool = false)
    # Convert modifiers to integer flags as per CDP spec
    modifier_map = Dict(
        "Alt" => 1,
        "Control" => 2,
        "Meta" => 4,
        "Shift" => 8
    )

    modifier_flags = sum((get(modifier_map, mod, 0) for mod in modifiers), init = 0)

    params = Dict{String, Any}(
        "type" => "keyDown",
        "text" => key,
        "modifiers" => modifier_flags
    )
    key_info = get_key_info(key)
    merge!(params, key_info)

    result = send_cdp(
        client, "Input.dispatchKeyEvent", merge(params, Dict("type" => "keyDown")))
    result = send_cdp(
        client, "Input.dispatchKeyEvent", merge(params, Dict("type" => "keyUp")))
    if haskey(result, "error")
        verbose && @info "Key press operation failed"
        return false
    end
    verbose && @info "Key press operation completed"
    return true
end

"""
    type_text(client::WSClient, text::String; modifiers::Vector{String} = String[],
        verbose::Bool = false)

Type text by simulating keyboard input for each character.

# Arguments
- `client::WSClient`: The WebSocket client to perform the action on
- `text::String`: Text to type
- `modifiers::Vector{String}=String[]`: Keyboard modifiers (e.g., ["Shift", "Control"])
- `verbose::Bool=false`: Whether to print verbose output
"""
function type_text(client::WSClient, text::String; modifiers::Vector{String} = String[],
        verbose::Bool = false)
    for char in collect(text)
        output = press_key(client, string(char); modifiers = modifiers, verbose = verbose)
        output || return false
    end
    return true
end
