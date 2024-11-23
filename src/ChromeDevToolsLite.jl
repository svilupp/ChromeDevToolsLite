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
export WSClient, connect_cdp, send_cdp_message
export goto, evaluate, screenshot, content
export ElementHandle, click, type_text, check, uncheck, select_option, is_visible, get_text, get_attribute, evaluate_handle

end
