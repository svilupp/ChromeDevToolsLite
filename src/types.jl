# Core types for ChromeDevToolsLite

"""
    ChromeClient

Represents a connection to Chrome DevTools Protocol.
"""
struct ChromeClient
    ws::HTTP.WebSockets.WebSocket
    message_id::Base.RefValue{Int}
end

# Constructor that initializes message_id
function ChromeClient(ws::HTTP.WebSockets.WebSocket)
    ChromeClient(ws, Ref(1))
end
