# Basic types for ChromeDevToolsLite

"""
    Browser

Represents a connection to a Chrome browser instance.
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
    Page

Represents a Chrome page/tab.
"""
struct Page
    id::String
    type::String
    url::String
    title::String
    ws_debugger_url::String
    dev_tools_frontend_url::String
end

# Constructor for Page from JSON response
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
