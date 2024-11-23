"""
    ChromeDevToolsLite

A lightweight Julia implementation of Chrome DevTools Protocol client.

# Features
- Browser automation and control
- Element interaction and manipulation
- Page navigation and evaluation
- Screenshot capture

# Configuration
All functions accept a `verbose` flag to control logging output:
- `verbose=true`: Enables detailed logging with @info and @debug messages
- `verbose=false` (default): Suppresses informational logging

Example:
```julia
client = connect_browser(verbose=true)
element = ElementHandle(client, "#my-button", verbose=true)
click(element)
```
"""
module ChromeDevToolsLite

using HTTP
using JSON3
using HTTP.WebSockets
import HTTP.WebSockets: WebSocketError
using Logging

const MAX_RECONNECT_ATTEMPTS = 3
const RECONNECT_DELAY = 2.0
const CONNECTION_TIMEOUT = 5.0

# Import Base operations
import Base: close, show

export extract_cdp_result, extract_element_result
include("utils.jl")

# Include types first
export WSClient
include("types.jl")

# Include core functionality
export connect!, send_cdp_message, close, handle_event, is_connected, try_connect
# export start_message_handler
include("websocket.jl")

export connect_browser
export ensure_chrome_running, get_ws_id
include("browser.jl")

export goto, evaluate, screenshot, content
include("page.jl")

export ElementHandle, click, type_text, check, uncheck, select_option,
       is_visible, get_text, get_attribute, evaluate_handle
include("element.jl")

end
