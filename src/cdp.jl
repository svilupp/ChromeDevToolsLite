# Core CDP commands for Chrome DevTools Protocol
using Base64
using JSON3

# This file only contains core CDP message handling functionality
# All high-level commands are in commands.jl

"""
    send_cdp_message(client::ChromeClient, message::Dict) -> Dict

Send a CDP message and wait for its response. Messages are identified by their ID.
"""
function send_cdp_message(client::ChromeClient, message::Dict)
    if !haskey(message, "id")
        message = Dict(message..., "id" => client.message_id[])
        client.message_id[] += 1
    end

    msg_str = JSON3.write(message)

    if !isopen(client.ws)
        error("WebSocket connection is closed")
    end

    HTTP.send(client.ws, msg_str)

    # Keep reading messages until we get the matching response
    while isopen(client.ws)
        response_str = String(HTTP.WebSockets.receive(client.ws))
        response = JSON3.read(response_str, Dict)

        # Return if we get a matching response ID
        if haskey(response, "id") && response["id"] == message["id"]
            return response
        end

        # Skip event messages
        if haskey(response, "method")
            continue
        end
    end

    error("WebSocket closed before receiving response")
end
