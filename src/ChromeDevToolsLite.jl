module ChromeDevToolsLite

using WebSockets
using HTTP
using JSON3
using Sockets
using Base64
using Base.Threads

# Export abstract types
export AbstractBrowser, AbstractBrowserContext, AbstractPage, AbstractElementHandle,
       AbstractBrowserProcess, AbstractWebSocketConnection, AbstractCDPSession
include("interfaces.jl")

# Include type definitions and utilities
export ChromeDevToolsError, ConnectionError, NavigationError, ElementNotFoundError,
       EvaluationError, TimeoutError
export handle_cdp_error
include("utils/errors.jl")

export with_timeout, retry_with_timeout
include("utils/timeout.jl")

# Types
export Browser, BrowserContext, Page, ElementHandle,
       create_page, goto, url, get_title, screenshot,
       is_visible, count_elements, get_text, get_value, is_checked, select_option,
       submit_form,
       set_file_input_files

# CDP Types and Functions
export AbstractCDPMessage, CDPRequest, CDPResponse, CDPEvent,
       create_cdp_message, parse_cdp_message,
       CDPSession, send_message, add_event_listener, remove_event_listener,
       base64decode  # Export the specific function we need

export WebSocketConnection, AbstractWebSocketConnection
include("types/websocket_interface.jl")
include("cdp/messages.jl")
include("cdp/session.jl")

# Browser Process Management
export BrowserProcess, launch_browser_process, kill_browser_process, find_process_id
include("browser/process.jl")
include("types/browser.jl")
include("types/page.jl")  # Move page.jl before browser_context.jl
include("types/browser_context.jl")
include("types/element_handle.jl")
include("page/file_input.jl")
include("page/selectors.jl")  # Add selectors.jl after page.jl

# Include Base operations implementations
include("base_operations.jl")

# Import and export Base operations
import Base: close, show

end
