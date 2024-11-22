"""
    AbstractWebSocketConnection

Abstract type for WebSocket-like connections.
"""
abstract type AbstractWebSocketConnection end

"""
    WebSocketConnection

Wraps a WebSocket connection with CDP-specific functionality.
"""
mutable struct WebSocketConnection <: AbstractWebSocketConnection
    ws::HTTP.WebSockets.WebSocket
    is_open::Bool
    task::Union{Task, Nothing}
end

WebSocketConnection(ws::HTTP.WebSockets.WebSocket) = WebSocketConnection(ws, true, nothing)

"""
    Base.isopen(conn::WebSocketConnection) -> Bool

Check if the WebSocket connection is open.
"""
function Base.isopen(conn::WebSocketConnection)
    try
        return conn.is_open && !isnothing(conn.task) && !istaskdone(conn.task)
    catch e
        @warn "Error checking WebSocket connection status: $e"
        return false
    end
end

"""
    Base.write(conn::WebSocketConnection, data::String)

Send data through the WebSocket connection.
"""
function Base.write(conn::WebSocketConnection, data::String)
    try
        HTTP.WebSockets.send(conn.ws, data)
    catch e
        conn.is_open = false
        error("Failed to write to WebSocket: $e")
    end
end

"""
    Base.read(conn::WebSocketConnection) -> String

Read data from the WebSocket connection.
"""
function Base.read(conn::WebSocketConnection)
    try
        return String(HTTP.WebSockets.receive(conn.ws))
    catch e
        conn.is_open = false
        error("Failed to read from WebSocket: $e")
    end
end

"""
    Base.close(conn::WebSocketConnection)

Close the WebSocket connection.
"""
function Base.close(conn::WebSocketConnection)
    try
        conn.is_open = false
        HTTP.WebSockets.close(conn.ws)
    catch e
        @warn "Error closing WebSocket connection: $e"
    end
end

export WebSocketConnection, AbstractWebSocketConnection
