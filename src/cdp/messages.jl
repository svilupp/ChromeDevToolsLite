"""
Module for handling Chrome DevTools Protocol (CDP) messages.
"""

using JSON3.StructTypes

# Message Types
abstract type AbstractCDPMessage end

struct CDPRequest <: AbstractCDPMessage
    id::Int
    method::String
    params::AbstractDict{String, Any}
end

struct CDPResponse <: AbstractCDPMessage
    id::Int
    result::Union{AbstractDict{String, Any}, Nothing}
    error::Union{AbstractDict{String, Any}, Nothing}
end

struct CDPEvent <: AbstractCDPMessage
    method::String
    params::AbstractDict{String, Any}
end

# Message Creation
"""
    create_cdp_message(method::String, params::Dict{String, Any}=Dict()) -> CDPRequest

Create a new CDP request message with an automatically generated ID.
"""
function create_cdp_message(method::String, params::AbstractDict{String, Any}=Dict{String, Any}())
    id = Base.Threads.atomic_add!(MESSAGE_ID_COUNTER, 1)
    CDPRequest(id, method, params)
end

# Message ID Counter
const MESSAGE_ID_COUNTER = Base.Threads.Atomic{Int}(0)

# Message Serialization
function JSON3.StructTypes.StructType(::Type{<:AbstractCDPMessage})
    JSON3.StructTypes.CustomStruct()
end

function JSON3.StructTypes.lower(msg::CDPRequest)
    Dict("id" => msg.id, "method" => msg.method, "params" => msg.params)
end

function JSON3.StructTypes.lower(msg::CDPResponse)
    if !isnothing(msg.error)
        Dict("id" => msg.id, "error" => msg.error)
    else
        Dict("id" => msg.id, "result" => msg.result)
    end
end

function JSON3.StructTypes.lower(msg::CDPEvent)
    Dict("method" => msg.method, "params" => msg.params)
end

# Message Parsing
"""
    parse_cdp_message(data::Dict{String, Any}) -> AbstractCDPMessage

Parse a raw CDP message into the appropriate message type.
"""
function parse_cdp_message(data::AbstractDict{String, Any})
    if haskey(data, "id")
        if haskey(data, "method")
            return CDPRequest(data["id"], data["method"], get(data, "params", Dict{String, Any}()))
        else
            return CDPResponse(
                data["id"],
                get(data, "result", nothing),
                get(data, "error", nothing)
            )
        end
    else
        return CDPEvent(data["method"], get(data, "params", Dict{String, Any}()))
    end
end

export AbstractCDPMessage, CDPRequest, CDPResponse, CDPEvent,
       create_cdp_message, parse_cdp_message, MESSAGE_ID_COUNTER

"""
    get_next_message_id() -> Int

Get the next message ID for CDP communication.
"""
function get_next_message_id()
    Base.Threads.atomic_add!(MESSAGE_ID_COUNTER, 1)
end

export get_next_message_id
