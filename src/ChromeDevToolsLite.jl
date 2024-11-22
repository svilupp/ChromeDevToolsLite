module ChromeDevToolsLite

using WebSockets
using JSON3
using Sockets
using Base64

# Forward declarations
abstract type AbstractBrowser end
abstract type AbstractBrowserContext end
abstract type AbstractPage end
abstract type AbstractElementHandle end
abstract type AbstractWebSocketConnection end

# Export abstract types
export AbstractBrowser, AbstractBrowserContext, AbstractPage, AbstractElementHandle, AbstractWebSocketConnection

# Types
export Browser, BrowserContext, Page, ElementHandle,
       create_page, close, goto, url, get_title, screenshot,
       is_visible, count_elements, get_text, get_value, is_checked, select_option, submit_form,
       set_file_input_files

# CDP Types and Functions
export AbstractCDPMessage, CDPRequest, CDPResponse, CDPEvent,
       create_cdp_message, parse_cdp_message,
       CDPSession, send_message, add_event_listener, remove_event_listener,
       base64decode  # Export the specific function we need

# Browser Process Management
export BrowserProcess, launch_browser_process, kill_browser_process

# Include type definitions and utilities
include("utils/errors.jl")  # Include errors first as it contains TimeoutError
include("utils/retry.jl")
include("types/websocket_interface.jl")
include("cdp/messages.jl")
include("cdp/session.jl")
include("browser/process.jl")
include("types/browser.jl")
include("types/page.jl")  # Move page.jl before browser_context.jl
include("types/browser_context.jl")
include("types/element_handle.jl")
include("page/file_input.jl")
include("page/selectors.jl")  # Add selectors.jl after page.jl

end
