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
        verbose::Bool = false
)

Connects to Chrome browser at the given debugging endpoint with enhanced error handling.

# Arguments
- `endpoint::String`: The URL of the Chrome debugging endpoint. Eg, `http://localhost:9222`.
- `max_retries::Int`: The maximum number of retries to check for Chrome.
- `retry_delay::Real`: The delay between retries in seconds.
- `verbose::Bool`: Whether to print verbose debug information.
"""
function connect_browser(
        endpoint::String = "http://localhost:9222";
        max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY,
        verbose::Bool = false
)
    client = with_retry(
        max_retries = max_retries, retry_delay = retry_delay, verbose = verbose) do
        verbose && @info "Connecting to browser" endpoint=endpoint

        # Ensure Chrome is available
        ensure_browser_available(endpoint; max_retries = 1, verbose = verbose) ||
            error("Chrome browser not available at $endpoint")

        # Get or create a page target
        page_target = get_or_create_page_target(endpoint; verbose = verbose)

        # Establish WebSocket connection
        ws_url = page_target["webSocketDebuggerUrl"]
        verbose && @debug "Creating WSClient" ws_url=ws_url target_id=page_target["id"]

        client = WSClient(ws_url)
        connect!(client; max_retries = 1, retry_delay = retry_delay, verbose = verbose)

        # Verify the connection
        result = send_cdp(
            client, "Browser.getVersion", Dict(); increment_id = false)

        haskey(result, "result") || error("Failed to verify browser connection")

        verbose &&
            @info "Connected to browser" version=get(result["result"], "product", "unknown")
        return client
    end

    return client
end
