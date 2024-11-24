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

                        # Handle Inspector.detached events with more robust reconnection
                        if get(data, "method", "") == "Inspector.detached"
                            reason = get(get(data, "params", Dict()), "reason", "unknown")
                            @warn "Chrome DevTools detached" reason=reason

                            if reason ∈ ["target_closed", "Render process gone.", "canceled"]
                                client.is_connected = false
                                # Try to reconnect if the connection was lost
                                try
                                    try_connect(client; max_retries=3, retry_delay=1.0)
                                    @info "Successfully reconnected after detachment"
                                catch e
                                    @error "Failed to reconnect after detachment" exception=e
                                end
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
    try_connect(client::WSClient; max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY, timeout::Real = CONNECTION_TIMEOUT,
        verbose::Bool = false)
        retry_delay::Real = RETRY_DELAY, verbose::Bool = false)

Attempt to establish a WebSocket connection with retry logic and timeout.
"""
function try_connect(client::WSClient; max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY, timeout::Real = CONNECTION_TIMEOUT,
        verbose::Bool = false)
    with_retry(max_retries = max_retries, retry_delay = retry_delay, verbose = verbose) do
        verbose && @debug "Attempting WebSocket connection" url=client.ws_url

        # Channel for connection status with buffer for race conditions
        connection_status = Channel{Union{WebSocket, Exception}}(2)

        # Connection task
        @async begin
            try
                WebSockets.open(client.ws_url; suppress_close_error = true) do ws
                    client.ws = ws
                    client.is_connected = true
                    put!(connection_status, ws)

                    # Keep connection alive with heartbeat
                    while client.is_connected && !WebSockets.isclosed(ws)
                        try
                            # Send a heartbeat message every 30 seconds
                            if isopen(ws)
                                WebSockets.send(ws, JSON3.write(Dict("id" => -1, "method" => "HeartBeat")))
                            end
                        catch e
                            @warn "Heartbeat failed" exception=e
                            break
                        end
                        sleep(30)
                    end
                end
            catch e
                put!(connection_status, e)
            end
        end

        # Timeout task
        @async begin
            sleep(timeout)
            if !isready(connection_status)
                put!(connection_status,
                    TimeoutError("Connection timeout after $(timeout) seconds"))
            end
        end

        # Wait for connection result with proper cleanup
        result = take!(connection_status)
        close(connection_status)

        isa(result, Exception) && throw(result)

        verbose && @debug "WebSocket connection established" url=client.ws_url
        return client
    end
end

"""
    connect!(client::WSClient; max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY, verbose::Bool = false)

Connect to Chrome DevTools Protocol WebSocket endpoint.
Returns the connected client.

# Arguments
- `max_retries::Int`: The maximum number of retries to establish the connection.
- `retry_delay::Real`: The delay between retries in seconds.
- `verbose::Bool`: Whether to print verbose debug information.
"""
function connect!(client::WSClient; max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY, verbose::Bool = false)
    if client.is_connected
        verbose && @debug "Client already connected"
        return client
    end

    try_connect(
        client; max_retries = max_retries, retry_delay = retry_delay, verbose = verbose)
    start_message_handler(client)
    return client
end

"""
    send_cdp(
        client::WSClient, method::String, params::Dict = Dict();
        increment_id::Bool = true, timeout::Real = CONNECTION_TIMEOUT)

Send a Chrome DevTools Protocol message and wait for the response.

# Arguments
- `client::WSClient`: The WebSocket client to use
- `method::String`: The CDP method to call (e.g., "Page.navigate")
- `params::Dict`: Parameters for the CDP method (default: empty Dict)
- `increment_id::Bool`: Whether to increment the message ID counter (default: true)
- `timeout::Real`: The timeout for the response in seconds (default: CONNECTION_TIMEOUT)

# Returns
- `Dict`: The CDP response message

# Throws
- `TimeoutError`: If response times out
"""
function send_cdp(
        client::WSClient, method::String, params::Dict = Dict();
        increment_id::Bool = true, timeout::Real = CONNECTION_TIMEOUT)
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

            # Create a separate task for timeout
            timeout_task = @async begin
                sleep(timeout)
                # Instead of closing the channel, put an error message
                put!(response_channel,
                    Dict{String, Any}("error" => Dict("type" => "TimeoutError",
                        "message" => "CDP response timeout after $(timeout) seconds")))
            end

            try
                while client.is_connected
                    msg = take!(client.message_channel)
                    if haskey(msg, "id") && msg["id"] == id
                        # Cancel timeout task if we got a response
                        if !istaskdone(timeout_task)
                            schedule(timeout_task, InterruptException(); error = true)
                        end
                        put!(response_channel, msg)
                        break
                    end
                end
            catch e
                # Remove timeout_reached check since we're not using that flag anymore
                rethrow(e)
            end
        catch e
            if e isa InterruptException
                # Ignore interrupts from canceling the timeout task
                return
            end
            @error "Error sending CDP message" exception=e method=method
            put!(response_channel,
                Dict("error" => Dict("message" => "Failed to send message: $e")))
        end
    end

    response = take!(response_channel)

    if haskey(response, "error")
        error_data = response["error"]
        if get(error_data, "type", "") == "TimeoutError"
            throw(TimeoutError(error_data["message"]))
        end
        error("CDP Error: $error_data")
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
