"""
    ElementNotFoundError(msg)

Error thrown when an element cannot be found on the page using the specified selector.
"""
struct ElementNotFoundError <: Exception
    msg::String
end

"""
    NavigationError(msg)

Error thrown when page navigation fails or times out.
"""
struct NavigationError <: Exception
    msg::String
end

"""
    EvaluationError(msg)

Error thrown when JavaScript evaluation fails.
"""
struct EvaluationError <: Exception
    msg::String
end

"""
    extract_cdp_result(response::Dict, path::Vector{String}=["result", "result", "value"])

Extract values from CDP responses with configurable path traversal.
Returns the extracted value or nothing if the path doesn't exist.
"""
function extract_cdp_result(
        response::Dict, path::Vector{String} = ["result", "result", "value"])
    current = response
    for key in path
        if haskey(current, key)
            current = current[key]
        else
            return nothing
        end
    end

    # Handle nested value objects
    if current isa Dict && haskey(current, "value")
        return current["value"]
    end

    return current
end

"""
    extract_element_result(response::Dict)

Extract element-specific results from CDP responses.
"""
function extract_element_result(response::Dict)
    # Try different path combinations to extract the result
    paths = [
        ["result", "result", "value"],  # Standard CDP path
        ["result", "result"],           # Direct result object
        ["result", "value"],            # Shallow result with value
        ["result"]                      # Direct result
    ]

    for path in paths
        result = extract_cdp_result(response, path)
        if !isnothing(result)
            # If we got a Dict with success/value pattern, extract the value
            if result isa Dict && haskey(result, "success") && haskey(result, "value")
                return result["success"] ? result["value"] : nothing
            end
            return result
        end
    end

    return nothing
end
