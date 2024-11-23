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

"""
    with_retry(f::Function; max_retries::Int = MAX_RETRIES, retry_delay::Real = RETRY_DELAY, verbose::Bool = false)

Executes the function `f` with retry logic. It will attempt to execute `f` up to `max_retries` times, waiting `retry_delay` seconds between attempts.

# Arguments
- `f::Function`: The function to execute with retries.
- `max_retries::Int`: The maximum number of retries.
- `retry_delay::Real`: The delay between retries in seconds.
- `verbose::Bool`: Whether to print verbose debug information.

# Returns
- The result of executing `f` if successful.

# Throws
- The last exception encountered if all retries fail.
"""
function with_retry(f::Function; max_retries::Int = MAX_RETRIES,
        retry_delay::Real = RETRY_DELAY, verbose::Bool = false)
    for attempt in 1:max_retries
        try
            verbose && @debug "Attempt $attempt/$max_retries"
            return f()
        catch e
            if attempt == max_retries
                verbose && @error "All retry attempts failed" exception=e
                rethrow(e)
            else
                verbose && @warn "Attempt $attempt failed, retrying..." exception=e
                sleep(retry_delay)
            end
        end
    end
end
