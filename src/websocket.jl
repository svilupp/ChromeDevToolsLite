using HTTP.WebSockets
using JSON3
using Base.Threads: @async
using Logging

# Simple WebSocket open implementation
function open(url::String; kw...)
    try
        WebSockets.open(url; kw...)
    catch e
        @error "WebSocket connection failed" exception=e
        rethrow(e)
    end
end

"""
    handle_event(client::WSClient, event::Dict)

Process CDP events.
"""
function handle_event(client::WSClient, event::Dict)
    try
        method = get(event, "method", nothing)
        if !isnothing(method)
            if method == "Page.loadEventFired"
                put!(client.message_channel, event)
            end
            # Add more event handlers as needed
        end
    catch e
        if isa(e, WebSocketError) && e.status == 1000
            # Normal close, ignore
            @debug "WebSocket closed normally"
            return
        else
            # Real error, rethrow
            rethrow(e)
        end
    end
end

export open, handle_event
