# Export all public functions at the top of the file
export Page, goto, evaluate, wait_for_selector, query_selector, screenshot, url, get_title, content, click, type_text, query_selector_all, is_visible, count_elements, get_text, get_value, wait_for_load

using Base64

"""
    Page

Represents a single tab or page in the browser.

# Base Operations
- `Base.close(page::Page)`: Closes the page and cleans up resources
- `Base.show(io::IO, page::Page)`: Displays page information in the format "Page(id=session_id)"
"""
Base.@kwdef mutable struct Page <: AbstractPage
    context::AbstractBrowserContext
    session_id::AbstractString
    target_id::AbstractString
    options::Dict{String,<:Any} = Dict{String,<:Any}()
    verbose::Bool = false
end

# Default constructor that creates a new page in the context
function Page(context::AbstractBrowserContext)
    return create_page(context)
end

# Full constructor
function Page(context::AbstractBrowserContext, session_id::AbstractString, target_id::AbstractString,
             options::AbstractDict{String,<:Any}=Dict{String,<:Any}(); verbose::Bool=false)
    page = Page(context=context, session_id=session_id, target_id=target_id,
                options=Dict{String,<:Any}(options), verbose=verbose)
    # Enable required domains with timeout
    for domain in ["Page", "Runtime", "DOM"]
        enable_message = Dict{String,<:Any}(
            "sessionId" => session_id,
            "method" => "$(domain).enable",
            "params" => Dict{String,<:Any}(),
            "id" => get_next_message_id()
        )
        response_channel = send_message(context.browser.session, enable_message, timeout=10000)  # 10 second timeout
        try
            response = take!(response_channel)
            if !isnothing(response.error)
                error("Failed to enable $domain domain: $(response.error["message"])")
            end
        catch e
            if e isa InvalidStateException
                error("Timeout while enabling $domain domain")
            end
            rethrow(e)
        end
    end
    return page
end

"""
    Base.show(io::IO, page::Page)

Custom display for Page instances.
"""
function Base.show(io::IO, page::Page)
    print(io, "Page(id=$(page.session_id))")
end

"""
    goto(page::Page, url::AbstractString; options=Dict()) -> Nothing

Navigate the page to the specified URL and wait for navigation to complete.
"""
function goto(page::Page, url::AbstractString; options::AbstractDict{String,<:Any}=Dict{String,<:Any}())
    # Create a channel to track navigation completion
    nav_channel = Channel{Bool}(1)

    # Register navigation event listener
    callback = params -> begin
        page.verbose && @info "Navigation event received" params
        try
            put!(nav_channel, true)
        catch e
            @error "Failed to signal navigation" exception=e
        end
    end

    add_event_listener(page.context.browser.session, "Page.frameNavigated", callback)

    try
        # Send navigation request
        params = Dict{String,<:Any}("url" => url)
        request = create_cdp_message("Page.navigate", merge(params, options))
        message = Dict{String,<:Any}(
            "sessionId" => page.session_id,
            "method" => request.method,
            "params" => request.params,
            "id" => request.id
        )

        response_channel = send_message(page.context.browser.session, message)
        response = take!(response_channel)

        if !isnothing(response.error)
            error("Navigation failed: $(response.error["message"])")
        end

        # Wait for navigation to complete
        page.verbose && @info "Waiting for navigation to complete..."
        take!(nav_channel)
        page.verbose && @info "Navigation completed"

    finally
        remove_event_listener(page.context.browser.session, "Page.frameNavigated", callback)
    end

    nothing
end

