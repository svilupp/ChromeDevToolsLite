"""
ChromeDevToolsLite.jl - A lightweight Julia interface to Chrome DevTools Protocol
"""
module ChromeDevToolsLite

using HTTP
using JSON3
using HTTP.WebSockets

# Import Base operations
import Base: close, show

# Include types first
include("types.jl")

# Include core functionality
include("websocket.jl")
include("browser.jl")
include("page.jl")
include("element.jl")

# Export core functionality
"""
    WSClient

WebSocket client for Chrome DevTools Protocol communication.
"""
export WSClient

"""
    connect_cdp(endpoint::String) -> WSClient

Connect to Chrome DevTools Protocol at the specified WebSocket endpoint.
"""
export connect_cdp

"""
    send_cdp_message(client::WSClient, method::String, params::Dict{String,Any}=Dict{String,Any}()) -> Dict

Send a CDP command to Chrome and return the response.
"""
export send_cdp_message, connect!

"""
    goto(client::WSClient, url::String)
    evaluate(client::WSClient, script::String)
    screenshot(client::WSClient)
    content(client::WSClient)

Core page manipulation functions.
"""
export goto, evaluate, screenshot, content

"""
    ElementHandle

Represents a DOM element in the page.

Available operations:
- click(element::ElementHandle)
- type_text(element::ElementHandle, text::String)
- check(element::ElementHandle)
- uncheck(element::ElementHandle)
- select_option(element::ElementHandle, value::String)
- is_visible(element::ElementHandle)
- get_text(element::ElementHandle)
- get_attribute(element::ElementHandle, name::String)
- evaluate_handle(element::ElementHandle, expression::String)
"""
export ElementHandle, click, type_text, check, uncheck, select_option, is_visible, get_text, get_attribute, evaluate_handle

end
