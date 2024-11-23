"""
    WSClient

WebSocket client for Chrome DevTools Protocol communication.

# Fields
- `ws::Union{WebSocket, Nothing}`: The WebSocket connection or nothing if not connected
- `ws_url::String`: The WebSocket URL to connect to
- `is_connected::Bool`: Connection status flag
- `message_channel::Channel{Dict{String, Any}}`: Channel for message communication
- `next_id::Int`: Counter for message IDs
- `page_loaded::Bool`: Flag indicating if the page has finished loading
"""
mutable struct WSClient
    ws::Union{WebSocket, Nothing}
    ws_url::String
    is_connected::Bool
    message_channel::Channel{Dict{String, Any}}
    next_id::Int
    page_loaded::Bool

    function WSClient(ws_url::String)
        new(nothing, ws_url, false, Channel{Dict{String, Any}}(100), 1, false)
    end
end

"""
    ElementHandle

Represents a handle to a DOM element in the browser.
"""
struct ElementHandle
    client::WSClient
    selector::String
    verbose::Bool
    function ElementHandle(client::WSClient, selector::String; verbose::Bool = false)
        new(client, selector, verbose)
    end
end