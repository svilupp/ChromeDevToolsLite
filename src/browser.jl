"""
    ensure_browser_available(
        endpoint::String;
        max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY,
        verbose::Bool = false
)

Checks if Chrome is running in debug mode on the specified endpoint.
Retries up to `max_retries` times with specified `retry_delay` between attempts.
Returns `true` if Chrome is responding on the debug port.

# Arguments
- `endpoint::String`: The URL of the Chrome debugging endpoint. Eg, `http://localhost:9222`.
- `max_retries::Int`: The maximum number of retries to check for Chrome.
- `retry_delay::Real`: The delay between retries in seconds.
- `verbose::Bool`: Whether to print verbose debug information.
"""
function ensure_browser_available(
        endpoint::String;
        max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY,
        verbose::Bool = false
)
    for attempt in 1:max_retries
        try
            verbose && @debug "Checking Chrome debug port (attempt $attempt/$max_retries)"
            response = HTTP.get("$endpoint/json/version")
            if response.status == 200
                verbose && @info "Chrome is running" version=String(response.body)
                return true
            else
                error("Unexpected response status: $(response.status)")
            end
        catch e
            if attempt < max_retries
                verbose &&
                    @warn "Chrome not responding, retrying..." attempt=attempt exception=e
                sleep(retry_delay)
            else
                @error "Chrome failed to respond after $max_retries attempts" exception=e
                return false
            end
        end
    end
    return false
end

"""
    get_or_create_page_target(endpoint::String; verbose::Bool = false)

Retrieves an available page target or creates a new one if none are available.
Returns the target dictionary containing details like `id` and `webSocketDebuggerUrl`.
"""
function get_or_create_page_target(endpoint::String; verbose::Bool = false)
    # Get available targets
    response = HTTP.get("$endpoint/json/list")
    targets = JSON3.read(response.body)

    # Find an available page target
    for target in targets
        if target["type"] == "page" &&
           !contains(get(target, "url", ""), "chrome-extension://") &&
           !get(target, "attached", false)
            verbose && @info "Found available page target" id=target["id"]
            return target
        end
    end

    # No suitable page found, create a new one
    verbose && @info "Creating new page target"
    response = HTTP.get("$endpoint/json/new")
    target = JSON3.read(String(response.body))
    verbose && @info "Created new page target" id=target["id"]
    return target
end

"""
    connect_browser(
        endpoint::String = "http://localhost:9222";
        max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY,
        timeout::Real = CONNECTION_TIMEOUT,
        verbose::Bool = false
)

Connects to Chrome browser at the given debugging endpoint with enhanced error handling.
Returns a WSClient connected to a new page.

# Arguments
- `endpoint::String`: The URL of the Chrome debugging endpoint. Eg, `http://localhost:9222`.
- `max_retries::Int`: The maximum number of retries to check for Chrome.
- `retry_delay::Real`: The delay between retries in seconds.
- `timeout::Real`: The timeout for the connection in seconds.
- `verbose::Bool`: Whether to print verbose debug information.
"""
function connect_browser(
        endpoint::String = "http://localhost:9222";
        max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY,
        timeout::Real = CONNECTION_TIMEOUT,
        verbose::Bool = false
)
    client = with_retry(
        max_retries = max_retries, retry_delay = retry_delay, verbose = verbose) do
        verbose && @info "Connecting to browser" endpoint=endpoint

        # Ensure Chrome is available with more retries for startup
        ensure_browser_available(endpoint; max_retries = max_retries, verbose = verbose) ||
            throw(ConnectionError("Chrome browser not available at $endpoint"))

        # Get or create a page target with retry
        local page_target
        try
            page_target = get_or_create_page_target(endpoint; verbose = verbose)
        catch e
            throw(ConnectionError("Failed to create page target: $(sprint(showerror, e))"))
        end

        # Establish WebSocket connection
        ws_url = page_target["webSocketDebuggerUrl"]
        verbose && @debug "Creating WSClient" ws_url=ws_url target_id=page_target["id"]

        client = WSClient(ws_url, endpoint)
        try
            connect!(client; max_retries = max_retries,
                retry_delay = retry_delay, timeout = timeout, verbose = verbose)
        catch e
            throw(ConnectionError("Failed to establish WebSocket connection: $(sprint(showerror, e))"))
        end

        # Enable required domains with proper error handling
        try
            send_cdp(client, "Page.enable", Dict())
            send_cdp(client, "Runtime.enable", Dict())
            send_cdp(client, "DOM.enable", Dict())
            send_cdp(client, "CSS.enable")
            send_cdp(client, "Network.enable")
        catch e
            throw(ConnectionError("Failed to enable CDP domains: $(sprint(showerror, e))"))
        end

        # Verify the connection
        try
            result = send_cdp(client, "Browser.getVersion", Dict(); increment_id = false)
            haskey(result, "result") ||
                throw(ConnectionError("Invalid response from Browser.getVersion"))
            verbose && @info "Connected to browser" version=get(
                result["result"], "product", "unknown")
        catch e
            throw(ConnectionError("Failed to verify browser connection: $(sprint(showerror, e))"))
        end

        return client
    end

    # Initialize browser state with proper error handling
    # try
    #     send_cdp(client, "Page.navigate", Dict("url" => "about:blank"))
    # catch e
    #     @warn "Failed to navigate to blank page" exception=e
    # end

    return client
end

"""
    new_context(
        client::WSClient; viewport::Dict{String, Any} = Dict(), user_agent::String = "")

Create a new browser context with optional viewport and user agent settings.

Note: Requires for the Chrome to be launched with `--enable-features=NetworkService,NetworkServiceInProcess`

# Example
```julia
client = connect_browser()
context = new_context(client,
    viewport=Dict("width" => 1920, "height" => 1080),
    user_agent="Mozilla/5.0 (iPhone; CPU iPhone OS 14_7_1 like Mac OS X)")
```
"""
function new_context(
        client::WSClient;
        viewport::Dict{String, Any} = Dict(),
        user_agent::String = ""
)
    # Create new context
    result = send_cdp(client, "Target.createBrowserContext", Dict{String, Any}())
    context_id = get(get(result, "result", Dict()), "browserContextId", "")

    # Create new page in context
    page = new_page(client, context_id)

    # Configure viewport if provided
    if !isempty(viewport)
        set_viewport!(page;
            width = get(viewport, "width", 1280),
            height = get(viewport, "height", 720),
            device_scale_factor = get(viewport, "deviceScaleFactor", 1.0),
            mobile = get(viewport, "mobile", false)
        )
    end

    # Set user agent if provided
    if !isempty(user_agent)
        send_cdp(page.client, "Network.setUserAgentOverride",
            Dict{String, Any}(
                "userAgent" => user_agent
            ))
    end

    return page
end
