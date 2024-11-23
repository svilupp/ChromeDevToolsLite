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
    ElementNotFoundError(msg::String)

Exception thrown when an element cannot be found in the DOM.

# Fields
- `msg::String`: Error message describing why the element was not found
"""
struct ElementNotFoundError <: Exception
    msg::String
end

"""
    NavigationError(msg::String)

Exception thrown when page navigation fails.

# Fields
- `msg::String`: Error message describing the navigation failure
"""
struct NavigationError <: Exception
    msg::String
end

"""
    EvaluationError(msg::String)

Exception thrown when JavaScript evaluation fails.

# Fields
- `msg::String`: Error message describing the evaluation failure
"""
struct EvaluationError <: Exception
    msg::String
end

"""
    TimeoutError(msg::String)

Exception thrown when an operation exceeds its timeout.

# Fields
- `msg::String`: Error message describing what operation timed out
"""
struct TimeoutError <: Exception
    msg::String
end

"""
    ConnectionError(msg::String)

Exception thrown when browser connection fails.

# Fields
- `msg::String`: Error message describing the connection failure
"""
struct ConnectionError <: Exception
    msg::String
end

# Base operations
"""
    Base.show(io::IO, client::WSClient)

Display a WSClient instance, showing its connection status.
"""
Base.show(io::IO, client::WSClient) = print(io, "WSClient(connected=$(client.is_connected))")
