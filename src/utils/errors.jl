"""
Module containing all error types and error handling utilities for ChromeDevToolsLite
"""

"""
    ChromeDevToolsError

Base error type for all ChromeDevToolsLite errors.
"""
abstract type ChromeDevToolsError <: Exception end

"""
    ConnectionError

Error raised when there are issues with the CDP connection.
"""
struct ConnectionError <: ChromeDevToolsError
    msg::String
end

"""
    NavigationError

Error raised when page navigation fails.
"""
struct NavigationError <: ChromeDevToolsError
    msg::String
end

"""
    ElementNotFoundError

Error raised when an element cannot be found on the page.
"""
struct ElementNotFoundError <: ChromeDevToolsError
    msg::String
end

"""
    EvaluationError

Error raised when JavaScript evaluation fails.
"""
struct EvaluationError <: ChromeDevToolsError
    msg::String
end

"""
    TimeoutError <: ChromeDevToolsError

Error raised when an operation times out.
"""
struct TimeoutError <: ChromeDevToolsError
    msg::String
    cause::Union{Nothing, Exception}
    TimeoutError(msg::String, cause::Union{Nothing, Exception}=nothing) = new(msg, cause)
end

"""
    handle_cdp_error(response::Dict) -> Nothing

Handle CDP response errors by throwing appropriate error types.
"""
function handle_cdp_error(response::Dict)
    if haskey(response, "error")
        error_data = response["error"]
        code = get(error_data, "code", -1)
        message = get(error_data, "message", "Unknown CDP error")

        # Map CDP error codes to specific error types
        if code == -32000  # Protocol error
            throw(ConnectionError(message))
        elseif code == -32602  # Invalid params
            throw(ArgumentError(message))
        elseif occursin("Navigation failed", message)
            throw(NavigationError(message))
        elseif occursin("Node", message) || occursin("element", message)
            throw(ElementNotFoundError(message))
        elseif occursin("Evaluation failed", message)
            throw(EvaluationError(message))
        else
            throw(ChromeDevToolsError(message))
        end
    end
    nothing
end

export ChromeDevToolsError, ConnectionError, NavigationError,
       ElementNotFoundError, EvaluationError, TimeoutError, handle_cdp_error
