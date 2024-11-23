# Examples

This guide showcases practical examples of using ChromeDevToolsLite's HTTP-based Chrome DevTools Protocol implementation.

## Basic Browser Operations
```julia
using ChromeDevToolsLite
using HTTP
using JSON3

# Connect to Chrome running with remote debugging enabled
browser = Browser("http://localhost:9222")

try
    # List all pages
    response = HTTP.get("$(browser.endpoint)/json/list")
    pages = [Page(Dict(pairs(p))) for p in JSON3.read(String(response.body))]
    println("Found $(length(pages)) pages")

    # Print information about each page
    for page in pages
        println("Page ID: $(page.id)")
        println("URL: $(page.url)")
        println("Title: $(page.title)")
    end
catch e
    if e isa HTTP.RequestError
        @error "Failed to connect to Chrome" exception=e
    else
        rethrow(e)
    end
end
```

## Page Navigation and JavaScript Execution
```julia
browser = Browser("http://localhost:9222")

try
    # Create a new page
    response = HTTP.get("$(browser.endpoint)/json/new")
    page = Page(Dict(pairs(JSON3.read(String(response.body)))))
    println("Created new page: $(page.id)")

    # Navigate to a website
    result = execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com"
    ))

    # Execute JavaScript to get page title
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => "document.title",
        "returnByValue" => true
    ))

    if haskey(result, "result") && haskey(result["result"], "value")
        println("Page title: ", result["result"]["value"])
    end

finally
    # Clean up
    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
end
```

## DOM Manipulation
```julia
browser = Browser("http://localhost:9222")

try
    # Create and navigate to a page
    response = HTTP.get("$(browser.endpoint)/json/new")
    page = Page(Dict(pairs(JSON3.read(String(response.body)))))

    # Navigate to a page with a form
    execute_cdp_method(browser, page, "Page.navigate", Dict(
        "url" => "https://example.com/form"
    ))

    # Fill a form using JavaScript
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const input = document.querySelector('input[name="username"]');
            input.value = 'testuser';
            input.dispatchEvent(new Event('input'));
        """,
        "returnByValue" => true
    ))

    if !haskey(result, "result")
        println("Error: ", get(result, "error", "Unknown error"))
    end

finally
    HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
end
```

For more details about supported features and limitations, see [HTTP Capabilities](assets/HTTP_CAPABILITIES.md).
