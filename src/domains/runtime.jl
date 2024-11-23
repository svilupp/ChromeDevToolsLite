"""
Runtime domain implementation for Chrome DevTools Protocol.
Basic functionality for JavaScript evaluation and DOM interaction.
"""

"""
    evaluate(client::WSClient, expression::String)

Evaluate JavaScript expression in the context of the current page.
"""
function evaluate(client::WSClient, expression::String)
    params = Dict(
        "expression" => expression,
        "returnByValue" => true
    )
    response = send_cdp_message(client, "Runtime.evaluate", params)
    return get(response, "result", Dict())
end

"""
    query_selector(client::WSClient, selector::String)

Query for a DOM element using the given CSS selector.
"""
function query_selector(client::WSClient, selector::String)
    js_expression = """document.querySelector("$(selector)")"""
    evaluate(client, js_expression)
end

"""
    click_element(client::WSClient, selector::String)

Click on an element matching the given CSS selector.
"""
function click_element(client::WSClient, selector::String)
    js_expression = """document.querySelector("$(selector)").click()"""
    evaluate(client, js_expression)
end

"""
    type_text(client::WSClient, selector::String, text::String)

Type text into an input element matching the given CSS selector.
"""
function type_text(client::WSClient, selector::String, text::String)
    js_expression = """
    const el = document.querySelector("$(selector)");
    el.value = "$(text)";
    el.dispatchEvent(new Event('input', { bubbles: true }));
    """
    evaluate(client, js_expression)
end
