"""
    retry_with_timeout(f::Function; timeout::Int=5000, interval::Int=100) -> Any

Retry a function until it succeeds or timeout is reached.
Returns the function's return value if successful, throws TimeoutError if timeout is reached.

# Arguments
- `f::Function`: Function to retry
- `timeout::Int=5000`: Maximum time to wait in milliseconds
- `interval::Int=100`: Time between retries in milliseconds
"""
function retry_with_timeout(f::Function; timeout::Int=5000, interval::Int=100)
    start_time = time() * 1000  # Convert to milliseconds
    last_error = nothing

    while (time() * 1000 - start_time) < timeout
        try
            result = f()
            if !isnothing(result)
                return result
            end
        catch e
            last_error = e
        end
        sleep(interval / 1000)  # Convert to seconds
    end

    throw(TimeoutError("Operation timed out after $(timeout)ms", last_error))
end

export retry_with_timeout
