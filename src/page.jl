# Add extras dictionary to store page metadata
const PAGE_EXTRAS = Dict{String, Dict{String, Any}}()

"""
    get_target_info(page::Page) -> Dict{String, Any}

Get information about the current target (page) using CDP command Target.getTargetInfo.
"""
function get_target_info(page::Page)
    result = send_cdp(page.client, "Target.getTargetInfo", Dict{String, Any}())
    return get(result, "result", Dict{String, Any}())
end

"""
    update_page!(page::Page) -> Page

Update page metadata using Target.getTargetInfo and save to page extras.
"""
function update_page!(page::Page)
    PAGE_EXTRAS[page.target_id] = get_target_info(page)
    return page
end

"""
    get_page_info(page::Page) -> Dict{String, Any}

Get the latest page metadata by updating the page and returning extras.
"""
function get_page_info(page::Page)
    update_page!(page)
    return get(PAGE_EXTRAS, page.target_id, Dict{String, Any}())
end

# Enhanced show method for Page type
function Base.show(io::IO, page::Page)
    info = get(PAGE_EXTRAS, page.target_id, Dict{String, Any}())
    url = get(info, "url", "unknown")
    print(io, "Page(id: $(page.target_id), url: $url)")
end

"""
    goto(client::WSClient, url::String; verbose::Bool=false)

Navigate to the specified URL and wait for page load.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `url::String`: The URL to navigate to
- `verbose::Bool`: Enable verbose logging (default: false)

# Throws
- `NavigationError`: If navigation fails or times out
"""
function goto(client::WSClient, url::String; verbose::Bool = false)
    verbose && @debug "Navigating to URL" url=url
    # Enable page domain first
    send_cdp(client, "Page.enable", Dict{String, Any}())

    # Navigate to URL
    result = send_cdp(client, "Page.navigate", Dict{String, Any}("url" => url))

    # Check for navigation errors
    if haskey(result, "errorText")
        throw(NavigationError("Navigation failed: $(result["errorText"])"))
    end

    # Wait for page load
    load_event = wait_for_event(client, "Page.loadEventFired")
    if load_event === nothing || haskey(load_event, "error")
        throw(NavigationError("Page load timed out or failed"))
    end

    # Enable runtime for JavaScript evaluation
    send_cdp(client, "Runtime.enable", Dict{String, Any}())

    verbose && @info "Page navigation completed" url=url
    return nothing
end

"""
    wait_for_event(client::WSClient, event_name::String; timeout::Float64=5.0) -> Union{Dict, Nothing}

Wait for a specific CDP event to occur.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `event_name::String`: Name of the event to wait for
- `timeout::Float64`: Maximum time to wait in seconds (default: 5.0)

# Returns
- `Dict`: The event data if received
- `Nothing`: If timeout occurs or error happens

# Notes
- Used internally for synchronizing page operations
"""
function wait_for_event(client::WSClient, event_name::String; timeout::Float64 = 5.0)
    start_time = time()
    while time() - start_time < timeout
        msg = try
            take!(client.message_channel)
        catch e
            return nothing
        end

        if haskey(msg, "method") && msg["method"] == event_name
            return msg
        end
    end
    return nothing
end

"""
    evaluate(client::WSClient, expression::String; verbose::Bool=false) -> Any

Evaluate JavaScript in the page context and return the result.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `expression::String`: JavaScript expression to evaluate
- `verbose::Bool`: Enable verbose logging (default: false)

# Returns
- `Any`: The result of the JavaScript evaluation, or nothing if no value returned

# Throws
- `EvaluationError`: If JavaScript evaluation fails
"""
function evaluate(client::WSClient, expression::String; verbose::Bool = false)
    verbose && @debug "Evaluating JavaScript" expression=expression
    response = send_cdp(
        client, "Runtime.evaluate", Dict{String, Any}("expression" => expression))

    result = extract_element_result(response)
    verbose && isnothing(result) && @warn "Evaluation returned no value"

    return result
end

"""
    screenshot(client::WSClient; verbose::Bool=false) -> String

Take a screenshot of the current page.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `verbose::Bool`: Enable verbose logging (default: false)

# Returns
- `String`: Base64 encoded string of the screenshot, or nothing if capture fails
"""
function screenshot(client::WSClient; verbose::Bool = false)
    verbose && @debug "Taking page screenshot"
    # Enable page domain if not already enabled
    send_cdp(client, "Page.enable", Dict{String, Any}())
    result = send_cdp(client, "Page.captureScreenshot", Dict{String, Any}())
    if result isa Dict && haskey(result, "result") && haskey(result["result"], "data")
        verbose && @debug "Screenshot captured successfully"
        return result["result"]["data"]
    end
    verbose && @warn "Screenshot capture failed"
    return nothing
end

