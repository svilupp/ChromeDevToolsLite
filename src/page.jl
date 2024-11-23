"""
Basic page operations for ChromeDevToolsLite
"""

"""
    goto(page::Page, url::String)

Navigate to the specified URL.
"""
function goto(page::Page, url::String)
    send_cdp_message(page.browser, "Page.enable", Dict("sessionId" => page.session_id))
    send_cdp_message(page.browser, "Page.navigate", Dict(
        "sessionId" => page.session_id,
        "url" => url
    ))
end

"""
    evaluate(page::Page, expression::String, args...) -> Any

Evaluate JavaScript in the page context with optional arguments.
"""
function evaluate(page::Page, expression::String, args...)
    send_cdp_message(page.browser, "Runtime.enable", Dict("sessionId" => page.session_id))

    # Create a function that wraps our expression to properly handle arguments
    wrapped_expression = """
    (function() {
        const __args = $(JSON3.write([args...]));
        return (function() { $expression }).apply(null, __args);
    })()
    """

    result = send_cdp_message(page.browser, "Runtime.evaluate", Dict(
        "sessionId" => page.session_id,
        "expression" => wrapped_expression
    ))

    return get(get(result, "result", Dict()), "value", nothing)
end

"""
    screenshot(page::Page) -> String

Take a screenshot of the current page, returns base64 encoded string.
"""
function screenshot(page::Page)
    result = send_cdp_message(page.browser, "Page.captureScreenshot", Dict(
        "sessionId" => page.session_id
    ))
    return get(result, "data", "")
end

"""
    content(page::Page) -> String

Get the HTML content of the page.
"""
function content(page::Page)
    result = evaluate(page, "document.documentElement.outerHTML")
    return result
end

"""
    set_content(page::Page, html::String)

Set the HTML content of the page.
"""
function set_content(page::Page, html::String)
    evaluate(page, """
        document.open();
        document.write(arguments[0]);
        document.close();
    """, html)
end

export goto, evaluate, screenshot, content, set_content
