module TestUtils

using ChromeDevToolsLite: AbstractWebSocketConnection

# Mock WebSocket for testing
mutable struct MockWebSocket <: AbstractWebSocketConnection
    io::IOBuffer
    is_closed::Bool
end

# Constructor
function MockWebSocket()
    io = IOBuffer()
    MockWebSocket(io, false)
end

# Required interface methods
Base.close(ws::MockWebSocket) = (ws.is_closed = true; nothing)
Base.isopen(ws::MockWebSocket) = !ws.is_closed
Base.write(ws::MockWebSocket, data) = write(ws.io, data)
Base.read(ws::MockWebSocket) = String(take!(ws.io))

export MockWebSocket

end
