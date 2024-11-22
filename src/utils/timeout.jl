"""
    TimeoutError

Custom error type for timeout-related errors.
"""
struct TimeoutError <: Exception
    msg::String
end

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

    timer = Timer(timeout/1000) do t
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
    retry_with_timeout(f::Function; timeout::Int=30000, interval::Int=100) -> Any

Retry function f until it succeeds or timeout is reached.
Waits interval milliseconds between retries.
"""
function retry_with_timeout(f::Function; timeout::Int=30000, interval::Int=100)
    start_time = time()
    timeout_seconds = timeout / 1000
    interval_seconds = interval / 1000

    while (time() - start_time) < timeout_seconds
        try
            return f()
        catch e
            if e isa TimeoutError
                throw(e)
            end
            sleep(interval_seconds)
        end
    end

    throw(TimeoutError("Operation timed out after $(timeout)ms"))
end

export TimeoutError, with_timeout, retry_with_timeout
