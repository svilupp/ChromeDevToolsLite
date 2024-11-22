module ChromeDevToolsLite

using HTTP, JSON3

"""
    Browser(endpoint::String)

Represents a connection to a Chrome browser instance running with remote debugging enabled.
The endpoint is typically "http://localhost:9222" when Chrome is started with --remote-debugging-port=9222.

Throws ArgumentError if endpoint is empty.
"""
struct Browser
    endpoint::String
    function Browser(endpoint::String)
        isempty(endpoint) && throw(ArgumentError("Browser endpoint cannot be empty"))
        new(endpoint)
    end
end

"""
    Page(id::String, url::String, title::String)

Represents a Chrome browser page/tab with its unique identifier, current URL, and title.
Used with Browser to execute CDP methods and manage browser tabs.
"""
struct Page
    id::String
    url::String
    title::String
end

# Core functions
export Browser, Page, execute_cdp_method
export connect_browser, new_page, get_pages, close_page

"""
    connect_browser(endpoint::String="http://localhost:9222") -> Browser

Connect to a Chrome instance running with remote debugging enabled.
"""
function connect_browser(endpoint::String="http://localhost:9222")
    try
        HTTP.get("$endpoint/json/version")
        Browser(endpoint)
    catch e
        error("Failed to connect to Chrome at $endpoint")
    end
end

"""
    get_pages(browser::Browser) -> Vector{Page}

List all available pages/tabs.
"""
function get_pages(browser::Browser)
    response = HTTP.get("$(browser.endpoint)/json/list")
    pages_data = JSON3.read(String(response.body))

    return [Page(
        page.id,
        page.url,
        page.title
    ) for page in pages_data]
end

"""
    new_page(browser::Browser) -> Page

Create a new empty page/tab.
"""
function new_page(browser::Browser)
    response = HTTP.put("$(browser.endpoint)/json/new")
    data = JSON3.read(String(response.body))

    Page(
        data.id,
        data.url,
        data.title
    )
end

"""
    close_page(browser::Browser, page::Page)

Close a page/tab.
"""
function close_page(browser::Browser, page::Page)
    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
end

"""
    execute_cdp_method(browser::Browser, page::Page, method::String, params::Dict=Dict()) -> Dict

Execute a Chrome DevTools Protocol method on a specific page via HTTP.

# Arguments
- `browser::Browser`: The browser instance
- `page::Page`: The page to execute the method on
- `method::String`: The CDP method name (e.g., "Page.navigate")
- `params::Dict`: Parameters for the CDP method (optional)

# Example
```julia
# Navigate to a URL
execute_cdp_method(browser, page, "Page.navigate", Dict("url" => "https://example.com"))

# Execute JavaScript
execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
    "expression" => "document.title",
    "returnByValue" => true
))
```
"""
function execute_cdp_method(browser::Browser, page::Page, method::String, params::Dict=Dict())
    endpoint = "$(browser.endpoint)/json/protocol/$(page.id)"

    payload = Dict(
        "method" => method,
        "params" => params,
        "id" => 1  # Request ID, could be made dynamic if needed
    )

    headers = ["Content-Type" => "application/json"]
    response = HTTP.post(endpoint, headers, JSON3.write(payload))

    result = JSON3.read(String(response.body))

    if haskey(result, "error")
        error("CDP Error: $(result.error)")
    end

    # Some CDP methods don't return a result
    if !haskey(result, "result")
        return Dict()
    end

    return result.result
end

"""
    Base.show(io::IO, browser::Browser)

Custom display for Browser instances, showing the endpoint URL.
"""
Base.show(io::IO, browser::Browser) = print(io, "Browser(endpoint=\"$(browser.endpoint)\")")

end # module
