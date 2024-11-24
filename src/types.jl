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
- `endpoint::String`: The debugging endpoint URL
"""
@kwdef mutable struct WSClient
    ws::Union{WebSocket, Nothing}
    ws_url::String
    is_connected::Bool
    message_channel::Channel{Dict{String, Any}}
    next_id::Int
    page_loaded::Bool
    endpoint::String

    function WSClient(ws_url::String, endpoint::String = "")
        new(nothing, ws_url, false, Channel{Dict{String, Any}}(100), 1, false, endpoint)
    end
end
Base.show(io::IO, client::WSClient) = print(io, "WSClient(url: $(client.ws_url))")

"""
    Browser

Alias for `WSClient`.
"""
const Browser = WSClient

"""
    Page

Represents a browser page/tab with its associated WebSocket client.

# Fields
- `client::WSClient`: The WebSocket client for communication
- `target_id::String`: The unique identifier for this page/tab
- `extras::Dict{String, Any}`: Additional page metadata refreshed on demand. It might be stale/inaccurate - run `update_page!` to refresh it.
"""
@kwdef mutable struct Page
    client::WSClient
    target_id::String
    extras::Dict{String, Any}
end
# Enhanced show method for Page type
function Base.show(io::IO, page::Page)
    url = get(page.extras, "url", "-")
    print(io, "Page(id: $(page.target_id), url: $url)")
end
function is_active(page::Page)
    get(page.extras, "attached", false)
end

"""
    Page

Represents a browser page/tab with its associated WebSocket client.

# Fields
- `client::WSClient`: The WebSocket client for communication
- `target_id::String`: The unique identifier for this page/tab
- `extras::Dict{String, Any}`: Additional page metadata
"""
struct Page
    client::WSClient
    target_id::String
    extras::Dict{String, Any}
end

"""
    ElementHandle

Represents a handle to a DOM element in the browser.
"""
@kwdef struct ElementHandle
    client::WSClient
    selector::String
    verbose::Bool = false
    function ElementHandle(client::WSClient, selector::String; verbose::Bool = false)
        new(client, selector, verbose)
    end
end
Base.show(io::IO, eh::ElementHandle) = print(io, "ElementHandle(selector: $(eh.selector))")
function ElementHandle(page::Page, selector::String; verbose::Bool = false)
    ElementHandle(page.client, selector, verbose)
end

### Errors

"""
    ElementNotFoundError

Thrown when an element cannot be found in the DOM using the specified selector.
"""
struct ElementNotFoundError <: Exception
    selector::String
    message::String
    ElementNotFoundError(selector::String) = new(selector, "Element not found: $selector")
end

"""
    NavigationError

Thrown when a page navigation fails or times out.
"""
struct NavigationError <: Exception
    url::String
    message::String
    NavigationError(url::String, msg::String = "Navigation failed") = new(url, "$msg: $url")
end

"""
    EvaluationError

Thrown when JavaScript evaluation in the browser fails.
"""
struct EvaluationError <: Exception
    script::String
    message::String
    function EvaluationError(script::String, msg::String = "Evaluation failed")
        new(script, "$msg\nScript: $script")
    end
end

"""
    TimeoutError

Thrown when an operation exceeds its time limit.
"""
struct TimeoutError <: Exception
    message::String
    TimeoutError(msg::String = "Operation timed out") = new(msg)
end

"""
    ConnectionError

Thrown when there are issues with the WebSocket connection.
"""
struct ConnectionError <: Exception
    message::String
    ConnectionError(msg::String = "Connection failed") = new(msg)
end
