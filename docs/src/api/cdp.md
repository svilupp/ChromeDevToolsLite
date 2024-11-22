# CDP Implementation

```@docs
AbstractCDPMessage
CDPEvent
CDPRequest
CDPResponse
CDPSession
AbstractWebSocketConnection
WebSocketConnection
```

## Session Methods

```@docs
CDPSession(::AbstractWebSocketConnection)
send_message
create_cdp_message
parse_cdp_message
handle_cdp_error
get_next_message_id
add_event_listener
remove_event_listener
Base.close(::CDPSession)
```

## WebSocket Methods

```@docs
Base.write(::WebSocketConnection, ::String)
Base.read(::WebSocketConnection)
Base.isopen(::WebSocketConnection)
Base.close(::WebSocketConnection)
```

## Error Types

```@docs
ChromeDevToolsError
```

## Utilities

```@docs
retry_with_timeout
```
