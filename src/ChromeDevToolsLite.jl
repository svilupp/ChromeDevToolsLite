module ChromeDevToolsLite

using HTTP, JSON3
import Base: show

# Export types and functions
export Browser, Page, show, execute_cdp_method, new_page, close_page, get_pages, verify_page_state, batch_update_elements

# Include type definitions and core functionality
include("types.jl")
include("core.jl")

end # module
