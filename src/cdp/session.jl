"""
Module for managing CDP sessions and message routing.
"""

"""
    CDPSession

Represents a Chrome DevTools Protocol session managing WebSocket communication and message routing.
"""
mutable struct CDPSession{T}
    ws::T
    callbacks::AbstractDict{Int, Channel{CDPResponse}}
    event_listeners::Dict{String, Vector{Function}}  # Keep concrete type for initialization
    lock::ReentrantLock
    is_closed::Ref{Bool}
    verbose::Bool
    message_task::Union{Task, Nothing}  # Add message processing task reference
end

"""
    CDPSession(ws::T; verbose::Bool=false) where T

Create a new CDP session with the given WebSocket connection.
"""
function CDPSession(ws::T; verbose::Bool = false) where {T}
    session = CDPSession{T}(
        ws,
        Dict{Int, Channel{CDPResponse}}(),
        Dict{String, Vector{Function}}(),
        ReentrantLock(),
        Ref(false),
        verbose,
        nothing  # Initialize message_task as nothing
    )

    # Start message processing task
    session.message_task = @async process_messages(session)

    return session
end

"""
    send_message(session::CDPSession, msg::CDPRequest) -> Channel{CDPResponse}

Send a CDP request and return a channel that will receive the response.
Throws ConnectionError if the session is closed.
"""
function send_message(
        session::CDPSession, msg::Union{CDPRequest, AbstractDict{AbstractString, <:Any}};
        timeout::Int = 5000)
    if session.is_closed[]
        throw(ConnectionError("Cannot send message: CDP session is closed"))
    end
    !isopen(session.ws) && throw(ConnectionError("WebSocket connection is closed"))

    response_channel = Channel{CDPResponse}(1)
    msg_id = msg isa CDPRequest ? msg.id : msg["id"]

    # Register callback
    lock(session.lock) do
        session.callbacks[msg_id] = response_channel
    end

    try
        json_msg = msg isa CDPRequest ? JSON3.write(msg) : JSON3.write(msg)
        session.verbose && @info "Sending CDP message" message=json_msg
        write(session.ws, json_msg)

        # Setup timeout for response
        timeout_task = @async begin
            sleep(timeout / 1000)
            if isopen(response_channel)
                lock(session.lock) do
                    if haskey(session.callbacks, msg_id)
                        delete!(session.callbacks, msg_id)
                        close(response_channel)
                    end
                end
            end
        end

        return response_channel
    catch e
        lock(session.lock) do
            delete!(session.callbacks, msg_id)
        end
        isopen(response_channel) && close(response_channel)
        throw(ConnectionError("Failed to send CDP message: $e"))
    end
end

"""
    add_event_listener(session::CDPSession, method::AbstractString, callback::Function)

Add a callback function for a specific CDP event method.
"""
function add_event_listener(session::CDPSession, method::AbstractString, callback::Function)
    session.verbose && @info "Adding event listener" method=method
    lock(session.lock) do
        if !haskey(session.event_listeners, method)
            session.verbose && @info "Creating new listener array for method" method=method
            session.event_listeners[method] = Function[]
        end
        session.verbose &&
            @info "Current listeners for method" method=method count=length(session.event_listeners[method])
        push!(session.event_listeners[method], callback)
        session.verbose &&
            @info "Added listener successfully" method=method new_count=length(session.event_listeners[method])
    end
end

"""
    remove_event_listener(session::CDPSession, method::AbstractString, callback::Function)

Remove a callback function for a specific CDP event method.
"""
function remove_event_listener(
        session::CDPSession, method::AbstractString, callback::Function)
    lock(session.lock) do
        if haskey(session.event_listeners, method)
            filter!(f -> f !== callback, session.event_listeners[method])
        end
    end
end

