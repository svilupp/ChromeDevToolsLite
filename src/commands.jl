"""
    navigate(client::ChromeClient, url::String) -> Dict
"""
function navigate(client::ChromeClient, url::String)
    send_cdp_message(client, Dict("method" => "Page.enable", "params" => Dict()))
    send_cdp_message(client, Dict(
        "method" => "Page.navigate",
        "params" => Dict("url" => url)
    ))
end

"""
    evaluate(client::ChromeClient, expression::String) -> Any
"""
function evaluate(client::ChromeClient, expression::String)
    send_cdp_message(client, Dict("method" => "Runtime.enable", "params" => Dict()))
    result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => expression,
            "returnByValue" => true,
            "awaitPromise" => true,
            "userGesture" => true,
            "includeCommandLineAPI" => true
        )
    ))

    if haskey(result, "result")
        if haskey(result["result"], "exceptionDetails")
            @warn "JavaScript error: " * get(result["result"]["exceptionDetails"], "text", "Unknown error")
            return nothing
        end
        if haskey(result["result"], "result")
            return get(result["result"]["result"], "value", nothing)
        end
    end
    nothing
end

"""
    screenshot(client::ChromeClient) -> Union{String,Nothing}
"""
function screenshot(client::ChromeClient)
    result = send_cdp_message(client, Dict(
        "method" => "Page.captureScreenshot",
        "params" => Dict()
    ))
    get(get(result, "result", Dict()), "data", nothing)
end

"""
    goto(client::ChromeClient, url::String) -> Bool

Navigate to a URL and return true if navigation was successful.
"""
function goto(client::ChromeClient, url::String)
    send_cdp_message(client, Dict("method" => "Page.enable", "params" => Dict()))
    result = send_cdp_message(client, Dict(
        "method" => "Page.navigate",
        "params" => Dict("url" => url)
    ))
    haskey(get(result, "result", Dict()), "frameId")
end

"""
    content(client::ChromeClient) -> Union{String,Nothing}

Get the HTML content of the current page.
"""
function content(client::ChromeClient)
    result = send_cdp_message(client, Dict(
        "method" => "Runtime.evaluate",
        "params" => Dict(
            "expression" => "document.documentElement.outerHTML",
            "returnByValue" => true
        )
    ))
    get(get(get(result, "result", Dict()), "result", Dict()), "value", nothing)
end

export navigate, evaluate, screenshot, goto, content
