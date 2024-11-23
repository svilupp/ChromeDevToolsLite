using HTTP
using JSON

"""
    check_endpoint()

Check if Chrome DevTools endpoint is accessible.
"""
function check_endpoint()
    try
        response = HTTP.get("http://localhost:9222/json/version"; readtimeout=5)
        return response.status == 200
    catch
        return false
    end
end

"""
    get_targets()

Get list of available Chrome DevTools Protocol targets.
"""
function get_targets()
    response = HTTP.get("http://localhost:9222/json/list"; readtimeout=5)
    return JSON.parse(String(response.body))
end

"""
    get_page_websocket_url()

Get the WebSocket debugger URL for the first available page target.
"""
function get_page_websocket_url()
    if !check_endpoint()
        error("Chrome DevTools endpoint not accessible")
    end

    targets = get_targets()
    page_target = findfirst(t -> t["type"] == "page", targets)

    if isnothing(page_target)
        # Create a new page if none exists
        response = HTTP.get("http://localhost:9222/json/new"; readtimeout=5)
        target = JSON.parse(String(response.body))
        return target["webSocketDebuggerUrl"]
    end

    return targets[page_target]["webSocketDebuggerUrl"]
end

"""
    get_websocket_url()

Get the WebSocket debugger URL for the browser from Chrome DevTools Protocol.
"""
function get_websocket_url()
    if !check_endpoint()
        error("Chrome DevTools endpoint not accessible")
    end
    response = HTTP.get("http://localhost:9222/json/version"; readtimeout=5)
    version_info = JSON.parse(String(response.body))
    return version_info["webSocketDebuggerUrl"]
end

mutable struct WSClient
    url::String
    id::Int

    WSClient(url::String) = new(url, 1)
end

"""
    send_cdp_message(client::WSClient, method::String, params::Dict=Dict())

Send a message to Chrome DevTools Protocol and wait for response.
"""
function send_cdp_message(client::WSClient, method::String, params::Dict=Dict())
    message = Dict(
        "id" => client.id,
        "method" => method,
        "params" => params
    )
    client.id += 1

    response = nothing
    HTTP.WebSockets.open(client.url) do ws
        HTTP.WebSockets.send(ws, JSON.json(message))
        response = JSON.parse(String(HTTP.WebSockets.receive(ws)))
    end

    if haskey(response, "error")
        error("CDP Error: $(response["error"])")
    end

    return response
end
