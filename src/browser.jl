using HTTP
using JSON3
using HTTP.WebSockets
using Base.Threads: @async
using Logging

"""
    connect_browser(endpoint::String="http://localhost:9222") -> WSClient

Connect to Chrome browser at the given debugging endpoint.
Returns a WebSocket client for CDP communication.
"""
function connect_browser(endpoint::String="http://localhost:9222")
    try
        # Get available targets
        response = HTTP.get("$endpoint/json/list")
        targets = JSON3.read(response.body)

        # Find or create a page target
        page_target = nothing
        for target in targets
            if target["type"] == "page"
                page_target = target
                break
            end
        end

        if isnothing(page_target)
            response = HTTP.put("$endpoint/json/new")
            page_target = JSON3.read(response.body)
        end

        ws_url = page_target["webSocketDebuggerUrl"]
        client = WSClient(ws_url)
        connected = Channel{Bool}(1)
        error_channel = Channel{Any}(1)

        # Create task to handle WebSocket connection
        @async begin
            try
                WebSockets.open(ws_url) do ws
                    client.ws = ws
                    client.is_connected = true
                    client.page_loaded = false
                    start_message_handler(client)
                    put!(connected, true)

                    # Keep connection alive until closed
                    while client.is_connected && !WebSockets.isclosed(ws)
                        sleep(0.1)
                    end
                end
            catch e
                @error "WebSocket connection failed" exception=e
                put!(error_channel, e)
                put!(connected, false)
            end
        end

        # Wait for connection with timeout
        @async begin
            sleep(5.0)
            if !isready(connected)
                put!(error_channel, "Connection timeout")
                put!(connected, false)
            end
        end

        # Check for errors or successful connection
        if isready(error_channel)
            error("WebSocket connection failed: $(take!(error_channel))")
        end

        if !take!(connected)
            error("Failed to establish WebSocket connection")
        end

        return client
    catch e
        @error "Connection error" exception=e
        rethrow(e)
    end
end

export connect_browser
