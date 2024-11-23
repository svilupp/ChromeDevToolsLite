"""
    CDPMessage

Represents a Chrome DevTools Protocol message.
"""
struct CDPMessage
    id::Int
    method::String
    params::Dict{String,Any}
    sessionId::Union{String,Nothing}
end

"""
    CDPParams

Helper functions to create properly typed CDP parameters.
"""
module CDPParams
    export create_params

    function create_params(; kwargs...)
        params = Dict{String,Any}()
        for (k, v) in pairs(kwargs)
            params[String(k)] = convert_value(v)
        end
        params
    end

    function convert_value(v::Dict)
        Dict(String(k) => convert_value(val) for (k, val) in v)
    end
    convert_value(v::Number) = Float64(v)
    convert_value(v::Bool) = v
    convert_value(v) = String(v)
end