"""
    wait_for_load(page::Page; timeout::Int=30000) -> Nothing

Waits for the page load event to fire.
"""
function wait_for_load(page::Page; timeout::Int=30000)
    # Create a channel to receive the load event
    load_channel = Channel{Bool}(1)

    # Create event handler
    callback = params -> begin
        page.verbose && @info "Load event callback triggered" params
        try
            put!(load_channel, true)
            page.verbose && @info "Load event signaled"
        catch e
            @error "Failed to signal load event" exception=e
        end
    end

    # Register event listener first
    event_name = "Page.loadEventFired"
    page.verbose && @info "Registering load event listener..." event_name
    add_event_listener(page.context.browser.session, event_name, callback)
    page.verbose && @info "Load event listener registered"

    # Enable Page events if not already enabled
    message = Dict{String,<:Any}(
        "sessionId" => page.session_id,
        "method" => "Page.enable",
        "params" => Dict{String,<:Any}(),
        "id" => get_next_message_id()
    )

    page.verbose && @info "Enabling Page events..."
    response_channel = send_message(page.context.browser.session, message)
    response = take!(response_channel)
    page.verbose && @info "Page events enabled" response

    result = try
        # Create timeout task
        timeout_task = @async begin
            sleep(timeout / 1000)
            if !isopen(load_channel)
                return
            end
            close(load_channel)
        end

        page.verbose && @info "Waiting for load event..."
        result = take!(load_channel)
        page.verbose && @info "Load event received" result

        # Clean up timeout task if it hasn't completed
        if !istaskdone(timeout_task)
            try
                schedule(timeout_task, InterruptException(); error=true)
            catch
                # Ignore any errors from canceling the timeout task
            end
        end

        result
    catch e
        if e isa InvalidStateException
            error("Page load timeout after $(timeout)ms")
        else
            error("Unexpected error in wait_for_load: $(e)")
        end
    finally
        # Clean up event listener
        page.verbose && @info "Cleaning up event listener..."
        remove_event_listener(page.context.browser.session, event_name, callback)
        page.verbose && @info "Event listener cleaned up"
    end

    nothing
end

"""
    evaluate(page::Page, expression::AbstractString) -> Any

Evaluates JavaScript code in the context of the page.
"""
function evaluate(page::Page, expression::AbstractString)
    page.verbose && @info "Evaluating JavaScript expression" expression

    # Only wrap in async IIFE if not already wrapped
    if !contains(expression, "async") && !contains(expression, "=>")
        # Wrap the code in a function if it contains return statements
        if contains(expression, "return")
            expression = "(function() { $expression })()"
        end

        # Add Promise handling
        expression = """
        (async () => {
            const result = $expression;
            if (result instanceof Promise) {
                return await result;
            }
            return result;
        })()
        """
    end

    params = Dict{String,<:Any}(
        "expression" => expression,
        "returnByValue" => true,
        "awaitPromise" => true  # This tells CDP to wait for Promise resolution
    )

    message = Dict{String,<:Any}(
        "sessionId" => page.session_id,
        "method" => "Runtime.evaluate",
        "params" => params,
        "id" => get_next_message_id()
    )

    page.verbose && @info "Sending evaluation request"
    response_channel = send_message(page.context.browser.session, message)
    response = take!(response_channel)
    page.verbose && @info "Received evaluation response"

    if !isnothing(response.error)
        error("Evaluation failed: $(response.error["message"])")
    end

    # Handle potential exceptions in the JavaScript execution
    if haskey(response.result, "exceptionDetails")
        error("JavaScript error: $(response.result["exceptionDetails"]["exception"]["description"])")
    end

    # Extract result and handle special cases
    result = response.result["result"]
    if result["type"] == "undefined" || (result["type"] == "object" && get(result, "subtype", "") == "null")
        return nothing
    end

    return get(result, "value", nothing)
end

"""
    wait_for_selector(page::Page, selector::AbstractString; timeout::Int=30000) -> ElementHandle

Waits for an element matching the selector to appear in page.

# Arguments
- `page::Page`: The page to search in
- `selector::AbstractString`: CSS selector to match
- `timeout::Int=30000`: Maximum time to wait in milliseconds

# Returns
- `ElementHandle`: Handle to the found element

# Throws
- `TimeoutError`: If element is not found within timeout period
"""
function wait_for_selector(page::Page, selector::AbstractString; timeout::Int=30000)
    retry_with_timeout(timeout=timeout, interval=100) do
        element = query_selector(page, selector)
        if isnothing(element)
            error("Element not found: $selector")
        end
        return element
    end
end

