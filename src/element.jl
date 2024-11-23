using HTTP, JSON3

"""
    click(client::WSClient, selector::String)

Click an element identified by CSS selector.
"""
function click(client::WSClient, selector::String)
    result = send_cdp_message(client, "Runtime.evaluate", Dict(
        "expression" => """
            (function() {
                const el = document.querySelector('$(selector)');
                if (el) {
                    el.click();
                    return true;
                }
                return false;
            })()
        """,
        "returnByValue" => true
    ))
    return get(get(result, "result", Dict()), "value", false)
end

"""
    type_text(client::WSClient, selector::String, text::String)

Type text into an element identified by CSS selector.
"""
function type_text(client::WSClient, selector::String, text::String)
    result = send_cdp_message(client, "Runtime.evaluate", Dict(
        "expression" => """
            (function() {
                const el = document.querySelector('$(selector)');
                if (el) {
                    el.value = '$(text)';
                    el.dispatchEvent(new Event('input'));
                    return true;
                }
                return false;
            })()
        """,
        "returnByValue" => true
    ))
    return get(get(result, "result", Dict()), "value", false)
end

export click, type_text
