"""
Module for managing CDP sessions and message routing.
"""

using Base.Threads
using ..ChromeDevToolsLite: TimeoutError, retry_with_timeout

mutable struct CDPSession
    ws::AbstractWebSocketConnection
    callbacks::Dict{Int, Channel{CDPResponse}}
    event_listeners::Dict{String, Vector{Function}}
    lock::ReentrantLock
    is_closed::Ref{Bool}
end

"""
    CDPSession(ws::AbstractWebSocketConnection)

Create a new CDP session with the given WebSocket connection.
"""
function CDPSession(ws::AbstractWebSocketConnection)
    session = CDPSession(
        ws,
        Dict{Int, Channel{CDPResponse}}(),
        Dict{String, Vector{Function}}(),
        ReentrantLock(),
        Ref(false)
    )

    # Start message processing task
    @async process_messages(session)

    return session
end

"""
    send_message(session::CDPSession, msg::CDPRequest) -> Channel{CDPResponse}

Send a CDP request and return a channel that will receive the response.
Throws ConnectionError if the session is closed.
"""
function send_message(session::CDPSession, msg::Union{CDPRequest,Dict{String,Any}}; timeout::Int=5000)
    if session.is_closed[]
        throw(ConnectionError("Cannot send message: CDP session is closed"))
    end

    response_channel = Channel{CDPResponse}(1)
    msg_id = msg isa CDPRequest ? msg.id : msg["id"]

    lock(session.lock) do
        session.callbacks[msg_id] = response_channel
    end

    try
        json_msg = msg isa CDPRequest ? JSON3.write(msg) : JSON3.write(msg)
        @info "Sending CDP message: $json_msg"  # Debug log
        write(session.ws, json_msg)

        # Create timeout task
        timeout_task = @async begin
            sleep(timeout / 1000)
            if !isopen(response_channel)
                return
            end
            lock(session.lock) do
                delete!(session.callbacks, msg_id)
            end
            close(response_channel)
        end

        return response_channel
    catch e
        delete!(session.callbacks, msg_id)
        close(response_channel)
        throw(ConnectionError("Failed to send CDP message: $e"))
    end
end

"""
    add_event_listener(session::CDPSession, method::String, callback::Function)

Add a callback function for a specific CDP event method.
"""
function add_event_listener(session::CDPSession, method::String, callback::Function)
    @info "Adding event listener" method=method
    lock(session.lock) do
        if !haskey(session.event_listeners, method)
            @info "Creating new listener array for method" method=method
            session.event_listeners[method] = Function[]
        end
        @info "Current listeners for method" method=method count=length(session.event_listeners[method])
        push!(session.event_listeners[method], callback)
        @info "Added listener successfully" method=method new_count=length(session.event_listeners[method])
    end
end

"""
    remove_event_listener(session::CDPSession, method::String, callback::Function)

Remove a callback function for a specific CDP event method.
"""
function remove_event_listener(session::CDPSession, method::String, callback::Function)
    lock(session.lock) do
        if haskey(session.event_listeners, method)
            filter!(f -> f !== callback, session.event_listeners[method])
        end
    end
end

"""
    process_messages(session::CDPSession)

Process incoming CDP messages and route them to appropriate handlers.
"""
function process_messages(session::CDPSession)
    try
        while !session.is_closed[]
            if !isopen(session.ws)
                throw(ConnectionError("WebSocket connection closed unexpectedly"))
            end

            data = try
                message = read(session.ws)
                @info "Received CDP message: $message"
                JSON3.read(message, Dict{String, Any})
            catch e
                if session.is_closed[]
                    break
                end
                throw(ConnectionError("Failed to read CDP message: $e"))
            end

            msg = parse_cdp_message(data)
            @info "Parsed CDP message" type=typeof(msg) msg=msg

            if msg isa CDPResponse
                @info "Processing response" id=msg.id callbacks=keys(session.callbacks)
                lock(session.lock) do
                    if haskey(session.callbacks, msg.id)
                        @info "Found callback for message" id=msg.id
                        try
                            put!(session.callbacks[msg.id], msg)
                            delete!(session.callbacks, msg.id)
                            @info "Successfully delivered response" id=msg.id
                        catch e
                            @error "Failed to deliver response" msg_id=msg.id exception=e
                        end
                    else
                        @warn "No callback found for message" id=msg.id
                    end
                end
            elseif msg isa CDPEvent
                @info "Processing CDP event" method=msg.method
                lock(session.lock) do
                    # Log current event listeners state
                    @info "Current event listeners" methods=keys(session.event_listeners)

                    if haskey(session.event_listeners, msg.method)
                        @info "Found listeners for method" method=msg.method count=length(session.event_listeners[msg.method])
                        for callback in session.event_listeners[msg.method]
                            @async try
                                @info "Executing callback for event" method=msg.method
                                callback(msg.params)
                                @info "Callback executed successfully" method=msg.method
                            catch e
                                @error "Event listener failed" method=msg.method exception=e stacktrace=stacktrace()
                            end
                        end
                    else
                        @debug "No listeners registered for event method" method=msg.method
                    end
                end
            end
        end
    catch e
        session.is_closed[] = true
        if e isa ConnectionError
            @warn "CDP connection closed: $(e.msg)"
        else
            @error "Unexpected error processing CDP messages" exception=e
        end
        rethrow(e)
    end
end

"""
    Base.close(session::CDPSession)

Close the CDP session and clean up resources.
"""
function Base.close(session::CDPSession)
    session.is_closed[] = true
    close(session.ws)

    # Clean up callbacks
    lock(session.lock) do
        for channel in values(session.callbacks)
            close(channel)
        end
        empty!(session.callbacks)
        empty!(session.event_listeners)
    end
end

export CDPSession, send_message, add_event_listener, remove_event_listener
