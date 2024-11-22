module ChromeDevToolsLite

using HTTP, JSON3

# Core types
struct Browser
    endpoint::String
end

struct Page
    id::String
    url::String
    title::String
end

# Core functions
export Browser, Page
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

end # module
