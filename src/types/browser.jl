"""
    Browser

Represents a browser instance with an active CDP session and process management.
"""
mutable struct Browser <: AbstractBrowser
    process::BrowserProcess
    session::CDPSession
    contexts::Vector{AbstractBrowserContext}
    options::Dict{String,<:Any}
    verbose::Bool
end

"""
    Browser(;headless::Bool=true, port::Union{Int,Nothing}=nothing) -> Browser

Create and launch a new browser instance with the specified options.
"""
function Browser(;headless::Bool=true, port::Union{Int,Nothing}=nothing, debug::Bool=false, verbose::Bool=false)
    launch_browser(;headless=headless, port=port, debug=debug, verbose=verbose)
end

"""
    launch_browser(;headless::Bool=true, port::Union{Int,Nothing}=nothing, debug::Bool=false) -> Browser

Launch a new browser instance with the specified options.
"""
function launch_browser(;headless::Bool=true, port::Union{Int,Nothing}=nothing, debug::Bool=false, verbose::Bool=false)
    process = launch_browser_process(;headless=headless, port=port, debug=debug)

    verbose && @info "Establishing WebSocket connection..."
    try
        ws_info = JSON3.read(HTTP.get("$(process.endpoint)/json/version").body)
        ws_url = ws_info["webSocketDebuggerUrl"]
        debug && @info "Connecting to WebSocket at $ws_url"

        # Create a channel for the WebSocket connection
        ws_channel = Channel{WebSocketConnection}(1)

        # Start WebSocket connection in a task
        task = @async WebSockets.open(ws_url) do ws
            ws_conn = WebSocketConnection(ws)
            ws_conn.task = current_task()
            put!(ws_channel, ws_conn)
            while ws_conn.is_open
                sleep(0.1)  # Keep connection alive
            end
        end

        # Wait for WebSocket connection
        ws_conn = take!(ws_channel)
        session = CDPSession(ws_conn; verbose=verbose)
        verbose && @info "WebSocket connection established"

        # Create a new target
        create_target = create_cdp_message("Target.createTarget", Dict{String,Any}("url" => "about:blank"))
        response_channel = send_message(session, create_target)
        response = take!(response_channel)
        if !isnothing(response.error)
            error("Failed to create target: $(response.error["message"])")
        end
        target_id = response.result["targetId"]

        # Attach to the target
        attach_params = Dict{String,Any}("targetId" => target_id, "flatten" => true)
        attach_target = create_cdp_message("Target.attachToTarget", attach_params)
        response_channel = send_message(session, attach_target)
        response = take!(response_channel)
        if !isnothing(response.error)
            error("Failed to attach to target: $(response.error["message"])")
        end
        session_id = response.result["sessionId"]

        # Now enable Runtime domain on the target
        enable_runtime = Dict{String,Any}(
            "sessionId" => session_id,
            "method" => "Runtime.enable",
            "params" => Dict(),
            "id" => get_next_message_id()
        )
        response_channel = send_message(session, enable_runtime)
        response = take!(response_channel)
        if !isnothing(response.error)
            error("Failed to enable Runtime domain: $(response.error["message"])")
        end
        verbose && @info "Runtime domain enabled"

        return Browser(process, session, AbstractBrowserContext[], process.options, verbose)
    catch e
        kill_browser_process(process)
        error("Failed to establish WebSocket connection: $e")
    end
end

"""
    contexts(browser::Browser) -> Vector{BrowserContext}

Retrieves all browser contexts.
"""
function contexts(browser::Browser)
    return browser.contexts
end

"""
    create_browser_context(browser::Browser) -> BrowserContext

Creates a new browser context.
"""
function create_browser_context(browser::Browser)
    browser.verbose && @info "Creating new browser context"
    context = BrowserContext(browser)  # This already creates the CDP context
    push!(browser.contexts, context)
    return context
end

# Alias for backward compatibility
const new_context = create_browser_context

"""
    Base.show(io::IO, browser::Browser)

Custom display for Browser instances.
"""
function Base.show(io::IO, browser::Browser)
    context_count = length(browser.contexts)
    print(io, "Browser(contexts=$context_count)")
end

"""
    Base.close(browser::Browser)

Ensures proper cleanup of browser resources.
"""
function Base.close(browser::Browser)
    browser.verbose && @info "Closing browser and cleaning up resources"
    close(browser.session)
    kill_browser_process(browser.process)
end

export launch_browser, contexts, new_context, create_browser_context
