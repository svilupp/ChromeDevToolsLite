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
    ws::WebSocket
    is_open::Bool
    task::Union{Task, Nothing}
    verbose::Bool
end

WebSocketConnection(ws::WebSocket; verbose::Bool=false) = WebSocketConnection(ws, true, nothing, verbose)

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
    Base.write(conn::WebSocketConnection, data::AbstractString)

Send data through the WebSocket connection.
"""
function Base.write(conn::WebSocketConnection, data::AbstractString)
    conn.verbose && @info "Writing to WebSocket" data_length=length(data)
    try
        WebSockets.send(conn.ws, data)
    catch e
        conn.is_open = false
        error("Failed to write to WebSocket (connection may be closed): $e")
    end
end

"""
    Base.read(conn::WebSocketConnection) -> AbstractString

Read data from the WebSocket connection.
"""
function Base.read(conn::WebSocketConnection)
    conn.verbose && @info "Reading from WebSocket"
    try
        data = String(WebSockets.receive(conn.ws))
        conn.verbose && @info "Received data from WebSocket" data_length=length(data)
        return data
    catch e
        conn.is_open = false
        error("Failed to read from WebSocket (connection may be closed): $e")
    end
end

"""
    Base.close(conn::WebSocketConnection)

Close the WebSocket connection.
"""
function Base.close(conn::WebSocketConnection)
    conn.verbose && @info "Closing WebSocket connection"
    try
        conn.is_open = false
        WebSockets.close(conn.ws)
        conn.verbose && @info "WebSocket connection closed successfully"
    catch e
        @warn "Error while closing WebSocket connection" exception=(e, catch_backtrace())
    end
end

export WebSocketConnection, AbstractWebSocketConnection
