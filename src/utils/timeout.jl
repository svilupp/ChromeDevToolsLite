"""
    with_timeout(f::Function, timeout::Int) -> Any

Execute function f with a timeout (in milliseconds).
Throws TimeoutError if the operation times out.
"""
function with_timeout(f::Function, timeout::Int)
    result_channel = Channel{Any}(1)

    @async begin
        try
            result = f()
            put!(result_channel, (:ok, result))
        catch e
            put!(result_channel, (:error, e))
        end
    end

    timer = Timer(timeout / 1000) do t
        put!(result_channel, (:timeout, nothing))
    end

    result = take!(result_channel)
    close(timer)
    close(result_channel)

    if result[1] == :timeout
        throw(TimeoutError("Operation timed out after $(timeout)ms"))
    elseif result[1] == :error
        throw(result[2])
    else
        return result[2]
    end
end

"""
    retry_with_timeout(f::Function; timeout::Int=5000, interval::Int=100) -> Any

Retry a function until it succeeds or timeout is reached.
Returns the function's return value if successful, throws TimeoutError if timeout is reached.

# Arguments
- `f::Function`: Function to retry
- `timeout::Int=5000`: Maximum time to wait in milliseconds
- `interval::Int=100`: Time between retries in milliseconds
"""
function retry_with_timeout(f::Function; timeout::Int = 5000, interval::Int = 100)
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
