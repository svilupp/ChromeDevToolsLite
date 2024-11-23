"""
Basic page operations for ChromeDevToolsLite
"""

using Logging

"""
    goto(client::WSClient, url::String)

Navigate to the specified URL.
"""
function goto(client::WSClient, url::String)
    @debug "Navigating to URL" url=url
    # Enable page domain first
    send_cdp_message(client, "Page.enable", Dict{String,Any}())

    # Navigate to URL
    send_cdp_message(client, "Page.navigate", Dict{String,Any}("url" => url))

    # Enable runtime for JavaScript evaluation
    send_cdp_message(client, "Runtime.enable", Dict{String,Any}())

    @info "Page navigation completed" url=url
    # Small delay to ensure page loads
    sleep(1)
end

"""
    evaluate(client::WSClient, expression::String) -> Any

Evaluate JavaScript in the page context.
"""
function evaluate(client::WSClient, expression::String)
    @debug "Evaluating JavaScript" expression=expression
    response = send_cdp_message(client, "Runtime.evaluate", Dict{String,Any}("expression" => expression))
    if response isa Dict &&
       haskey(response, "result") &&
       haskey(response["result"], "result") &&
       haskey(response["result"]["result"], "value")
        @debug "Evaluation successful" result=response["result"]["result"]["value"]
        return response["result"]["result"]["value"]
    end
    @warn "Evaluation returned no value"
    return nothing
end

"""
    screenshot(client::WSClient) -> String

Take a screenshot of the current page, returns base64 encoded string.
"""
function screenshot(client::WSClient)
    @debug "Taking page screenshot"
    # Enable page domain if not already enabled
    send_cdp_message(client, "Page.enable", Dict{String,Any}())
    result = send_cdp_message(client, "Page.captureScreenshot", Dict{String,Any}())
    if result isa Dict && haskey(result, "result") && haskey(result["result"], "data")
        @debug "Screenshot captured successfully"
        return result["result"]["data"]
    end
    @warn "Screenshot capture failed"
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
