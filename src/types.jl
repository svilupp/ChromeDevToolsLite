using HTTP.WebSockets
using JSON3

"""
    WSClient

WebSocket client for Chrome DevTools Protocol communication.
"""
mutable struct WSClient
    ws::Union{WebSocket, Nothing}
    ws_url::String
    is_connected::Bool
    message_channel::Channel{Dict{String, Any}}
    next_id::Int
    page_loaded::Bool

    WSClient(ws_url::String) = new(nothing, ws_url, false, Channel{Dict{String, Any}}(100), 1, false)
end

"""
    start_message_handler(client::WSClient)

Start asynchronous message handler for WebSocket client.
"""
function start_message_handler(client::WSClient)
    @async begin
        while client.is_connected && client.ws !== nothing
            try
                msg = String(receive(client.ws))
                response = JSON3.read(msg, Dict{String, Any})

                # Handle page load events
                if !haskey(response, "id")  # This is an event
                    if get(response, "method", "") == "Page.loadEventFired"
                        client.page_loaded = true
                    end
                    @debug "Received event" event=response
                    continue
                end

                # Handle command responses
                put!(client.message_channel, response)
            catch e
                if e isa WebSocketError && e.status == 1000  # Normal closure
                    @debug "WebSocket closed normally"
                    break
                else
                    @error "Message handler error" exception=e
                end
                client.is_connected = false
                break
            end
        end
        client.is_connected = false
    end
end

"""
    send_cdp_message(client::WSClient, method::String, params::Dict{String,Any}=Dict{String,Any}())

Send a CDP command to the browser.
"""
function send_cdp_message(client::WSClient, method::String, params::Dict{String,Any}=Dict{String,Any}(); timeout::Float64=5.0)
    if !client.is_connected || isnothing(client.ws)
        error("WebSocket not connected")
    end

    id = client.next_id
    client.next_id += 1

    # Reset page_loaded flag when navigating
    if method == "Page.navigate"
        client.page_loaded = false
    end

    message = Dict{String,Any}(
        "id" => id,
        "method" => method,
        "params" => params
    )

    @debug "Sending CDP message" id method params
    send(client.ws, JSON3.write(message))

    # Wait for response with matching id with timeout
    start_time = time()
    while (time() - start_time) < timeout
        if isready(client.message_channel)
            response = take!(client.message_channel)
            @debug "Received response" response
            if haskey(response, "id") && response["id"] == id
                if haskey(response, "error")
                    error("CDP Error: $(response["error"])")
                end
                if haskey(response, "result")
                    @debug "Command result" result=response["result"]
                end
                return response
            end
            # If not our response, put it back
            put!(client.message_channel, response)
        end
        sleep(0.1)  # Small sleep to prevent busy waiting
    end
    error("Timeout waiting for response to CDP command: $method")
end

"""
    close(client::WSClient)

Close the WebSocket connection.
"""
function close(client::WSClient)
    if client.is_connected && !isnothing(client.ws)
        client.is_connected = false
        try
            close(client.ws)
        catch e
            @debug "Error during WebSocket closure" exception=e
        end
        client.ws = nothing
    end
end

export WSClient, start_message_handler, send_cdp_message, close
