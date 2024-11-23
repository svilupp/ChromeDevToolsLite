"""
    click(element::ElementHandle; options=Dict())

Click an element.
"""
function click(element::ElementHandle; options = Dict())
    element.verbose && @debug "Attempting to click element" selector=element.selector
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    if (!el || !el.isConnected) {
                        console.error('Element not found or not connected to DOM');
                        return false;
                    }
                    // Ensure element is in viewport
                    el.scrollIntoView({behavior: 'instant', block: 'center'});
                    return true;
                })()
            """,
            "returnByValue" => true
        ))
    success = extract_element_result(result)
    if !success
        element.verbose && @info "Click operation failed - element not found" selector=element.selector
        return false
    end

    # Get element position and perform CDP click
    pos = get_element_position(element.client, element.selector)
    click(element.client; x=pos.x, y=pos.y)

    element.verbose && @info "Click operation completed" selector=element.selector
    return true
end

"""
    type_text(element::ElementHandle, text::String; options=Dict())

Type text into an element.
"""
function type_text(element::ElementHandle, text::String; options = Dict())
    element.verbose && @debug "Attempting to type text" selector=element.selector text=text
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    if (!el || !el.isConnected) {
                        console.error('Element not found or not connected to DOM');
                        return false;
                    }
                    el.focus();
                    // Clear existing value
                    el.value = '';
                    return true;
                })()
            """,
            "returnByValue" => true
        ))
    success = extract_element_result(result)
    if !success
        element.verbose && @info "Type text operation failed - element not found" selector=element.selector
        return false
    end

    # Use CDP to type text
    type_text(element.client, text)

    # Ensure value is set and events are triggered
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    el.value = '$(text)';
                    el.dispatchEvent(new Event('input', { bubbles: true }));
                    el.dispatchEvent(new Event('change', { bubbles: true }));
                    return true;
                })()
            """,
            "returnByValue" => true
        ))

    element.verbose && @info "Type text operation completed" selector=element.selector
    return true
end

"""
    check(element::ElementHandle; options=Dict())

Check a checkbox or radio button element.
"""
function check(element::ElementHandle; options = Dict())
    element.verbose && @debug "Attempting to check element" selector=element.selector
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    if (!el || !el.isConnected || (el.type !== 'checkbox' && el.type !== 'radio')) {
                        console.error('Element not found or not checkable');
                        return { success: false };
                    }
                    const wasChecked = el.checked;
                    el.checked = true;
                    if (wasChecked !== el.checked) {
                        el.dispatchEvent(new Event('change', { bubbles: true }));
                        el.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                    return { success: true, checked: el.checked };
                })()
            """,
            "returnByValue" => true
        ))
    response = extract_element_result(result)
    success = get(response, "success", false)
    element.verbose &&
        @info "Check operation result" selector=element.selector success=success
    return success
end

"""
    uncheck(element::ElementHandle; options=Dict())

Uncheck a checkbox element.
"""
function uncheck(element::ElementHandle; options = Dict())
    element.verbose && @debug "Attempting to uncheck element" selector=element.selector
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    if (!el || !el.isConnected || el.type !== 'checkbox') {
                        console.error('Element not found or not a checkbox');
                        return { success: false };
                    }
                    const wasChecked = el.checked;
                    el.checked = false;
                    if (wasChecked !== el.checked) {
                        el.dispatchEvent(new Event('change', { bubbles: true }));
                        el.dispatchEvent(new Event('input', { bubbles: true }));
                    }
                    return { success: true, checked: el.checked };
                })()
            """,
            "returnByValue" => true
        ))
    response = extract_element_result(result)
    success = get(response, "success", false)
    element.verbose &&
        @info "Uncheck operation result" selector=element.selector success=success
    return success
end

"""
    select_option(element::ElementHandle, value::String; options=Dict())

