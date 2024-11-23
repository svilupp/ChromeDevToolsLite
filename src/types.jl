# Basic types for ChromeDevToolsLite

"""
    Browser(endpoint::String) -> Browser

Represents a connection to a Chrome browser instance running with remote debugging enabled.

# Arguments
- `endpoint::String`: The HTTP endpoint where Chrome is listening for CDP commands (e.g., "http://localhost:9222")

# Returns
- `Browser`: A new Browser instance initialized with the provided endpoint

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
    Page(id::String, type::String, url::String, title::String, ws_debugger_url::String, dev_tools_frontend_url::String) -> Page
    Page(data::Dict) -> Page

Represents a Chrome page/tab with its associated debugging information.

# Arguments
- `id::String`: Unique identifier for the page
- `type::String`: Type of the target (usually "page")
- `url::String`: Current URL of the page
- `title::String`: Page title
- `ws_debugger_url::String`: WebSocket URL for debugging (unused in HTTP-only implementation)
- `dev_tools_frontend_url::String`: URL for Chrome DevTools frontend
- `data::Dict`: Dictionary containing page information from CDP response

# Returns
- `Page`: A new Page instance initialized with the provided parameters

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
