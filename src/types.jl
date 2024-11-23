using HTTP.WebSockets
using JSON3
using Logging

const MAX_RECONNECT_ATTEMPTS = 3
const RECONNECT_DELAY = 2.0

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

export WSClient
