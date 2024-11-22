module TestUtils

using ChromeDevToolsLite
using JSON3

# Import abstract types
import ChromeDevToolsLite: AbstractWebSocketConnection, AbstractBrowserProcess, AbstractCDPSession

# Mock WebSocket for testing
mutable struct MockWebSocket <: ChromeDevToolsLite.AbstractWebSocketConnection
    io::IOBuffer
    is_closed::Bool
end

# Constructor
function MockWebSocket()
    MockWebSocket(IOBuffer(), false)
end

# Required interface methods
Base.close(ws::MockWebSocket) = (ws.is_closed = true; nothing)
Base.isopen(ws::MockWebSocket) = !ws.is_closed

function Base.write(ws::MockWebSocket, data)
    !isopen(ws) && throw(ErrorException("WebSocket is closed"))
    if data isa String
        write(ws.io, data)
    else
        write(ws.io, JSON3.write(data))
    end
end

function Base.read(ws::MockWebSocket)
    !isopen(ws) && throw(ErrorException("WebSocket is closed"))
    data = String(take!(ws.io))
    try
        return JSON3.read(data)
    catch
        return data
    end
end

# Mock Browser Process for testing
mutable struct MockBrowserProcess <: AbstractBrowserProcess
    endpoint::String
    options::Dict{String,Any}
    pid::Int
end

# Constructor
MockBrowserProcess() = MockBrowserProcess("http://localhost:9222", Dict{String,Any}(), 1234)

# Mock CDP Session for testing
mutable struct MockCDPSession <: AbstractCDPSession
    ws::MockWebSocket
    messages::Vector{Dict{String,Any}}
end

# Constructor and methods
MockCDPSession(ws::MockWebSocket) = MockCDPSession(ws, Dict{String,Any}[])

function ChromeDevToolsLite.send_message(session::MockCDPSession, message::Union{ChromeDevToolsLite.CDPRequest, AbstractDict{AbstractString}}; timeout::Union{Real,Nothing}=nothing)
    msg_dict = message isa ChromeDevToolsLite.CDPRequest ? Dict{String,Any}("method" => message.method, "params" => message.params) : message
    push!(session.messages, msg_dict)
    write(session.ws, msg_dict)

    # Create a channel and put a mock response in it
    response_channel = Channel{ChromeDevToolsLite.CDPResponse}(1)
    put!(response_channel, ChromeDevToolsLite.CDPResponse(nothing, Dict{String,Any}("browserContextId" => "mock-context-id")))
    return response_channel
end

# Helper function to get last message
function get_last_message(ws::MockWebSocket, offset::Int=-1)
    data = read(ws)
    return data isa Dict ? data : JSON3.read(data)
end

export MockWebSocket, MockBrowserProcess, MockCDPSession, get_last_message

end
