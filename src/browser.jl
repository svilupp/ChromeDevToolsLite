"""
    verify_browser_available(endpoint::String) -> Bool

Check if Chrome browser is available at the given endpoint.
"""
function verify_browser_available(endpoint::String)
    try
        response = HTTP.get("$endpoint/json/version")
        return response.status == 200
    catch
        return false
    end
end

"""
    find_available_target(targets::Vector) -> Union{Dict, Nothing}

Find an available page target that isn't already being debugged.
"""
function find_available_target(targets)
    for target in targets
        if target["type"] == "page" && !get(target, "attached", false)
            return target
        end
    end
    return nothing
end

"""
    connect_browser(endpoint::String="http://localhost:9222"; max_retries::Int=3) -> WSClient

Connect to Chrome browser at the given debugging endpoint with enhanced error handling.
"""
function connect_browser(endpoint::String = "http://localhost:9222"; max_retries::Int = 3)
    for attempt in 1:max_retries
        try
            @info "Connecting to browser (attempt $attempt/$max_retries)" endpoint

            if !verify_browser_available(endpoint)
                error("Chrome browser not available at $endpoint")
            end

            # Get available targets
            response = HTTP.get("$endpoint/json/list")
            targets = JSON3.read(response.body)

            # Find an available target or create new one
            page_target = find_available_target(targets)

            if isnothing(page_target)
                @debug "Creating new page target"
                response = HTTP.put("$endpoint/json/new")
                page_target = JSON3.read(response.body)
            end

            ws_url = page_target["webSocketDebuggerUrl"]
            @debug "Creating WSClient" ws_url target_id=page_target["id"]

            client = WSClient(ws_url)
            connect!(client)

            # Wait a bit for the connection to stabilize
            sleep(0.5)

            # Check if connection is still active
            if !client.is_connected
                error("WebSocket connection failed to establish")
            end

            @debug "Sending version check message"
            # Verify connection is working with a simpler message first
            result = send_cdp_message(
                client, "Browser.getVersion", Dict(); increment_id = false)

            if haskey(result, "result")
                @info "Connected to browser" version=get(
                    result["result"], "product", "unknown")
                return client
            else
                error("Failed to verify browser connection")
            end

        catch e
            @error "Connection attempt $attempt failed" exception=e
            if attempt == max_retries
                rethrow(e)
            end
            sleep(2.0)  # Wait before retrying
        end
    end
    error("Failed to connect after $max_retries attempts")
end

"""
    ensure_chrome_running(; max_attempts=5, delay=1.0)

Checks if Chrome is running in debug mode on port 9222.
Retries up to max_attempts times with specified delay between attempts.
Returns true if Chrome is responding on the debug port.
"""
function ensure_chrome_running(;
        endpoint = "http://localhost:9222", max_attempts = 5, delay = 1.0)
    for attempt in 1:max_attempts
        try
            @debug "Checking Chrome debug port (attempt $attempt/$max_attempts)"
            response = HTTP.get("$endpoint/json/version")
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
    get_ws_id(; endpoint = "http://localhost:9222")

Gets the WebSocket debugger ID from Chrome's debug interface.
Returns the ID string that can be used to construct the WebSocket URL.
"""
function get_ws_id(; endpoint = "http://localhost:9222")
    @debug "Requesting WebSocket debugger ID"
    response = HTTP.get("$endpoint/json/list")
    targets = JSON3.read(String(response.body))

    # Find a page target or create one
    for target in targets
        if target["type"] == "page" &&
           !contains(get(target, "url", ""), "chrome-extension://")
            ws_url = target["webSocketDebuggerUrl"]
            id = split(ws_url, "/")[end]
            @info "Retrieved WebSocket debugger ID" id=id
            return id
        end
    end

    # No suitable page found, create a new one
    @info "Creating new page target"
    response = HTTP.get("$endpoint/json/new")
    target = JSON3.read(String(response.body))
    id = target["id"]
    @info "Created new page target" id=id
    return id
end
