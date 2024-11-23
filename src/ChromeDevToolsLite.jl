"""
    ChromeDevToolsLite

A lightweight Julia implementation of Chrome DevTools Protocol client.

# Features
- Browser automation and control via Chrome DevTools Protocol
- Element interaction and manipulation
- Page navigation and JavaScript evaluation
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

const MAX_RETRIES = 3
const RETRY_DELAY = 2.0
const CONNECTION_TIMEOUT = 5.0

# Import Base operations
import Base: close, show

export extract_cdp_result, extract_element_result, with_retry
include("utils.jl")

# Include types first
export WSClient, ElementHandle, Page
export ElementNotFoundError, NavigationError, EvaluationError, TimeoutError, ConnectionError
include("types.jl")

# Include core functionality
export connect!, send_cdp_message, send_command, close, handle_event, is_connected, try_connect
include("websocket.jl")

export connect_browser, ensure_browser_available
include("browser.jl")

export goto, evaluate, screenshot, content
include("page.jl")

# Include input functionality before element handling
export click, dblclick, move_mouse, get_mouse_position, press_key, type_text
include("input.jl")

export check, uncheck, select_option, is_visible, get_text, get_attribute, evaluate_handle
include("element.jl")

end
