# Basic types for ChromeDevToolsLite

"""
    Browser(endpoint::String)

Represents a connection to a Chrome browser instance running with remote debugging enabled.

# Fields
- `endpoint::String`: The HTTP endpoint where Chrome is listening for CDP commands (e.g., "http://localhost:9222")

# Example
```julia
browser = Browser("http://localhost:9222")
```
"""
struct Browser
    endpoint::String
    function Browser(endpoint::String)
        if isempty(endpoint)
            throw(ArgumentError("Browser endpoint cannot be empty"))
        end
        new(endpoint)
    end
end

"""
    Page(id::String, type::String, url::String, title::String, ws_debugger_url::String, dev_tools_frontend_url::String)

Represents a Chrome page/tab with its associated debugging information.

# Fields
- `id::String`: Unique identifier for the page
- `type::String`: Type of the target (usually "page")
- `url::String`: Current URL of the page
- `title::String`: Page title
- `ws_debugger_url::String`: WebSocket URL for debugging (unused in HTTP-only implementation)
- `dev_tools_frontend_url::String`: URL for Chrome DevTools frontend

See also: [`new_page`](@ref), [`close_page`](@ref)
"""
struct Page
    id::String
    type::String
    url::String
    title::String
    ws_debugger_url::String
    dev_tools_frontend_url::String
end

"""
    Page(data::Dict) -> Page

Construct a Page instance from a dictionary of CDP response data.

# Arguments
- `data::Dict`: Dictionary containing page information from CDP response

# Returns
- `Page`: A new Page instance initialized with the provided data
"""
function Page(data::Dict)
    Page(
        get(data, "id", ""),
        get(data, "type", ""),
        get(data, "url", ""),
        get(data, "title", ""),
        get(data, "webSocketDebuggerUrl", ""),
        get(data, "devtoolsFrontendUrl", "")
    )
end

"""
    Base.show(io::IO, browser::Browser)

Custom display for Browser instances.

# Arguments
- `io::IO`: The I/O stream to write to
- `browser::Browser`: The Browser instance to display
"""
function Base.show(io::IO, browser::Browser)
    print(io, "Browser(endpoint=\"$(browser.endpoint)\")")
end
