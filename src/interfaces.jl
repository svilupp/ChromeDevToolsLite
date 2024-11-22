"""
    AbstractWebSocketConnection

Abstract type for WebSocket connections used in ChromeDevToolsLite.
"""
abstract type AbstractWebSocketConnection end

# Required interface methods that must be implemented:
# Base.close(ws::AbstractWebSocketConnection)
# Base.isopen(ws::AbstractWebSocketConnection)
# Base.write(ws::AbstractWebSocketConnection, data)
# Base.read(ws::AbstractWebSocketConnection)

export AbstractWebSocketConnection
