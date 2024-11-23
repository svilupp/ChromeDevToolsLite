# Core CDP functionality over HTTP

"""
    execute_cdp_method(browser::Browser, page::Page, method::String, params::Dict=Dict()) -> Dict

Execute any CDP method via HTTP protocol endpoint. Some methods may not work if they require WebSocket connections.
See HTTP_CAPABILITIES.md for details on supported features.
"""
function execute_cdp_method(browser::Browser, page::Page, method::String, params::Dict=Dict())
    if isempty(method)
        throw(ArgumentError("CDP method name cannot be empty"))
    end

    # Validate page is still active
    if !any(p -> p.id == page.id, get_pages(browser))
        throw(ArgumentError("Page $(page.id) is no longer active"))
    end

    # Construct the CDP message
    message = Dict(
        "id" => 1,
        "method" => method,
        "params" => params
    )

    try
        # Execute CDP method via HTTP endpoint
        response = HTTP.post(
            "$(browser.endpoint)/json/protocol/$(page.id)",
            ["Content-Type" => "application/json"],
            JSON3.write(message),
            retry = false,
            readtimeout = 30
        )

        # Parse and validate the result
        result = JSON3.read(String(response.body))
        if haskey(result, "error")
            error_data = result["error"]
            @warn "CDP method error" method=method error=error_data params=params
            if haskey(error_data, "message") && occursin("WebSocket connection", error_data["message"])
                throw(ArgumentError("Method $method requires WebSocket connection. See HTTP_CAPABILITIES.md"))
            end
        end
        return result
    catch e
        if e isa HTTP.ExceptionRequest.StatusError
            if e.status == 404
                throw(ArgumentError("Method $method failed. This might be because it requires WebSocket connection. See HTTP_CAPABILITIES.md"))
            elseif e.status == 500
                throw(ErrorException("Internal CDP error executing $method. Check browser console for details."))
            else
                throw(ArgumentError("HTTP error ($(e.status)) executing $method: $(e.message)"))
            end
        elseif e isa HTTP.TimeoutError
            throw(ErrorException("Timeout executing $method. The operation took too long to complete."))
        end
        rethrow(e)
    end
end

"""
    verify_page_state(browser::Browser, page::Page, timeout::Number=5) -> Union{Dict, Nothing}

Verify the page load state and return page metrics. Returns nothing if verification fails or times out.
"""
function verify_page_state(browser::Browser, page::Page, timeout::Number=5)
    start_time = time()
    while (time() - start_time) < timeout
        result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
            "expression" => """
                ({
                    ready: document.readyState === 'complete',
                    url: window.location.href,
                    title: document.title,
                    metrics: {
                        links: document.querySelectorAll('a').length,
                        forms: document.querySelectorAll('form').length
                    }
                })
            """,
            "returnByValue" => true
        ))
        if !haskey(result, "error") && result["result"]["value"]["ready"]
            return result["result"]["value"]
        end
        sleep(0.1)
    end
    return nothing
end

"""
    batch_update_elements(browser::Browser, page::Page, updates::Dict) -> Dict

Update multiple DOM elements in a single CDP call. Returns a dictionary of success/failure status for each selector.
"""
function batch_update_elements(browser::Browser, page::Page, updates::Dict)
    result = execute_cdp_method(browser, page, "Runtime.evaluate", Dict(
        "expression" => """
            const updates = $(JSON3.write(updates));
            const results = {};
            for (const [selector, value] of Object.entries(updates)) {
                const el = document.querySelector(selector);
                if (el) {
                    el.value = value;
                    el.dispatchEvent(new Event('input'));
                    results[selector] = true;
                } else {
                    results[selector] = false;
                }
            }
            return results;
        """,
        "returnByValue" => true
    ))

    if haskey(result, "error")
        throw(ErrorException("Failed to batch update elements: $(result["error"])"))
    end
    return result["result"]["value"]
end

"""
    new_page(browser::Browser, url::String="about:blank") -> Page

Create a new page and optionally navigate to the specified URL.
"""
function new_page(browser::Browser, url::String="about:blank")
    try
        response = HTTP.get("$(browser.endpoint)/json/new?url=$(HTTP.escapeuri(url))")
        Page(Dict(pairs(JSON3.read(String(response.body)))))
    catch e
        throw(ErrorException("Failed to create new page: $(e.message)"))
    end
end

"""
    close_page(browser::Browser, page::Page)

Close the specified page.
"""
function close_page(browser::Browser, page::Page)
    try
        HTTP.get("$(browser.endpoint)/json/close/$(page.id)")
        nothing
    catch e
        @warn "Failed to close page: $(e.message)"
        nothing
    end
end

"""
    get_pages(browser::Browser) -> Vector{Page}

Get a list of all pages in the browser. Throws ErrorException if the browser is not accessible
or if the request fails.
"""
function get_pages(browser::Browser)
    try
        response = HTTP.get("$(browser.endpoint)/json/list", retry=false, readtimeout=5)
        [Page(Dict(pairs(p))) for p in JSON3.read(String(response.body))]
    catch e
        if e isa HTTP.TimeoutError
            throw(ErrorException("Browser at $(browser.endpoint) is not responding"))
        else
            throw(ErrorException("Failed to list pages: $(e.message)"))
        end
    end
end
