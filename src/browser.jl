using HTTP
using JSON3
using HTTP.WebSockets
using Base.Threads: @async

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

        # Create task to handle WebSocket connection
        @async begin
            WebSockets.open(ws_url) do ws
                client.ws = ws
                client.is_connected = true
                start_message_handler(client)
                put!(connected, true)  # Signal connection is ready

                # Keep connection alive until closed
                while client.is_connected && !WebSockets.isclosed(ws)
                    sleep(0.1)
                end
            end
        end

        # Wait for connection to be established
        if !take!(connected)
            error("Failed to establish WebSocket connection")
        end

        # Enable necessary domains after connection is confirmed
        send_cdp_message(client, "Page.enable")
        send_cdp_message(client, "Runtime.enable")

        return client
    catch e
        error("Failed to connect to Chrome: $e")
    end
end

export connect_browser
