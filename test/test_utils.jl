using HTTP
using JSON3
using Logging

"""
    ensure_chrome_running()

Checks if Chrome is running in debug mode on port 9222.
Returns true if Chrome is responding on the debug port.
"""
function ensure_chrome_running()
    try
        @debug "Checking Chrome debug port"
        response = HTTP.get("http://localhost:9222/json/version")
        @info "Chrome is running" version=String(response.body)
        return true
    catch e
        @warn "Chrome not running on debug port" exception=e
        return false
    end
end

"""
    get_ws_id()

Gets the WebSocket debugger ID from Chrome's debug interface.
Returns the ID string that can be used to construct the WebSocket URL.
"""
function get_ws_id()
    @debug "Requesting WebSocket debugger ID"
    response = HTTP.get("http://localhost:9222/json/version")
    data = JSON3.read(String(response.body))
    ws_url = data["webSocketDebuggerUrl"]
    id = split(ws_url, "/")[end]  # Extract the ID from the full URL
    @info "Retrieved WebSocket debugger ID" id=id
    return id
end

export ensure_chrome_running, get_ws_id
