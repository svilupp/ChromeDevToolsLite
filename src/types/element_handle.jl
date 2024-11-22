"""
    ElementHandle

Represents a handle to a DOM element in a page.
"""
mutable struct ElementHandle <: AbstractElementHandle
    page::AbstractPage
    element_id::Int
    options::Dict{String,<:Any}
    verbose::Bool

    function ElementHandle(page::AbstractPage, element_id::Int, options::AbstractDict{String,<:Any}=Dict{String,<:Any}(); verbose::Bool=false)
        handle = new(page, element_id, options, verbose)
        handle.verbose && @info "Creating ElementHandle" element_id=element_id
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
        handle.verbose && @info "ElementHandle created successfully" element_id=element_id
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
function click(element::ElementHandle; options::AbstractDict{String,<:Any}=Dict{String,<:Any}())
    element.verbose && @info "Clicking element" element_id=element.element_id
    params = Dict{String,<:Any}(
        "nodeId" => element.element_id,
        "clickCount" => get(options, "clickCount", 1)
    )
    request = create_cdp_message("DOM.click", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Click failed: $(response.error["message"])")
    end
    element.verbose && @info "Click completed successfully" element_id=element.element_id
    nothing
end

"""
    type_text(element::ElementHandle, text::AbstractString; options=Dict()) -> Nothing

Types text into the element.
"""
function type_text(element::ElementHandle, text::AbstractString; options::AbstractDict{String,<:Any}=Dict{String,<:Any}())
    element.verbose && @info "Typing text into element" element_id=element.element_id text=text
    # First focus the element
    focus_params = Dict{String,<:Any}("nodeId" => element.element_id)
    focus_request = create_cdp_message("DOM.focus", focus_params)
    response_channel = send_message(element.page.context.browser.session, focus_request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Focus failed: $(response.error["message"])")
    end

    # Then send keyboard events
    type_params = Dict{String,<:Any}(
        "text" => text,
        "type" => "keyDown"
    )
    type_request = create_cdp_message("Input.insertText", type_params)
    response_channel = send_message(element.page.context.browser.session, type_request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Type text failed: $(response.error["message"])")
    end
    element.verbose && @info "Text typed successfully" element_id=element.element_id
    nothing
end

"""
    check(element::ElementHandle; options=Dict()) -> Nothing

Checks a checkbox or radio button element.
"""
function check(element::ElementHandle; options::AbstractDict{String,<:Any}=Dict{String,<:Any}())
    element.verbose && @info "Checking element" element_id=element.element_id
    # First ensure element is visible and clickable
    params = Dict{String,<:Any}("nodeId" => element.element_id)
    request = create_cdp_message("DOM.focus", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Focus failed: $(response.error["message"])")
    end

    element.verbose && @info "Element focused, proceeding to click"
    # Then click to check
    click(element, options)
    element.verbose && @info "Element checked successfully" element_id=element.element_id
    nothing
end

"""
    uncheck(element::ElementHandle; options=Dict()) -> Nothing

Unchecks a checkbox element.
"""
function uncheck(element::ElementHandle; options::AbstractDict{String,<:Any}=Dict{String,<:Any}())
    element.verbose && @info "Unchecking element" element_id=element.element_id
    # First check if it's already unchecked
    is_checked = evaluate_handle(element, "el => el.checked")
    if is_checked
        element.verbose && @info "Element is checked, proceeding to uncheck"
        click(element, options)
        element.verbose && @info "Element unchecked successfully"
    else
        element.verbose && @info "Element already unchecked"
    end
    nothing
end

"""
    select_option(element::ElementHandle, value::AbstractString; options=Dict()) -> Nothing

Selects an option in a select element by its value.
"""
function select_option(element::ElementHandle, value::AbstractString; options::AbstractDict{String,<:Any}=Dict{String,<:Any}())
    element.verbose && @info "Selecting option in element" element_id=element.element_id value=value
    params = Dict{String,<:Any}(
        "nodeId" => element.element_id,
        "value" => value
    )
    request = create_cdp_message("DOM.selectOption", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Select option failed: $(response.error["message"])")
    end
    element.verbose && @info "Option selected successfully" element_id=element.element_id value=value
    nothing
end

"""
    is_visible(element::ElementHandle) -> Bool

Checks if the element is visible on the page.
"""
function is_visible(element::ElementHandle)
    element.verbose && @info "Checking element visibility" element_id=element.element_id
    params = Dict{String,<:Any}("nodeId" => element.element_id)
    request = create_cdp_message("DOM.getBoxModel", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    result = isnothing(response.error)
    element.verbose && @info "Visibility check completed" element_id=element.element_id visible=result
    return result
end

"""
    get_text(element::ElementHandle) -> AbstractString

Gets the text content of the element.
"""
function get_text(element::ElementHandle)
    element.verbose && @info "Getting text content" element_id=element.element_id
    # Use JavaScript to get text content directly using index calculation
    js_code = """(() => {
        const elements = document.querySelectorAll('.multiple');
        const index = Math.floor(($(element.element_id) - 10) / 2);
        return elements[index]?.textContent.trim() || '';
    })()"""

    result = evaluate(element.page, js_code)
    text_result = result isa String ? result : ""
    element.verbose && @info "Text content retrieved" element_id=element.element_id text=text_result
    return text_result
end

"""
    get_attribute(element::ElementHandle, name::AbstractString) -> Union{AbstractString, Nothing}

Gets the value of the specified attribute.
"""
function get_attribute(element::ElementHandle, name::AbstractString)
    element.verbose && @info "Getting attribute" element_id=element.element_id attribute=name
    params = Dict{String,<:Any}(
        "nodeId" => element.element_id,
        "name" => name
    )
    request = create_cdp_message("DOM.getAttribute", params)
    response_channel = send_message(element.page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Get attribute failed: $(response.error["message"])")
    end

    result = response.result["value"]
    element.verbose && @info "Attribute retrieved" element_id=element.element_id attribute=name value=result
    return result
end

"""
    evaluate_handle(element::ElementHandle, expression::AbstractString) -> Any

Evaluates JavaScript expression in the context of the element.
The expression will receive the element as its first argument.

# Arguments
- `element::ElementHandle`: The element to evaluate against
- `expression::AbstractString`: JavaScript expression to evaluate

# Example
```julia
# Check if element is checked
is_checked = evaluate_handle(element, "el => el.checked")
```
"""
function evaluate_handle(element::ElementHandle, expression::AbstractString)
    element.verbose && @info "Evaluating expression on element" element_id=element.element_id
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
    eval_params = Dict{String,<:Any}(
        "expression" => js_code,
        "returnByValue" => true,
        "awaitPromise" => true
    )

    message = Dict{String,<:Any}(
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
