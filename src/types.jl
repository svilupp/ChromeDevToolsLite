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

"""
    ElementNotFoundError(msg::String)

Thrown when an element cannot be found in the DOM.
"""
struct ElementNotFoundError <: Exception
    msg::String
end

"""
    NavigationError(msg::String)

Thrown when page navigation fails.
"""
struct NavigationError <: Exception
    msg::String
end

"""
    EvaluationError(msg::String)

Thrown when JavaScript evaluation fails.
"""
struct EvaluationError <: Exception
    msg::String
end

"""
    TimeoutError(msg::String)

Thrown when an operation exceeds its timeout.
"""
struct TimeoutError <: Exception
    msg::String
end

"""
    ConnectionError(msg::String)

Thrown when browser connection fails.
"""
struct ConnectionError <: Exception
    msg::String
end

# Base operations
Base.show(io::IO, client::WSClient) = print(io, "WSClient(connected=$(client.is_connected))")
