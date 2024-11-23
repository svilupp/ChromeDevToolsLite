using HTTP
using JSON3
using Logging

"""
    ensure_chrome_running(; max_attempts=5, delay=1.0)

Checks if Chrome is running in debug mode on port 9222.
Retries up to max_attempts times with specified delay between attempts.
Returns true if Chrome is responding on the debug port.
"""
function ensure_chrome_running(; max_attempts=5, delay=1.0)
    for attempt in 1:max_attempts
        try
            @debug "Checking Chrome debug port (attempt $attempt/$max_attempts)"
            response = HTTP.get("http://localhost:9222/json/version")
            @info "Chrome is running" version=String(response.body)
            return true
        catch e
            if attempt < max_attempts
                @warn "Chrome not responding, retrying..." attempt=attempt exception=e
                sleep(delay)
            else
                @error "Chrome failed to respond after $max_attempts attempts" exception=e
                return false
            end
        end
    end
    return false
end

"""
    get_ws_id()

Gets the WebSocket debugger ID from Chrome's debug interface.
Returns the ID string that can be used to construct the WebSocket URL.
"""
function get_ws_id()
    @debug "Requesting WebSocket debugger ID"
    response = HTTP.get("http://localhost:9222/json/list")
    targets = JSON3.read(String(response.body))

    # Find a page target or create one
    for target in targets
        if target["type"] == "page" && !contains(get(target, "url", ""), "chrome-extension://")
            ws_url = target["webSocketDebuggerUrl"]
            id = split(ws_url, "/")[end]
            @info "Retrieved WebSocket debugger ID" id=id
            return id
        end
    end

    # No suitable page found, create a new one
    @info "Creating new page target"
    response = HTTP.get("http://localhost:9222/json/new")
    target = JSON3.read(String(response.body))
    id = target["id"]
    @info "Created new page target" id=id
    return id
end

export ensure_chrome_running, get_ws_id