"""
    query_selector(page::Page, selector::AbstractString) -> Union{ElementHandle, Nothing}

Returns the first element matching the selector.
"""
function query_selector(page::Page, selector::AbstractString)
    page.verbose && @info "Querying selector" selector

    # First get the document root
    root_request = create_cdp_message("DOM.getDocument", Dict{String,<:Any}())
    root_message = Dict{String,<:Any}(
        "sessionId" => page.session_id,
        "method" => root_request.method,
        "params" => root_request.params,
        "id" => root_request.id
    )
    page.verbose && @info "Getting document root"
    root_response_channel = send_message(page.context.browser.session, root_message)
    root_response = take!(root_response_channel)
    page.verbose && @info "Received document root"

    if !isnothing(root_response.error)
        error("Failed to get document root: $(root_response.error["message"])")
    end

    root_node_id = root_response.result["root"]["nodeId"]

    # Then query the selector
    page.verbose && @info "Querying DOM for selector"
    params = Dict{String,<:Any}("nodeId" => root_node_id, "selector" => selector)
    request = create_cdp_message("DOM.querySelector", params)
    message = Dict{String,<:Any}(
        "sessionId" => page.session_id,
        "method" => request.method,
        "params" => request.params,
        "id" => request.id
    )

    response_channel = send_message(page.context.browser.session, message)
    response = take!(response_channel)
    page.verbose && @info "Received selector query response"

    if !isnothing(response.error)
        error("Query selector failed: $(response.error["message"])")
    end

    node_id = response.result["nodeId"]
    if node_id != 0
        # Set the __cdp_node_id__ property on the element
        js_code = """
        (() => {
            const element = document.querySelector('$(selector)');
            if (element) {
                element.__cdp_node_id__ = $(node_id);
                return true;
            }
            return false;
        })()
        """
        evaluate(page, js_code)
        return ElementHandle(page, node_id, Dict{String,<:Any}())
    end
    return nothing
end

"""
    screenshot(page::Page; options=Dict()) -> AbstractString

Takes a screenshot of the page and returns it as a base64-encoded string.
"""
function screenshot(page::Page; options::AbstractDict{String,<:Any}=Dict{String,<:Any}())
    page.verbose && @info "Taking screenshot" options

    params = Dict{String,<:Any}(
        "format" => get(options, "format", "png"),
        "quality" => get(options, "quality", 100),
        "fromSurface" => get(options, "fromSurface", true)
    )
    message = Dict{String,<:Any}(
        "sessionId" => page.session_id,
        "method" => "Page.captureScreenshot",
        "params" => params,
        "id" => get_next_message_id()
    )
    page.verbose && @info "Sending screenshot request"
    response_channel = send_message(page.context.browser.session, message)
    response = take!(response_channel)
    page.verbose && @info "Received screenshot response"

    if !isnothing(response.error)
        error("Screenshot failed: $(response.error["message"])")
    end

    return response.result["data"]  # Base64-encoded image data
end

"""
    screenshot(page::Page, path::AbstractString; options=Dict()) -> Nothing

Takes a screenshot of the page and saves it to the specified path.
"""
function screenshot(page::Page, path::AbstractString; options::AbstractDict{String,<:Any}=Dict{String,Any}())
    page.verbose && @info "Taking screenshot and saving to path" path options
    data = screenshot(page; options)
    decoded_data = Base64.base64decode(data)
    write(path, decoded_data)
    page.verbose && @info "Screenshot saved successfully" path
    nothing
end

function evaluate_script(page::Page, script::AbstractString, args::Vector=[])
    response = send_message(page.session, "Runtime.evaluate", Dict{String,<:Any}(
        "expression" => script,
        "arguments" => args,
        "returnByValue" => true,
        "awaitPromise" => true
    ))
    return response
end

"""
    url(page::Page) -> AbstractString

Gets the current URL of the page.
"""
function url(page::Page)
    evaluate(page, "window.location.href")
end

"""
    get_title(page::Page) -> AbstractString

Gets the current title of the page.
"""
function get_title(page::Page)
    evaluate(page, "document.title")
end

"""
    content(page::Page) -> AbstractString

Gets the full HTML content of the page.
"""
function content(page::Page)
    evaluate(page, "document.documentElement.outerHTML")
