"""
    goto(client::WSClient, url::String; verbose::Bool=false)

Navigate to the specified URL and wait for page load.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `url::String`: The URL to navigate to
- `verbose::Bool`: Enable verbose logging (default: false)

# Throws
- `NavigationError`: If navigation fails or times out
"""
function goto(client::WSClient, url::String; verbose::Bool=false)
    verbose && @debug "Navigating to URL" url=url
    # Enable page domain first
    send_cdp_message(client, "Page.enable", Dict{String, Any}())

    # Navigate to URL
    result = send_cdp_message(client, "Page.navigate", Dict{String, Any}("url" => url))

    # Check for navigation errors
    if haskey(result, "errorText")
        throw(NavigationError("Navigation failed: $(result["errorText"])"))
    end

    # Wait for page load
    load_event = wait_for_event(client, "Page.loadEventFired")
    if load_event === nothing || haskey(load_event, "error")
        throw(NavigationError("Page load timed out or failed"))
    end

    # Enable runtime for JavaScript evaluation
    send_cdp_message(client, "Runtime.enable", Dict{String, Any}())

    verbose && @info "Page navigation completed" url=url
    return nothing
end

"""
    evaluate(client::WSClient, expression::String; verbose::Bool=false) -> Any

Evaluate JavaScript in the page context and return the result.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `expression::String`: JavaScript expression to evaluate
- `verbose::Bool`: Enable verbose logging (default: false)

# Returns
- `Any`: The result of the JavaScript evaluation, or nothing if no value returned

# Throws
- `EvaluationError`: If JavaScript evaluation fails
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

Take a screenshot of the current page.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `verbose::Bool`: Enable verbose logging (default: false)

# Returns
- `String`: Base64 encoded string of the screenshot, or nothing if capture fails
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

Get the HTML content of the current page.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `verbose::Bool`: Enable verbose logging (default: false)

# Returns
- `String`: The HTML content of the page
"""
function content(client::WSClient; verbose::Bool=false)
    evaluate(client, "document.documentElement.outerHTML"; verbose=verbose)
end

"""
    evaluate_handle(client::WSClient, expression::String; verbose::Bool=false) -> Any

Evaluate JavaScript in the page context and return a handle to the result.
Useful for evaluating expressions that return DOM elements or complex objects.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `expression::String`: JavaScript expression to evaluate
- `verbose::Bool`: Enable verbose logging (default: false)

# Returns
- `Any`: A handle to the evaluated result, typically a Dict containing object reference

# Throws
- `EvaluationError`: If JavaScript evaluation fails
"""
function evaluate_handle(client::WSClient, expression::String; verbose::Bool=false)
    verbose && @debug "Evaluating JavaScript for handle" expression=expression
    response = send_cdp_message(
        client, "Runtime.evaluate",
        Dict{String,Any}(
            "expression" => expression,
            "returnByValue" => false
        )
    )

    if haskey(response, "result") && haskey(response["result"], "result")
        verbose && @debug "Handle evaluation successful"
        return response["result"]["result"]
    end

    verbose && @warn "Handle evaluation returned no result"
    return nothing
end