"""
    process_messages(session::CDPSession)

Process incoming CDP messages and route them to appropriate handlers.

# API Private
"""
function process_messages(session::CDPSession)
    try
        while !session.is_closed[]
            if !isopen(session.ws)
                throw(ConnectionError("WebSocket connection closed unexpectedly"))
            end

            data = try
                read_channel = Channel{Any}(1)
                read_task = @async begin
                    try
                        message = read(session.ws)
                        if !session.is_closed[] && isopen(read_channel)
                            put!(read_channel, message)
                        end
                    catch e
                        if !session.is_closed[] && isopen(read_channel)
                            put!(read_channel, e)
                        end
                    finally
                        isopen(read_channel) && close(read_channel)
                    end
                end

                timeout_task = @async begin
                    sleep(5.0)  # 5 second timeout
                    if !istaskdone(read_task) && isopen(read_channel)
                        put!(read_channel,
                            TimeoutError("WebSocket read operation timed out"))
                        close(read_channel)
                    end
                end

                message = try
                    take!(read_channel)
                finally
                    isopen(read_channel) && close(read_channel)
                end

                if message isa Exception
                    throw(message)
                end

                if isempty(message)
                    session.verbose && @info "Received empty message, skipping"
                    continue
                end
                session.verbose && @info "Received CDP message" message=message
                JSON3.read(message)
            catch e
                if session.is_closed[]
                    return
                end
                throw(e)
            end

            # Handle response messages
            if haskey(data, "id")
                session.verbose && @info "Processing response message" data=data
                response = if data isa JSON3.Object
                    CDPResponse(data)
                else
                    CDPResponse(
                        data["id"],
                        get(data, "result", nothing),
                        get(data, "error", nothing)
                    )
                end
                lock(session.lock) do
                    if haskey(session.callbacks, response.id)
                        channel = session.callbacks[response.id]
                        if isopen(channel)
                            put!(channel, response)
                        end
                        delete!(session.callbacks, response.id)
                    end
                end
                # Handle event messages
            elseif haskey(data, "method")
                session.verbose && @info "Processing CDP event" method=data["method"]
                lock(session.lock) do
                    session.verbose &&
                        @info "Current event listeners" methods=keys(session.event_listeners)

                    if haskey(session.event_listeners, data["method"])
                        session.verbose &&
                            @info "Found listeners for method" method=data["method"] count=length(session.event_listeners[data["method"]])
                        for callback in session.event_listeners[data["method"]]
                            @async try
                                session.verbose &&
                                    @info "Executing callback for event" method=data["method"]
                                callback(data["params"])
                                session.verbose &&
                                    @info "Callback executed successfully" method=data["method"]
                            catch e
                                session.verbose &&
                                    @error "Event listener failed" method=data["method"] exception=e stacktrace=stacktrace()
                            end
                        end
                    else
                        session.verbose &&
                            @debug "No listeners registered for event method" method=data["method"]
                    end
                end
            end
        end
    catch e
        if !session.is_closed[]
            @error "Error in message processing" exception=e
            rethrow(e)
        end
    finally
        # Ensure all callbacks are cleaned up
        lock(session.lock) do
            for channel in values(session.callbacks)
                isopen(channel) && close(channel)
            end
            empty!(session.callbacks)
        end
    end
end

"""
    Base.close(session::CDPSession)

Close the CDP session and clean up resources.
"""
function Base.close(session::CDPSession)
    session.is_closed[] = true

    # Clean up callbacks and event listeners
    lock(session.lock) do
        for channel in values(session.callbacks)
            isopen(channel) && close(channel)
        end
        empty!(session.callbacks)
        empty!(session.event_listeners)
    end

    # Close WebSocket connection
    if isopen(session.ws)
        try
            close(session.ws)
        catch e
            session.verbose && @warn "Error closing WebSocket" exception=e
        end
    end

    # Wait for message processing task with timeout
    if !isnothing(session.message_task) && !istaskdone(session.message_task)
        timeout_task = @async begin
            sleep(5.0)  # 5 second timeout
            if !istaskdone(session.message_task)
                try
                    schedule(session.message_task, InterruptException(), error = true)
                catch
                end
            end
        end

        try
            wait(session.message_task)
        catch e
            session.verbose && @warn "Message task interrupted during shutdown" exception=e
        finally
            wait(timeout_task)
        end
    end
end

export CDPSession, send_message, add_event_listener, remove_event_listener
