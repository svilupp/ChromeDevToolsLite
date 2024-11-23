module ChromeDevToolsLite

using HTTP, JSON3
import Base: show

# Export types and functions
export Browser, Page, show, execute_cdp_method, connect_browser, new_page, close_page, get_pages, verify_page_state, batch_update_elements

# Include type definitions and core functionality
include("types.jl")
include("core.jl")

"""
    connect_browser(endpoint::String="http://localhost:9222") -> Browser

Connect to a Chrome instance running with remote debugging enabled.
Throws an error if Chrome is not accessible or not running with --remote-debugging-port.
"""
function connect_browser(endpoint::String="http://localhost:9222")
    try
        response = HTTP.get("$endpoint/json/version", readtimeout=5)
        if response.status == 200
            return Browser(endpoint)
        end
        error("Failed to connect to Chrome at $endpoint. Invalid response: $(response.status)")
    catch e
        error("Failed to connect to Chrome at $endpoint. Make sure Chrome is running with --remote-debugging-port enabled. Error: $(e.message)")
    end
end

end # module
