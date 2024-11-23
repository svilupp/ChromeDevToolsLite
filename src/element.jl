# Core element operations
using HTTP, JSON3

"""
    query_selector(client::ChromeClient, selector::String) -> Union{String, Nothing}

Find an element in the page using CSS selector.
"""
function query_selector(client::ChromeClient, selector::String)
    result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => "!!document.querySelector('$(selector)')",
            "returnByValue" => true
        )
    ))

    exists = get(get(get(result, "result", Dict()), "result", Dict()), "value", false)
    return exists ? selector : nothing
end

"""
    click_element(client::ChromeClient, selector::String) -> Bool

Click an element identified by CSS selector.
"""
function click_element(client::ChromeClient, selector::String)
    result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(selector)');
                    if (el && typeof el.click === 'function') {
                        el.click();
                        return true;
                    }
                    return false;
                })()
            """,
            "returnByValue" => true
        )
    ))

    return get(get(get(result, "result", Dict()), "result", Dict()), "value", false)
end

"""
    type_text(client::ChromeClient, selector::String, text::String) -> Bool

Type text into an element identified by CSS selector.
"""
function type_text(client::ChromeClient, selector::String, text::String)
    result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(selector)');
                    if (el && (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA')) {
                        el.value = '$(text)';
                        el.dispatchEvent(new Event('input', { bubbles: true }));
                        el.dispatchEvent(new Event('change', { bubbles: true }));
                        return true;
                    }
                    return false;
                })()
            """,
            "returnByValue" => true
        )
    ))

    return get(get(get(result, "result", Dict()), "result", Dict()), "value", false)
end

"""
    get_text(client::ChromeClient, selector::String) -> Union{String, Nothing}

Get text content of an element identified by CSS selector.
"""
function get_text(client::ChromeClient, selector::String)
    result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => """
                (function() {
                    const el = document.querySelector('$(selector)');
                    if (el) {
                        return el.textContent || el.value || '';
                    }
                    return null;
                })()
            """,
            "returnByValue" => true
        )
    ))

    return get(get(get(result, "result", Dict()), "result", Dict()), "value", nothing)
end

export query_selector, click_element, type_text, get_text
