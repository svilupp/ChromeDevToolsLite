"""
    goto(client::WSClient, url::String; verbose::Bool=false)

Navigate to the specified URL.
"""
function goto(client::WSClient, url::String; verbose::Bool=false)
    verbose && @debug "Navigating to URL" url=url
    # Enable page domain first
    send_cdp_message(client, "Page.enable", Dict{String, Any}())

    # Navigate to URL
    send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => url))

    # Enable runtime for JavaScript evaluation
    send_cdp_message(client, "Runtime.enable", Dict{String, Any}())

    verbose && @info "Page navigation completed" url=url
    return nothing
end

"""
    evaluate(client::WSClient, expression::String; verbose::Bool=false) -> Any

Evaluate JavaScript in the page context.
"""
function evaluate(client::WSClient, expression::String; verbose::Bool=false)
    verbose && @debug "Evaluating JavaScript" expression=expression
    response = send_cdp_message(
        client, "Runtime.evaluate", Dict{String, Any}("expression" => expression))
    if response isa Dict &&
       haskey(response, "result") &&
       haskey(response["result"], "result") &&
       haskey(response["result"]["result"], "value")
        verbose && @debug "Evaluation successful" result=response["result"]["result"]["value"]
        return response["result"]["result"]["value"]
    end
    verbose && @warn "Evaluation returned no value"
    return nothing
end

"""
    screenshot(client::WSClient; verbose::Bool=false) -> String

Take a screenshot of the current page, returns base64 encoded string.
"""
function screenshot(client::WSClient; verbose::Bool=false)
    verbose && @debug "Taking page screenshot"
    # Enable page domain if not already enabled
    send_cdp_message(client, "Page.enable", Dict{String, Any}())
    result = send_cdp_message(client, "Page.captureScreenshot", Dict{String, Any}())
    if result isa Dict && haskey(result, "result") && haskey(result["result"], "data")
        verbose && @debug "Screenshot captured successfully"
        return result["result"]["data"]
    end
    verbose && @warn "Screenshot capture failed"
    return nothing
end

"""
    content(client::WSClient; verbose::Bool=false) -> String

Get the HTML content of the page.
"""
function content(client::WSClient; verbose::Bool=false)
    evaluate(client, "document.documentElement.outerHTML"; verbose=verbose)
end
