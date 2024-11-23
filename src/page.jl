"""
Basic page operations for ChromeDevToolsLite
"""

"""
    goto(client::WSClient, url::String)

Navigate to the specified URL.
"""
function goto(client::WSClient, url::String)
    # Enable page domain first
    send_cdp_message(client, "Page.enable", Dict{String,Any}())

    # Navigate to URL
    send_cdp_message(client, "Page.navigate", Dict{String,Any}("url" => url))

    # Enable runtime for JavaScript evaluation
    send_cdp_message(client, "Runtime.enable", Dict{String,Any}())

    # Small delay to ensure page loads
    sleep(1)
end

"""
    evaluate(client::WSClient, expression::String) -> Any

Evaluate JavaScript in the page context.
"""
function evaluate(client::WSClient, expression::String)
    response = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}("expression" => expression))
    if response isa Dict &&
       haskey(response, "result") &&
       haskey(response["result"], "result") &&
       haskey(response["result"]["result"], "value")
        return response["result"]["result"]["value"]
    end
    return nothing
end

"""
    screenshot(client::WSClient) -> String

Take a screenshot of the current page, returns base64 encoded string.
"""
function screenshot(client::WSClient)
    # Enable page domain if not already enabled
    send_cdp_message(client, "Page.enable", Dict{String,Any}())
    result = send_cdp_message(client, "Page.captureScreenshot", Dict{String,Any}())
    if result isa Dict && haskey(result, "result") && haskey(result["result"], "data")
        return result["result"]["data"]
    end
    return nothing
end

"""
    content(client::WSClient) -> String

Get the HTML content of the page.
"""
function content(client::WSClient)
    evaluate(client, "document.documentElement.outerHTML")
end

export goto, evaluate, screenshot, content
