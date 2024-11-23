using HTTP
using JSON3
using HTTP.WebSockets
using Base.Threads: @async
using Logging

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
function connect_browser(endpoint::String="http://localhost:9222"; max_retries::Int=3)
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
            result = send_cdp_message(client, "Browser.getVersion", Dict(); increment_id=false)

            if haskey(result, "result")
                @info "Connected to browser" version=get(result["result"], "product", "unknown")
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

export connect_browser
