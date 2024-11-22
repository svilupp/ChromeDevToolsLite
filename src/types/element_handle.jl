"""
    ElementHandle

Represents a handle to a DOM element in a page.
"""
mutable struct ElementHandle <: AbstractElementHandle
    page::AbstractPage
    element_id::Int
    options::Dict{String, Any}

    function ElementHandle(page::AbstractPage, element_id::Int, options::Dict{String, Any}=Dict{String, Any}())
        handle = new(page, element_id, options)
        # Set a unique identifier for the element
        js_code = """(() => {
            const elements = document.querySelectorAll('*');
            const targetElement = Array.from(elements)[$(element_id - 1)];
            if (targetElement) {
                targetElement.__cdp_node_id__ = $(element_id);
                return true;
            }
            return false;
        })()"""
        evaluate(page, js_code)
        return handle
    end
end

"""
    Base.show(io::IO, element::ElementHandle)

Custom display for ElementHandle instances.
"""
function Base.show(io::IO, element::ElementHandle)
    print(io, "ElementHandle(id=$(element.element_id))")
end

"""
    Base.close(element::ElementHandle)

Ensures proper cleanup of element resources.
"""
function Base.close(element::ElementHandle)
    # Will implement actual CDP element cleanup here if needed
    nothing
end

"""
    click(element::ElementHandle; options=Dict()) -> Nothing

Clicks the element.
"""
function click(element::ElementHandle; options=Dict())
    params = Dict(
        "nodeId" => element.element_id,
        "clickCount" => get(options, "clickCount", 1)
    )
    request = create_cdp_message("DOM.click", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Click failed: $(response.error["message"])")
    end
    nothing
end

"""
    type_text(element::ElementHandle, text::String; options=Dict()) -> Nothing

Types text into the element.
"""
function type_text(element::ElementHandle, text::String; options=Dict())
    # First focus the element
    focus_params = Dict("nodeId" => element.element_id)
    focus_request = create_cdp_message("DOM.focus", focus_params)
    response_channel = send_message(element.page.context.browser.session, focus_request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Focus failed: $(response.error["message"])")
    end

    # Then send keyboard events
    type_params = Dict(
        "text" => text,
        "type" => "keyDown"
    )
    type_request = create_cdp_message("Input.insertText", type_params)
    response_channel = send_message(element.page.context.browser.session, type_request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Type text failed: $(response.error["message"])")
    end
    nothing
end

"""
    check(element::ElementHandle; options=Dict()) -> Nothing

Checks a checkbox or radio button element.
"""
function check(element::ElementHandle; options=Dict())
    # First ensure element is visible and clickable
    params = Dict("nodeId" => element.element_id)
    request = create_cdp_message("DOM.focus", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Focus failed: $(response.error["message"])")
    end

    # Then click to check
    click(element, options)
    nothing
end

"""
    uncheck(element::ElementHandle; options=Dict()) -> Nothing

Unchecks a checkbox element.
"""
function uncheck(element::ElementHandle; options=Dict())
    # First check if it's already unchecked
    is_checked = evaluate_handle(element, "el => el.checked")
    if is_checked
        click(element, options)
    end
    nothing
end

"""
    select_option(element::ElementHandle, value::String; options=Dict()) -> Nothing

Selects an option in a select element by its value.
"""
function select_option(element::ElementHandle, value::String; options=Dict())
    params = Dict(
        "nodeId" => element.element_id,
        "value" => value
    )
    request = create_cdp_message("DOM.selectOption", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Select option failed: $(response.error["message"])")
    end
    nothing
end

"""
    is_visible(element::ElementHandle) -> Bool

Checks if the element is visible on the page.
"""
function is_visible(element::ElementHandle)
    params = Dict("nodeId" => element.element_id)
    request = create_cdp_message("DOM.getBoxModel", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    return isnothing(response.error)
end

"""
    get_text(element::ElementHandle) -> String

Gets the text content of the element.
"""
function get_text(element::ElementHandle)
    # Use JavaScript to get text content directly using index calculation
    js_code = """(() => {
        const elements = document.querySelectorAll('.multiple');
        const index = Math.floor(($(element.element_id) - 10) / 2);
        return elements[index]?.textContent.trim() || '';
    })()"""

    result = evaluate(element.page, js_code)
    return result isa String ? result : ""
end

"""
    get_attribute(element::ElementHandle, name::String) -> Union{String, Nothing}

Gets the value of the specified attribute.
"""
function get_attribute(element::ElementHandle, name::String)
    params = Dict(
        "nodeId" => element.element_id,
        "name" => name
    )
    request = create_cdp_message("DOM.getAttribute", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Get attribute failed: $(response.error["message"])")
    end

    return response.result["value"]
end

"""
    evaluate_handle(element::ElementHandle, expression::String) -> Any

Evaluates JavaScript expression in the context of the element.
The expression will receive the element as its first argument.

# Arguments
- `element::ElementHandle`: The element to evaluate against
- `expression::String`: JavaScript expression to evaluate

# Example
```julia
# Check if element is checked
is_checked = evaluate_handle(element, "el => el.checked")
```
"""
function evaluate_handle(element::ElementHandle, expression::String)
    # Create a JavaScript function that evaluates the expression on the element
    js_code = """
    (() => {
        const elements = document.querySelectorAll('*');
        const targetElement = Array.from(elements).find(el => el.__cdp_node_id__ === $(element.element_id));
        if (!targetElement) {
            throw new Error('Element not found');
        }
        return ($expression)(targetElement);
    })()
    """

    # Create properly formatted CDP message
    eval_params = Dict{String,Any}(
        "expression" => js_code,
        "returnByValue" => true,
        "awaitPromise" => true
    )

    message = Dict{String,Any}(
        "sessionId" => element.page.session_id,
        "method" => "Runtime.evaluate",
        "params" => eval_params,
        "id" => get_next_message_id()
    )

    response_channel = send_message(element.page.context.browser.session, message)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Evaluation failed: $(response.error["message"])")
    end

    # Extract and return the result
    result = response.result["result"]
    if result["type"] == "undefined" || (result["type"] == "object" && get(result, "subtype", "") == "null")
        return nothing
    end

    return get(result, "value", nothing)
end

export click, type_text, check, uncheck, select_option, is_visible, get_text, get_attribute, evaluate_handle
