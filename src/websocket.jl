"""
    start_message_handler(client::WSClient)

Start an asynchronous task to handle incoming WebSocket messages.
"""
function start_message_handler(client::WSClient)
    @async begin
        try
            while client.is_connected && !isnothing(client.ws)
                try
                    msg = WebSockets.receive(client.ws)
                    if !isnothing(msg)
                        data = JSON3.read(msg, Dict)

                        # Handle Inspector.detached events
                        if get(data, "method", "") == "Inspector.detached"
                            reason = get(get(data, "params", Dict()), "reason", "unknown")
                            @warn "Chrome DevTools detached" reason=reason

                            if reason ∈ ["target_closed", "Render process gone."]
                                client.is_connected = false
                                break
                            end
                        end

                        put!(client.message_channel, data)
                    end
                catch e
                    if isa(e, WebSocketError) && e.status == 1000
                        @debug "WebSocket closed normally"
                        break
                    elseif isa(e, ArgumentError) && occursin("receive() requires", e.msg)
                        @debug "WebSocket connection closed"
                        break
                    else
                        @error "Error receiving message" exception=e
                        client.is_connected = false
                        break
                    end
                end
            end
        finally
            client.is_connected = false
        end
    end
end

"""
    try_connect(client::WSClient) -> WSClient

Attempt to establish a WebSocket connection with retry logic and timeout.
"""
function try_connect(client::WSClient)
    for attempt in 1:MAX_RECONNECT_ATTEMPTS
        try
            @debug "Attempting connection" attempt=attempt url=client.ws_url

            # Create channels for connection status
            connection_status = Channel{Union{WebSocket, Exception}}(1)

            # Create a connection task
            @async begin
                try
                    WebSockets.open(client.ws_url; suppress_close_error = true) do ws
                        client.ws = ws
                        client.is_connected = true
                        put!(connection_status, ws)

                        # Keep connection alive until explicitly closed
                        while client.is_connected && !WebSockets.isclosed(ws)
                            sleep(0.1)
                        end
                    end
                catch e
                    put!(connection_status, e)
                end
            end

            # Wait for either connection success or timeout
            @async begin
                sleep(CONNECTION_TIMEOUT)
                if !isready(connection_status)
                    put!(connection_status,
                        TimeoutError("Connection timeout after $(CONNECTION_TIMEOUT) seconds"))
                end
            end

            # Wait for result
            result = take!(connection_status)

            if isa(result, Exception)
                throw(result)
            end

            @debug "Connection established" attempt=attempt
            return client

        catch e
            @warn "Connection attempt $attempt failed" exception=e
            if attempt == MAX_RECONNECT_ATTEMPTS
                error("Failed after $MAX_RECONNECT_ATTEMPTS attempts: $e")
            end
            sleep(RECONNECT_DELAY * attempt)
        end
    end
    error("Failed to establish WebSocket connection")
end

"""
    connect!(client::WSClient) -> WSClient

Connect to Chrome DevTools Protocol WebSocket endpoint.
Establishes a WebSocket connection and starts the message handler.

# Arguments
- `client::WSClient`: The WebSocket client to connect

# Returns
- `WSClient`: The connected client instance

# Throws
- `TimeoutError`: If connection times out
- `ConnectionError`: If connection fails after max retries
"""
function connect!(client::WSClient)
    if client.is_connected
        @debug "Client already connected"
        return client
    end

    try_connect(client)
    start_message_handler(client)
    return client
end

"""
    send_cdp_message(client::WSClient, method::String, params::Dict=Dict(); increment_id::Bool=true) -> Dict

Send a Chrome DevTools Protocol message and wait for the response.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `method::String`: The CDP method to call (e.g., "Page.navigate")
- `params::Dict`: Parameters for the CDP method (default: empty Dict)
- `increment_id::Bool`: Whether to increment the message ID counter (default: true)

# Returns
- `Dict`: The CDP response message

# Throws
- `TimeoutError`: If response times out
- `ConnectionError`: If connection is lost during message exchange
"""
function send_cdp_message(
        client::WSClient, method::String, params::Dict = Dict(); increment_id::Bool = true)
    if !client.is_connected || isnothing(client.ws)
        @warn "WebSocket not connected, attempting reconnection"
        try_connect(client)
    end

    # Convert params to Dict{String,Any}
    typed_params = Dict{String, Any}(String(k) => v for (k, v) in params)

    id = client.next_id
    if increment_id
        client.next_id += 1
    end

    message = Dict{String, Any}(
        "id" => id,
        "method" => method,
        "params" => typed_params
    )

    response_channel = Channel{Dict{String, Any}}(1)

    @async begin
        try
            WebSockets.send(client.ws, JSON3.write(message))

            # Add timeout for response
            timeout_task = @task begin
                sleep(CONNECTION_TIMEOUT)
                put!(response_channel,
                    Dict("error" => Dict("message" => "Response timeout")))
            end

            while client.is_connected
                msg = take!(client.message_channel)
                if haskey(msg, "id") && msg["id"] == id
                    schedule(timeout_task, InterruptException(); error = true)
                    put!(response_channel, msg)
                    break
                end
            end
        catch e
            @error "Error sending CDP message" exception=e method=method
            put!(response_channel,
                Dict("error" => Dict("message" => "Failed to send message: $e")))
        end
    end

    response = take!(response_channel)

    if haskey(response, "error")
        error("CDP Error: $(response["error"])")
    end

    return response
end

"""
    Base.close(client::WSClient)

Close the WebSocket connection and clean up resources.

# Arguments
- `client::WSClient`: The WebSocket client to close
"""
function close(client::WSClient)
    if client.is_connected && !isnothing(client.ws)
        client.is_connected = false
        try
            close(client.ws)
        catch e
            @debug "Error during WebSocket closure" exception=e
        end
        client.ws = nothing
    end
end

"""
    handle_event(client::WSClient, event::Dict)

Process CDP events.
"""
function handle_event(client::WSClient, event::Dict)
    try
        method = get(event, "method", nothing)
        if !isnothing(method)
            if method == "Page.loadEventFired"
                put!(client.message_channel, event)
            end
            # Add more event handlers as needed
        end
    catch e
        if isa(e, WebSocketError) && e.status == 1000
            # Normal close, ignore
            @debug "WebSocket closed normally"
            return
        else
            # Real error, rethrow
            rethrow(e)
        end
    end
end

"""
    is_connected(ws::WebSocket)

Check if the WebSocket connection is still active.
"""
function is_connected(ws::WebSocket)
    try
        return !WebSockets.isclosed(ws)
    catch
        return false
    end
end