"""
    content(client::WSClient; verbose::Bool=false) -> String

Get the HTML content of the current page.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `verbose::Bool`: Enable verbose logging (default: false)

# Returns
- `String`: The HTML content of the page
"""
function content(client::WSClient; verbose::Bool = false)
    evaluate(client, "document.documentElement.outerHTML"; verbose = verbose)
end

"""
    get_viewport(page::Page) -> Dict{String, Any}

Get the current viewport metrics using Page.getLayoutMetrics.
"""
function get_viewport(page::Page)
    result = send_cdp(page.client, "Page.getLayoutMetrics", Dict{String, Any}())
    return get(result, "result", Dict{String, Any}())
end

"""
    set_viewport(page::Page; width::Int=1280, height::Int=720, device_scale_factor::Float64=1.0,
                mobile::Bool=false) -> Nothing

Set viewport metrics using Emulation.setDeviceMetricsOverride.
"""
function set_viewport(page::Page; width::Int=1280, height::Int=720,
                     device_scale_factor::Float64=1.0, mobile::Bool=false)
    send_cdp(page.client, "Emulation.setDeviceMetricsOverride", Dict{String,Any}(
        "width" => width,
        "height" => height,
        "deviceScaleFactor" => device_scale_factor,
        "mobile" => mobile
    ))
    return nothing
end

"""
    query_selector(page::Page, selector::String) -> Union{Dict, Nothing}

Find the first element matching the given selector using DOM.querySelector.
"""
function query_selector(page::Page, selector::String)
    # First, get the document root
    root = send_cdp(page.client, "DOM.getDocument", Dict{String,Any}("depth" => 0))
    root_node_id = get(root, "result", Dict())["root"]["nodeId"]

    # Then find the element
    result = send_cdp(page.client, "DOM.querySelector", Dict{String,Any}(
        "nodeId" => root_node_id,
        "selector" => selector
    ))

    node_id = get(get(result, "result", Dict()), "nodeId", 0)
    return node_id != 0 ? Dict("nodeId" => node_id) : nothing
end

"""
    query_selector_all(page::Page, selector::String) -> Vector{Int}

Find all elements matching the given selector using DOM.querySelectorAll.
"""
function query_selector_all(page::Page, selector::String)
    # First, get the document root
    root = send_cdp(page.client, "DOM.getDocument", Dict{String,Any}("depth" => 0))
    root_node_id = get(root, "result", Dict())["root"]["nodeId"]

    # Then find all matching elements
    result = send_cdp(page.client, "DOM.querySelectorAll", Dict{String,Any}(
        "nodeId" => root_node_id,
        "selector" => selector
    ))

    return get(get(result, "result", Dict()), "nodeIds", Int[])
end

"""
    get_element_info(page::Page, selector::String) -> Dict{String, Any}

Get detailed information about the first element matching the selector.
"""
function get_element_info(page::Page, selector::String)
    node = query_selector(page, selector)
    isnothing(node) && return Dict{String,Any}()

    result = send_cdp(page.client, "DOM.describeNode", Dict{String,Any}(
        "nodeId" => node["nodeId"],
        "depth" => 1
    ))

    node_info = get(result, "result", Dict{String,Any}())
    if haskey(node_info, "node")
        node_data = node_info["node"]
        return Dict{String,Any}(
            "tag" => get(node_data, "nodeName", ""),
            "attributes" => get(node_data, "attributes", String[]),
            "classes" => split(get(Dict(zip(get(node_data, "attributes", String[])...)), "class", ""), " "),
            "child_count" => get(node_data, "childNodeCount", 0),
            "id" => get(Dict(zip(get(node_data, "attributes", String[])...)), "id", ""),
            "text_content" => get(node_data, "nodeValue", "")
        )
    end

    return Dict{String,Any}()
end

"""
    evaluate_handle(client::WSClient, expression::String; verbose::Bool=false) -> Any

Evaluate JavaScript in the page context and return a handle to the result.
Useful for evaluating expressions that return DOM elements or complex objects.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `expression::String`: JavaScript expression to evaluate
- `verbose::Bool`: Enable verbose logging (default: false)

# Returns
- `Any`: A handle to the evaluated result, typically a Dict containing object reference

# Throws
- `EvaluationError`: If JavaScript evaluation fails
"""
function evaluate_handle(client::WSClient, expression::String; verbose::Bool = false)
    verbose && @debug "Evaluating JavaScript for handle" expression=expression
    response = send_cdp(
        client, "Runtime.evaluate",
        Dict{String, Any}(
            "expression" => expression,
            "returnByValue" => false
        )
    )

    if haskey(response, "result") && haskey(response["result"], "result")
        verbose && @debug "Handle evaluation successful"
        return response["result"]["result"]
    end

    verbose && @warn "Handle evaluation returned no result"
    return nothing
end