Select an option in a select element by value.
"""
function select_option(element::ElementHandle, value::String; options = Dict())
    element.verbose &&
        @debug "Attempting to select option" selector=element.selector value=value
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    if (!el || el.tagName.toLowerCase() !== 'select') {
                        console.log('Element not found or not a select element');
                        return false;
                    }
                    el.value = '$(value)';
                    el.dispatchEvent(new Event('change'));
                    return el.value === '$(value)';
                })()
            """,
            "returnByValue" => true
        ))
    success = extract_element_result(result)
    element.verbose &&
        @info "Select option result" selector=element.selector value=value success=success
    return success
end

"""
    is_visible(element::ElementHandle) -> Bool

Check if an element is visible.
"""
function is_visible(element::ElementHandle)
    element.verbose && @debug "Checking element visibility" selector=element.selector
    safe_selector = replace(element.selector, "'" => "\\'")
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(safe_selector)');
                    if (!el || !el.isConnected) {
                        console.error('Element not found or not connected to DOM');
                        return false;
                    }
                    const rect = el.getBoundingClientRect();
                    const style = window.getComputedStyle(el);
                    return style.display !== 'none' &&
                           style.visibility !== 'hidden' &&
                           style.opacity !== '0' &&
                           rect.width > 0 &&
                           rect.height > 0 &&
                           rect.top <= window.innerHeight &&
                           rect.bottom >= 0;
                })()
            """,
            "returnByValue" => true
        ))
    visible = extract_element_result(result)
    element.verbose &&
        @info "Visibility check result" selector=element.selector visible=visible
    return visible
end

"""
    get_text(element::ElementHandle) -> String

Get the text content of an element.
"""
function get_text(element::ElementHandle)
    element.verbose && @debug "Getting element text" selector=element.selector
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    if (!el) {
                        console.log('Element not found for text retrieval');
                        return { success: false, value: '' };
                    }
                    return { success: true, value: el.textContent.trim() };
                })()
            """,
            "returnByValue" => true
        ))

    response = extract_cdp_result(result, ["result", "result"])
    text = get(response, "value", "")
    element.verbose && @info "Get text result" selector=element.selector text=text
    return text
end

"""
    get_attribute(element::ElementHandle, name::String) -> Union{String, Nothing}

Get the value of an attribute on an element.
"""
function get_attribute(element::ElementHandle, name::String)
    element.verbose &&
        @debug "Getting element attribute" selector=element.selector attribute=name
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    if (!el) {
                        console.log('Element not found for attribute:', '$(element.selector)');
                        return { success: false, value: null };
                    }
                    const value = el.getAttribute('$(name)');
                    return { success: true, value: value };
                })()
            """,
            "returnByValue" => true
        ))

    response = extract_cdp_result(result, ["result", "result"])
    if response === nothing || !get(response, "success", false)
        return nothing
    end

    value = get(response, "value", nothing)
    if value === nothing
        return nothing
    end

    element.verbose &&
        @info "Get attribute result" selector=element.selector attribute=name value=value
    return string(value)
end

"""
    evaluate_handle(element::ElementHandle, expression::String) -> Any

Evaluate JavaScript expression in the context of the element.
Assumed the element is variable `el`.
"""
function evaluate_handle(element::ElementHandle, expression::String)
    element.verbose &&
        @debug "Evaluating expression on element" selector=element.selector expression=expression
    result = send_cdp_message(element.client,
        "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(element.selector)');
                    if (!el || !el.isConnected) {
                        console.error('Element not found or not connected to DOM:', '$(element.selector)');
                        return { success: false, value: null };
                    }
                    try {
                        const fn = function(el) { return $(expression); };
                        const value = fn(el);
                        return {
                            success: true,
                            value: value
                        };
                    } catch (e) {
                        console.error('Evaluation error:', e);
                        return { success: false, value: null };
                    }
                })()
            """,
            "returnByValue" => true
        ))

    response = extract_cdp_result(result, ["result", "result"])
    if response === nothing || !get(response, "success", false)
        return nothing
    end
    return response["value"]
end