end

"""
    query_selector_all(page::Page, selector::AbstractString) -> Vector{ElementHandle}

Returns all elements matching the selector.
"""
function query_selector_all(page::Page, selector::AbstractString)
    page.verbose && @info "Querying all elements matching selector" selector

    # First get the document root
    page.verbose && @info "Getting document root"
    root_request = create_cdp_message("DOM.getDocument", Dict{String,<:Any}())
    root_message = Dict{String,<:Any}(
        "sessionId" => page.session_id,
        "method" => root_request.method,
        "params" => root_request.params,
        "id" => root_request.id
    )
    root_response_channel = send_message(page.context.browser.session, root_message)
    root_response = take!(root_response_channel)

    if !isnothing(root_response.error)
        error("Failed to get document root: $(root_response.error["message"])")
    end

    root_node_id = root_response.result["root"]["nodeId"]

    page.verbose && @info "Querying all matching elements"
    # Query all matching elements
    params = Dict{String,<:Any}("nodeId" => root_node_id, "selector" => selector)
    request = create_cdp_message("DOM.querySelectorAll", params)
    message = Dict{String,<:Any}(
        "sessionId" => page.session_id,
        "method" => request.method,
        "params" => request.params,
        "id" => request.id
    )

    response_channel = send_message(page.context.browser.session, message)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Query selector all failed: $(response.error["message"])")
    end

    page.verbose && @info "Creating element handles"
    # Create ElementHandle objects for each node
    elements = ElementHandle[]
    for node_id in response.result["nodeIds"]
        if node_id != 0
            push!(elements, ElementHandle(page, node_id, Dict{String,<:Any}()))
        end
    end

    page.verbose && @info "Found elements" count=length(elements)
    return elements
end

"""
    count_elements(page::Page, selector::AbstractString) -> Int

Returns the number of elements matching the selector.
"""
function count_elements(page::Page, selector::AbstractString)
    result = evaluate(page, """(() => {
        const elements = document.querySelectorAll('$(selector)');
        return elements ? elements.length : 0;
    })()""")
    return result === nothing ? 0 : convert(Int, result)
end

"""
    get_text(page::Page, selector::AbstractString) -> Union{AbstractString, Nothing}

Gets the text content of the first element matching the selector.
"""
function get_text(page::Page, selector::AbstractString)
    result = evaluate(page, """
    (() => {
        const element = document.querySelector('$(selector)');
        return element ? element.textContent : null;
    })()
    """)
    return result
end

"""
    is_checked(page::Page, selector::AbstractString) -> Bool

Returns true if the checkbox/radio element matching the selector is checked.
"""
function is_checked(page::Page, selector::AbstractString)
    evaluate(page, """(() => {
        const element = document.querySelector('$(selector)');
        return element ? element.checked : false;
    })()""")
end

"""
    is_visible(page::Page, selector::AbstractString) -> Bool

Returns true if the element matching the selector is visible.
"""
function is_visible(page::Page, selector::AbstractString)
    evaluate(page, """
    const element = document.querySelector('$(selector)');
    if (!element) return false;
    const style = window.getComputedStyle(element);
    return style && style.display !== 'none' && style.visibility !== 'hidden';
    """)
end

"""
    get_value(page::Page, selector::AbstractString) -> Union{AbstractString, Nothing}

Gets the value of the first form element matching the selector.
"""
function get_value(page::Page, selector::AbstractString)
    evaluate(page, """(() => {
        const element = document.querySelector('$(selector)');
        return element ? element.value : null;
    })()""")
end

"""
    click(page::Page, selector::AbstractString; options=Dict()) -> Nothing

Clicks an element matching the selector.
"""
function click(page::Page, selector::AbstractString; options::AbstractDict{String,<:Any}=Dict{String,Any}())
    page.verbose && @info "Clicking element" selector
    result = evaluate(page, """
    const element = document.querySelector('$(selector)');
    if (element) {
        element.click();
        return true;
    }
    return false;
    """)
    page.verbose && @info "Click operation completed" success=result
    nothing
end

