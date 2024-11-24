"""
    new_context(client::WSClient; viewport::Dict{String,Any}=Dict(), user_agent::String="") -> Page

Create a new browser context with optional viewport and user agent settings.

# Example
```julia
client = connect_browser()
context = new_context(client,
    viewport=Dict("width" => 1920, "height" => 1080),
    user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X)")
```
"""
function new_context(client::WSClient; viewport::Dict{String,Any}=Dict(), user_agent::String="")
    # Create new context
    result = send_cdp(client, "Target.createBrowserContext", Dict{String,Any}())
    context_id = get(get(result, "result", Dict()), "browserContextId", "")

    # Create new page in context
    page = new_page(client, context_id)

    # Configure viewport if provided
    if !isempty(viewport)
        set_viewport(page;
            width=get(viewport, "width", 1280),
            height=get(viewport, "height", 720),
            device_scale_factor=get(viewport, "deviceScaleFactor", 1.0),
            mobile=get(viewport, "mobile", false)
        )
    end

    # Set user agent if provided
    if !isempty(user_agent)
        send_cdp(page.client, "Network.setUserAgentOverride", Dict{String,Any}(
            "userAgent" => user_agent
        ))
    end

    return page
end

"""
    new_page(client::WSClient, context_id::String="") -> Page

Create a new page in the specified browser context.
"""
function new_page(client::WSClient, context_id::String="")
    params = Dict{String,Any}("url" => "about:blank")
    if !isempty(context_id)
        params["browserContextId"] = context_id
    end

    result = send_cdp(client, "Target.createTarget", params)
    target_id = get(get(result, "result", Dict()), "targetId", "")

    # Get WebSocket URL for the new target
    endpoint = replace(client.ws_url, r"ws://[^/]+/" => "http://localhost:9222/")
    targets = JSON3.read(HTTP.get("$(endpoint)json/list").body)
    target = findfirst(t -> t["id"] == target_id, targets)
    ws_url = target["webSocketDebuggerUrl"]

    # Create new client and page
    new_client = WSClient(ws_url)
    connect!(new_client)
    return Page(new_client, target_id)
end

"""
    get_all_pages(client::WSClient) -> Vector{Page}

Get all available page targets as Page objects.
"""
function get_all_pages(client::WSClient)
    pages = Page[]
    endpoint = replace(client.ws_url, r"ws://[^/]+/" => "http://localhost:9222/")
    targets = JSON3.read(HTTP.get("$(endpoint)json/list").body)

    for target in targets
        if target["type"] == "page"
            new_client = WSClient(target["webSocketDebuggerUrl"])
            connect!(new_client)
            push!(pages, Page(new_client, target["id"]))
        end
    end

    return pages
end
