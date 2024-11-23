"""
Page domain implementation for Chrome DevTools Protocol.
Basic functionality for page control and navigation.
"""

"""
    enable(client::WSClient)

Enable page domain events.
"""
function enable(client::WSClient)
    send_cdp_message(client, "Page.enable")
end

"""
    navigate(client::WSClient, url::String)

Navigate to the given URL.
"""
function navigate(client::WSClient, url::String)
    send_cdp_message(client, "Page.navigate", Dict("url" => url))
end

"""
    reload(client::WSClient)

Reload the current page.
"""
function reload(client::WSClient)
    send_cdp_message(client, "Page.reload")
end

"""
    capture_screenshot(client::WSClient; format::String="png", quality::Union{Nothing,Int}=nothing)

Capture a screenshot of the current page.
"""
function capture_screenshot(client::WSClient; format::String="png", quality::Union{Nothing,Int}=nothing)
    params = Dict("format" => format)
    if !isnothing(quality)
        params["quality"] = quality
    end
    response = send_cdp_message(client, "Page.captureScreenshot", params)
    return get(response, "result", Dict())["data"]
end