"""
    type_text(page::Page, selector::AbstractString, text::AbstractString; options=Dict()) -> Nothing

Types text into an element matching the selector.
"""
function type_text(page::Page, selector::AbstractString, text::AbstractString; options::AbstractDict{String,<:Any}=Dict{String,Any}())
    page.verbose && @info "Typing text into element" selector text
    element = wait_for_selector(page, selector)
    if isnothing(element)
        error("Element not found: $selector")
    end

    page.verbose && @info "Element found, typing text"
    # Focus and type using JavaScript evaluation
    js_code = """
    (() => {
        const element = document.querySelector('$(selector)');
        if (!element) return null;
        element.focus();
        element.value = '$(text)';
        const inputEvent = new Event('input', { bubbles: true });
        element.dispatchEvent(inputEvent);
        const changeEvent = new Event('change', { bubbles: true });
        element.dispatchEvent(changeEvent);
        return element.value;
    })()
    """
    result = evaluate(page, js_code)

    if isnothing(result) || result != text
        error("Failed to type text: expected '$(text)', got '$(result)'")
    end
    page.verbose && @info "Text typed successfully"
    nothing
end

"""
    press_key(page::Page, key::AbstractString; options=Dict()) -> Nothing

Simulates pressing a keyboard key. The key should be a valid key value like "Enter", "Tab", "ArrowLeft", etc.
"""
function press_key(page::Page, key::AbstractString; options::AbstractDict{String,<:Any}=Dict{String,Any}())
    page.verbose && @info "Pressing key" key
    params = Dict{String,<:Any}(
        "type" => "keyDown",
        "key" => key
    )
    request = create_cdp_message("Input.dispatchKeyEvent", params)
    response_channel = send_message(page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Key press failed: $(response.error["message"])")
    end
    page.verbose && @info "Key press completed successfully" key
    nothing
end

"""
    select_option(page::Page, selector::AbstractString, value::AbstractString; options=Dict()) -> Nothing

Selects an option in a select element matching the selector.
"""
function select_option(page::Page, selector::AbstractString, value::AbstractString; options::AbstractDict{String,<:Any}=Dict{String,Any}())
    page.verbose && @info "Selecting option in select element" selector value
    result = evaluate(page, """(function() {
        const select = document.querySelector('$(selector)');
        if (!select) return false;
        const option = Array.from(select.options).find(o => o.value === '$(value)');
        if (!option) return false;
        select.value = '$(value)';
        select.dispatchEvent(new Event('change', { bubbles: true }));
        return true;
    })()""")

    if !result
        error("Failed to select option: $value in element: $selector")
    end
    page.verbose && @info "Option selected successfully" selector value
    nothing
end

export click, type_text, press_key, select_option

"""
    Base.close(page::Page)

Ensures proper cleanup of page resources.
"""
function Base.close(page::Page)
    page.verbose && @info "Closing page" target_id=page.target_id
    params = Dict{String,<:Any}("targetId" => page.target_id)
    request = create_cdp_message("Target.closeTarget", params)
    response_channel = send_message(page.context.browser.session, request)
    response = take!(response_channel)

    if !isnothing(response.error)
        error("Failed to close page: $(response.error["message"])")
    end

    # Remove page from context's pages list
    filter!(p -> p.target_id != page.target_id, page.context.pages)
    nothing
end

"""
    submit_form(page::Page, selector::AbstractString) -> Bool

Submits a form element matching the selector.
Returns true if successful, false otherwise.
"""
function submit_form(page::Page, selector::AbstractString)
    page.verbose && @info "Submitting form" selector
    evaluate(page, """(() => {
        const form = document.querySelector('$(selector)');
        if (!form) return false;

        // Find submit button and click it to trigger form submission properly
        const submitButton = form.querySelector('button[type="submit"]');
        if (submitButton) {
            submitButton.click();
            return true;
        }

        // Fallback to dispatching submit event if no submit button found
        const submitEvent = new Event('submit', { bubbles: true, cancelable: true });
        return form.dispatchEvent(submitEvent);
    })()""")
end

export goto, evaluate, wait_for_selector, query_selector, query_selector_all,
       get_value, get_text, click, type_text, press_key, select_option
