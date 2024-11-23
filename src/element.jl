using HTTP, JSON3
using Logging

"""
    ElementHandle

Represents a handle to a DOM element in the browser.
"""
struct ElementHandle
    client::WSClient
    selector::String
end

"""
    click(element::ElementHandle; options=Dict())

Click an element.
"""
function click(element::ElementHandle; options=Dict())
    @debug "Attempting to click element" selector=element.selector
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict{String, Any}(
        "expression" => """
            (function() {
                const el = document.querySelector('$(element.selector)');
                if (!el || !el.isConnected) {
                    console.error('Element not found or not connected to DOM');
                    return false;
                }
                // Ensure element is in viewport
                el.scrollIntoView({behavior: 'instant', block: 'center'});
                // Dispatch events in correct order
                el.dispatchEvent(new MouseEvent('mousedown', {bubbles: true}));
                el.dispatchEvent(new MouseEvent('mouseup', {bubbles: true}));
                el.click();
                return true;
            })()
        """,
        "returnByValue" => true
    ))
    success = get(get(result, "result", Dict()), "value", false)
    @info "Click operation result" selector=element.selector success=success
    return success
end

"""
    type_text(element::ElementHandle, text::String; options=Dict())

Type text into an element.
"""
function type_text(element::ElementHandle, text::String; options=Dict())
    @debug "Attempting to type text" selector=element.selector text=text
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict(
        "expression" => """
            (function() {
                const el = document.querySelector('$(element.selector)');
                if (!el || !el.isConnected) {
                    console.error('Element not found or not connected to DOM');
                    return false;
                }
                // Focus the element first
                el.focus();
                // Clear existing value
                el.value = '';
                // Set new value
                el.value = '$(text)';
                // Dispatch events in correct order
                el.dispatchEvent(new Event('input', { bubbles: true }));
                el.dispatchEvent(new Event('change', { bubbles: true }));
                return el.value === '$(text)';
            })()
        """,
        "returnByValue" => true
    ))
    success = get(get(result, "result", Dict()), "value", false)
    @info "Type text operation result" selector=element.selector success=success
    return success
end

"""
    check(element::ElementHandle; options=Dict())

Check a checkbox or radio button element.
"""
function check(element::ElementHandle; options=Dict())
    @debug "Attempting to check element" selector=element.selector
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict(
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
    response = get(get(result, "result", Dict()), "value", Dict())
    success = get(response, "success", false)
    @info "Check operation result" selector=element.selector success=success
    return success
end

"""
    uncheck(element::ElementHandle; options=Dict())

Uncheck a checkbox element.
"""
function uncheck(element::ElementHandle; options=Dict())
    @debug "Attempting to uncheck element" selector=element.selector
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict{String, Any}(
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
    response = get(get(result, "result", Dict()), "value", Dict())
    success = get(response, "success", false)
    @info "Uncheck operation result" selector=element.selector success=success
    return success
end

"""
    select_option(element::ElementHandle, value::String; options=Dict())

Select an option in a select element by value.
"""
function select_option(element::ElementHandle, value::String; options=Dict())
    @debug "Attempting to select option" selector=element.selector value=value
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict{String, Any}(
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
    success = get(get(result, "result", Dict()), "value", false)
    @info "Select option result" selector=element.selector value=value success=success
    return success
end

"""
    is_visible(element::ElementHandle) -> Bool

Check if an element is visible.
"""
function is_visible(element::ElementHandle)
    @debug "Checking element visibility" selector=element.selector
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict{String, Any}(
        "expression" => """
            (function() {
                const el = document.querySelector('$(element.selector)');
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
    visible = get(get(result, "result", Dict()), "value", false)
    @info "Visibility check result" selector=element.selector visible=visible
    return visible
end

"""
    get_text(element::ElementHandle) -> String

Get the text content of an element.
"""
function get_text(element::ElementHandle)
    @debug "Getting element text" selector=element.selector
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict{String, Any}(
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
    response = get(get(result, "result", Dict()), "value", Dict())
    text = get(response, "value", "")
    @info "Get text result" selector=element.selector text=text
    return text
end

"""
    get_attribute(element::ElementHandle, name::String) -> Union{String, Nothing}

Get the value of an attribute on an element.
"""
function get_attribute(element::ElementHandle, name::String)
    @debug "Getting element attribute" selector=element.selector attribute=name
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict(
        "expression" => """
            (function() {
                const el = document.querySelector('$(element.selector)');
                if (!el) {
                    console.log('Element not found for attribute:', '$(element.selector)');
                    return null;
                }
                return el.getAttribute('$(name)');
            })()
        """,
        "returnByValue" => true
    ))
    value = get(get(result, "result", Dict()), "value", nothing)
    @info "Get attribute result" selector=element.selector attribute=name value=value
    return value === nothing ? nothing : string(value)
end

"""
    evaluate_handle(element::ElementHandle, expression::String) -> Any

Evaluate JavaScript expression in the context of the element.
"""
function evaluate_handle(element::ElementHandle, expression::String)
    @debug "Evaluating expression on element" selector=element.selector expression=expression
    result = send_cdp_message(element.client, "Runtime.evaluate", Dict{String, Any}(
        "expression" => """
            (function() {
                const el = document.querySelector('$(element.selector)');
                console.log('Selector lookup:', {
                    selector: '$(element.selector)',
                    found: !!el,
                    isConnected: el ? el.isConnected : false,
                    tagName: el ? el.tagName : null,
                    innerHTML: el ? el.innerHTML : null,
                    outerHTML: el ? el.outerHTML : null
                });

                if (!el || !el.isConnected) {
                    console.error('Element not found or not connected to DOM:', '$(element.selector)');
                    return { success: false, value: null, error: 'Element not found' };
                }

                try {
                    const fn = function(el) { return $(expression); };
                    const value = fn(el);
                    console.log('Evaluation result:', {
                        selector: '$(element.selector)',
                        expression: '$(expression)',
                        value: value,
                        type: typeof value
                    });
                    return {
                        success: true,
                        value: value,
                        type: typeof value
                    };
                } catch (e) {
                    console.error('Evaluation error:', e);
                    return { success: false, value: null, error: e.toString() };
                }
            })()
        """,
        "returnByValue" => true
    ))

    response = get(get(result, "result", Dict()), "value", Dict())
    success = get(response, "success", false)
    value = get(response, "value", nothing)
    value_type = get(response, "type", nothing)
    error_msg = get(response, "error", nothing)

    @info "Evaluate handle result" selector=element.selector success=success value=value type=value_type error=error_msg

    # Handle boolean values explicitly
    if value_type == "boolean"
        return value === true
    end

    return success ? value : nothing
end

export ElementHandle, click, type_text, check, uncheck, select_option,
       is_visible, get_text, get_attribute, evaluate_handle
