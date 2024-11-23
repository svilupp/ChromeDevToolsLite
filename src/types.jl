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

    function WSClient(ws_url::String)
        new(nothing, ws_url, false, Channel{Dict{String, Any}}(100), 1, false)
    end
end