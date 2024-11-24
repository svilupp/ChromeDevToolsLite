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
import Base: close, show
using Logging

const MAX_RETRIES = 3
const RETRY_DELAY = 2.0
const CONNECTION_TIMEOUT = 5.0

export extract_cdp_result, extract_element_result, with_retry
include("utils.jl")

# Include base types first
export WSClient, ElementHandle, Page
export ElementNotFoundError, NavigationError, EvaluationError, TimeoutError, ConnectionError
include("types.jl")

# Include core functionality that depends on types
export connect!, send_cdp, close, handle_event, is_connected, try_connect
include("websocket.jl")

# Include page functionality
export goto, evaluate, screenshot, content
export get_target_info, update_page!, get_page_info, get_page
export get_viewport, set_viewport, query_selector, query_selector_all, get_element_info
export new_context, new_page, get_all_pages
include("page.jl")

export connect_browser, ensure_browser_available
include("browser.jl")

include("browser_context.jl")

# Include input functionality before element handling
export click, dblclick, move_mouse, get_mouse_position, press_key, type_text, get_element_position
include("input.jl")

export check, uncheck, select_option, is_visible, get_text, get_attribute, evaluate_handle
include("element.jl")

end
